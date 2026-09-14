# Development and Release Tooling

This document covers repository development, testing, Docker image validation, and releases.

## Prerequisites

Install:

- Git
- PowerShell 7
- [uv](https://docs.astral.sh/uv/)
- Docker Desktop with Linux containers enabled

Recommended VS Code extensions:

- Docker: `ms-azuretools.vscode-docker`
- PowerShell: `ms-vscode.powershell`
- YAML: `redhat.vscode-yaml`

## Python tests

Run the isolated Python test harness:

```powershell
.\tools\test-python.ps1
```

Or use Make:

```powershell
make test
```

The tests cover frame encoding, configuration loading, credential redaction, and the UDP timeout path without requiring a connected pellet burner.

## Native Python run

Run the application without Docker using the repository-root `config.json`:

```powershell
.\tools\run-python.ps1
```

Use another configuration file when needed:

```powershell
.\tools\run-python.ps1 -ConfigFile .\config.local.json
```

The native runner connects directly to the configured burner and MQTT broker. With `"log_level": "DEBUG"`, startup output includes the effective configuration with passwords redacted, the burner target, discovery and RSA-key exchange, queries, responses, and timeout details.

## Local Docker image

Create a local runtime environment file from the safe example:

```powershell
Copy-Item config.env-example config.env
# Edit config.env with burner and MQTT values
```

Build and run the local image:

```powershell
.\tools\local-docker.ps1
```

Build without running, or stop the local container:

```powershell
.\tools\local-docker.ps1 -BuildOnly
.\tools\local-docker.ps1 -Stop
```

## Release-image smoke test

Validate the image before publishing:

```powershell
.\tools\test-docker-image.ps1
```

This builds `nbe:release-test`, verifies `/config.env-example` is present, starts the image with local `config.env`, and confirms application startup. Use `-NoBuild` to test an already-built image.

The real `config.env` and `config.json` are excluded from the Docker build context. Runtime credentials are supplied only when the container starts.

## Release process

Run the local checks first:

```powershell
.\tools\test-python.ps1
.\tools\test-docker-image.ps1
```

Create and push a release:

```powershell
.\tools\release.ps1 -Version 0.2.0 -Push
```

This creates the changelog entry, release commit, and `v0.2.0` tag, then pushes the branch and tag. The tag starts GitHub Actions, which creates the GitHub release and publishes `ghcr.io/ohmegastar/nbe` tags for the version and `latest`, plus the legacy `aarch64` tag.

For a review before pushing:

```powershell
.\tools\release.ps1 -Version 0.2.0
git push origin HEAD:master
git push origin v0.2.0
```

GHCR publishing uses the built-in `GITHUB_TOKEN`; no Docker Hub credentials are required. Make the `nbe` package public in the repository's **Packages** settings if users should pull it without logging in.
