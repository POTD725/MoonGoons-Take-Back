# MoonGoons Take Back: RTS Skirmish

`scenes/Main.tscn` runs the MoonGoons Take Back real-time strategy skirmish. It is a code-drawn Peacekeeper versus Syndicate match built around a tactical rhythm: establish an economy, expand Command Capacity, unlock production, capture territory, fortify forward positions, and break the enemy command structure.

## Current playable loop

1. Select **Survey Drones** with left-click or a drag-selection box.
2. Right-click a **Credits** or **Lunar Alloy** node to begin harvesting.
3. Drones return cargo to the Command Nexus, funding production and construction.
4. Train Survey Drones and Patrol Deputies at the Command Nexus.
5. Use Survey Drones to build Communications Relays, Tactical Armories, and Security Turrets.
6. Build Communications Relays to increase **Command Capacity**, the MoonGoons supply limit.
7. Complete a Tactical Armory to produce Riot Vanguards.
8. Secure hostile sectors with combat units, then build Communications Relays inside them to turn them into Forward Relay outposts.
9. Defend the Command Nexus from escalating Syndicate pressure and destroy the Syndicate Hideout to win.

## Phase Two command systems

### Data-driven production

Patrol Deputy and Riot Vanguard costs resolve from the Peacekeeper unit catalog, with safe local defaults if a catalog cannot load.

### Control groups and rally points

- Select Survey Drones and combat units.
- Press **Shift + 1** through **Shift + 5** to assign a control group.
- Press **1** through **5** to recall that group.
- Hold **Shift** and right-click the lunar field to set Nexus and Armory production rally points.

### Smart worker assignment

Idle Survey Drones seek working resource nodes automatically. They favor Lunar Alloy while the stockpile is low, then return to Credits. Manual right-click harvesting remains available.

### Riot Vanguard: Shield Wall

Select ready Riot Vanguards and press **S**.

- Shield Wall lasts six seconds.
- The Vanguard holds position and slows down while braced.
- A temporary barrier absorbs a large share of incoming damage.
- The ability enters cooldown after use.

### Enemy adaptation

As your army and Communications Relay network grow, the Syndicate accelerates pressure against your resource line.

## Phase Three: Territory Control and Forward Operations

Three hostile lunar sectors now sit on the battlefield:

- **Aurora Exchange:** provides Credits.
- **Gravity Foundry:** provides Lunar Alloy.
- **Eclipse Signal Tower:** provides Credits and creates pressure near the Syndicate Hideout.

### Capture sectors

Move one or more combat units into a sector’s glowing control ring. Your Peacekeepers capture it while no Syndicate unit contests the zone. Enemy units can take an abandoned sector back.

### Establish Forward Relays

After securing a sector, build a completed **Communications Relay** inside its control ring.

- The sector becomes a Forward Relay outpost.
- Its recurring Credits or Lunar Alloy income doubles.
- The Relay still contributes its normal Command Capacity bonus.
- Each capture pulls the next Syndicate wave closer, so an exposed frontier can become a neon dinner bell.

The lower-left territory panel reports controlled sectors and active Forward Relays during play.

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

- **Lunar Peacekeepers:** combined arms, Security Grids, patrol discipline, capacity-based expansion, territorial reclamation, and defensive tactical abilities.
- **The Syndicate:** mobility, stealth, mobile Credit Siphons, air-drop raids, and economic sabotage.
- **The Nullborn:** Corrupted Ground, Biomass Vents, rapid swarm production, and territorial attrition.

## Current boundary

This is a growing RTS slice, not a complete competitive RTS. Still pending are obstacle-aware pathfinding, worker repair, production rallies for every building, fog of war, full unit abilities, playable Syndicate and Nullborn economies, advanced build trees, map variety, campaign-scene integration, multiplayer transport, original art and audio, accessibility options, and Android controls.

MoonGoons Take Back borrows the *shape* of a real-time strategy match, not another game’s names, story, maps, art, or implementation.