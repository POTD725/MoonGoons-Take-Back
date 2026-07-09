# MoonGoons Take Back 🌙

**MoonGoons Take Back** is a Godot 4 real-time strategy prototype set in the MoonGoons universe. Build a lunar precinct economy, reclaim territory, establish Forward Relays, scout unknown sectors, counter Syndicate extraction, and follow the Peacekeeper story campaign chapter by chapter before the Nullborn crisis consumes the Moon.

## Playable link

The browser-playable test build is published through GitHub Pages:

**https://potd725.github.io/MoonGoons-Take-Back/**

If the page is not live yet, open **Actions → Browser Playable Build → Run workflow**. The workflow exports the Godot web build and deploys it to GitHub Pages. See [`docs/LATEST_PLAY_LINK.md`](docs/LATEST_PLAY_LINK.md), [`docs/LINKS.md`](docs/LINKS.md), [`docs/BROWSER_PLAY_LINK.md`](docs/BROWSER_PLAY_LINK.md), [`docs/PLAYABLE_LINK_READY.md`](docs/PLAYABLE_LINK_READY.md), [`docs/QUICK_LINKS.md`](docs/QUICK_LINKS.md), [`docs/PLAY_NOW.md`](docs/PLAY_NOW.md), [`docs/WEB_PLAYABLE_LINK.md`](docs/WEB_PLAYABLE_LINK.md), [`docs/PLAYABLE_STATUS.md`](docs/PLAYABLE_STATUS.md), or [`docs/DEPLOYMENT_URLS.md`](docs/DEPLOYMENT_URLS.md) for deployment references.

## Playable RTS prototype: Phase Nine + Android testbed

`scenes/Main.tscn` launches a touch-ready Android/browser testbed shell that extends the Phase Nine Lunar Peacekeepers versus Syndicate RTS story-campaign build.

- Survey Drones harvest Credits and Lunar Alloy, returning cargo to the Command Nexus.
- Communications Relays expand Command Capacity; Tactical Armories unlock Riot Vanguards.
- Use control groups, production rally points, attack-move, hold position, Riot Vanguard Shield Wall, and queued route commands on desktop.
- Use the Android/browser touch command deck for tap selection, drag selection, move, attack, gather, Shield Wall, Tactical Scan, Story Dispatch, and cancel.
- Capture Aurora Exchange, Gravity Foundry, and Eclipse Signal Tower.
- Build a completed Relay in a secured sector to create a Forward Relay, doubling sector income and extending vision.
- Explore through unit and structure vision. Unknown terrain is hidden by lunar fog.
- Spend Intel on Tactical Scan to expose fog-covered threats.
- Respond to hidden Siphon Raids before their extraction arrays drain resources and fund the Syndicate War Chest.
- Counter Syndicate doctrines: fast Shades, armored Bruisers, and accelerated relay-network raids.
- Press `C` or tap **STORY** to open **Story Dispatch**. The next chapter follows the campaign sequence automatically; choose only Easy, Medium, or Hard opponent difficulty before beginning.

The active build is an early RTS and campaign slice, not a complete commercial RTS. It uses code-drawn gameplay visuals plus checked-in Android launcher SVGs and a custom web shell, so it does not require external textures or fonts to run.

## Run it on desktop

1. Install **Godot 4.3 or newer**.
2. Clone or download this repository.
3. Import `project.godot` with Godot Project Manager.
4. Open the project and press **F6** or the Play button.

For headless verification:

```bash
chmod +x compile_and_test.sh
./compile_and_test.sh
```

You can also manually start the GitHub Actions workflow from **Actions → MoonGoons Godot Verification → Run workflow**.

## Build the browser playable version

The web export preset is named **Web Playable** and writes this build:

```text
builds/web/index.html
```

### GitHub Pages build

1. Open **Actions** in this repository.
2. Run **Browser Playable Build**.
3. Open **https://potd725.github.io/MoonGoons-Take-Back/** after the deployment completes.

### Local Windows web build

```powershell
$env:GODOT_BIN="C:\Godot\godot.exe"
.\tools\build_web_playable.ps1
python -m http.server 8000 --directory .\builds\web
```

Then open:

```text
http://localhost:8000
```

### Local Linux/macOS web build

```bash
chmod +x tools/build_web_playable.sh
GODOT_BIN=/path/to/godot ./tools/build_web_playable.sh
python -m http.server 8000 --directory builds/web
```

## Build the Android test APK

The Android export preset is named **Android Test APK** and writes this debug build:

```text
builds/android/MoonGoonsTakeBack-debug.apk
```

### GitHub Actions build

1. Open **Actions** in this repository.
2. Run **Android APK Test Build**.
3. Download the artifact named **MoonGoons-Take-Back-Android-Test-APK**.
4. Install the APK on an Android phone or tablet with sideloading enabled.

### Local Windows build

```powershell
$env:GODOT_BIN="C:\Godot\godot.exe"
.\tools\build_android_test_apk.ps1
```

### Local Linux/macOS build

```bash
chmod +x tools/build_android_test_apk.sh
GODOT_BIN=/path/to/godot ./tools/build_android_test_apk.sh
```

See [`docs/ANDROID_TEST_BUILD.md`](docs/ANDROID_TEST_BUILD.md) for Android prerequisites, phone controls, and test limits.

## Core desktop controls

| Control | Action |
|---|---|
| Left-click / left-drag | Select one unit / select a group |
| Right-click | Immediate move, harvest, or attack order |
| `Ctrl + right-click` | Queue movement waypoint |
| `Ctrl + Shift + right-click` | Queue attack-move waypoint |
| `Q` / `W` | Queue Survey Drone / Patrol Deputy |
| `E` / `R` / `T` | Build Relay / Armory / Security Turret |
| `F` | Queue Riot Vanguard after Armory completion |
| `A` / `H` | Attack-move / hold position |
| `S` | Riot Vanguard Shield Wall |
| `X` | Tactical Scan at cursor |
| `G` / `B` | Gather nearest resource / cancel build placement |
| `M` | Toggle terrain labels and outlines |
| `Shift + 1–5` / `1–5` | Assign / recall control groups |
| `Shift + right-click` | Set production rally point |
| Tactical-map click | Move selected units or workers |
| Tactical-map Shift-click | Attack-move selected combat units |
| `C` | Story Dispatch and opponent difficulty |
| `F1` | Developer console in debug/editor builds |

## Android/browser touch controls

| Touch control | Action |
|---|---|
| Tap a unit | Select one unit |
| Drag across battlefield | Select a squad |
| Tap battlefield with units selected | Move selected units |
| ALL | Select all playable units |
| GATHER | Send selected Survey Drones to the nearest resource |
| MOVE | Arm tap-to-move |
| ATTACK | Arm attack-move or target attack |
| SHIELD | Activate selected Riot Vanguard Shield Wall |
| SCAN | Arm Tactical Scan placement |
| STORY | Open or close Story Dispatch |
| CANCEL | Clear touch order, attack mode, build mode, and Story Dispatch |

## Story campaign

The current playable campaign route is **Lunar Peacekeepers**. The first five Act I chapters, `1.01` through `1.05`, are required story dispatches that advance in order. A victory records local progress, applies its rewards once, and makes the following chapter the next required operation.

No campaign chapter picker is used. The player-facing campaign choice is opponent difficulty:

- **Easy:** slower, weaker, less-funded Syndicate pressure.
- **Medium:** intended story balance.
- **Hard:** faster, stronger, better-funded Syndicate pressure.

Syndicate and Nullborn story routes are data placeholders until those factions are genuinely playable. They are not exposed as selectable campaigns yet.

See [`docs/PHASE_NINE_CAMPAIGN.md`](docs/PHASE_NINE_CAMPAIGN.md) for story-dispatch and profile details.

## Current foundations

- Tier 1–3 unit catalogs, building trees, economy, damage, VFX, achievements, and localization data.
- A 20-mission campaign catalog, plus a persistent Act I story-dispatch bridge for missions `1.01` through `1.05`.
- Fixed-point helpers, seeded RNG, lockstep buffering, state hashing, local saves, Resource Bank, combat/arrest resolution, and ability cooldowns.
- GitHub Actions import, smoke-test, browser playable deployment, and Android debug APK automation with manual workflow triggers.
- Android/browser touch command deck, checked-in launcher icon SVGs, custom web shell, export presets, local build helpers, and smoke tests.
- A playable RTS with resources, capacity, construction, production, territory capture, Forward Relay bonuses, fog of war, Tactical Scan, Siphon Raids, terrain steering, tactical-map orders, queued routes, Syndicate doctrine pressure, and fixed-route Act I progression.

## Three-faction destination

- **Lunar Peacekeepers:** combined arms, defensive grids, territory reclamation, visibility infrastructure, and tactical defensive abilities.
- **The Syndicate:** mobility, stealth, sensor disruption, air-drop raids, Credit Siphons, War Chest doctrine escalation, counter-intelligence, and sabotage.
- **The Nullborn:** Corrupted Ground, Biomass Vents, hidden growth, swarm pressure, and territorial attrition.

The current playable scenario is Peacekeepers versus a live Syndicate director. Player-selectable Syndicate and Nullborn economies, full navmesh pathfinding, camera scrolling, zoomable minimap, dedicated campaign maps, scripted mission objectives, final production art/audio, full native mobile UX polish, release signing, and online multiplayer remain future work.

## Key project files

```text
scenes/Main.tscn                                      Current Android/browser testbed RTS scene
scripts/moongoons_rts_android_testbed.gd             Touch controls and code-drawn Android/browser visual pass
scripts/moongoons_rts_phase_nine_campaign.gd          Fixed story route and difficulty layer
data/rts_phase_nine_campaign.json                     Route, story chapter, and difficulty rules
scripts/moongoons_rts_phase_eight_syndicate.gd         Syndicate War Chest and doctrine director
data/rts_phase_eight_syndicate.json                    Syndicate doctrine rules
assets/android/                                       Android launcher icon SVG artwork
web/shell.html                                        Custom browser playable shell
docs/LATEST_PLAY_LINK.md                             Latest play link
docs/LINKS.md                                        Simplest playable/deploy links
docs/BROWSER_PLAY_LINK.md                            Browser play link
docs/PLAYABLE_LINK_READY.md                          Playable link ready note
docs/QUICK_LINKS.md                                  Shortest playable/deploy links
docs/PLAY_NOW.md                                     Fast playable link
docs/WEB_PLAYABLE_LINK.md                             Browser playable link and deployment guide
docs/PLAYABLE_STATUS.md                               Current browser deployment status
docs/DEPLOYMENT_URLS.md                               Deployment URL references
docs/ANDROID_TEST_BUILD.md                            Android APK build and phone-testing guide
docs/USER_MANUAL.md                                   Full player and debug-console guide
docs/PHASE_NINE_CAMPAIGN.md                            Story campaign and difficulty guide
docs/PHASE_EIGHT_SYNDICATE.md                          Syndicate counterplay guide
docs/DEVELOPMENT_ROADMAP.md                            Current development roadmap
tests/rts_phase_nine_campaign_smoke_test.gd            Phase Nine story-campaign smoke test
tests/rts_android_testbed_smoke_test.gd                Android testbed smoke test
tests/rts_web_playable_smoke_test.gd                   Browser playable smoke test
compile_and_test.sh                                    Fourteen-step local verification pipeline
export_presets.cfg                                    Android Test APK and Web Playable export presets
.github/workflows/godot-ci.yml                         Godot import and smoke-test verification
.github/workflows/android-apk.yml                      Android debug APK artifact build
.github/workflows/pages-playable.yml                   Browser playable GitHub Pages deployment
```

## Licensing

The root `LICENSE` covers original repository code and documentation. Read `docs/LICENSING.md` and `docs/CREDITS.md` before adding art, audio, fonts, packages, or other third-party materials.

## Design north star

Every reclaimed lunar district should change the war. MoonGoons Take Back is about restoring order, exploiting chaos, or feeding corruption one hard-won sector at a time.
