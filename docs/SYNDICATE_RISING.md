# Syndicate Rising criminal campaign

**Syndicate Rising** is the playable criminal-side companion route for **MoonGoons Take Back**. It uses original MoonGoons names, mechanics, code, illustrations, and synthesized audio. It does not copy assets, code, audio, names, or story from the Police Chief APK or any other game.

## Opening premise

The Peacekeepers shattered the old Syndicate network, seized its relays, and turned surviving crews against one another. The player takes command of a damaged lunar hideout beneath Crater Market. Backroom Command still works, but the Chop Shop, Black Market, Safehouse Bunks, Street Clinic, Boss's Office, Signal Den, and Smuggler Tunnel must be rebuilt.

The opening campaign follows Nyx Raze and her crew as they steal the Ghost Key, break the Blueglass evidence network, hijack the Dawn Convoy, blackout Authority Grid Seven, and seize Eclipse Signal Tower.

## Included playable systems

1. Illustrated prologue and chapter cutscenes.
2. Eight individually illustrated hideout rooms.
3. Room rebuilding and upgrades through level 5.
4. Four named crew members with portrait art, classes, XP, levels, health, power, defense, injuries, and recovery.
5. Five sequential story jobs plus repeatable procedural scores.
6. Turn-based tactical raids with Strike, Evade, Specials, Auto Raid, abort, victory, and defeat states.
7. Credits, Contraband, Intel, Heat, Notoriety, Black Tech, and separate criminal-side saving.
8. Room effects including faster healing, stronger fencing, improved Heat cooling, crew capacity, and income bonuses.
9. Original runtime-generated music themes and sound effects for menus, hideout play, combat, rebuilding, warnings, abilities, victories, and defeats.
10. Mouse and touch controls for browser, desktop, and Android builds.

## Starter crew

| Crew member | Class | Specialty |
|---|---|---|
| Nyx Raze | Enforcer | Durable pressure and self-recovery |
| Vox-13 | Runner | Fast burst damage and evasion |
| Cinder Quell | Sharpshot | Highest single special attack |
| Grit Mercer | Enforcer | Defensive frontline muscle |

## Story chapters

| Chapter | Story score | Location |
|---|---|---|
| 1 | Steal the Ghost Key | Crater Market Relay |
| 2 | Break Blueglass Records | Blueglass Evidence Vault |
| 3 | Hijack the Dawn Convoy | Mare Highway |
| 4 | Blackout the Precinct | Authority Grid Seven |
| 5 | Crown the Crater | Eclipse Signal Tower |

The Score Board also offers skiff hijackings, evidence-vault cracks, payroll siphons, fixer extractions, sensor sabotage, reactor-core smuggling, and raids against the Hollow Fang rival syndicate.

## Campaign selection

`CampaignRouter.tscn` keeps all current play surfaces available:

- **Syndicate Rising:** illustrated criminal hideout and tactical-job campaign.
- **Precinct Duty:** existing Peacekeeper station-management campaign.
- **Take Back Front:** existing fixed-story RTS build.

Syndicate and Precinct saves use separate files, so switching viewpoints does not overwrite either campaign.

## Asset and audio policy

All campaign illustrations are original MoonGoons SVG assets stored under `assets/syndicate/`. Music and sound effects are synthesized at runtime by `scripts/syndicate_audio.gd`, avoiding third-party sample dependencies. These assets are a focused production pack for the current playable campaign, not a claim of one-for-one parity with the thousands of remotely downloaded resources used by the reference APK.
