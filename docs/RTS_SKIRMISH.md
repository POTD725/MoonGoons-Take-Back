# MoonGoons RTS Skirmish Direction

MoonGoons: Take Back now has a playable real-time strategy slice in `scenes/Main.tscn`. It uses MoonGoons factions, places, and terminology while taking broad inspiration from classic real-time base-building games: economy first, production next, then tactical combat and map control.

## Current playable loop

1. **Select Survey Drones** with left-click or a drag-selection box.
2. **Right-click Credits or Lunar Alloy nodes** to assign harvesting.
3. Drones collect cargo, return to the Command Nexus, and deposit it into the resource bank.
4. Spend resources to train additional Drones and Patrol Deputies.
5. Use selected Drones to place Communications Relays, Tactical Armories, and Security Turrets.
6. Build Communications Relays to increase **Command Capacity**, the MoonGoons supply limit.
7. Complete a Tactical Armory to produce Riot Vanguards.
8. Use right-click orders or `A` then right-click for attack-move.
9. Defend the Command Nexus from escalating Syndicate waves and destroy the Syndicate Hideout to win.

## Hotkeys

| Key | Action |
|---|---|
| `Q` | Queue Survey Drone |
| `W` | Queue Patrol Deputy |
| `E` | Place Communications Relay |
| `R` | Place Tactical Armory |
| `F` | Queue Riot Vanguard after Armory completion |
| `T` | Place Security Turret |
| `A` | Arm attack-move; then right-click a destination or enemy |
| `G` | Send selected Survey Drones to the resource node nearest the cursor |
| `B` | Cancel structure placement |

## Three-faction destination

The live prototype is Peacekeeper versus Syndicate. The data direction keeps the eventual three playable factions asymmetric:

- **Lunar Peacekeepers:** defensible combined arms, Security Grids, precise ranged fire, and capacity-based expansion.
- **The Syndicate:** mobile credit siphons, stealth raids, air-drop pressure, and opportunistic sabotage.
- **The Nullborn:** Corrupted Ground, Biomass Vents, swarm production, and territorial attrition.

## Implementation boundary

The prototype currently uses code-drawn visuals and a local AI spawner. It is not a full competitive RTS yet. Still pending: pathfinding around blockers, worker repair, production rallies, control groups, unit abilities, fog of war, a playable Syndicate economy, a playable Nullborn economy, multiplayer transport, saved build orders, art assets, audio assets, and expanded maps.

The goal is a MoonGoons RTS with its own police-versus-criminal-versus-corruption identity, not a recreation of another game’s intellectual property.
