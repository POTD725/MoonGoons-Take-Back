# Syndicate Rising criminal campaign

**Syndicate Rising** is the playable criminal-side companion route for **MoonGoons Take Back**. It uses original MoonGoons names, mechanics, code, and vector art. It does not copy assets or code from the Police Chief APK or any other game.

## Opening premise

The Peacekeepers shattered the old Syndicate network, seized its relays, and turned the surviving gangs against one another. The player takes command of a damaged lunar hideout beneath Crater Market. Backroom Command still works, but the Chop Shop, Black Market, Safehouse Bunks, Street Clinic, Boss's Office, Signal Den, and Smuggler Tunnel must be rebuilt.

The goal of this vertical slice is to rebuild the criminal network from the underside of the Moon, run increasingly dangerous scores, and grow enough Notoriety to challenge the Peacekeeper occupation.

## Core criminal loop

1. Rebuild hideout rooms using Credits.
2. Select a timed score from the Score Board.
3. Choose up to three available crew members.
4. Fight a turn-based tactical job using Strike, Evade, and class Specials.
5. Bring home Credits, Contraband, Intel, and Notoriety.
6. Fence Contraband through the Smuggler Tunnel.
7. Manage Heat. High Heat makes response teams stronger and job windows shorter.
8. Advance Black Tech through the Signal Den.

## Starter crew

| Crew member | Class | Specialty |
|---|---|---|
| Nyx Raze | Enforcer | Durable pressure and self-recovery |
| Vox-13 | Runner | Fast burst damage and evasion |
| Cinder Quell | Sharpshot | Highest single special attack |
| Grit Mercer | Enforcer | Defensive frontline muscle |

## Current scores

The procedural Score Board can offer skiff hijackings, evidence-vault cracks, payroll siphons, fixer extractions, sensor sabotage, reactor-core smuggling, and raids against the Hollow Fang rival syndicate.

## Campaign selection

The new `CampaignRouter.tscn` keeps all current play surfaces available:

- **Syndicate Rising:** criminal hideout and tactical-job campaign.
- **Precinct Duty:** existing Peacekeeper station-management campaign.
- **Take Back Front:** existing fixed-story RTS build.

Syndicate and Precinct saves use separate files, so switching viewpoints does not overwrite either campaign.

## Art direction

The route retains the established code-drawn lunar UI, cutaway rooms, touch-friendly cards, and neon command panels. The criminal side shifts the palette toward magenta, violet, amber, smoke-black, and salvaged-metal tones. Original reusable SVGs live under `assets/syndicate/`.
