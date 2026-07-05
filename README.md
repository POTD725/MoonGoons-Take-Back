# MoonGoons: Take Back 🌙

**MoonGoons: Take Back** is a playable Godot 4 prototype and the growing RTS foundation for **MoonGoons: Crime Wars**: a sci-fi noir struggle for lunar territory, Evidence, resources, and survival.

## Playable prototype status

`Main.tscn` is currently a **single-player Peacekeeper relay-reclamation prototype**.

- Left-click a deputy to select them.
- Right-click in the lunar field to move them.
- Recruit deputies and build Lunar Beacons from the Tactical Console.
- Secure three hostile relays before escalating Syndicate raids destroy the Command Nexus.

The main scene uses code-drawn visuals, so it launches without external texture, sprite, or font dependencies.

## Run and verify

1. Install **Godot 4.3 or newer**.
2. Clone or download the repository.
3. Import `project.godot` through Godot Project Manager.
4. Press **F6** or the Play button.

For headless validation:

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

See `INSTALL.md` for Windows, macOS, Linux, Godot path, test, and troubleshooting instructions.

## Implemented foundations

- Tier 1–3 unit catalogs, faction building trees, economy, damage, map, VFX, achievement, and localization data.
- A 20-mission campaign catalog: Mission 1.01 through the Mission 1.20 finale, including Act II routes, the Nullborn escalation, bosses, hazards, defense events, and finale evacuation hooks.
- `MoonGoonsGameData`, a data validator, and a focused campaign catalog validator.
- Skirmish AI, dynamic audio event routing, localization, achievements, debug tooling, checksum saves, and CI smoke tests.
- Fixed-point movement, seeded RNG, lockstep turn buffering, canonical state hashing, resource banking, combat/arrest resolution, ability cooldowns, and an authoritative simulation loop.
- GitHub Actions checks that import the Godot project and run core plus campaign smoke tests.

## Reality check

The repository includes **campaign definitions and simulation scaffolding**, not twenty finished playable levels or online multiplayer. Individual mission scenes, map geometry, hazards, production/UI integration, boss behavior, enemy AI execution, art, sound, Android controls, and network transport still need implementation.

The multiplayer layer is not a shipping online service. It has no matchmaking, dedicated server, authentication, encryption, NAT traversal, anti-cheat, or snapshot-recovery transport.

## Project map

```text
LICENSE                             MIT license for repository code/docs
INSTALL.md                          Godot installation and test guide
compile_and_test.sh                 Local headless Godot verification
.github/workflows/godot-ci.yml      GitHub Actions verification

scenes/Main.tscn                    Current playable prototype
scripts/
  moongoons_game.gd                 Prototype gameplay loop
  game_data.gd                      Unified data registry
  mission_controller.gd             Multi-catalog campaign trigger runner
  campaign_catalog_validator.gd     Validates all 20 campaign records
  save_system.gd                    Profile and mission snapshot saves
  simulation/                       Fixed-point, resource, combat, ability, and lockstep systems

data/
  campaign_missions.json            Missions 1.01–1.02
  campaign_missions_act_2_to_4.json Missions 1.03–1.20
  unit_data.json                    Tier 1 units
  unit_tier_2.json                  Tier 2 units
  unit_tier_3.json                  Tier 3 specified units
  building_data.json                Faction tech progression
  gameplay_rules.json               Economy, balance, controls, maps, campaign
  localization.json                 English/Spanish UI plus English campaign objectives

docs/
  MISSION_01_SCRIPT.md
  MISSION_02_SCRIPT.md
  MISSION_03_TO_05_SCRIPT.md
  MISSION_06_TO_20_SCRIPT.md
  INSTALL.md                        Additional architecture docs remain here
  SAVE_SYSTEM.md
  BUILD_AUTOMATION.md
  CREDITS.md
  LICENSING.md
  NETWORKING.md
  TESTING_QA.md

tests/
  data_and_simulation_smoke_test.gd
  campaign_catalog_smoke_test.gd
```

## Development rules

- Balance and authored content live in `data/`, not duplicated in scene scripts.
- Authoritative simulation uses fixed-point values and seeded randomness.
- VFX, audio, camera, and UI observe simulation state but do not alter it.
- Debug commands remain disabled outside local development builds.
- `LICENSE` covers the repository code/docs; see `docs/LICENSING.md` and `docs/CREDITS.md` for asset and attribution boundaries.

## Immediate build priorities

1. Wire Resource Bank, unit data, Command Capacity, buildings, combat, and abilities into `moongoons_game.gd`.
2. Add box selection, attack orders, control groups, QWER actions, build placement, workers, harvesting, and production queues.
3. Build Mission 1.01 and 1.02 as real Godot scenes, then proceed through the authored campaign.
4. Add playable Syndicate and Nullborn factions, including missing numeric Nullborn Tier 2/3 profiles.
5. Add deterministic replay/state-hash tests before any network transport work.
6. Replace prototype shapes with original MoonGoons art, VFX, audio, accessibility options, and Android controls.

## Design north star

Every reclaimed district should change the war. MoonGoons is not only about turning hostile structures into moon gravel. It is about restoring order, exploiting chaos, or feeding the corruption one hard-won sector at a time.
