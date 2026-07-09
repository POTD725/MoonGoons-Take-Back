# MoonGoons Take Back Android Test Build

This document covers the first Android-testable slice of **MoonGoons Take Back**. It is not a finished Play Store release. It is a debug APK path for testing the RTS on an Android phone or tablet.

## What is included

- `scenes/Main.tscn` now launches `scripts/moongoons_rts_android_testbed.gd`.
- The Android testbed extends the existing Phase Nine story-campaign RTS instead of replacing it.
- Touch input supports tap selection, drag-box selection, tap-to-move, attack-move, gather, Shield Wall, Tactical Scan, Story Dispatch, and cancel.
- The game still uses code-drawn runtime visuals, with a stronger Android test pass for the battlefield, touch HUD, command deck, glow rings, lunar overlays, and unit markers.
- Android launcher icon SVGs are checked into `assets/android/`.
- `export_presets.cfg` includes an `Android Test APK` preset.
- `.github/workflows/android-apk.yml` can build and upload a debug APK artifact.

## Phone controls

| Touch action | Result |
|---|---|
| Tap a Survey Drone or combat unit | Select one unit |
| Drag across the battlefield | Select a group |
| Tap empty battlefield while units are selected | Move selected units |
| ALL | Select all playable units |
| GATHER | Send selected Survey Drones to the nearest resource |
| MOVE, then tap battlefield | Force a move order |
| ATTACK, then tap battlefield or enemy | Attack-move or attack target |
| SHIELD | Trigger Riot Vanguard Shield Wall for selected Vanguards |
| SCAN, then tap battlefield | Use Tactical Scan at that location |
| STORY | Open or close Story Dispatch |
| CANCEL | Clear touch order mode, attack-move, build mode, and Story Dispatch |

The right-side command panel is still active. You can tap the existing train/build buttons, then tap the battlefield to place structures.

## GitHub Actions APK build

1. Open the repository on GitHub.
2. Go to **Actions**.
3. Select **Android APK Test Build**.
4. Choose **Run workflow**.
5. After the workflow finishes, download the artifact named **MoonGoons-Take-Back-Android-Test-APK**.
6. Install `MoonGoonsTakeBack-debug.apk` on an Android device with sideloading enabled.

## Local Windows build

Install Godot 4.3 or newer, Android export templates, OpenJDK 17, and the Android SDK packages required by Godot.

From PowerShell in the repository root:

```powershell
$env:GODOT_BIN="C:\Godot\godot.exe"
.\tools\build_android_test_apk.ps1
```

The APK will be written to:

```text
builds\android\MoonGoonsTakeBack-debug.apk
```

## Local Linux/macOS build

```bash
chmod +x tools/build_android_test_apk.sh
GODOT_BIN=/path/to/godot ./tools/build_android_test_apk.sh
```

The APK will be written to:

```text
builds/android/MoonGoonsTakeBack-debug.apk
```

## Verification

The normal project verification pipeline now includes an Android testbed check:

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

The final check confirms:

- `Main.tscn` launches the Android testbed script.
- The Android testbed controller loads and exposes its touch methods.
- The Android export preset exists and targets the debug APK path.
- The Android launcher icon SVG files exist.

## Current limits

This is a testable Android build, not a finished mobile release. Final production art, audio, native mobile scaling polish, Google Play signing, store metadata, controller support, and full Play Store packaging still need a later production pass.
