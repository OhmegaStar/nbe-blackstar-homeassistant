[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
    [string] $Version,

    [switch] $Push
)

$ErrorActionPreference = 'Stop'

if (git status --short) {
    throw 'Working tree is not clean. Commit or remove your changes before creating a release.'
}

$tag = "v$Version"
if (git tag --list $tag) {
    throw "Tag $tag already exists. Choose a new version."
}

$lastTag = git tag --sort=-version:refname | Select-Object -First 1
if (-not $lastTag) {
    throw 'No previous release tag found. Create an initial release tag manually first.'
}

$commitMessages = @(git log "$lastTag..HEAD" --no-merges --format='- %s (%h)')
$fileChanges = @(git diff --stat "$lastTag..HEAD")
if ($commitMessages.Count -eq 0) {
    throw "No commits found since $lastTag. Add and commit changes before creating a release."
}

$date = Get-Date -Format 'yyyy-MM-dd'
$changelogEntry = @(
    "## [$tag] - $date"
    ''
    '### Changed'
    ''
    $commitMessages
    ''
    '### Files changed'
    ''
    '```text'
    $fileChanges
    '```'
    ''
) -join "`n"

$changelogPath = Join-Path $PSScriptRoot '..\CHANGELOG.md'
$changelog = Get-Content $changelogPath -Raw
$unreleasedMarker = '## [Unreleased]'
if (([regex]::Matches($changelog, '(?m)^## \[Unreleased\]')).Count -ne 1) {
    throw 'CHANGELOG.md must contain exactly one Unreleased section.'
}
$changelog = $changelog.Replace($unreleasedMarker, "$changelogEntry$unreleasedMarker")
Set-Content $changelogPath $changelog -Encoding utf8

git diff --check
git add $changelogPath
git commit -m "Release $tag"
git tag $tag

if ($Push) {
    git push origin HEAD:master
    git push origin $tag
    Write-Host "Pushed $tag. GitHub Actions will build the Docker image and create the GitHub release."
} else {
    Write-Host "Created $tag locally. Review the commit, then run: .\tools\release.ps1 -Version $Version -Push"
}