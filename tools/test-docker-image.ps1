[CmdletBinding()]
param(
    [string] $Image = 'nbe:release-test',

    [string] $EnvFile = 'config.env',

    [switch] $NoBuild,

    [int] $StartupTimeoutSeconds = 15
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
    if (-not (Test-Path -LiteralPath $userInstallDocker)) {
        throw 'Docker was not found. Start Docker Desktop or add docker.exe to PATH.'
    }
    $env:Path = "$userInstallBin;$env:Path"
    $docker = $userInstallDocker
}

$resolvedEnvFile = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
    $EnvFile
} else {
    Join-Path $root $EnvFile
}
if (-not (Test-Path -LiteralPath $resolvedEnvFile)) {
    throw "Environment file '$resolvedEnvFile' was not found. Copy config.env-example to config.env and edit it first."
}

if (-not $NoBuild) {
    Write-Host "Building $Image for local release testing..."
    & $docker build --tag $Image --file Dockerfile .
    if ($LASTEXITCODE -ne 0) {
        throw 'Docker image build failed.'
    }
}

$artifact = & $docker run --rm --entrypoint /bin/sh $Image -c 'test -f /config.env-example && echo present'
if ($LASTEXITCODE -ne 0 -or $artifact -notcontains 'present') {
    throw 'The image does not contain /config.env-example.'
}
Write-Host 'Verified /config.env-example is present in the image.'

$dockerArguments = @('run', '--rm', '--env-file', $resolvedEnvFile, $Image)
$process = [System.Diagnostics.Process]::new()
$process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
$process.StartInfo.FileName = $docker
$process.StartInfo.UseShellExecute = $false
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardError = $true
$process.StartInfo.CreateNoWindow = $true
foreach ($argument in $dockerArguments) {
    [void] $process.StartInfo.ArgumentList.Add($argument)
}

Write-Host "Starting $Image with $EnvFile for up to $StartupTimeoutSeconds seconds..."
[void] $process.Start()
$finished = $process.WaitForExit($StartupTimeoutSeconds * 1000)
if (-not $finished) {
    $process.Kill($true)
    $process.WaitForExit()
}
$output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
Write-Host $output

if ($output -notmatch 'Started up!') {
    throw 'Docker smoke test did not reach application startup.'
}
if ($output -match 'required$|Traceback|Unable to connect') {
    throw 'Docker smoke test reported a startup failure.'
}
Write-Host 'Docker image smoke test passed.'