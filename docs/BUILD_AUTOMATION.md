# Continuous Integration & Build Automation

MoonGoons is a Godot/GDScript project, so its automated verification pipeline uses a headless Godot binary rather than the .NET/C# build script described in the early engine sketches.

## Implemented workflow

```text
.github/workflows/godot-ci.yml
compile_and_test.sh
tests/data_and_simulation_smoke_test.gd
```

The workflow runs on pushes and pull requests targeting `main` or `staging`.

1. GitHub Actions checks out the repository.
2. The workflow downloads a Godot 4.3 headless-capable Linux binary.
3. `compile_and_test.sh` performs a headless editor import/parse pass.
4. The smoke test validates game data, fixed-point movement, and a two-player lockstep turn.
5. Failure logs are uploaded as a short-lived artifact.

## Local use

Install Godot 4.3 or newer, then run:

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

When Godot is not on your shell path, pass its executable explicitly:

```bash
GODOT_BIN="/full/path/to/Godot" ./compile_and_test.sh
```

On Windows PowerShell, launch the Godot executable directly with the same two headless commands from `compile_and_test.sh`, or use Git Bash/WSL for the shell script.

## Current test coverage

The smoke test currently verifies:

- All JSON catalogs load through `MoonGoonsGameData`.
- `MoonGoonsDataValidator` accepts the committed schema.
- Tier 1 and Tier 3 unit profiles resolve through the ability/unit parser.
- A fixed-point unit advances toward a target and does not overshoot it.
- A two-player lockstep turn waits for both packets and executes exactly three simulation ticks.

## Before treating CI as release certification

The workflow is a foundational verification tool, not a shipping-build pipeline. Add the following before claiming release-grade automation:

- Main-scene launch and input tests.
- Campaign mission-controller tests.
- Resource, combat, ability, save/load, and achievement regression tests.
- Android and Windows export checks.
- Deterministic replay and state-hash comparison tests across separate clients.
- Asset licensing and export compliance checks.
