# MoonGoons Take Back: User Manual

## Start the game

1. Install Godot 4.3 or newer.
2. Import `project.godot` in Godot Project Manager.
3. Open the project and press **F6** or the Play button.

The current build is a single-player Lunar Peacekeepers story campaign versus the Syndicate.

## Objective

Win a dispatch by destroying the **Syndicate Hideout**.

Lose if the **Command Nexus** reaches zero integrity.

A campaign victory advances the story to its next required chapter automatically.

## Controls

| Control | Action |
|---|---|
| Left-click | Select a unit |
| Left-drag | Select a group of units |
| Right-click terrain | Issue immediate movement order |
| Right-click resource | Send selected Survey Drones to harvest |
| Right-click enemy | Attack that enemy |
| `Ctrl + right-click` | Queue a movement waypoint |
| `Ctrl + Shift + right-click` | Queue an attack-move waypoint |
| `Q` | Queue Survey Drone |
| `W` | Queue Patrol Deputy |
| `E` | Build Communications Relay |
| `R` | Build Tactical Armory |
| `F` | Queue Riot Vanguard after Armory completion |
| `T` | Build Security Turret |
| `A`, then right-click | Attack-move |
| `H` | Hold selected combat units in place |
| `S` | Riot Vanguard Shield Wall |
| `X` | Tactical Scan at the cursor |
| `G` | Gather from resource nearest the cursor |
| `B` | Cancel building placement |
| `M` | Toggle terrain labels and outlines |
| `C` | Open Story Dispatch and choose opponent difficulty |
| `Shift + 1` through `Shift + 5` | Assign control group |
| `1` through `5` | Recall control group |
| `Shift + right-click` | Set production rally points |
| Tactical-map left-click | Move selected units or workers |
| Tactical-map Shift-click | Attack-move selected combat units |
| `F1` | Developer console in debug/editor builds |

## Story campaign and difficulty

The current campaign follows the **Lunar Peacekeepers** in a fixed story order. Operations are not manually selectable and cannot be skipped.

Press `C` to open **Story Dispatch**. It shows the mandatory next chapter, briefing, and objective. The only campaign match choice is opponent difficulty:

| Difficulty | Enemy behavior |
|---|---|
| **Easy** | Slower raids, weaker Syndicate units, reduced War Chest funding |
| **Medium** | Intended story balance |
| **Hard** | Faster raids, stronger Syndicate units, increased War Chest funding |

The chosen setting persists locally and applies when the current dispatch begins. The Syndicate and Nullborn routes are reserved until those factions are actually playable; they are not selectable placeholder campaigns.

## Economy

**Credits** pay for core operations. Yellow nodes provide Credits.

**Lunar Alloy** is used for advanced construction and Riot Vanguards. Purple nodes provide Alloy.

**Intel** is earned from neutralizing Syndicate forces. It pays for Tactical Scan.

**Command Capacity** limits field units. Build Communications Relays to increase it by 10 each.

Survey Drones collect resources and return their cargo to the Command Nexus. Protect them.

## Units

### Survey Drone

Harvests resources and constructs buildings. Low combat durability.

### Patrol Deputy

Fast ranged infantry. Useful for scouting, sector capture, worker escort, and Siphon response.

### Riot Vanguard

Heavy frontline unit unlocked by the Tactical Armory. Press `S` to use Shield Wall, which holds the Vanguard in place and provides a temporary barrier.

## Structures

### Command Nexus

Main base. Produces Survey Drones and Patrol Deputies. Its destruction ends the match.

### Communications Relay

Adds Command Capacity. A completed Relay inside a secured sector creates a Forward Relay, doubles sector income, and improves vision.

### Tactical Armory

Unlocks Riot Vanguard production.

### Security Turret

Automatically attacks nearby Syndicate units. Use them at mining routes and Forward Relay sectors.

## First build order

1. Send Drones to both Credits and Lunar Alloy.
2. Queue another Survey Drone.
3. Build a Communications Relay.
4. Train Patrol Deputies.
5. Build a Tactical Armory.
6. Secure Aurora Exchange or Gravity Foundry.
7. Build a Relay inside the secured sector.
8. Produce Riot Vanguards and protect your resource line.

## Territory control

Combat units capture a sector while standing inside its glowing ring without Syndicate units contesting it.

- **Aurora Exchange** supplies Credits.
- **Gravity Foundry** supplies Lunar Alloy.
- **Eclipse Signal Tower** supplies Credits near the Hideout.

Captures increase Syndicate pressure, but they also reduce its War Chest. Establish defenses before expanding too far.

## Terrain, tactical map, and routes

Units steer around lunar obstacles. Impact Ridges, Collapsed Conduits, and Shardfields also block building placement. Use the blue Transit Lane for faster movement and avoid the brown-orange Glass Regolith when time matters.

The sidebar tactical map gives quick battlefield orders. A yellow marker records its latest destination.

Route queues support deliberate navigation through choke points:

- Select units.
- Use `Ctrl + right-click` for the first or next movement waypoint.
- Use `Ctrl + Shift + right-click` to queue an attack-move waypoint.
- Each route holds up to six waypoints and draws its planned path in the field.
- Normal right-click orders replace that unit’s queued route.

## Fog and Tactical Scan

The field has visible, explored, and unexplored areas. Units, structures, secured sectors, and Forward Relays provide sight.

Tactical Scan costs 4 Intel, reveals the cursor area for 10 seconds, and has an 18-second cooldown. Use it to check fog, contested sectors, and suspected Siphon activity.

## Syndicate War Chest and Siphon Raids

Siphon Arrays can hide at active resource nodes. They drain material from the occupied node and steal from the matching stockpile.

The Counter-Intelligence panel warns when one is active but does not show its location. Sweep mining routes with Patrol Deputies or use Tactical Scan. Destroying an Array grants additional Intel and cuts into the Syndicate War Chest.

As the War Chest rises, the Syndicate unlocks faster Shades, armored Bruisers, and accelerated attack waves. Secure sectors and stop Siphons before its doctrines harden into a larger problem.

## Developer console: debug/editor only

Press `F1`, type a command, and press Enter. Press `F1`, `Esc`, or type `close` to dismiss it. The console is disabled in release exports by default.

| Command | Effect |
|---|---|
| `help` | Show console commands |
| `status` | Report resources and field state |
| `credits 500` | Change Credits |
| `alloy 250` | Change Lunar Alloy |
| `intel 20` | Change Intel |
| `capacity 20` | Change Command Capacity |
| `spawn worker 3` | Spawn Survey Drones |
| `spawn deputy 6` | Spawn Patrol Deputies |
| `spawn vanguard 3` | Spawn Riot Vanguards |
| `wave` | Force a Syndicate wave |
| `siphon` | Force a Siphon Raid |
| `capture all` | Secure all opening sectors |
| `reveal 60` | Reveal the map for 60 seconds |
| `heal` | Restore friendly health |
| `clear` | Remove current Syndicate units |
| `win` | Destroy the Hideout |
| `lose` | Destroy the Nexus |
| `restart` | Start a fresh match |
| `close` | Close the console |

## Troubleshooting

For a Godot error, copy the first line that begins with `Parse Error:` and includes a `res://` path and line number.

For a failed GitHub Actions run, open the newest `verify-godot-project` job and copy the final 25 to 40 log lines. Use the newest run, not old red entries.

When construction fails, select at least one Survey Drone, verify your resources, and place the building clear of resource nodes and other structures.

To reset campaign progress during development, close the game and delete `user://moongoons_campaign_profile.json`. This returns the Peacekeeper story to Operation 1.01 and difficulty to Medium.

## Current scope

The present prototype does not yet include full navmesh pathfinding, camera scrolling, zoomable minimap, full playable Syndicate or Nullborn economies, dedicated campaign maps, scripted secondary objectives, final art/audio, Android controls, or online multiplayer.
