# Generic Prometheus Exporter

Dead simple Prometheus exporter that serves metrics stored in local files over HTTP for Prometheus to scrape.

## Description

This exporter gathers the content of files in a specific directory (configurable) and exposes it on a specific port (configurable) over HTTP.

> The files in the directory are supposed to contain Prometheus metrics in the [Prometheus metrics format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format). However, the format of these files is neither checked nor enforced, so the exporter could also be used to expose other data than Prometheus metrics.

The exported data can be queried by clients over HTTP on any path (including the `/metrics` path which is used by default by Prometheus).

## Configuration

Some aspects of the exporter can be configured through the following environment variables:

- `DIR`: directory containing the data files (default `/srv/metrics`)
- `PORT`: port that the exporter listens on (default 8080)

## Usage

A possible usage for this exporter is to use it as a sidecar container in Kubernetes to export the metrics of another container:

```yaml
spec:
  containers:
    - name: app
      image: <image:tag>
      volumeMounts:
        - name: metrics
          mountPath: /root/metrics
    - name: generic-exporter
      image: weibeld/generic-exporter:0.0.1
      ports:
        - name: metrics
          containerPort: 8080
      volumeMounts:
        - name: metrics
          mountPath: /srv/metrics
  volumes:
    - name: metrics
      emptyDir: {}
```

The above [PodSpec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#podspec-v1-core) specifies two containers that share an [emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) volume. Now, in order for the `app` container to export its metrics, all it has to do is to dump them as files in the [Prometheus metrics format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format) into its mount of the emptyDir volume (`/root/metrics`). From there, the metrics are then picked up, combined, and served by the `generic-exporter` container whenever it receives a request from a client.

The metrics can be accessed by clients under `http://<pod-ip>:8080`.

Note that any other URL path also works, for example, `http://<pod-ip>:8080/metrics` is also a valid request (this URL uses the `/metrics` path which is used by default by Prometheus).

To configure the exporter, you can set the appropriate environment variables in the container specification:

```yaml
    - name: generic-exporter
      image: weibeld/generic-exporter:0.0.1
      env:
        - name: DIR
          value: /home/my_metrics
        - name: PORT
          value: "9099"
      ports:
        - name: metrics
          containerPort: 9099
      volumeMounts:
        - name: metrics
          mountPath: /home/my_metrics
```

The above uses `/home/my_metrics` as the metrics directory and listens on port 9099 instead.

> If you change the metrics directory and port, don't forget to also updates the corresponding fields in the `ports` and `volumeMounts` fields of the container specification.
