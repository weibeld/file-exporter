# File Exporter

Dead simple Prometheus exporter that serves metrics stored in local files over HTTP.

[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/weibeld/file-exporter?color=blue&label=docker%20hub&sort=semver)](https://hub.docker.com/r/weibeld/file-exporter)

## Description

This exporter combines the content of one or more files in a directory ([configurable](#configuration)) and serves it on a specific port ([configurable](#configuration)) over HTTP.

The basic idea is as follows: to export metrics from any process, just write them in the [Prometheus metrics format](https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format) to one or more files in the configured directory, and the exporter will take care of exposing them over HTTP for Prometheus to scrape.

> **Note:** the exporter does neither check nor enforce the Prometheus metrics format in the files it serves. That means, any inconsistencies will only be reported by Prometheus at scrape time. However, it also means that the exporter can also be used for other data than metrics, as it's in fact just a very simple HTTP server.

The exposed metrics can be scraped on any HTTP path, including `/metrics` which is used by default by Prometheus.

## Configuration

The exporter can be configured through the following environment variables:

| Name | Description | Default value |
|------|-------------|---------------|
| `DIR` | Directory containing the files to serve | `/srv/metrics` |
| `PORT` | Port on which the content is served | 9872 |

## Use case

A common use case for this exporter is using it as a sidecar container in Kubernetes for exporting the metrics of another container:

```yaml
spec:
  containers:
    - name: app
      image: <image:tag>
      volumeMounts:
        - name: metrics
          mountPath: /root/metrics
    - name: exporter
      image: weibeld/file-exporter:0.0.1
      ports:
        - name: metrics
          containerPort: 9872
      volumeMounts:
        - name: metrics
          mountPath: /srv/metrics
  volumes:
    - name: metrics
      emptyDir: {}
```

The above [PodSpec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#podspec-v1-core) defines two containers that share an [emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir) volume. The `app` container can have its metrics exported by the `exporter` container by simply writing them to one or more files in its mount of the emptyDir volume (in that case, `/root/metrics`). The `exporter` container will then combine and serve the metrics in these files whenever it receives a scrape request.

Prometheus can scrape the `exporter` container under the following URL:

```
http://<pod-ip>:9872/metrics
```

> **Note:** as mentioned, any other HTTP path would also work, for example, `http://<pod-ip>:9872`.

### Custom configuration

To customise the configurable parameters of the exporter, you can assign custom values to the corresponding environment variables in the container specification:

```yaml
    - name: exporter
      image: weibeld/file-exporter:0.0.1
      env:
        - name: DIR
          value: /metrics
        - name: PORT
          value: "10000"
      ports:
        - name: metrics
          containerPort: 10000
      volumeMounts:
        - name: metrics
          mountPath: /metrics
```

> **Attention:** when you change the values of the environment variables, don't forget to also update the corresponding values in other parts of the container specification, such as in `volumeMounts` or `ports`.
