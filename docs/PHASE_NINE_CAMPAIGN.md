# Phase Nine: Campaign Operations and Progression

## Campaign Operations Board

Press `C` during a match, or click **Campaign Operations** in the sidebar, to open the campaign board.

The board pauses the active RTS simulation while it is open. It lists the first five linked Act I operations:

1. **1.01 First Light Dispatch**
2. **1.02 Cold Ledger**
3. **1.03 Signal Theft**
4. **1.04 Glassline Stand**
5. **1.05 Breakwater Zero**

Select an unlocked card, then click **Start Operation** or press Enter.

## Local progression

Campaign progression is saved in:

```text
user://moongoons_campaign_profile.json
```

The profile stores:

- Selected operation
- Completed operation IDs
- Clearance earned from campaign victories
- Intel Cache totals earned from campaign victories

Clearing an operation unlocks the next linked dispatch. Replaying an already completed operation is allowed, but it does not award the same clearance twice.

## Operation profiles

Each Act I dispatch uses the live RTS battlefield but applies distinct match conditions:

- Starting Credits, Lunar Alloy, and Intel
- Command Capacity
- Command Nexus integrity
- Syndicate Hideout integrity
- Delay before the first Syndicate wave
- Initial Syndicate War Chest value

The later operations begin with stronger Syndicate funding and more immediate pressure, turning the campaign into a paced escalation instead of the same skirmish with a new hat.

## Current completion boundary

The Phase Nine bridge currently uses the core RTS win condition, destroying the Syndicate Hideout, as the final completion event for each operation.

Mission cards can describe sector, relay, terrain, and Siphon priorities, and their profiles alter the actual match. Bespoke map scenes, scripted secondary objectives, cinematic briefings, and unique mission-only bosses are still the next continuation of Phase Nine.

## Troubleshooting

To reset local campaign progression during development, close the game and delete:

```text
user://moongoons_campaign_profile.json
```

This resets Act I to Operation 1.01. It does not change repository data or source files.
