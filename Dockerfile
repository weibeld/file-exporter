FROM alpine:3.15
RUN apk add socat
ENV DIR=/srv/metrics \
    PORT=9872
CMD socat \
      TCP4-LISTEN:"$PORT",fork,reuseaddr \
      SYSTEM:"echo 'HTTP/1.1 200 OK'; echo; cat \"$DIR\"/*"
