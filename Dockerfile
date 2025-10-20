FROM alpine:3.10
LABEL org.opencontainers.image.authors="e1z0, OhmegaStar"

RUN apk add --no-cache \
    bash \
    python3 \
    py3-pip \
    py3-simplejson \
    py3-crypto \
    py3-paho-mqtt

COPY /docker/docker_init /docker_init
COPY /src /app

ENTRYPOINT ["/docker_init"]