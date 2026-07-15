param(
    [string]$Destination = "assets/skins/moongoons"
)

$ErrorActionPreference = "Stop"
$baseUrl = "https://raw.githubusercontent.com/POTD725/MoonGoons-Crime-Wars/main/assets/graphics"

$skins = [ordered]@{
    "structures/command_nexus.png"     = "command_nexus.png"
    "structures/tactical_armory.png"   = "tactical_armory.png"
    "structures/machine_shop.png"      = "machine_shop.png"
    "troops/builder_drone.png"         = "builder_drone.png"
    "troops/patrol_deputy.png"         = "patrol_deputy.png"
    "troops/shield_deputy.png"         = "shield_deputy.png"
    "defenses/sentry_turret.png"       = "sentry_turret.png"
    "defenses/pulse_cannon.png"        = "pulse_cannon.png"
    "resources/ore_deposit.png"        = "ore_deposit.png"
    "resources/evidence_cache.png"     = "evidence_cache.png"
    "environment/cargo_crate.png"      = "cargo_crate.png"
    "environment/wrecked_shuttle.png"  = "wrecked_shuttle.png"
    "environment/cargo_wall.png"       = "cargo_wall.png"
    "environment/crater.png"           = "crater.png"
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

foreach ($entry in $skins.GetEnumerator()) {
    $source = "$baseUrl/$($entry.Key)"
    $target = Join-Path $Destination $entry.Value
    Write-Host "Fetching $($entry.Value)..."
    Invoke-WebRequest -Uri $source -OutFile $target -UseBasicParsing
}

Write-Host "MoonGoons skin package ready: $Destination"
