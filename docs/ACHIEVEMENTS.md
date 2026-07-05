# Achievement Systems & Progression Tracking

Achievements are tracked through explicit events, not continuous battlefield polling. This protects performance in busy missions and makes unlock rules easy to audit.

## Event policy

Use the global gameplay event dispatcher at meaningful moments:

- `on_mission_complete`
- `on_match_end`
- `on_unit_arrest`
- `on_siphon_tick`

`MoonGoonsAchievementTracker` owns the local progression profile and only evaluates achievement definitions registered for the incoming event.

## Current registry

| Achievement | ID | Trigger | Requirement | Reward |
|---|---|---|---|---|
| Badge of Office | `ach_campaign_act1_complete` | `on_mission_complete` | Complete mission `m_1_02` | Alternate Patrol Deputy cosmetic |
| Cold Case Closed | `ach_campaign_all_evidence` | `on_match_end` | Collect all optional campaign Evidence | +5% Campaign starting Intel capacity |
| Miranda Rights | `ach_pk_arrest_streak` | `on_unit_arrest` | Arrest 30 Syndicate units in one match | Precinct Captain banner |
| Corporate Espionage | `ach_syn_siphon_max` | `on_siphon_tick` | Siphon 5,000 Credits across competitive matches | Syndicate structure emblem |
| Patient Zero | `ach_nb_corruption_map` | `on_match_end` | Win as Nullborn with at least 80% Corrupted Ground coverage | Apex Singularity menu background |

## Profile format

Local profiles are saved at `user://profile_save.json` and follow the structure from `data/achievements.json`.

```json
{
  "profile_id": "local_commander",
  "persistent_progression": {
    "campaign_completed_acts": [],
    "total_credits_siphoned": 1240,
    "unlocked_cosmetics": ["pk_deputy_skin_alt01"],
    "unlocked_achievements": ["ach_campaign_act1_complete"]
  }
}
```

## Platform integration rule

The local tracker is the source for gameplay verification. Steam, console, mobile, or other platform achievement APIs should receive an unlock notification only **after** the local condition has been validated and written to the profile. Platform responses must never be treated as gameplay authority.
