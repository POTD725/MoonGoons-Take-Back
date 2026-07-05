# MoonGoons Take Back 🌙

**MoonGoons Take Back** is a Godot 4 real-time strategy prototype set in the wider MoonGoons universe. Build a lunar precinct economy, reclaim territory, establish forward operations, scout unknown sectors, counter Syndicate extraction, and dismantle the enemy network before the Nullborn crisis consumes the Moon.

## Playable RTS prototype: Phase Five

`scenes/Main.tscn` launches a code-drawn Peacekeeper versus Syndicate RTS skirmish.

- Survey Drones harvest Credits and Lunar Alloy, returning cargo to the Command Nexus.
- Communications Relays expand Command Capacity; Tactical Armories unlock Riot Vanguards.
- Use control groups, rally points, attack-move, hold position, and Riot Vanguard Shield Wall.
- Capture Aurora Exchange, Gravity Foundry, and Eclipse Signal Tower.
- Place a completed Communications Relay in a secured sector to create a Forward Relay that doubles sector income and extends sight.
- Explore through unit and structure vision. Previously scouted terrain remains dim; unknown terrain is hidden by lunar fog.
- Gain Intel from neutralizing Syndicate forces. Press `X` or use Tactical Scan to reveal the cursor area temporarily.
- Respond to hidden Syndicate **Siphon Raids** before their extraction arrays drain a resource node and matching stockpile.
- Destroy Siphon Arrays for additional Intel, then destroy the Syndicate Hideout before its escalating waves destroy the Command Nexus.

This is an early skirmish slice, not a complete commercial RTS. The active game uses code-drawn visuals without external texture or font dependencies.

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

See [`INSTALL.md`](INSTALL.md) for setup and troubleshooting.

## RTS controls

| Key | Action |
|---|---|
| `Q` / `W` | Queue Survey Drone / Patrol Deputy |
| `E` / `R` / `T` | Build Relay / Armory / Security Turret |
| `F` | Queue Riot Vanguard after Armory completion |
| `A` / `H` | Attack-move / hold position |
| `S` | Riot Vanguard Shield Wall |
| `X` | Tactical Scan at cursor |
| `G` / `B` | Gather nearest resource / cancel build |
| `Shift + 1–5` / `1–5` | Assign / recall control group |
| `Shift + right-click` | Set production rally points |

## Current foundations

- Tier 1–3 unit catalogs, building trees, economy, damage, VFX, achievements, and localization data.
- A 20-mission campaign catalog from Mission 1.01 through Mission 1.20.
- Fixed-point helpers, seeded RNG, lockstep buffering, state hashing, saves, Resource Bank, combat/arrest resolution, and ability cooldowns.
- GitHub Actions import and smoke-test automation.
- A playable RTS with resources, capacity, construction, production, territory capture, Forward Relay bonuses, fog of war, Tactical Scan, and hidden Syndicate Siphon Raids.

## Three-faction destination

- **Lunar Peacekeepers:** combined arms, defensive grids, territory reclamation, visibility infrastructure, and tactical defensive abilities.
- **The Syndicate:** mobility, stealth, sensor disruption, air-drop raids, Credit Siphons, counter-intelligence, and sabotage.
- **The Nullborn:** Corrupted Ground, Biomass Vents, hidden growth, swarm pressure, and territorial attrition.

The current playable skirmish is Peacekeeper versus Syndicate. Playable Syndicate and Nullborn economies, obstacle-aware pathfinding, worker repair, full build trees, minimap/camera movement, deeper abilities, campaign scenes, original art/audio, Android controls, and online network transport remain future work.

## Key project files

```text
scenes/Main.tscn                              Current Phase Five RTS skirmish
scripts/moongoons_rts_phase_four.gd           Fog of war and Tactical Scan layer
scripts/moongoons_rts_phase_five.gd           Siphon Raid and counter-operation layer
data/rts_phase_four_recon.json                Fog, vision, and Tactical Scan rules
data/rts_phase_five_siphon_raids.json         Siphon Raid values and counter-intel rewards
tests/rts_phase_four_smoke_test.gd            Phase Four recon smoke test
tests/rts_phase_five_smoke_test.gd            Phase Five Siphon Raid smoke test
docs/RTS_SKIRMISH.md                          RTS controls and design scope
compile_and_test.sh                           Seven-step local verification pipeline
.github/workflows/godot-ci.yml                GitHub Actions verification
```

## Licensing

The root `LICENSE` covers original repository code and documentation. Read `docs/LICENSING.md` and `docs/CREDITS.md` before adding art, audio, fonts, packages, or other third-party materials.

## Design north star

Every reclaimed lunar district should change the war. MoonGoons Take Back is about restoring order, exploiting chaos, or feeding corruption one hard-won sector at a time.
