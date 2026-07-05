# MoonGoons Take Back: Development Roadmap

## Completed foundation phases

- **Phase 1:** RTS economy, construction, production, units, and Syndicate waves.
- **Phase 2:** Data-driven Peacekeeper production, control groups, rally points, Shield Wall, and adaptive pressure.
- **Phase 3:** Territory capture, sector income, and Forward Relay operations.
- **Phase 4:** Fog of war, explored terrain, vision sources, and Tactical Scan.
- **Phase 5:** Syndicate Siphon Raids and counter-intelligence response.
- **Phase 6:** Player manual, debug developer console, and expanded test coverage.

## Active development

### Phase 7: Navigation, terrain, and map control

Implemented so far:

- Terrain-aware steering around Impact Ridges, Collapsed Conduits, and Shardfields.
- Glass Regolith slow zones and Lunar Transit Lane speed zones.
- Terrain-based building exclusions.
- Compact clickable tactical map.
- Formation-aware queued move and attack-move routes.

Still pending within Phase Seven:

- Camera movement and zoom.
- A larger/minimizable tactical map.
- Full navmesh pathfinding and dynamic obstacle resolution.
- More than one playable lunar map.
- Improved formation behavior in narrow choke points.

### Phase 8: Faction expansion

Implemented so far:

- Syndicate War Chest economy driven by Hideout income and active Siphon Arrays.
- Ghost Protocol, Black Market Forge, and Relay Network doctrine progression.
- Shade infiltrator variant, armored Bruiser upgrades, and accelerated post-doctrine waves.
- Peacekeeper counterplay that reduces the War Chest by destroying Siphons and reclaiming sectors.

Still pending within Phase Eight:

- Player-selectable Syndicate base, construction menu, worker loop, and independent production queue.
- First playable Nullborn economy using Corrupted Ground and Biomass Vents.
- Initial faction-specific technologies and asymmetrical win pressure.
- Matchup balancing for Peacekeeper versus Syndicate and Peacekeeper versus Nullborn.

## Remaining core phases

### Phase 9: Campaign and progression

- Connect campaign missions to real scene maps and objectives.
- Mission briefing, debriefing, rewards, unlocks, and persistent progression.
- Save-slot interface and campaign chapter selection.
- Hero, ship, or officer progression where it supports the RTS game rather than replacing it.

### Phase 10: Presentation and release hardening

- Original final art, unit silhouettes, animations, UI skin, music, and sound effects.
- Accessibility options, input remapping, performance profiling, and balance passes.
- Windows export pipeline, Android control design, crash reporting, and release checklist.
- Developer console disabled in release builds unless intentionally enabled.

## Separate major milestone: Online multiplayer

Online multiplayer is intentionally separate from the core phases above. It needs deterministic simulation verification, authoritative networking decisions, lobbies, matchmaking, reconnect handling, anti-cheat planning, security review, and live operations support. It should begin only after the single-player RTS loop and pathfinding are stable.

## Recommended order

Finish the remaining Phase Seven camera and pathfinding work while stabilizing the current Syndicate director. Then build the player-selectable Syndicate and Nullborn economies on top of proven terrain, movement, and faction systems.