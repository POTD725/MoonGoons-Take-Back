# Local Storage & Save Game Architecture

MoonGoons stores player progression and mission snapshots inside Godot’s per-user sandbox. The active implementation is `scripts/save_system.gd`.

## Storage locations

The save manager writes to:

```text
user://saves/profile_save.json
user://saves/profile_save.json.bak
user://saves/slot_0.mgcs through slot_9.mgcs
user://saves/slot_0.mgcs.bak through slot_9.mgcs.bak
```

Godot maps `user://` to the appropriate application-data location on Windows, macOS, Linux, Android, and other export targets. The game should never assume it can write to the repository directory.

## Profile saves

Profiles are JSON envelopes containing the profile payload and a SHA-256 checksum. A profile includes campaign progress, cosmetic unlocks, local settings, and persistent achievement data.

```json
{
  "format": "MoonGoonsProfileEnvelope",
  "payload": {
    "save_version": "1.0.0",
    "last_updated_epoch": 0,
    "player_profile": {
      "account_name": "Lunar_Commander_01",
      "campaign_progress": {
        "highest_completed_act": 1,
        "highest_completed_mission": "m_1_02"
      },
      "user_preferences": {
        "interface_language": "en",
        "grid_controls_enabled": true,
        "audio_master_volume": 0.85
      }
    }
  },
  "checksum_sha256": "..."
}
```

## Mission snapshot saves

Mission snapshots use a compact binary container with a JSON simulation payload compressed with DEFLATE.

```text
MGCS magic header              4 bytes
format version                 uint32
engine build ID                uint32
simulation tick                uint64
compression enabled            uint8
raw payload size               uint32
stored payload size            uint32
compressed payload             byte[]
SHA-256 payload checksum       32 bytes
```

The snapshot payload is expected to contain authoritative data only: fixed-point unit state, combat state, ability state, resource accounts, objective state, seeded RNG state, and mission state. Camera, VFX, audio playback, tooltip, and menu state are excluded.

## Integrity and recovery

Before overwriting a profile or mission slot, the existing file is copied to a `.bak` file. On load, the manager validates header, version, payload length, decompression, and SHA-256 checksum. If the primary file fails, it attempts the backup automatically.

The checksum protects against accidental corruption. It does **not** encrypt files or stop deliberate player modification. Secure cloud saves, platform cryptography, and server-authoritative ranked progression require a separate security design.

## Save compatibility

- Increment `SNAPSHOT_FORMAT_VERSION` only when binary structure changes.
- Store an engine build ID with every snapshot.
- Add migration code before changing a profile or snapshot field that existing players depend on.
- Never deserialize unvalidated data directly into active authoritative simulation state.
