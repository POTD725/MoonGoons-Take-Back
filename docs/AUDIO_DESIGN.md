# Audio Design & Dynamic Soundscape Architecture

MoonGoons: Crime Wars should sound like a lunar police scanner trapped inside a crime opera: clean Peacekeeper signals, dirty Syndicate machinery, and Nullborn corruption leaking through every wall.

## Dynamic music state machine

The music director crossfades among three layers using live combat conditions.

### Layer 1: Underworld Ambiance

**When:** No active combat anywhere on the map.

**Palette:** Minimal synth pads, distant mechanical clangs, pressure-door groans, sparse percussion, and a cold lunar wind bed.

### Layer 2: Tactical Escalation

**When:** The player enters a contested sector or starts a small skirmish.

**Palette:** Fast electronic hats, restrained bass swells, clipped radio artifacts, and tightened rhythmic pulses.

### Layer 3: Syndicate Turf War

**When:** More than ten combat units are exchanging attacks in a shared area, or a Command Nexus takes damage.

**Palette:** Industrial distortion, aggressive orchestral-cyberpunk percussion, alarm layers, and urgent sub-bass. It should feel like the Moon has started grinding its teeth.

## Faction sound signatures

### Lunar Peacekeepers

- **Identity:** Disciplined, clean, high-tech, regulated.
- **Foley:** Digital chirps, pneumatic reloads, crisp radio chatter, armored bootfalls.
- **Weapons:** Laser pings, pulse-carbine clicks, hard orbital-artillery shockwaves.
- **Voice direction:** Calm and professional. Example language: “Copy that, central.” “Suspect in sight.” “Code 3 initialized.”

### The Syndicate

- **Identity:** Gritty, analog, improvised, industrial.
- **Foley:** Exhaust sputters, grinding gears, short circuits, brittle radio static.
- **Weapons:** Loud ballistic bursts, sizzling plasma cuts, muffled explosive thuds.
- **Voice direction:** Cynical, quick, street-smart. Example language: “Ears open.” “Cops on the grid.” “Grab the cash and run.”

### The Nullborn

- **Identity:** Organic, corrupted, eldritch, bio-mechanical.
- **Foley:** Slithers, wet movement, guttural pulses, reversed digital fragments, stressed metal.
- **Weapons:** Hissing bio-acid, unstable void crackle, heavy flesh-and-alloy impacts.
- **Voice direction:** Non-verbal or heavily processed. Favor layered whispers, clicks, harmonic screams, and inverted electronic speech.

## Operational voice-line matrix

| Trigger | Peacekeepers | Syndicate | Nullborn |
|---|---|---|---|
| Unit selected | “Standing by for dispatch.” | “What’s the payout?” | Low harmonic click |
| Move order | “En route to coordinates.” | “Moving light, moving fast.” | Wet slithering slide |
| Attack order | “Engaging hostilities.” | “Light ’em up!” | Guttural screech |
| Under attack | “Officer down! Requesting backup!” | “They’re blowing our cover!” | High-frequency burst |
| Low resources | “Budget allocation depleted.” | “Vault is dry. We need cash.” | Hollow organic groan |
| Unit created | “Deputy reporting for patrol.” | “Let’s crack some safes.” | Flesh-rupture pop |

## Asset naming

Use these prefixes so audio content remains searchable:

```text
music_ambient_*
music_escalation_*
music_war_*
pk_voice_*
pk_weapon_*
syn_voice_*
syn_weapon_*
nb_voice_*
nb_weapon_*
ui_*
world_*
```

## Implementation target

`res://scripts/audio_director.gd` should receive three values from a mission controller: active combatant count, contested-sector presence, and headquarters damage state. It selects the appropriate music layer and emits event names for UI, voice, weapon, and environmental audio routing.
