# Contributing to MoonGoons: Take Back

Thank you for helping build the lunar underworld. This project currently uses Godot and GDScript, with data-driven gameplay definitions in `data/` and a future-facing deterministic simulation layer in `scripts/simulation/`.

## Branch workflow

```text
main                 Stable, playable releases
staging              Integration and internal playtesting
feature/<name>       New gameplay, UI, mission, or engine work
bugfix/<name>        Fixes for defects, balance, or desync risks
data/<name>          JSON balance and content changes
```

Examples:

```text
feature/nullborn-mutation-ui
bugfix/relay-income-tick
data/tier-3-cost-pass
```

Do not commit experimental work directly to `main`.

## Core engineering rules

### Deterministic simulation

For future lockstep multiplayer code, do not use raw floating-point values for authoritative movement, damage, resource totals, random outcomes, cooldown timing, or serialized targets. Use the fixed-point helpers under `scripts/simulation/`.

The current prototype is not yet a lockstep multiplayer game, so ordinary UI and visual math may use Godot `float` and `Vector2`. Keep those client-only values out of the future authoritative command/state pipeline.

### Seeded randomness only

Procedural maps, mission rolls, damage variation, and any state-changing random outcome must use a match-seeded generator. Do not let `RandomNumberGenerator.randomize()` decide multiplayer outcomes.

### Rendering is read-only

Particles, shaders, animation, sound, camera motion, UI transitions, and screen shake can react to simulation events. They may not write back into health, movement, cooldown, visibility, targeting, or objective state.

### Data is the source of truth

Unit, building, balance, localization, achievement, and VFX values belong in `data/`. New code should query `MoonGoonsGameData` or a dedicated manager instead of copying balance values into scene scripts.

## Pull request checklist

Every pull request into `staging` should include:

1. A brief summary of the player-facing and technical changes.
2. Local test steps that match `docs/TESTING_QA.md` where applicable.
3. Any new or changed JSON files validated through `MoonGoonsDataValidator`.
4. A note about deterministic impact: `none`, `client-only`, or `authoritative simulation`.
5. For authoritative simulation changes, a repeatable command log or test scenario and a state-hash result.
6. Screenshots or clips for meaningful UI, VFX, art, or UX changes.

## Commit guidance

Use focused commits with clear verbs:

```text
Add Tier 3 Magistrate data
Fix relay capacity cost validation
Document lockstep no-op packets
Refactor audio event routing
```

Avoid combining unrelated art imports, balance rewrites, and logic refactors in one commit. Lunar paperwork is already heavy enough.

## Security and release notes

- Debug commands must remain disabled in release and multiplayer builds.
- Do not commit secrets, API tokens, credentials, private endpoints, or player save files.
- Do not report a multiplayer feature as complete until transport, validation, state hashing, recovery, and security checks are implemented and tested.
