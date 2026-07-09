# Local browser build helper for MoonGoons Take Back on Windows.
# Prerequisites: Godot 4.3+ with Web export templates installed.

$ErrorActionPreference = "Stop"

$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotBin = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "godot" }
$WebPreset = if ($env:WEB_PRESET) { $env:WEB_PRESET } else { "Web Playable" }
$WebOutput = if ($env:WEB_OUTPUT) { $env:WEB_OUTPUT } else { Join-Path $RootDir "builds\web\index.html" }
$WebFolder = Split-Path $WebOutput -Parent

New-Item -ItemType Directory -Force -Path $WebFolder | Out-Null

Write-Host "Importing MoonGoons Take Back before web export..."
& $GodotBin --headless --path $RootDir --editor --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Exporting browser build with preset: $WebPreset"
& $GodotBin --headless --path $RootDir --export-release $WebPreset $WebOutput
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Web build exported to: $WebOutput"
Write-Host "Preview locally with: python -m http.server 8000 --directory $WebFolder"
