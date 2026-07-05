# Mission 1.01: First Response

**Act:** I, The Broken Peace  
**Location:** Sub-Sector 01-A, Outer Crater Slums  
**Playable faction:** Lunar Peacekeepers

Mission data lives in `data/campaign_missions.json`; `MoonGoonsMissionController` evaluates its triggers and emits dialogue, tutorial, objective, spawn, and mission effects.

## Scene 1: Crash Site

The camera descends from the Earth-rise horizon toward a burning Peacekeeper courier transport. Amber sparks, gray smoke, and distant lunar-wind audio establish the crash site.

**Radio Dispatch:** “All active units, Code 3 emergency in Sector 01-A. Courier Transport 9-Delta has been ambushed. Respond immediately.”

**Deputy Reed:** “Copy that, Central. I am on-site. Fresh tracks lead into the smuggling tunnels.”

## Scene 2: Secure the Outpost

Selecting Deputy Reed activates the initial objective and causes four Black-Market Runners to emerge from the fog around the abandoned outpost.

**Objective:** Secure the local Command Nexus.

When Reed reaches the outpost core, he discovers the security grid was deliberately disabled.

**Deputy Reed:** “The security grid is offline. This was a hit, not an accident.”

## Scene 3: Arrest Protocol

When a Syndicate target drops to 25% health or below, the mission pauses player input for the tutorial overlay.

**Tutorial:** Press `W` to Detain a low-health organic target and gain Evidence.

**Radio Dispatch:** “We need information, Reed. Detain that suspect.”

A successful arrest awards 25 Evidence through `MoonGoonsCombatDamageProcessor` and moves the player toward the Black-Market Spaceport gate.

**Arrested Runner:** “The boss took the cargo to the black-market spaceport. They are shipping it off-world tonight.”

## Implementation events

```text
on_mission_started
on_unit_selected { unit_callsign: "Deputy Reed" }
on_enter_area { area_id: "abandoned_outpost_core" }
on_target_low_health { target_faction: "the_syndicate", health_pct: 0.25 }
on_unit_arrest { target_faction: "the_syndicate" }
```

The current prototype does not yet contain this mission map or cutscene sequence. These events are ready for the future campaign scene and mission controller integration.
