# Campaign Script: Missions 1.03–1.05

The canonical machine-readable definitions live in `data/campaign_missions_act_2_to_4.json`. This document is the designer-facing companion for the opening of Act II.

## Mission 1.03: Smuggler’s Run

**Route:** Act II Choice A  
**Setting:** Black-Market Spaceport / Orbital Docks  
**Objective:** Tag three Syndicate cargo freighters before their launch windows close.

The spaceport introduces **Low Gravity**: units gain 25% movement speed and +2 weapon range, while armor is reduced by 20%. Tagging the second freighter triggers a hostile Widowmaker Sky-Skiff ambush from the landing pad.

**Commander Vance:** “If those cargo hulls leave the dockyard, we lose the trace on the biological anomalies.”

**Tutorial:** Use K-9 Proximity Sensors to keep the Sky-Skiff visible and vulnerable to targeted fire.

## Mission 1.04: Cold Storage

**Route:** Act II Choice B  
**Setting:** Frozen Lunar Valley / Sealed Core Lab  
**Objective:** Secure four high-value Evidence canisters from the vault chambers.

Entering the central Evidence Vault spawns three stealth Shadow-Stalkers behind the support line and ruptures a Corrosive Gas Vent. The gas hazard removes armor protection within its danger zone.

**Deputy Reed:** “Perimeter breached. The security logs were wiped from the inside.”

**Tutorial:** Use Riot Vanguard Flashbangs to reveal infiltrators and preserve the support line.

## Mission 1.05: The Quarantine Line

**Setting:** Ruined Research Outpost / Perimeter Junction Block  
**Objective:** Hold the sector defense gate for ten minutes.

The mission introduces the Nullborn threat. At the five-minute point, 40% of the center valley becomes Corrupted Ground, slowing units by 15%. The Nullborn AI shifts into `FULL_ASSAULT` and releases repeated Corrupted Scavenger waves against the perimeter.

**Commander Vance:** “The Nullborn protocols are verified active. Pull all security squads behind the gate.”

## Runtime events

```text
m_1_03: on_counter_changed { counter_id: "freighters_tagged", value: 2 or 3 }
m_1_04: on_enter_area { area_id: "central_evidence_vault" }
m_1_05: on_timer_remaining { timer_id: "gate_defense", seconds: 300 }
```

The main prototype does not yet include these maps, Sky-Skiff flight behavior, Corrosive Gas collision, or Nullborn combat spawns. The campaign controller already resolves their mission triggers and emits the requested scene effects for future map scenes.
