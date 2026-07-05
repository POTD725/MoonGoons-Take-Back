# MoonGoons: Take Back

A playable **Godot 4** prototype and data-driven RTS foundation for the next branch of the MoonGoons universe.

The lunar districts have been swallowed by Syndicate signal relays. You command a small MoonGoons response force from the Command Nexus: reclaim territory, build income infrastructure, recruit deputies, and survive escalating raids. The repository now also contains the wider **MoonGoons: Crime Wars** faction, economy, campaign, AI, audio, and QA framework.

## Current playable loop

- Start with two deputies and a Command Nexus.
- **Left-click** a deputy to select them.
- **Right-click** in the lunar field to move the selected deputy.
- Reach the three hostile relays to secure them.
- Recruit deputies from the Tactical Console for credits.
- Build Lunar Beacons for passive credit income.
- Defend the Nexus from increasingly heavy Syndicate raids.
- Win by securing all three relays. Lose if Nexus Integrity reaches zero.

## Run it

1. Install **Godot 4.3 or newer**.
2. Clone or download this repository.
3. In Godot Project Manager, choose **Import** and select `project.godot`.
4. Open the project and press **F6** or click the play button.

The current playable scene uses code-drawn neon lunar visuals, so it launches without missing texture, sprite, or font files.

## Project structure

```text
project.godot                         Godot project configuration
scenes/Main.tscn                      Current playable lunar territory mission
scripts/moongoons_game.gd             Current game loop, UI, units, raids, and visuals
scripts/game_data.gd                  Data registry for units, buildings, rules, and campaign acts
scripts/data_validator.gd             Debug-build schema validation for game data
scripts/ai_commander.gd               Two-second skirmish AI macro-state evaluator
scripts/audio_director.gd             Dynamic music and faction audio-event routing
scripts/debug_console.gd              Developer-only validated debug command parser
data/unit_data.json                   Tier 1 production unit profiles
data/unit_tier_2.json                 Tier 2 production unit profiles
data/building_data.json               Three-faction building tech trees
data/building_runtime_profiles.json   HP, armor, construction time, and aura details
data/gameplay_rules.json              Economy, balance, controls, map, and campaign rules
data/roster_roadmap.json              Tier 2/3 and hero implementation direction
docs/DESIGN_BIBLE.md                  High-level MoonGoons design source
docs/AI_BEHAVIOR.md                   Skirmish behavior-state design
docs/AUDIO_DESIGN.md                  Music, voice, weapon, and ambience direction
docs/TESTING_QA.md                    QA cases, smoke tests, and debug command registry
```

## Data-first RTS architecture

The active playable prototype still uses a focused Peacekeeper-versus-Syndicate mission, but future mission controllers, production panels, AI, and combat systems should query `MoonGoonsGameData` rather than hardcoding cost, range, health, building, or upgrade values.

The current structured systems include:

- Tier 1 and Tier 2 unit stats for Peacekeepers and Syndicate, plus Tier 1 Nullborn data.
- Tech trees and gameplay identities for all three factions.
- Credits, Lunar Alloy, Intel, Evidence, and Command Capacity rules.
- Damage-versus-armor modifiers and faction counter relationships.
- Campaign acts, maps, territory bonuses, controls, and commander abilities.
- AI behavior states, audio routing, QA verification cases, and debug-build command parsing.

## Immediate implementation priorities

1. Wire `MoonGoonsGameData` into `moongoons_game.gd` so recruitment, costs, damage, capacity, and building progression use the JSON source of truth.
2. Add drag selection, attack commands, command groups, and QWER ability bindings.
3. Add buildable Peacekeeper structures and real Command Capacity limits.
4. Implement the Syndicate and Nullborn as selectable skirmish factions.
5. Connect `MoonGoonsAICommander`, `MoonGoonsAudioDirector`, and `MoonGoonsDebugConsole` to a mission controller.
6. Add actual MoonGoons art, effects, sound assets, save data, and Android-friendly controls.

## Design north star

**MoonGoons: Take Back** is a readable lunar RTS where every reclaimed district changes the battlefield. The player is not merely surviving raids: they are restoring a fractured moon one relay, one beacon, and one hard-won push at a time.
