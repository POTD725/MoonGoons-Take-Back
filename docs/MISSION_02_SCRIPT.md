# Mission 1.02: The Breach

**Act:** I, The Broken Peace  
**Location:** Sub-Sector 02-B, Abandoned Mining Facility  
**Playable faction:** Lunar Peacekeepers

Mission data lives in `data/campaign_missions.json`; `MoonGoonsMissionController` exposes the required objective, dialogue, spawn, tutorial, resource, and completion events.

## Scene 1: Establish the Grid

The player starts with one Command Nexus and three Patrol Deputies at the mining-facility gate. The mountain pass beyond the facility remains hidden by fog of war.

**Commander Vance:** “Secure a staging perimeter before we follow the scavengers into the mining lines.”

**Deputy Reed:** “Deploying resource processing. The sensor grids are dead, so we are blind out here.”

**Objective:** Construct one Tactical Armory and one Drone Bay.

**Tutorial:** Select the Command Nexus, press `Q` to queue a worker drone, and send workers to Helium-3 vents for Credits.

## Scene 2: Valley Choke Point

After the Armory and Drone Bay exist, the northern valley is revealed and two Syndicate Smuggler Bruisers are prepared behind a barricade. Entering the choke point presents the Riot Vanguard tutorial.

**Syndicate Bruiser:** “Keep those mining lasers locked on the choke line!”

**Tutorial:** Put Riot Vanguards at the front and press `Q` to activate Shield Wall.

## Scene 3: Mining Intel

After the mining yard is clear, moving within range of the terminal locks input for three seconds and displays a download progress sequence.

**Objective:** Eliminate the lookouts and download the shipping logs.

**Deputy Reed:** “The Syndicate has been transporting volatile ancient biological material from the deep crust.”

**Commander Vance:** “The Nullborn files were purged decades ago. Sector 02-B is under emergency quarantine.”

The mission awards **50 Evidence**, then dispatches `on_mission_complete` for `m_1_02`. That event feeds the campaign progression and Badge of Office achievement path.

## Implementation events

```text
on_mission_started
on_buildings_changed {
  built_building_ids: ["pk_tactical_armory", "pk_drone_bay"]
}
on_enter_area { area_id: "northern_choke" }
on_enter_area {
  area_id: "mining_terminal",
  hostiles_cleared_in_area: "mining_yard"
}
```

The current prototype does not yet contain this mining-facility map, building placement, or terminal sequence. The authored mission state is committed and can be attached to the future Mission 1.02 scene.
