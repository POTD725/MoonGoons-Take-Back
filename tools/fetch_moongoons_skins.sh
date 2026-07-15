#!/usr/bin/env bash
# Pull the established MoonGoons PNG art package from MoonGoons: Crime Wars.
# These repositories are owned by the same project owner. The files are copied
# into this project before Godot import/export so web and Android builds contain
# the real artwork instead of relying on procedural fallback shapes.

set -Eeuo pipefail

ROOT="${1:-assets/skins/moongoons}"
BASE="https://raw.githubusercontent.com/POTD725/MoonGoons-Crime-Wars/main/assets/graphics"

fetch_skin() {
  local source_path="$1"
  local target_name="$2"
  mkdir -p "${ROOT}"
  echo "Fetching ${target_name}..."
  curl --fail --location --retry 3 --silent --show-error \
    "${BASE}/${source_path}" \
    --output "${ROOT}/${target_name}"
}

fetch_skin "structures/command_nexus.png" "command_nexus.png"
fetch_skin "structures/tactical_armory.png" "tactical_armory.png"
fetch_skin "structures/machine_shop.png" "machine_shop.png"
fetch_skin "troops/builder_drone.png" "builder_drone.png"
fetch_skin "troops/patrol_deputy.png" "patrol_deputy.png"
fetch_skin "troops/shield_deputy.png" "shield_deputy.png"
fetch_skin "defenses/sentry_turret.png" "sentry_turret.png"
fetch_skin "defenses/pulse_cannon.png" "pulse_cannon.png"
fetch_skin "resources/ore_deposit.png" "ore_deposit.png"
fetch_skin "resources/evidence_cache.png" "evidence_cache.png"
fetch_skin "environment/cargo_crate.png" "cargo_crate.png"
fetch_skin "environment/wrecked_shuttle.png" "wrecked_shuttle.png"
fetch_skin "environment/cargo_wall.png" "cargo_wall.png"
fetch_skin "environment/crater.png" "crater.png"

printf 'MoonGoons skin package ready: %s\n' "${ROOT}"
