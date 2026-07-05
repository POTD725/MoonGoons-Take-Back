# MoonGoons: Take Back Installation Guide

MoonGoons: Take Back is a **Godot 4 / GDScript** project. The current playable build is a single-player relay-reclamation prototype; the repository also contains campaign, simulation, save, and CI foundations that are still being wired into the main scene.

## Requirements

- **Godot:** 4.3 or newer. Godot 4.7 is supported by the project direction.
- **Git:** Recommended for cloning, pulling updates, and contributing.
- **Optional terminal:** PowerShell on Windows, or Bash/Zsh on macOS/Linux.
- **Optional GitHub Desktop:** Easier visual Git workflow on Windows and macOS.

You do **not** need the .NET SDK to run or test this Godot project.

## Windows setup

1. Install Godot 4.3+ and Git.
2. Clone the repository with GitHub Desktop or a terminal:

```powershell
git clone https://github.com/POTD725/MoonGoons-Take-Back.git
cd MoonGoons-Take-Back
```

3. Open Godot Project Manager.
4. Select **Import**, then choose the repository’s `project.godot`.
5. Open the project and press **F6** or the Play button.

If Windows does not recognize `godot` in PowerShell, use the full path to `Godot.exe` for command-line testing.

## macOS and Linux setup

```bash
git clone https://github.com/POTD725/MoonGoons-Take-Back.git
cd MoonGoons-Take-Back
```

Import `project.godot` through Godot Project Manager and run the main scene with **F6**.

## Headless verification

The repository includes `compile_and_test.sh`, which performs a headless Godot import/parse pass and runs the smoke tests.

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

If Godot is not on your shell path:

```bash
GODOT_BIN="/full/path/to/Godot" ./compile_and_test.sh
```

The test suite checks data catalogs, localization, movement, lockstep turn timing, resource accounting, combat/arrest rules, Siphon income, mission triggers, and save/load integrity.

## Useful project paths

```text
project.godot                         Godot project definition
scenes/Main.tscn                      Current playable prototype
scripts/moongoons_game.gd             Current prototype gameplay loop
scripts/simulation/                   Authoritative simulation scaffolding
data/                                 Unit, building, campaign, and rules catalogs
tests/data_and_simulation_smoke_test.gd
compile_and_test.sh
.github/workflows/godot-ci.yml
```

## Troubleshooting

### Godot reports a script parse error

Copy the entire first error line from Godot’s **Output** panel, including its file and line number. Fix the first parse error before chasing later messages, since one indentation or type error can cause a small meteor shower of follow-on errors.

### Godot reports missing assets

The current `Main.tscn` uses code-drawn visuals and should not require external textures or fonts. Check that you imported the repository root containing `project.godot`, not only a subfolder.

### `compile_and_test.sh` cannot find Godot

Set `GODOT_BIN` to the executable path, as shown above. On Windows, run the equivalent Godot headless commands from PowerShell or use Git Bash/WSL for the shell script.

### CI workflow fails

Open the failed GitHub Actions run and download the `moongoons-godot-failure-logs` artifact. It contains the import and smoke-test logs needed to locate the failed script or data catalog.

## Command-line notes

The project does not currently expose a finished player-facing command-line launcher with `--mode`, `--map`, or multiplayer flags. Deterministic seed, map, difficulty, and session settings belong to future mission/skirmish launch configuration, not an unfinished public CLI.
