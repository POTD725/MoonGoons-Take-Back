# Visual Effects Design & Particle Asset Guidelines

MoonGoons effects must read instantly under pressure. The battlefield should feel noir, lunar, and overloaded with contraband science, but never turn into a fluorescent soup that hides unit ownership or danger.

## Faction color language

| Faction | Primary | Secondary | Use |
|---|---|---|---|
| Lunar Peacekeepers | `#00E5FF` cyan | `#FFFFFF` white | Security grids, clean energy, scans, regulated precision |
| The Syndicate | `#FF9100` amber | `#424242` smoke gray | Ballistic heat, hacked hardware, industrial fire, concealment |
| The Nullborn | `#00E676` acid green | `#7C4DFF` abyss violet | Corruption, biological threats, unstable mutation, void energy |

Never use an enemy faction’s primary color for a friendly high-priority warning.

## Weapon profiles

### Ballistic and kinetic tracers

- Short yellow-white tracer lines with brief smoke tails.
- Sharp sparks and gravity-falling debris against hard targets.
- Used by Patrol Deputy carbines and Syndicate automatic weapons.
- Keep lifespan short enough that rapid fire does not create a glowing fence across the screen.

### Energy and laser beams

- Continuous beam from muzzle to target.
- Peacekeeper energy is stable cyan; Syndicate energy flickers and jitters as modified hardware.
- Impacts create a compact heat-distortion sphere and temporary dark burn decal.
- Used by mining lasers, laser cannons, and rail-rifle impact events.

### Bio-acid and corrosive spray

- Thick, bubbling green globules in a cone or arc.
- Impact creates a wet, boiling puddle that fades in roughly 6 seconds.
- The ground effect must show its damage boundary clearly and avoid covering selection rings.
- Used by Corrupted Scavenger and Abyssal Defiler attacks.

## Ability and environmental effects

### Syndicate cloaking

- Cloaked meshes render at roughly 95% transparency with a low-amplitude refraction shimmer.
- Detection reveals the target with a bright cyan wireframe pulse, then a brief target marker.
- The reveal effect is a player-information signal, not a permanent decoration.

### Peacekeeper Security Grid

- Faint cyan hex pattern on terrain inside a valid grid radius.
- A soft ripple expands outward from the source every 3 seconds.
- Friendly units inside receive a subtle cyan rim light; it must not obscure team-color or health bars.

### Nullborn Corrupted Ground

- Lunar dust transitions into dark violet substrate with glowing green biological veins.
- Edges advance using animated noise and alpha blending; never pop in as a hard circle.
- Low contrast at the edge, high legibility around hazard boundaries and occupied buildings.

## Implementation rules

- VFX, shaders, and audio only read simulation events. They never modify movement, health, cooldowns, pathfinding, fog, or hit confirmation.
- Particle spawning must be pooled. Avoid one-node-per-projectile effects in large battles.
- Respect accessibility: use shape, motion, sound, and UI iconography in addition to color.
- Effects must scale with quality settings and remain readable at mobile target resolutions.

## Asset naming

```text
fx_pk_*
fx_syn_*
fx_nb_*
fx_world_*
shader_pk_*
shader_syn_*
shader_nb_*
```

## Data hook

Use `data/fx_profiles.json` for effect IDs and palette values. Gameplay scripts emit an event name, while client visuals resolve that event into an effect profile.
