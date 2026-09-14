[CmdletBinding()]
param(
    [string] $ConfigFile = 'config.json',

    [switch] $NoSync
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location $root

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw 'uv was not found. Install uv, then rerun this script.'
}

$resolvedConfigFile = if ([System.IO.Path]::IsPathRooted($ConfigFile)) {
    $ConfigFile
} else {
    Join-Path $root $ConfigFile
}
if (-not (Test-Path -LiteralPath $resolvedConfigFile)) {
    throw "Configuration file '$resolvedConfigFile' was not found. Copy config.json-example to config.json and edit it first."
}

$env:NBE_CONFIG_FILE = (Resolve-Path -LiteralPath $resolvedConfigFile).Path
if (-not $NoSync) {
    uv sync --group test
    if ($LASTEXITCODE -ne 0) {
        throw 'uv dependency setup failed.'
    }
}

uv run --group test python src/nbe.py
if ($LASTEXITCODE -ne 0) {
    throw 'Native Python application exited with an error.'
}