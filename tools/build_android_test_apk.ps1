# Local Android debug APK export helper for MoonGoons Take Back on Windows.
# Prerequisites: Godot 4.3+ with Android export templates, Android SDK, and OpenJDK 17.

$ErrorActionPreference = "Stop"

$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotBin = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { "godot" }
$AndroidPreset = if ($env:ANDROID_PRESET) { $env:ANDROID_PRESET } else { "Android Test APK" }
$ApkOutput = if ($env:ANDROID_APK_OUTPUT) { $env:ANDROID_APK_OUTPUT } else { Join-Path $RootDir "builds\android\MoonGoonsTakeBack-debug.apk" }
$ApkFolder = Split-Path $ApkOutput -Parent

New-Item -ItemType Directory -Force -Path $ApkFolder | Out-Null

Write-Host "Importing MoonGoons Take Back before Android export..."
& $GodotBin --headless --path $RootDir --editor --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Exporting Android debug APK with preset: $AndroidPreset"
& $GodotBin --headless --path $RootDir --export-debug $AndroidPreset $ApkOutput
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Android test APK exported to: $ApkOutput"
