# NBE Blackstar+/RTB Pellet Burners Home Assistant Integration

<img src="https://github.com/e1z0/nbe-blackstar-homeassistant/raw/master/pics/nbe_blackstar_plus.png" width=45% height=45%><img src="https://github.com/e1z0/nbe-blackstar-homeassistant/raw/master/pics/nbe1.png" width=45% height=45%>

**Runs as service or as docker container**

# Requirements

* MQTT Broker server
* Home Assistant or compatible home automation system OpenHab, IoBroker, Node-Red etc...

# Compatible Pellet Burners

* NBE RTB 10 (v13 controller)
* NBE RTB 10 VAC (v13 controller)
* NBE RTB 16 (v13 controller)
* NBE RTB 16 VAC (v13 controller)
* NBE RTB 30 (v13 controller)
* NBE RTB 30 VAC (v13 controller)
* NBE RTB 50 (v13 controller)
* NBE RTB 50 VAC (v13 controller)
* NBE RTB 80 (v13 controller)
* NBE BS+ (Blackstar+) 10 (v13 controller)
* NBE BS+ (Blackstar+) 16 (v13 controller)
* NBE BS+ (Blackstar+) 25 (v13 controller)

If you don't know what model you are using, try to open pellet burner door and look over there, then compare with the user manual of most common models, it can be found [here](https://www.nbe.dk/wp-content/uploads/2017/07/RTB-BS-Manual-V13-ENG-08.03.2017.pdf)

# How to run?

```
make up          # x86_64 Architecture (Intel/Amd)
make up_aarch64  # ARM x64 Architecture (RaspberryPI, OrangePI, nVidia Jetson, Rockchip64 etc...)
```
It will bring docker up, docker system must be already running on the host system. You can edit compose file for different options and set nbe serial and password.

`docker-compose.yml` is for **x86_64** architecture and `docker-compose_aarch64.yml` is for **ARM x64** architecture.

# Local Docker development

Install Docker Desktop with Linux containers enabled, then create a local environment file:

```powershell
Copy-Item config.env-example config.env
# Edit config.env with the burner and MQTT settings
```

Build and run the local image without creating a release:

```powershell
.\tools\local-docker.ps1
```

Build without running, or stop the local container:

```powershell
.\tools\local-docker.ps1 -BuildOnly
.\tools\local-docker.ps1 -Stop
```

The equivalent Make targets are `make build` and `make build_aarch64`. The release workflow builds and pushes the published multi-architecture images; local Docker is not required to create a Git release. The image contains no user configuration: it requires the runtime environment variables shown in `config.env-example`. Credentials are used only to generate the container's temporary `/app/config.json` at startup and are not printed.

The release image includes `/config.env-example` as a safe configuration reference. It does not include the real `config.env` or `config.json`. Test the release image locally before publishing:

```powershell
.\tools\test-docker-image.ps1
```

This builds `nbe:release-test`, verifies the example file is present, and starts the container with local `config.env` long enough to confirm application startup. Use `-NoBuild` to test an already-built image.

# Local Python tests

Install [uv](https://docs.astral.sh/uv/), then run the Python harness before building the image:

```powershell
.\tools\test-python.ps1
```

This creates an isolated uv environment, installs the test dependencies, and runs tests that exercise frame encoding and the UDP timeout path without requiring a connected pellet burner. The timeout test is expected to raise the same `socket.timeout` seen when the configured burner does not answer.

The equivalent Make target is:

```powershell
make test
```

Run the application directly with Python, using the root configuration file:

```powershell
.\tools\run-python.ps1
```

This connects directly to the configured burner and MQTT broker, so it requires reachable devices. To use another configuration file:

```powershell
.\tools\run-python.ps1 -ConfigFile .\config.local.json
```

With `"log_level": "DEBUG"`, startup output includes the effective configuration with passwords redacted, followed by the burner target, discovery and RSA-key exchange, each query, response, and timeout. A timeout identifies the exact UDP stage that did not receive a response.

# Releasing

Before releasing, run both local checks from a clean configuration:

```powershell
.\tools\test-python.ps1
.\tools\test-docker-image.ps1
```

Create and push a release in one command:

```powershell
.\tools\release.ps1 -Version 0.2.0 -Push
```

This creates the changelog entry, release commit, and `v0.2.0` tag, then pushes the branch and tag. The tag starts GitHub Actions, which creates the GitHub release and publishes `ohmegastar/nbe` tags for the version and `latest`. It also refreshes the legacy `aarch64` image tag.

For a review before pushing, create the release locally without `-Push`, inspect the changelog and commit, then push manually:

```powershell
.\tools\release.ps1 -Version 0.2.0
git push origin HEAD:master
git push origin v0.2.0
```

The repository needs the `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` Actions secrets before running a release.

# VS Code requirements

No project-specific VS Code modules are required. Recommended extensions are Docker (`ms-azuretools.vscode-docker`), PowerShell (`ms-vscode.powershell`), and YAML (`redhat.vscode-yaml`) for workflow validation. GitHub Actions support is optional; the release itself runs on GitHub-hosted runners.

* **NBE Serial** can be found on system menu System > User account > Serial number on the controller
* **NBE Password** can be found on the pallet burner phisically just open the door and look at the top, it should be written over there.

# Standard install (without docker)

Move files from **src/** to **/opt/nbe** and do not forget to copy **nbe.service** to **/etc/systemd/system**, edit **config.json**, enable and start the service
```
pip3 install pycrypto paho-mqtt simplejson
systemctl enable nbe&&systemctl start nbe
```

# Features

What features are working by now:
* Various sensors
* Climate control for hot water
* Climate control for pellet burner itself

# TODO

* Different zones regulation as climate control or similar
* Turn on/off pellet burner
* <del>Climate control</del>
* Cross platform docker images


# Customization

<img src="https://github.com/e1z0/nbe-blackstar-homeassistant/raw/master/pics/nbe2.png" width=40% height=40%>

You can enable different sensors, controls, etc..  just look at **nbe_schema** file..

The main configuration lies in config.json, just modify to suit your needs.
