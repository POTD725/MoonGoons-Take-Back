# MoonGoons Take Back 🌙

**MoonGoons Take Back** is a Godot 4 real-time strategy prototype set in the MoonGoons universe. Build a lunar precinct economy, reclaim territory, establish Forward Relays, scout unknown sectors, counter Syndicate extraction, and follow the Peacekeeper story campaign chapter by chapter before the Nullborn crisis consumes the Moon.

## Playable RTS prototype: Phase Nine

`scenes/Main.tscn` launches a code-drawn Lunar Peacekeepers versus Syndicate RTS story-campaign build.

- Survey Drones harvest Credits and Lunar Alloy, returning cargo to the Command Nexus.
- Communications Relays expand Command Capacity; Tactical Armories unlock Riot Vanguards.
- Use control groups, production rally points, attack-move, hold position, Riot Vanguard Shield Wall, and queued route commands.
- Capture Aurora Exchange, Gravity Foundry, and Eclipse Signal Tower.
- Build a completed Relay in a secured sector to create a Forward Relay, doubling sector income and extending vision.
- Explore through unit and structure vision. Unknown terrain is hidden by lunar fog.
- Spend Intel on Tactical Scan to expose fog-covered threats.
- Respond to hidden Siphon Raids before their extraction arrays drain resources and fund the Syndicate War Chest.
- Counter Syndicate doctrines: fast Shades, armored Bruisers, and accelerated relay-network raids.
- Press `C` to open **Story Dispatch**. The next chapter follows the campaign sequence automatically; choose only Easy, Medium, or Hard opponent difficulty before beginning.

The active build is an early RTS and campaign slice, not a complete commercial RTS. It uses code-drawn visuals and does not require external textures or fonts to run.

## Run it

1. Install **Godot 4.3 or newer**.
2. Clone or download this repository.
3. Import `project.godot` with Godot Project Manager.
4. Open the project and press **F6** or the Play button.

For headless verification:

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

You can also manually start the GitHub Actions workflow from **Actions → MoonGoons Godot Verification → Run workflow**.

## Core controls

| Control | Action |
|---|---|
| Left-click / left-drag | Select one unit / select a group |
| Right-click | Immediate move, harvest, or attack order |
| `Ctrl + right-click` | Queue movement waypoint |
| `Ctrl + Shift + right-click` | Queue attack-move waypoint |
| `Q` / `W` | Queue Survey Drone / Patrol Deputy |
| `E` / `R` / `T` | Build Relay / Armory / Security Turret |
| `F` | Queue Riot Vanguard after Armory completion |
| `A` / `H` | Attack-move / hold position |
| `S` | Riot Vanguard Shield Wall |
| `X` | Tactical Scan at cursor |
| `G` / `B` | Gather nearest resource / cancel build placement |
| `M` | Toggle terrain labels and outlines |
| `Shift + 1–5` / `1–5` | Assign / recall control groups |
| `Shift + right-click` | Set production rally point |
| Tactical-map click | Move selected units or workers |
| Tactical-map Shift-click | Attack-move selected combat units |
| `C` | Story Dispatch and opponent difficulty |
| `F1` | Developer console in debug/editor builds |

## Story campaign

The current playable campaign route is **Lunar Peacekeepers**. The first five Act I chapters, `1.01` through `1.05`, are required story dispatches that advance in order. A victory records local progress, applies its rewards once, and makes the following chapter the next required operation.

No campaign chapter picker is used. The player-facing campaign choice is opponent difficulty:

- **Easy:** slower, weaker, less-funded Syndicate pressure.
- **Medium:** intended story balance.
- **Hard:** faster, stronger, better-funded Syndicate pressure.

Syndicate and Nullborn story routes are data placeholders until those factions are genuinely playable. They are not exposed as selectable campaigns yet.

See [`docs/PHASE_NINE_CAMPAIGN.md`](docs/PHASE_NINE_CAMPAIGN.md) for story-dispatch and profile details.

## Current foundations

- Tier 1–3 unit catalogs, building trees, economy, damage, VFX, achievements, and localization data.
- A 20-mission campaign catalog, plus a persistent Act I story-dispatch bridge for missions `1.01` through `1.05`.
- Fixed-point helpers, seeded RNG, lockstep buffering, state hashing, local saves, Resource Bank, combat/arrest resolution, and ability cooldowns.
- GitHub Actions import and smoke-test automation with a manual workflow trigger.
- A playable RTS with resources, capacity, construction, production, territory capture, Forward Relay bonuses, fog of war, Tactical Scan, Siphon Raids, terrain steering, tactical-map orders, queued routes, Syndicate doctrine pressure, and fixed-route Act I progression.

## Three-faction destination

- **Lunar Peacekeepers:** combined arms, defensive grids, territory reclamation, visibility infrastructure, and tactical defensive abilities.
- **The Syndicate:** mobility, stealth, sensor disruption, air-drop raids, Credit Siphons, War Chest doctrine escalation, counter-intelligence, and sabotage.
- **The Nullborn:** Corrupted Ground, Biomass Vents, hidden growth, swarm pressure, and territorial attrition.

The current playable scenario is Peacekeepers versus a live Syndicate director. Player-selectable Syndicate and Nullborn economies, full navmesh pathfinding, camera scrolling, zoomable minimap, dedicated campaign maps, scripted mission objectives, final art/audio, Android controls, and online multiplayer remain future work.

## Key project files

```text
scenes/Main.tscn                                      Current Phase Nine story-campaign RTS scene
scripts/moongoons_rts_phase_nine_campaign.gd          Fixed story route and difficulty layer
data/rts_phase_nine_campaign.json                     Route, story chapter, and difficulty rules
scripts/moongoons_rts_phase_eight_syndicate.gd         Syndicate War Chest and doctrine director
data/rts_phase_eight_syndicate.json                    Syndicate doctrine rules
docs/USER_MANUAL.md                                   Full player and debug-console guide
docs/PHASE_NINE_CAMPAIGN.md                            Story campaign and difficulty guide
docs/PHASE_EIGHT_SYNDICATE.md                          Syndicate counterplay guide
docs/DEVELOPMENT_ROADMAP.md                            Current development roadmap
tests/rts_phase_nine_campaign_smoke_test.gd            Phase Nine story-campaign smoke test
compile_and_test.sh                                    Twelve-step local verification pipeline
.github/workflows/godot-ci.yml                         GitHub Actions verification
```

## Licensing

The root `LICENSE` covers original repository code and documentation. Read `docs/LICENSING.md` and `docs/CREDITS.md` before adding art, audio, fonts, packages, or other third-party materials.

## Design north star

Every reclaimed lunar district should change the war. MoonGoons Take Back is about restoring order, exploiting chaos, or feeding corruption one hard-won sector at a time.
