[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Version,

    [Parameter(Mandatory = $true)]
    [string] $Output,

    [string] $NotesFile
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$changelogPath = Join-Path $root "CHANGELOG.md"

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]] $Arguments)

    $result = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
    return ($result -join "`n").TrimEnd()
}

if ($Version -notmatch '^v?\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$') {
    throw "version must be semantic version text such as 1.2.3 or v1.2.3"
}
$normalisedVersion = if ($Version.StartsWith("v")) { $Version } else { "v$Version" }

$tags = @(((Invoke-Git -Arguments @("tag", "--list", "v*", "--sort=-version:refname")) -split "`r?`n") | Where-Object { $_ })
$previousTag = if ($tags.Count -gt 0) { $tags[0] } else { $null }
$revision = if ($previousTag) { "$previousTag..HEAD" } else { "HEAD" }
$commitLines = @(((Invoke-Git -Arguments @("log", "--no-merges", "--format=%h%x09%s", $revision)) -split "`r?`n") | Where-Object { $_ })

$commits = foreach ($line in $commitLines) {
    $parts = $line -split "`t", 2
    if ($parts.Count -eq 2) {
        [PSCustomObject]@{ Hash = $parts[0]; Subject = $parts[1] }
    }
}

$notes = ""
if ($NotesFile -and (Test-Path -LiteralPath $NotesFile)) {
    $notes = Get-Content -LiteralPath $NotesFile -Raw
}

$sectionLines = @("## [$normalisedVersion] - $([DateTime]::UtcNow.ToString('yyyy-MM-dd'))", "")
if ($notes.Trim()) {
    $sectionLines += @("### Release notes", "", $notes.Trim(), "")
}
$sectionLines += @("### Commits", "")
if ($commits.Count -gt 0) {
    $sectionLines += @($commits | ForEach-Object { "- $($_.Subject) ($($_.Hash))" })
} else {
    $sectionLines += "- No commits found since the previous release."
}
$section = ($sectionLines -join "`n") + "`n"

$content = if (Test-Path -LiteralPath $changelogPath) {
    Get-Content -LiteralPath $changelogPath -Raw
} else {
    "# Changelog`n`n"
}
if ($content -match "(?m)^## \[$([regex]::Escape($normalisedVersion))\]") {
    throw "$normalisedVersion is already present in CHANGELOG.md"
}

$firstHeading = [regex]::Match($content, '(?m)^## ')
if ($firstHeading.Success) {
    $updated = $content.Insert($firstHeading.Index, "$section`n")
} else {
    $updated = $content.TrimEnd() + "`n`n$section"
}
[System.IO.File]::WriteAllText($changelogPath, $updated, [System.Text.UTF8Encoding]::new($false))

$outputPath = if ([System.IO.Path]::IsPathRooted($Output)) { $Output } else { Join-Path (Get-Location) $Output }
[System.IO.File]::WriteAllText($outputPath, $section, [System.Text.UTF8Encoding]::new($false))