[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

# tools/Publish-Wiki.ps1
# Publishes documentation from wiki/ to https://github.com/nadeemhaaju143/nh-win-debloater.wiki.git

$projectRoot = Split-Path -Parent $PSScriptRoot
$wikiSource = Join-Path $projectRoot "wiki"
$tempWikiDir = Join-Path $env:TEMP "nh-win-debloater-wiki-deploy"

if (-not (Test-Path $wikiSource)) {
    Write-Error "Wiki source directory not found: $wikiSource"
    exit 1
}

$token = gh auth token
if (-not $token) {
    Write-Error "Could not retrieve GitHub auth token via 'gh auth token'."
    exit 1
}

if (Test-Path $tempWikiDir) {
    Remove-Item -Path $tempWikiDir -Recurse -Force | Out-Null
}
New-Item -ItemType Directory -Path $tempWikiDir -Force | Out-Null

Copy-Item -Path "$wikiSource\*" -Destination $tempWikiDir -Recurse -Force

Push-Location $tempWikiDir
try {
    git init -b master | Out-Null
    git config user.name "Mohammed Nadeem BM"
    git config user.email "nadeemhaaju143@users.noreply.github.com"
    git add . | Out-Null
    git commit -m "Publish full GitHub Wiki documentation" | Out-Null

    $remoteUrl = "https://x-access-token:$token@github.com/nadeemhaaju143/nh-win-debloater.wiki.git"
    git remote add origin $remoteUrl
    $pushOutput = git push -u origin master --force 2>&1
    Write-Output $pushOutput
}
finally {
    Pop-Location
    if (Test-Path $tempWikiDir) {
        Remove-Item -Path $tempWikiDir -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
