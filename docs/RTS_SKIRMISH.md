# MoonGoons Take Back: RTS Skirmish

`scenes/Main.tscn` now runs the MoonGoons Take Back real-time strategy skirmish. It is a code-drawn Peacekeeper versus Syndicate match designed around a classic RTS rhythm: establish an economy, expand capacity, unlock technology, field an army, defend your resource line, and break the enemy command structure.

## Current playable loop

1. Select **Survey Drones** with left-click or a drag-selection box.
2. Right-click a **Credits** or **Lunar Alloy** node to begin harvesting.
3. Drones return cargo to the Command Nexus, funding production and construction.
4. Train more Survey Drones and Patrol Deputies at the Command Nexus.
5. Use Survey Drones to build Communications Relays, Tactical Armories, and Security Turrets.
6. Build Communications Relays to increase **Command Capacity**, the MoonGoons supply limit.
7. Complete a Tactical Armory to produce Riot Vanguards.
8. Set production rally points, assign control groups, and use attack-move or hold-position orders to control the fight.
9. Defend the Command Nexus from escalating Syndicate pressure and destroy the Syndicate Hideout to win.

## Phase Two command systems

### Data-driven production

Patrol Deputy and Riot Vanguard costs now resolve from the committed Peacekeeper unit catalog, with safe local defaults if the catalog cannot load. This ties playable production to the same unit-data foundation used by the larger project.

### Control groups

- Select any mixture of Survey Drones and combat units.
- Press **Shift + 1** through **Shift + 5** to assign the selected units to a group.
- Press **1** through **5** to recall that group.

### Production rally points

Hold **Shift** and right-click any position in the lunar field to set the rally marker. New Command Nexus units move toward the Nexus rally marker; new Armory units move toward the Armory rally marker.

### Smart worker assignment

Idle Survey Drones automatically seek a nearby working resource node. They favor Lunar Alloy while the stockpile is low, then return to Credits. Manual right-click harvesting always remains available.

### Riot Vanguard: Shield Wall

Select one or more ready Riot Vanguards and press **S**.

- Shield Wall lasts six seconds.
- The Vanguard holds position and slows down while braced.
- A temporary barrier absorbs a large share of incoming damage.
- The ability then enters a cooldown before it can be used again.

### Enemy adaptation

As your army and Communications Relay network grow, the Syndicate detects the expansion and accelerates pressure against the lunar resource line.

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
| `H` | Hold selected combat units in place |
| `S` | Activate Shield Wall for selected Riot Vanguards |
| `G` | Send selected Survey Drones to the resource node nearest the cursor |
| `B` | Cancel structure placement |
| `Shift + 1–5` | Assign a control group |
| `1–5` | Recall a control group |
| `Shift + right-click` | Set Nexus and Armory production rally points |

## Three-faction destination

The live prototype remains Peacekeeper versus Syndicate. The eventual three playable factions are deliberately asymmetric:

- **Lunar Peacekeepers:** combined arms, Security Grids, patrol discipline, capacity-based expansion, and defensive tactical abilities.
- **The Syndicate:** mobility, stealth, mobile Credit Siphons, air-drop raids, and economic sabotage.
- **The Nullborn:** Corrupted Ground, Biomass Vents, rapid swarm production, and territorial attrition.

## Current boundary

This is now a richer RTS slice, not a complete competitive RTS. Still pending are obstacle-aware pathfinding, worker repair, production rallies for every building, fog of war, full unit abilities, playable Syndicate and Nullborn economies, advanced build trees, map variety, campaign-scene integration, multiplayer transport, original art and audio, accessibility options, and Android controls.

MoonGoons Take Back borrows the *shape* of a real-time strategy match, not another game’s names, story, maps, art, or implementation.