# MoonGoons: Take Back

A playable **Godot 4** prototype for the next branch of the MoonGoons universe.

The lunar districts have been swallowed by Syndicate signal relays. You command a small MoonGoons response force from the Command Nexus: reclaim territory, build income infrastructure, recruit deputies, and survive escalating raids.

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

The prototype uses code-drawn neon lunar visuals, so it launches without missing texture, sprite, or font files.

## Project structure

```text
project.godot                  Godot project configuration
scenes/Main.tscn               Main mission scene
scripts/moongoons_game.gd      Game loop, UI, units, raids, objectives, visuals
```

## Next build targets

1. Add true multi-select, squad formations, and unit abilities.
2. Replace code-drawn unit shapes with the MoonGoons art roster and animated sprites.
3. Add buildable Command Nexus modules: Armory, Drone Bay, Medbay, and Intel Lab.
4. Add a mission map with multiple lunar districts, enemy bases, and territory rewards.
5. Add sound, save data, player progression, and an Android-friendly control layer.

## Design north star

**MoonGoons: Take Back** is a brisk, readable lunar RTS where every reclaimed district changes the battlefield. The player is not merely surviving raids: they are restoring a fractured moon one relay, one beacon, and one hard-won push at a time.
