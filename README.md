# MoonGoons: Take Back 🌙

**MoonGoons: Take Back** is a Godot 4 real-time strategy prototype and the growing foundation for **MoonGoons: Crime Wars**. Build a lunar precinct economy, control territory, assemble squads, and dismantle the Syndicate before the Nullborn crisis consumes the Moon.

## Playable RTS prototype

`scenes/Main.tscn` now launches a code-drawn **Peacekeeper versus Syndicate RTS skirmish**.

- Select individual units with left-click or drag a selection box around a squad.
- Send **Survey Drones** to Credits or Lunar Alloy nodes with right-click.
- Drones harvest, return cargo to the Command Nexus, and fund your build order.
- Train more Drones and Patrol Deputies from the Command Nexus.
- Use selected Drones to build Communications Relays, Tactical Armories, and Security Turrets.
- Communications Relays increase **Command Capacity**, MoonGoons’ supply limit.
- Tactical Armories unlock durable Riot Vanguards.
- Press `A`, then right-click to attack-move; right-click enemies for focused attacks.
- Destroy the Syndicate Hideout before its Runner and Bruiser waves destroy your Command Nexus.

The live scene is still an early skirmish slice, not a complete commercial RTS. It uses code-drawn visuals and has no external texture or font dependency.

## Run it

1. Install **Godot 4.3 or newer**.
2. Clone or download this repository.
3. Import `project.godot` through Godot Project Manager.
4. Open the project and press **F6** or the Play button.

For headless verification:

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

See [`INSTALL.md`](INSTALL.md) for Windows, macOS, Linux, Godot path, testing, and troubleshooting details.

## RTS controls

| Key | Action |
|---|---|
| `Q` | Queue Survey Drone |
| `W` | Queue Patrol Deputy |
| `E` | Place Communications Relay |
| `R` | Place Tactical Armory |
| `F` | Queue Riot Vanguard after Armory completion |
| `T` | Place Security Turret |
| `A` | Arm attack-move, then right-click |
| `G` | Send selected Drones to nearest resource node |
| `B` | Cancel building placement |

## Current foundations

- Tier 1–3 unit catalogs, faction building trees, economy, damage, VFX, achievements, and localization data.
- A 20-mission campaign catalog: Mission 1.01 through the Mission 1.20 finale.
- Fixed-point simulation helpers, seeded RNG, lockstep turn buffering, state hashing, Resource Bank, combat/arrest resolution, and ability cooldowns.
- Data-driven campaign trigger runner, local checksummed profile/snapshot saves, and GitHub Actions smoke-test automation.
- A playable RTS economy with two resources, workers, capacity, production, structures, defense, attack-move, and enemy waves.

## Three-faction destination

- **Lunar Peacekeepers:** combined arms, defensive grids, lawful territory control, and capacity-based expansion.
- **The Syndicate:** mobility, stealth, air-drop raiding, and mobile Credit Siphons.
- **The Nullborn:** Corrupted Ground, Biomass Vents, swarm pressure, and territorial attrition.

The current playable skirmish is Peacekeeper versus Syndicate. Playable Syndicate and Nullborn economies, pathfinding, worker repair, production rallies, control groups, fog of war, advanced abilities, map variety, boss fights, campaign scenes, original art/audio, Android controls, and online network transport remain future development work.

## Project map

```text
LICENSE                             MIT license for repository code and documentation
INSTALL.md                          Godot installation and testing guide
compile_and_test.sh                 Local headless verification
.github/workflows/godot-ci.yml      GitHub Actions verification

scenes/Main.tscn                    Current RTS skirmish scene
scripts/moongoons_rts_match.gd      Playable economy, build, combat, and enemy loop
scripts/moongoons_rts_match_launch.gd
scripts/mission_controller.gd       Multi-catalog campaign trigger runner
scripts/simulation/                 Fixed-point, combat, resource, and lockstep systems

data/rts_skirmish_rules.json        RTS loop and faction-direction data
data/campaign_missions.json         Missions 1.01–1.02
data/campaign_missions_act_2_to_4.json
                                    Missions 1.03–1.20
docs/RTS_SKIRMISH.md                Full RTS control and scope guide

tests/                              Data, simulation, and campaign smoke tests
```

## Licensing

The root `LICENSE` covers original repository code and documentation. See `docs/LICENSING.md` and `docs/CREDITS.md` before adding art, audio, fonts, packages, or other third-party material.

## Design north star

Every reclaimed lunar district should change the war. MoonGoons is about restoring order, exploiting chaos, or feeding corruption one hard-won sector at a time.
