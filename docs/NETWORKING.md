# Multiplayer Network Architecture & State Synchronization

> **Status: architecture and local simulation scaffolding.** This repository does not yet ship multiplayer transport, matchmaking, NAT traversal, server authority, encryption, or anti-cheat. The rules below define how the future RTS simulation must behave before online play is enabled.

## Deterministic lockstep goal

MoonGoons multiplayer should synchronize **player commands**, not every position, health value, or visual effect. Each client simulates the same deterministic game state from the same ordered command stream.

```text
Client input -> host/relay validation -> ordered turn packet -> every client simulates identical turns
```

Rendering, particle effects, audio, camera motion, and UI animations are observers. They must never alter simulation state.

## Fixed simulation timing

- Simulation rate: **30 ticks per second**.
- Communication turn: **3 simulation ticks**, or approximately **100 ms**.
- Input delay: commands issued during turn `N` should execute during turn `N + 2`.
- Hash interval: every **150 simulation ticks** (5 seconds).

The current Godot scaffolding lives in:

```text
scripts/simulation/fixed_math.gd
scripts/simulation/fixed_vector2.gd
scripts/simulation/simulation_unit.gd
scripts/simulation/fixed_point_movement_controller.gd
scripts/simulation/lockstep_network_manager.gd
scripts/simulation/game_state_hash.gd
```

## Canonical command envelope

All commands must be expressed with stable IDs and fixed-point coordinates before they enter a lockstep turn.

```json
{
  "turn_id": 42,
  "player_id": 1,
  "command_type": "move",
  "selected_unit_ids": ["unit_000017", "unit_000019"],
  "target_x_fp": 142500,
  "target_z_fp": -82150
}
```

`*_fp` values are integers scaled by 1,000. Network code must not rely on raw floats for movement targets, combat values, resource math, random rolls, or state hashes.

## Command rules

- A client submits commands for a future execution turn.
- Each expected player must submit a command packet, including an explicit `no_op` when they have no action.
- A turn advances only when every player packet for that turn is available and validated.
- Command order is deterministic: sort by player ID, then command sequence ID.
- The simulation runs exactly three fixed ticks after executing a complete communication turn.

## State-hash checks

Every 150 simulation ticks, clients serialize a canonical snapshot of critical simulation state and calculate a SHA-256 digest.

Include:

- Turn and tick number
- Resource banks
- Command Capacity
- Unit IDs, faction IDs, health, status flags, and fixed-point positions
- Buildings, upgrades, ownership, and construction state
- Seeded random-generator state
- Mission objectives and capture-point ownership

Exclude:

- Camera position
- Animation timing
- Audio playback state
- Particle systems
- UI hover, tooltips, and menus

A mismatch should pause future turn execution and present the localized `system_alerts.game_desynced` message. Recovery requires an authoritative, validated simulation snapshot. Do not attempt silent correction.

## Transport boundary

The `MoonGoonsLockstepNetworkManager` is intentionally transport-agnostic. A future adapter may use Godot Multiplayer, ENet, WebSocket, or dedicated-server networking, but that adapter must only deliver validated command envelopes and snapshot messages. It must not bypass the command queue.

## Security and shipping rules

- The host or dedicated authority validates player ownership, unit IDs, target coordinates, command costs, cooldowns, and build prerequisites.
- Developer commands are disabled in release and multiplayer builds.
- Do not trust client-reported resources, health, achievement rewards, or state hashes without validation.
- Use authenticated sessions and encrypted transport before public matchmaking is enabled.

## Test requirements before multiplayer

1. Run two local clients with an identical seed and repeatable command log.
2. Verify matching state hashes for at least 5 minutes.
3. Simulate delayed, duplicated, out-of-order, and absent packets.
4. Confirm a `no_op` packet prevents a stalled turn when a player is idle.
5. Verify host-side rejection of commands for enemy-owned units and invalid ability targets.
6. Confirm a snapshot recovery restores hashes before resuming the match.
