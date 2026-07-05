# Skirmish AI Behavior Tree & Finite-State Machine

MoonGoons skirmish commanders evaluate the map every **2.0 seconds**. The AI reads resources, army strength, discovered structures, controlled sectors, and local threat values before choosing a macro state.

## Macro states

```text
BOOTSTRAP -> MACRO_EXPAND -> HARASS -> FULL_ASSAULT
                 |              ^          |
                 +--> DEFEND ---+----------+
```

### BOOTSTRAP

Used at match start. Send workers to the nearest resources, queue Tier 1 scouts, and establish the first production building.

### MACRO_EXPAND

Used when home-sector threat is below 20%. Spend roughly 70% of income on extraction, Command Capacity, tech, and controlled expansion.

### HARASS

Used after the AI has at least four Tier 1 combat units. Form a small raiding party and target exposed resource nodes, natural expansions, isolated Siphons, and lightly defended side sectors.

### DEFEND

Triggered when hostile units enter the home sector or when local sector threat exceeds the AI’s safe threshold. Cancel non-critical expansion queues, pull local squads into defensive zones, and prioritize turrets or faction-equivalent defenses.

### FULL_ASSAULT

Triggered when command-capacity utilization exceeds 80%, a target has a confirmed security gap, or the enemy’s main force is absent. Commit combat groups to a coordinated push against a capture terminal, production hub, or headquarters.

## Faction brains

### Lunar Peacekeepers

- Do not establish a second base until a Tactical Armory and at least two defensive turrets are active.
- Pair Riot Vanguards with Combat Medics, then advance through overlapping Security Zones.
- Prefer decisive, slowly advancing formations rather than chasing raiders into unscouted terrain.

### The Syndicate

- Prioritize flank sectors and Intel Relays over static central positions.
- Use cheap mobile crews to scout and Siphon scattered resources.
- Withdraw an attack if it fails to produce a breakthrough within 15 seconds. Trigger Sprint, break line of sight, and regroup inside fog or a Signal Jammer shroud.

### The Nullborn

- Push Corrupted Ground from the map edge toward the central sectors.
- Use expendable Tier 1 swarms to exhaust enemy cooldowns and soften positions.
- Favor attrition, map denial, and mutation preparation before committing heavy Tier 3 units.

## Sector Threat Value

Before crossing into a hostile sector, calculate:

```text
STV = (enemy combat units × 1.0)
    + (enemy defensive buildings × 1.5)
    - (friendly combat units × 1.2)
```

- **STV > 1.5:** Fall back to `DEFEND`, build counters, and reinforce.
- **STV < 0.8:** Use `HARASS` or `FULL_ASSAULT`, depending on command-capacity utilization and target value.
- **0.8 to 1.5:** Scout, reposition, secure nearby resources, and wait for a favorable state change.

## Integration target

`res://scripts/ai_commander.gd` should own timing, state selection, faction policy, target scoring, and order requests. Individual units should only receive orders, never decide the entire war on their own.
