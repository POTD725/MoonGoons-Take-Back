# Project Credits & Third-Party Attribution

This file tracks the technologies, artistic direction, and people involved in MoonGoons: Take Back / MoonGoons: Crime Wars. Add the license, source URL, version, and attribution wording for every third-party asset or package before release.

## Project leadership

- **Project creator and lead direction:** Louie Green (`POTD725`)
- **MoonGoons universe, gameplay direction, and campaign concept:** MoonGoons project team
- **Repository architecture and implementation support:** Contributions documented through Git history and pull requests

## Engine and development tools

- **Godot Engine:** Game engine, GDScript runtime, scene system, rendering, export pipeline, and `user://` save sandbox.
- **Git and GitHub:** Source control, repository hosting, issues, pull requests, and CI workflows.
- **GitHub Actions:** Automated project verification when the configured workflow is enabled.

## Internal technical systems

- **Fixed-point simulation helpers:** Project-local integer arithmetic for future authoritative lockstep movement and state progression.
- **Deterministic lockstep architecture:** Project-local design and scaffolding for ordered multiplayer command simulation.
- **SHA-256 integrity checks:** Used for local profile/snapshot validation and future canonical state-hash verification.
- **Data-driven content pipeline:** Project-local JSON catalogs for units, buildings, balance, localization, campaign events, achievements, and VFX.

## Art and audio direction

- **Peacekeeper palette:** Cyan `#00E5FF` and white `#FFFFFF`.
- **Syndicate palette:** Amber `#FF9100` and smoke gray `#424242`.
- **Nullborn palette:** Acid green `#00E676` and abyss violet `#7C4DFF`.
- **Visual and audio design direction:** Defined in `docs/FX_GUIDE.md` and `docs/AUDIO_DESIGN.md`.

## Third-party assets and packages

No external art packs, fonts, audio libraries, plugins, SDKs, or code packages are credited here yet. Before a public build, add each dependency in this format:

```text
Name:
Creator / Publisher:
Version:
Source:
License:
Required attribution:
Used for:
```

Do not list a third-party asset as cleared for release unless its license has been reviewed and its required attribution has been added.
