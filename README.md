# MoonGoons: Take Back 🌙

**MoonGoons: Take Back** is a playable Godot 4 prototype and the growing RTS foundation for **MoonGoons: Crime Wars**: a sci-fi noir struggle for lunar territory, evidence, resources, and survival.

Command disciplined Peacekeeper squads, prepare the Syndicate’s hidden raiding network, or eventually spread the Nullborn’s corrupted territory across the Moon. Victory is objective-driven: secure districts, recover Evidence, defend civilians, sabotage infrastructure, or break an enemy command network.

## Playable prototype status

The current `Main.tscn` is a **single-player Peacekeeper relay-reclamation prototype**.

- Select deputies with **left-click**.
- Move selected deputies with **right-click**.
- Recruit deputies and build Lunar Beacons from the Tactical Console.
- Reclaim three hostile relays before escalating Syndicate raids destroy the Command Nexus.

The current scene uses code-drawn neon visuals, so it runs without external sprites, textures, or font dependencies.

## Run it

1. Install **Godot 4.3 or newer**.
2. Clone or download this repository.
3. In Godot Project Manager, choose **Import** and select `project.godot`.
4. Open the project and press **F6** or the Play button.

For headless validation after Godot is installed:

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

## What is implemented in the repository

### Game data

- Tier 1, Tier 2, and Tier 3 unit catalogs for the specified Peacekeeper and Syndicate units.
- Tier 1 Nullborn unit data and a documented advanced-roster roadmap.
- Three-faction building technology trees and runtime building profiles.
- Economy, damage matrix, map, campaign, controls, achievement, localization, VFX, and mission-event data.
- English and Spanish localization catalog, including Mission 1.01 and 1.02 objectives.

### Godot systems and scaffolding

- `MoonGoonsGameData` unified data registry and schema validator.
- Skirmish AI commander, audio director, localization manager, achievement tracker, and developer-only debug parser.
- Fixed-point movement, seeded match RNG, lockstep turn buffer, canonical state hashing, and composed simulation loop.
- Resource Bank with Credits, Lunar Alloy, Intel cap, Evidence, and Command Capacity management.
- Combat damage and ability controllers with armor modifiers, arrests, Evidence rewards, cooldowns, durations, and Siphon income.
- Data-driven Mission 1.01 and Mission 1.02 trigger runner.
- Checksum-protected local profile and mission snapshot save system with backup recovery.
- Headless Godot smoke tests and GitHub Actions verification workflow.

### Important multiplayer note

The repository contains **multiplayer architecture and local deterministic simulation scaffolding only**. It does **not** yet provide a shipping online multiplayer service, dedicated server, matchmaking, authentication, encryption, anti-cheat, NAT traversal, or snapshot-recovery transport. See `docs/NETWORKING.md` before attempting multiplayer work.

## Directory map

```text
project.godot
scenes/Main.tscn
compile_and_test.sh
.github/workflows/godot-ci.yml

scripts/
  moongoons_game.gd                 Current playable mission
  game_data.gd                      Unified game-data registry
  data_validator.gd                 Schema checks for data assets
  mission_controller.gd             Data-driven campaign trigger runner
  save_system.gd                    Profile and mission snapshot save manager
  ai_commander.gd                   High-level skirmish AI
  audio_director.gd                 Dynamic music and audio-event routing
  debug_console.gd                  Developer-only command parser
  localization_manager.gd           JSON translation lookup
  achievement_tracker.gd            Event-driven local progression
  simulation/
    fixed_math.gd                   Fixed-point integer helpers
    fixed_vector2.gd                Fixed-point ground-plane vectors
    simulation_unit.gd              Authoritative unit simulation state
    fixed_point_movement_controller.gd
    resource_bank.gd                Fixed-point economy and Command Capacity
    combat_damage_processor.gd      Armor damage and arrest processing
    combat_ability_controller.gd    Cooldowns, durations, and Siphon channels
    main_simulation_loop.gd         Authoritative subsystem composition
    ability_data_parser.gd          Unit/ability catalog parser
    lockstep_network_manager.gd     Future-turn command buffer
    game_state_hash.gd              Canonical SHA-256 state hashes
    game_rand.gd                    Seeded authoritative RNG

data/
  unit_data.json                    Tier 1 unit profiles
  unit_tier_2.json                  Tier 2 unit profiles
  unit_tier_3.json                  Tier 3 specified profiles
  building_data.json                Faction building progression
  building_runtime_profiles.json    HP, armor, construction, aura data
  gameplay_rules.json               Economy, balance, controls, maps, campaign
  campaign_missions.json            Mission 1.01 and 1.02 event definitions
  localization.json                 English and Spanish strings
  achievements.json                 Event-driven progression definitions
  fx_profiles.json                  Visual effects profile definitions

docs/
  DESIGN_BIBLE.md
  MISSION_01_SCRIPT.md
  MISSION_02_SCRIPT.md
  SAVE_SYSTEM.md
  BUILD_AUTOMATION.md
  CREDITS.md
  AI_BEHAVIOR.md
  AUDIO_DESIGN.md
  FX_GUIDE.md
  NETWORKING.md
  ACHIEVEMENTS.md
  TESTING_QA.md

tests/data_and_simulation_smoke_test.gd
CONTRIBUTING.md
```

## Development rules

- Balance and authored content live in `data/`, not duplicated in scenes.
- Future authoritative simulation uses fixed-point values and seeded randomness.
- VFX, audio, camera, and UI are read-only observers of gameplay state.
- Debug commands remain disabled outside local development builds.
- Use `CONTRIBUTING.md`, `docs/TESTING_QA.md`, and `docs/BUILD_AUTOMATION.md` for change and verification rules.

## Immediate build priorities

1. Wire the Resource Bank, unit data, Command Capacity, buildings, combat, and abilities into `moongoons_game.gd` so the playable relay mission uses the new systems at runtime.
2. Add box selection, attack orders, control groups, QWER actions, build placement, worker harvesting, and production queues.
3. Build the Mission 1.01 and Mission 1.02 scenes around the authored campaign trigger data.
4. Implement selectable Syndicate and Nullborn skirmish factions, including their structures and missing numeric Nullborn Tier 2/3 profiles.
5. Add deterministic replay/state-hash tests before any online transport work begins.
6. Replace prototype shapes with MoonGoons art, VFX, audio assets, accessibility settings, and Android controls.

## Design north star

Every reclaimed district should change the war. MoonGoons is not simply about grinding every hostile structure into moon gravel: it is about restoring order, exploiting chaos, or feeding the corruption one hard-won sector at a time.
