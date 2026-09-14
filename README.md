# NBE Blackstar+/RTB Pellet Burners Home Assistant Integration

<img src="https://github.com/e1z0/nbe-blackstar-homeassistant/raw/master/pics/nbe_blackstar_plus.png" width=45% height=45%><img src="https://github.com/e1z0/nbe-blackstar-homeassistant/raw/master/pics/nbe1.png" width=45% height=45%>

**Runs as a service or Docker container.**

# Requirements

* MQTT broker
* Home Assistant or compatible home automation system such as OpenHab, IoBroker, or Node-Red

# Compatible Pellet Burners

* NBE RTB 10, 10 VAC, 16, 16 VAC, 30, 30 VAC, 50, 50 VAC, and 80 (v13 controller)
* NBE BS+ (Blackstar+) 10, 16, and 25 (v13 controller)

If you do not know your model, compare the controller with the [NBE RTB/BS manual](https://www.nbe.dk/wp-content/uploads/2017/07/RTB-BS-Manual-V13-ENG-08.03.2017.pdf).

# Released Docker image

Released images are published to GitHub Container Registry:

```text
ghcr.io/ohmegastar/nbe:latest
ghcr.io/ohmegastar/nbe:aarch64
```

The image contains no user configuration. At startup it requires the runtime environment variables shown in [config.env-example](config.env-example). Credentials generate the container's temporary `/app/config.json` and are not printed.

For a direct Docker run, copy the safe template, edit it, and pass it at runtime:

```powershell
Copy-Item config.env-example config.env
# Edit config.env with the burner and MQTT settings
docker run --rm --name nbe --env-file config.env ghcr.io/ohmegastar/nbe:latest
```

The image includes `/config.env-example` as a safe configuration reference. The real `config.env` and `config.json` are not included in the image.

For private GHCR images, authenticate with a GitHub token that has package read access. Public packages require no registry login.

# Docker Compose

Use the included Compose files for common architectures. Edit their environment values before starting:

* `docker-compose.yml` is for x86_64.
* `docker-compose_aarch64.yml` is for ARM64.

```powershell
make up
make up_aarch64
```

Stop the service with:

```powershell
make down
make down_aarch64
```

# Standard install without Docker

Move files from `src/` to `/opt/nbe`, copy `nbe.service` to `/etc/systemd/system`, and edit the configuration file. Install the Python dependencies:

```bash
pip3 install pycrypto paho-mqtt simplejson
systemctl enable nbe && systemctl start nbe
```

# Features

* Various sensors
* Climate control for hot water
* Climate control for the pellet burner itself

# Customization

<img src="https://github.com/e1z0/nbe-blackstar-homeassistant/raw/master/pics/nbe2.png" width=40% height=40%>

You can enable different sensors and controls by editing `src/nbe_schema`. The configuration controls the burner connection, MQTT connection, refresh rate, logging, and Home Assistant device naming.

Development, testing, local image validation, and release instructions are in [docs/TOOLING.md](docs/TOOLING.md).
