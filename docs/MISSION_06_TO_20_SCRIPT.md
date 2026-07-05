# Comprehensive Campaign Script: Missions 1.06–1.20

The canonical machine-readable definitions live in `data/campaign_missions_act_2_to_4.json`. This document summarizes each remaining operation, its player objective, and its special runtime hook.

## Act II: Underworld Crackdown

| Mission | Operation | Objective | Signature event |
|---|---|---|---|
| 1.06 | The Protection Racket | Disable 3 Syndicate Siphon Overrides | Final override triggers The Fixer’s 10-second minimap blackout. |
| 1.07 | Black-Market Hijack | Escort a captured supply truck to safety | Ridge explosives block the primary path and redirect the truck through low gravity. |
| 1.08 | The Informant | Extract a rogue Syndicate technician | A protected download grants +2 Intel per second while the channel runs. |
| 1.09 | Precinct Under Siege | Survive the outpost assault | At three minutes, Sky-Skiffs air-drop infiltrators into resource zones. |
| 1.10 | Raid on Vault 7 | Secure the lost Evidence vault | Energy-ramp mining turrets demand a coordinated Shield Wall line. |

## Act III: The Null Protocols

| Mission | Operation | Objective | Signature event |
|---|---|---|---|
| 1.11 | The First Spore | Destroy 4 Biomass Vents | Destroyed vents create 12-second Corrosive Gas clouds. |
| 1.12 | Uneasy Alliance | Protect the Syndicate hideout | Syndicate units become temporary allies; hideout destruction fails the mission. |
| 1.13 | The Deep Crust Lab | Retrieve the original biological sequence | Burrowing Abyssal Defilers attack support lines and apply silence. |
| 1.14 | The Corrupted Relays | Cleanse 3 Communications Relays | Captures cause HUD static and irregular fog pulses. |
| 1.15 | Evacuation Alpha | Launch 5 civilian transports | A Goliath Flesh-Titan arrives every two minutes; Grave Spores can raise fallen infantry. |

## Act IV: Lunar Apocalypse

| Mission | Operation | Objective | Signature event |
|---|---|---|---|
| 1.16 | The Swallowed Colony | Establish a Command Nexus in the infected city center | Organic units suffer constant drain outside Peacekeeper Security Grids. |
| 1.17 | The Fixer’s Final Gamble | Defeat The Fixer | The boss fight opens with a 30-second global blackout. |
| 1.18 | Into the Maw | Escort an Experimental Alloy Core bomb to the hive | Tremors rotate low-gravity sectors every 60 seconds. |
| 1.19 | The Reality Tear | Destroy 3 Reality Anchors | The Singularity pulls and freezes squads before a Void Plasma barrage. |
| 1.20 | MoonGoons: Crime Wars | Destroy the Spore Heart and evacuate | At 10% health, a 60-second orbital strike countdown begins. |

## Finale rules

Mission 1.20 completes through the `on_timer_elapsed` orbital-strike event after survivors reach the transport zone. Completion triggers the custom skirmish sandbox unlock effect and the final credits event.

**Commander Vance:** “Reed! Get your squads out before the strike cleanses the sector!”

## Implementation boundary

These missions are complete as campaign data and trigger specifications. Their individual map scenes, boss behaviors, hazards, civilian transport logic, and final credits presentation still need to be built and wired to the `MoonGoonsMissionController` effect signal.
