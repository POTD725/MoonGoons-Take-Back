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

### Phase 9: Campaign and progression

Implemented so far:

- Campaign Operations Board opened with `C` or its sidebar button.
- Five linked Act I mission profiles, from 1.01 through 1.05.
- Local persistent progression profile for completed missions, selected operation, Clearance, and Intel Cache.
- Mission-specific starting resources, capacity, Nexus strength, Hideout strength, first-wave timing, and initial Syndicate funding.
- Victory rewards that unlock the next dispatch.

Still pending within Phase Nine:

- Dedicated campaign map scenes and mission-specific terrain layouts.
- Scripted secondary objectives, failure conditions, and bespoke enemy spawns.
- Cinematic briefing/debriefing sequences, voice work, and unique mission-only bosses.
- Campaign save-slot UI and multiple player profiles.

## Remaining core phase

### Phase 10: Presentation and release hardening

- Original final art, unit silhouettes, animations, UI skin, music, and sound effects.
- Accessibility options, input remapping, performance profiling, and balance passes.
- Windows export pipeline, Android control design, crash reporting, and release checklist.
- Developer console disabled in release builds unless intentionally enabled.

## Separate major milestone: Online multiplayer

Online multiplayer is intentionally separate from the core phases above. It needs deterministic simulation verification, authoritative networking decisions, lobbies, matchmaking, reconnect handling, anti-cheat planning, security review, and live operations support. It should begin only after the single-player RTS loop and pathfinding are stable.

## Recommended order

Stabilize the current terrain, faction, and campaign layers through the Godot test workflow. Then use dedicated mission maps and original presentation assets to turn the campaign bridge into a full story-driven MoonGoons experience.