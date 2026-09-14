FROM alpine:3.10
LABEL org.opencontainers.image.authors="e1z0, OhmegaStar" \
    org.opencontainers.image.source="https://github.com/OhmegaStar/nbe-blackstar-homeassistant" \
    org.opencontainers.image.description="NBE Blackstar+ pellet burner MQTT integration for Home Assistant"

RUN apk add --no-cache \
    bash \
    python3 \
    py3-pip \
    py3-simplejson \
    py3-crypto \
    py3-paho-mqtt

COPY /docker/docker_init /docker_init
COPY /src /app
COPY /config.env-example /config.env-example

ENTRYPOINT ["/docker_init"]