[CmdletBinding(DefaultParameterSetName = 'Run')]
param(
    [string] $Image = 'nbe:local',

    [string] $EnvFile = 'config.env',

    [Parameter(ParameterSetName = 'BuildOnly')]
    [switch] $BuildOnly,

    [Parameter(ParameterSetName = 'Stop')]
    [switch] $Stop,

    [string] $ContainerName = 'nbe-local'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
Set-Location $root

$dockerCommand = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerCommand) {
    $docker = $dockerCommand.Source
} else {
    $userInstallBin = Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin'
    $userInstallDocker = Join-Path $userInstallBin 'docker.exe'
    if (Test-Path -LiteralPath $userInstallDocker) {
        $env:Path = "$userInstallBin;$env:Path"
        $docker = $userInstallDocker
    } else {
        throw 'Docker was not found. Start Docker Desktop or add docker.exe to PATH.'
    }
}

& $docker version --format '{{.Server.Version}}' | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker CLI was found, but the Docker engine is not available. Start Docker Desktop and try again.'
}

if ($Stop) {
    & $docker rm --force $ContainerName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Container '$ContainerName' is not running."
    }
    exit 0
}

Write-Host "Building $Image from Dockerfile..."
& $docker build --tag $Image --file Dockerfile .
if ($LASTEXITCODE -ne 0) {
    throw 'Docker image build failed.'
}

if ($BuildOnly) {
    Write-Host "Built $Image."
    exit 0
}

$resolvedEnvFile = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
    $EnvFile
} else {
    Join-Path $root $EnvFile
}
if (-not (Test-Path -LiteralPath $resolvedEnvFile)) {
    throw "Environment file '$resolvedEnvFile' was not found. Copy config.env-example to config.env and edit it first."
}

& $docker rm --force $ContainerName 2>$null | Out-Null
Write-Host "Starting $ContainerName from $Image..."
& $docker run --rm --name $ContainerName --env-file $resolvedEnvFile $Image