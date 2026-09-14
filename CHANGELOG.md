# Changelog

All notable changes to this project are documented in this file.

## [v99.0.1] - 2026-09-14

### Commits

- fix for binary_sensors ON / OFF is case sensitive in payload (9ddef01)

## [v0.1.3] - 2026-09-14

### Changed

- cleanup tooling (48bfc8a)
- Use local PowerShell release command (17764ed)
- Add release automation (187effe)
- fix for binary_sensors ON / OFF is case sensitive in payload (9ddef01)

### Files changed

```text
 .github/workflows/release.yml | 71 +++++++++++++++++++++++++++++++++++++++++++
 CHANGELOG.md                  | 11 +++++++
 README.md                     |  6 ++++
 src/nbe.py                    |  2 +-
 tools/release.ps1             | 68 +++++++++++++++++++++++++++++++++++++++++
 5 files changed, 157 insertions(+), 1 deletion(-)
```
## [v0.1.4] - 2026-09-14

### Changed

- Update release actions for Node 24 (6abef9b)

### Files changed

```text
 .github/workflows/release.yml | 12 +++++-------
 1 file changed, 5 insertions(+), 7 deletions(-)
```
## [v0.1.5] - 2026-09-14

### Changed

- Fix release workflow YAML indentation (117d316)

### Files changed

```text
 .github/workflows/release.yml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```
## [v0.1.6] - 2026-09-14

### Changed

- migrate to ghcr.io/ohmegastar/nbe (4f3f35a)
- Add local testing and secure Docker release tooling (69c3ab4)

### Files changed

```text
 .dockerignore                 |   1 +
 .github/workflows/release.yml |   9 +-
 .gitignore                    |   4 +
 Dockerfile                    |   1 +
 Makefile                      |  18 +--
 README.md                     |  91 ++++++++++++++-
 config.env-example            |  13 +++
 docker-compose.yml            |   2 +-
 docker-compose_aarch64.yml    |   2 +-
 docker/docker_init            |  17 ++-
 pyproject.toml                |  18 +++
 src/nbe.py                    |  48 ++++----
 src/protocol.py               |  32 ++++--
 src/settings.py               |  12 +-
 tests/test_protocol.py        |  48 ++++++++
 tests/test_settings.py        |  29 +++++
 tools/local-docker.ps1        |  69 ++++++++++++
 tools/run-python.ps1          |  36 ++++++
 tools/test-docker-image.ps1   |  80 +++++++++++++
 tools/test-python.ps1         |  24 ++++
 uv.lock                       | 257 ++++++++++++++++++++++++++++++++++++++++++
 21 files changed, 763 insertions(+), 48 deletions(-)
```
## [v0.1.7] - 2026-09-14

### Changed

- Link GHCR image to repository (a25c693)

### Files changed

```text
 Dockerfile | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)
```
## [Unreleased]





