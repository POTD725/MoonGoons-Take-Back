# QA Verification Protocol & Developer Debug Registry

This guide defines the minimum local verification loop for MoonGoons systems. Run the relevant checks after any change to selection, combat resolution, pathfinding, AI, data loading, or economy logic.

## Core verification cases

| Test ID | System | Setup | Expected result | Pass criteria |
|---|---|---|---|---|
| QA-101 | Selection box filter | Box-select 3 Deputies and 2 workers. | All selected entities register, but worker entries are excluded from the combat action panel. | Only the 3 Deputies receive combat movement orders. |
| QA-204 | Tactical Siphon | A Syndicate Runner channels Siphon on an active node. | The node remains intact and the Syndicate gains 2 Credits per second. | Income ticks precisely and does not corrupt the node state. |
| QA-309 | FSM threat response | Place 6 Peacekeeper squads outside an AI base. | AI enters `DEFEND`, pauses expansion, recalls local forces, and prioritizes turrets. | Defensive construction and retreat behavior occur without a stalled AI tick. |
| QA-412 | Shield Wall direction | Activate Riot Vanguard Shield Wall and attack from front, flank, and rear. | Only frontal kinetic hits gain the 75% reduction. | Side and rear hits deal normal computed damage. |
| QA-501 | Data registry lookup | Load all JSON data and request known and unknown IDs. | Known IDs return dictionaries; unknown IDs return empty dictionaries without crashing. | `MoonGoonsGameData.errors` stays empty for valid assets. |
| QA-602 | Command Capacity | Recruit until capacity is full, then attempt one additional recruit. | UI displays the capacity limit and does not spend resources on the rejected unit. | Unit count and Credits remain correct. |
| QA-703 | Combat modifier table | Apply Kinetic, Energy, and Bio-Acid to each armor class. | Damage follows `gameplay_rules.json` multipliers. | Result matches the configured table to displayed precision. |
| QA-804 | Mission state | Secure all relays, then run a Nexus-loss scenario. | Victory and defeat states cannot trigger together. | One terminal state is displayed and redeploy restores a clean mission. |

## Developer-only commands

Developer commands must only be enabled in debug builds or behind a local development flag. Never ship a live multiplayer build with authority-changing commands enabled.

| Command | Effect |
|---|---|
| `mg_give_credits <integer>` | Add or remove Credits. |
| `mg_give_alloy <integer>` | Add or remove Lunar Alloy. |
| `mg_unlock_intel` | Set current Intel to the 200 cap. |
| `mg_give_evidence <integer>` | Add or remove Evidence. |
| `mg_reveal_map` | Reveal all sectors and disable fog for test use. |
| `mg_spawn_unit <unit_id>` | Spawn a known unit at the test cursor/world coordinate. |
| `mg_kill_selected` | Destroy the selected test entity. |
| `mg_freeze_ai` | Toggle AI evaluation. |
| `mg_game_speed <float>` | Set global test timescale within safe bounds. |

## Smoke-test sequence

1. Launch the project with the debug flag enabled.
2. Confirm `MoonGoonsGameData.load_all()` returns true.
3. Spawn one unit from every implemented faction and Tier.
4. Verify selection, move, attack, resource, and ability commands.
5. Trigger one AI defense scenario and one assault scenario.
6. Test win, loss, restart, and reload behavior.
7. Return time scale to `1.0`, unfreeze AI, and repeat the test without console intervention.

## Bug-report minimum fields

Every issue should include the map or mission, faction, selected unit/building IDs, reproduction steps, expected result, actual result, screenshot or video when available, and the active Git commit hash.
