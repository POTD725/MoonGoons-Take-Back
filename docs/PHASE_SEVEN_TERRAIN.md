# Phase Seven: Terrain, Tactical Map, and Route Guide

## Terrain types

### Glass Regolith

Glass Regolith is shown as a brown-orange field. Units moving through it are slowed. Avoid routing workers, retreating squads, and fragile Patrol Deputies through it when a clear route exists.

### Transit Lane

The blue Lunar Transit Lane improves unit movement speed. It is useful for shifting defenders across the central district or moving a capture squad between the Nexus and outer sectors.

### Navigation obstacles

Impact Ridges, Collapsed Conduits, and Shardfields are solid terrain hazards.

- Units steer around them instead of walking through them.
- Buildings cannot be placed inside their exclusion area.
- Obstacles create chokepoints where Security Turrets, Shield Wall, and hold-position orders are stronger.

## Tactical map

The sidebar includes a compact tactical map.

- Left-click a location on the tactical map to order selected units and workers to that location.
- Hold Shift while clicking to issue an attack-move order to selected combat units.
- A yellow cross shows the latest tactical-map destination.
- Friendly workers are cyan, combat units are green, Syndicate forces are red, and territory-sector markers use their current ownership colors.

## Queued routes

Use route queues to move around hazards deliberately.

- **Ctrl + right-click:** queue a movement waypoint for selected workers or combat units.
- **Ctrl + Shift + right-click:** queue an attack-move waypoint for selected combat units.
- Each selected unit keeps its own formation offset, so a squad does not all aim for the same exact crater pebble.
- The game displays planned cyan worker routes and green combat routes directly on the field.
- A route can contain up to six waypoints. When a unit reaches one, it proceeds to the next.
- A normal right-click still issues an immediate order and clears that unit’s earlier queued route.

Route queues are especially useful for moving around Glass Regolith, using the Transit Lane, staging behind a choke point, or sending one response squad toward a Siphon alert while another holds a Forward Relay.

## Terrain overlay

Press `M` to toggle terrain labels and outlines. Use this when you want a clean battlefield view or need to inspect routes and choke points.

## Practical tactics

1. Build a Security Turret near a route that exits the Transit Lane into a narrow obstacle gap.
2. Use Riot Vanguards in Shield Wall to hold a chokepoint while Patrol Deputies attack from behind.
3. Send workers along safe open routes, not through slow Glass Regolith while a Siphon Raid is active.
4. Use the tactical map to move a response squad toward a distant alert without losing focus on the main field.
5. Queue a two- or three-point patrol route to approach a contested sector from a safe angle rather than filing directly through an obstacle lane.

This is a terrain-aware steering and route-control pass, not yet a full navmesh or camera-scrolling system.