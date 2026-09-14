[CmdletBinding()]
param(
    [switch] $NoSync
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location $root

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw 'uv was not found. Install uv, then rerun this script.'
}

if (-not $NoSync) {
    uv sync --group test
    if ($LASTEXITCODE -ne 0) {
        throw 'uv dependency setup failed.'
    }
}

uv run --group test pytest
if ($LASTEXITCODE -ne 0) {
    throw 'Python tests failed.'
}