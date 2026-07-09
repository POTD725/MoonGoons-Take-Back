#!/usr/bin/env bash
# Local Android debug APK export helper for MoonGoons Take Back.
# Prerequisites: Godot 4.3+ with Android export templates, Android SDK, and OpenJDK 17.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
ANDROID_PRESET="${ANDROID_PRESET:-Android Test APK}"
APK_OUTPUT="${ANDROID_APK_OUTPUT:-${ROOT_DIR}/builds/android/MoonGoonsTakeBack-debug.apk}"

if ! command -v "${GODOT_BIN}" >/dev/null 2>&1 && [[ ! -x "${GODOT_BIN}" ]]; then
  echo "Godot executable not found. Set GODOT_BIN to your Godot 4.3+ executable path."
  exit 1
fi

mkdir -p "$(dirname "${APK_OUTPUT}")"

echo "Importing MoonGoons Take Back before Android export..."
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --editor --quit

echo "Exporting Android debug APK with preset: ${ANDROID_PRESET}"
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --export-debug "${ANDROID_PRESET}" "${APK_OUTPUT}"

echo "Android test APK exported to: ${APK_OUTPUT}"
