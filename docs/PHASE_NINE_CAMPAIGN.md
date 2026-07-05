# Phase Nine: Story Campaign and Opponent Difficulty

## Fixed story route

The campaign is not a selectable mission list.

MoonGoons Take Back currently follows the **Lunar Peacekeepers** story route in a required narrative order. Every victory advances the player to the next dispatch automatically:

1. **1.01 First Light Dispatch**
2. **1.02 Cold Ledger**
3. **1.03 Signal Theft**
4. **1.04 Glassline Stand**
5. **1.05 Breakwater Zero**

The game remembers the next unfinished chapter. Completed operations are not presented as alternate campaign choices.

The Syndicate and Nullborn have route placeholders in the campaign data, but they are not selectable until those factions have playable bases, economies, units, and their own story campaigns.

## Story Dispatch screen

Press `C` during a match, or click **Story Dispatch** in the sidebar.

The Story Dispatch screen pauses the active RTS simulation. It shows:

- The current Act and required next operation
- A story briefing
- The primary objective
- Clearance earned so far
- The only player-facing choice: **Easy, Medium, or Hard** opponent difficulty

Click a difficulty, then click **Begin Next Dispatch** or press Enter.

## Opponent difficulty

Difficulty changes enemy pressure without changing chapter order or story rewards.

| Setting | Enemy response |
|---|---|
| **Easy** | Slower first raid, less Syndicate funding, weaker units, and longer wave intervals |
| **Medium** | Intended story pressure and baseline enemy strength |
| **Hard** | Faster raids, more War Chest funding, stronger units, and shorter wave intervals |

The selected setting is stored in the local campaign profile and applies when the current story dispatch starts.

## Local progression

Campaign progression is saved in:

```text
user://moongoons_campaign_profile.json
```

The profile stores:

- Active story route
- Next story operation
- Opponent difficulty
- Completed operation IDs
- Clearance earned from campaign victories
- Intel Cache totals earned from campaign victories

Clearing a new chapter grants its rewards and automatically advances the next required dispatch. Replaying the Act I finale after completion is allowed, but does not award duplicate Clearance.

## Operation profiles

Each dispatch uses the live RTS battlefield while applying its own story profile:

- Starting Credits, Lunar Alloy, and Intel
- Command Capacity
- Command Nexus integrity
- Syndicate Hideout integrity
- Delay before the first Syndicate wave
- Initial Syndicate War Chest value

Difficulty then modifies the opponent’s funding, wave timing, durability, and damage. This lets a player choose how hard the enemy pushes without letting them skip the story’s spine.

## Current completion boundary

The current Phase Nine bridge uses the core RTS victory condition, destroying the Syndicate Hideout, as the completion event for every Act I chapter.

The chapters already change real match conditions, and the narrative order now persists. Dedicated campaign maps, scripted secondary objectives, cinematic briefings, unique mission-only bosses, and multi-profile save slots are the next continuation of Phase Nine.

## Troubleshooting

To reset local campaign progression during development, close the game and delete:

```text
user://moongoons_campaign_profile.json
```

This resets the Peacekeeper story route to Operation 1.01 and returns opponent difficulty to Medium. It does not change repository data or source files.
