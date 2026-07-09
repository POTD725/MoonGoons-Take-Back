#!/usr/bin/env bash
# Local browser build helper for MoonGoons Take Back.
# Prerequisites: Godot 4.3+ with Web export templates installed.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
WEB_PRESET="${WEB_PRESET:-Web Playable}"
WEB_OUTPUT="${WEB_OUTPUT:-${ROOT_DIR}/builds/web/index.html}"

if ! command -v "${GODOT_BIN}" >/dev/null 2>&1 && [[ ! -x "${GODOT_BIN}" ]]; then
  echo "Godot executable not found. Set GODOT_BIN to your Godot 4.3+ executable path."
  exit 1
fi

mkdir -p "$(dirname "${WEB_OUTPUT}")"

echo "Importing MoonGoons Take Back before web export..."
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --editor --quit

echo "Exporting browser build with preset: ${WEB_PRESET}"
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --export-release "${WEB_PRESET}" "${WEB_OUTPUT}"

echo "Web build exported to: ${WEB_OUTPUT}"
echo "Preview locally with: python -m http.server 8000 --directory $(dirname "${WEB_OUTPUT}")"
