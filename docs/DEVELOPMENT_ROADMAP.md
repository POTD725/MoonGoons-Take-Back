# MoonGoons Take Back: Development Roadmap

## Completed foundation phases

- **Phase 1:** RTS economy, construction, production, units, and Syndicate waves.
- **Phase 2:** Data-driven Peacekeeper production, control groups, rally points, Shield Wall, and adaptive pressure.
- **Phase 3:** Territory capture, sector income, and Forward Relay operations.
- **Phase 4:** Fog of war, explored terrain, vision sources, and Tactical Scan.
- **Phase 5:** Syndicate Siphon Raids and counter-intelligence response.
- **Phase 6:** Player manual, debug developer console, and expanded test coverage.

## Remaining core phases

### Phase 7: Navigation, terrain, and map control

- Obstacle-aware movement and pathfinding.
- Traversable terrain types, chokepoints, blockers, and lane design.
- Camera movement and a tactical minimap.
- More than one playable lunar map.
- Improved selection feedback, formation movement, and squad behavior.

### Phase 8: Faction expansion

- Playable Syndicate economy, construction, and unit roster.
- First playable Nullborn economy using Corrupted Ground and Biomass Vents.
- Initial faction-specific technologies and asymmetrical win pressure.
- Matchup balancing for Peacekeeper versus Syndicate and Peacekeeper versus Nullborn.

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

Online multiplayer is intentionally separate from the four core phases above. It needs deterministic simulation verification, authoritative networking decisions, lobbies, matchmaking, reconnect handling, anti-cheat planning, security review, and live operations support. It should begin only after the single-player RTS loop and pathfinding are stable.

## Recommended order

Finish Phase 7 before starting faction expansion. Strong terrain, movement, camera, and map controls make every later faction, mission, and piece of art more valuable.
