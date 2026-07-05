# MoonGoons Take Back: User Manual

## Start the game

1. Install Godot 4.3 or newer.
2. Import `project.godot` in Godot Project Manager.
3. Open the project and press **F6** or the Play button.

The live mode is a single-player Lunar Peacekeepers versus Syndicate RTS skirmish.

## Objective

Win by destroying the **Syndicate Hideout**.

Lose if the **Command Nexus** reaches zero integrity.

## Controls

| Control | Action |
|---|---|
| Left-click | Select a unit |
| Left-drag | Select a group of units |
| Right-click terrain | Move selected units |
| Right-click resource | Send selected Survey Drones to harvest |
| Right-click enemy | Attack that enemy |
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
| `Shift + 1` through `Shift + 5` | Assign control group |
| `1` through `5` | Recall control group |
| `Shift + right-click` | Set production rally points |
| `F1` | Developer console in debug/editor builds |

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

Captures increase Syndicate pressure, so establish defenses before expanding too far.

## Fog and Tactical Scan

The field has visible, explored, and unexplored areas. Units, structures, secured sectors, and Forward Relays provide sight.

Tactical Scan costs 4 Intel, reveals the cursor area for 10 seconds, and has an 18-second cooldown. Use it to check fog, contested sectors, and suspected Siphon activity.

## Syndicate Siphon Raids

Siphon Arrays can hide at active resource nodes. They drain material from the occupied node and steal from the matching stockpile.

The Counter-Intelligence panel warns when one is active but does not show its location. Sweep mining routes with Patrol Deputies or use Tactical Scan. Destroying an Array grants additional Intel.

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

## Current scope

The present prototype does not yet include obstacle-aware pathfinding, camera scrolling, minimap, full playable Syndicate or Nullborn economies, final art/audio, Android controls, campaign-map scenes, or online multiplayer.
