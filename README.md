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

## What is implemented in the repository

### Game data

- Tier 1, Tier 2, and Tier 3 unit catalogs for the specified Peacekeeper and Syndicate units.
- Tier 1 Nullborn unit data and a documented advanced-roster roadmap.
- Three-faction building technology trees and runtime building profiles.
- Economy, damage matrix, map, campaign, controls, achievement, localization, and VFX data.
- English and Spanish localization catalog.

### Godot systems and scaffolding

- `MoonGoonsGameData` unified data registry.
- Data schema validation for units, buildings, translations, achievements, and VFX profiles.
- Skirmish AI commander with bootstrap, macro, harassment, defense, and assault states.
- Audio director that routes dynamic music and faction sound events.
- Developer-only debug command parser.
- Achievement tracker and local profile persistence layer.
- Godot-native fixed-point movement, seeded match RNG, lockstep turn buffer, and state-hash helpers for future deterministic multiplayer.

### Important multiplayer note

The repository contains **multiplayer architecture and local simulation scaffolding only**. It does **not** yet provide a shipping online multiplayer service, dedicated server, matchmaking, authentication, encryption, anti-cheat, NAT traversal, or snapshot-recovery transport. See `docs/NETWORKING.md` before attempting multiplayer work.

## Directory map

```text
project.godot
scenes/Main.tscn

scripts/
  moongoons_game.gd                 Current playable mission
  game_data.gd                      Unified game-data registry
  data_validator.gd                 Schema checks for data assets
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
  localization.json                 English and Spanish strings
  achievements.json                 Event-driven progression definitions
  fx_profiles.json                  Visual effects profile definitions

docs/
  DESIGN_BIBLE.md
  AI_BEHAVIOR.md
  AUDIO_DESIGN.md
  FX_GUIDE.md
  NETWORKING.md
  ACHIEVEMENTS.md
  TESTING_QA.md

CONTRIBUTING.md
```

## Development rules

- Balance values live in `data/`, not duplicated in scenes.
- Future authoritative simulation uses fixed-point values and seeded randomness.
- VFX, audio, camera, and UI are read-only observers of gameplay state.
- Debug commands remain disabled outside local development builds.
- Use `CONTRIBUTING.md` and `docs/TESTING_QA.md` for change and verification rules.

## Immediate build priorities

1. Wire `MoonGoonsGameData` into the active mission so costs, unit stats, capacity, buildings, and damage resolve from JSON at runtime.
2. Add box selection, attack orders, control groups, QWER actions, and build-placement flow.
3. Implement production buildings, Command Capacity, and the Peacekeeper Tier 2 roster in the live scene.
4. Add playable Syndicate and Nullborn skirmish factions.
5. Connect the simulation scaffolding to an actual mission controller, then test deterministic replays before online transport work begins.
6. Replace prototype shapes with MoonGoons art, VFX, audio assets, accessibility settings, and Android controls.

## Design north star

Every reclaimed district should change the war. MoonGoons is not simply about grinding every hostile structure into moon gravel: it is about restoring order, exploiting chaos, or feeding the corruption one hard-won sector at a time.
