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
## [Unreleased]

