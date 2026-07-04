# MoonGoons: Crime Wars - Design Bible

## Premise

MoonGoons: Crime Wars is a real-time strategy game about reclaiming a Moon fractured into crater settlements, black-market stations, abandoned mining sites, and corrupted research infrastructure. Every match begins with a headquarters, a small security force, and a dangerous district. Players gather resources, build a base, protect command capacity, capture territory, complete objectives, and dismantle enemy networks.

## Core Match Loop

1. Establish and defend a faction headquarters.
2. Gather Credits, Lunar Alloy, Intel, and Evidence.
3. Build production, support, research, and defensive structures.
4. Expand Command Capacity through headquarters, relays, technology, and controlled districts.
5. Capture terminals and districts to earn vision, map control, and economic advantages.
6. Direct squads through real-time combat, investigation, rescues, arrests, sabotage, and survival objectives.
7. Win by completing the mission objective, not merely by flattening every building.

## Factions

### Lunar Peacekeepers

The Peacekeepers are the Moon's disciplined law-enforcement force. They use Security Zones, repairs, arrests, interrogation, defensive structures, and tactical support. Their fundamental path is Command Nexus, Tactical Armory and Drone Bay, Communications Relay, Field Medbay and Evidence Vault, then Orbital Watchtower.

Tier 1 begins with Patrol Deputies and Combat Medics. The wider roster includes Riot Vanguards, K-9 Drone Operators, Enforcer armored patrol vehicles, and the Elite Magistrate.

### The Syndicate

The Syndicate is a decentralized criminal empire of smugglers, hackers, mercenaries, and scavengers. It emphasizes speed, ambushes, stealth, siphoning, sabotage, and economic disruption. Its structures may hide until they attack or are detected.

Tier 1 begins with Black-Market Runners and Wire-Tappers. The wider roster includes Shadow-Stalker Infiltrators, Smuggler Bruisers, Widowmaker Sky-Skiffs, and The Fixer.

### The Nullborn

The Nullborn are an ancient corrupted force from the Moon's forgotten infrastructure. They spread Corrupted Ground, mutate units, consume resource sites, infect systems, and weaponize terrain.

Tier 1 begins with Corrupted Scavengers and Shard Drones. The wider roster includes Abyssal Defilers, Nullborn Siphons, Goliath Flesh-Titans, and The Singularity.

## Economy

- **Credits:** Basic structures, infantry, and routine upgrades.
- **Lunar Alloy:** High-tier structures, vehicles, armor, and mutations.
- **Intel:** Capped tactical currency for scans, commander abilities, and support.
- **Evidence:** Slow strategic currency for heroes, Tier 3, and critical mission goals.
- **Command Capacity:** Army-size limit supplied by key buildings, research, and territory.

District bonuses reward control of black-market spaceports, mining sites, communications relays, and crater settlements.

## Combat Rules

Kinetic weapons are early-game generalist tools. Energy weapons excel against heavy infantry and shields. Bio-acid works best against light units and heavy mechanical armor, but performs poorly against protected heavy infantry.

The intended macro matchups are:

- Peacekeepers counter Syndicate raids inside fortified Security Zones.
- Syndicate harassment counters slow-growing Nullborn territory.
- Nullborn corrosion and environmental control counter static Peacekeeper lines.

## Controls

The RTS command scheme uses click selection, drag selection, contextual right-click orders, Shift command queues, control groups, edge-scroll, middle-mouse panning, and wheel zoom.

The action grid is QWER / ASDF / ZXCV. The universal command row is:

- **Z:** Attack-move
- **X:** Stop
- **C:** Hold Ground
- **V:** Patrol

## Campaign

### Act I: The Broken Peace

A routine inspection reveals coordinated Syndicate sabotage. Missions establish the Peacekeepers, repair a damaged outpost, arrest a ringleader, and escort an Alloy convoy.

### Act II: Underworld Crackdown

The player selects an investigation route: infiltrate orbital smugglers or raid a sealed research facility. The choice changes the early unlock path.

### Act III: The Null Protocols

The Nullborn emerge as the third force. Players survive a containment failure, protect the research core, and destroy Apex Singularity nests.

## Map Rules

Maps are divided into capture sectors separated by crater walls, rifts, and station bulkheads. Chokes must allow 1.5 heavy-vehicle widths. Competitive 1v1 layouts are point- or line-symmetric. The Moon introduces tactical modifiers through corrosive gas vents, neutral Syndicate camps, and low-gravity pockets.

## Repository Source of Truth

- `data/unit_data.json` contains directly usable Tier 1 unit profiles.
- `data/building_data.json` contains all three faction technology trees.
- `data/gameplay_rules.json` contains the economy, balance modifiers, controls, map rules, and campaign progression.
- `scripts/game_data.gd` loads those systems for Godot scenes, UI, AI, unit spawners, and mission controllers.

The existing playable prototype can now be upgraded system by system using these files as its canonical rules.
