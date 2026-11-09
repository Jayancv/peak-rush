# Peak Rush — Development Plan

Work through the milestones in order. Each one ends with something you can **play and test on your phone**.
Claude Code ticks `[x]` as tasks finish and updates "Current status" in `CLAUDE.md`.

## How to use this with Claude Code
1. Create a project folder. Put `CLAUDE.md` in the root and `PLAN.md` and `GAME_DESIGN.md` in `docs/`.
2. Install the latest stable **Godot 4** and make sure the `godot` command works in your terminal (or tell Claude Code where it is).
3. Open Claude Code in the folder and say:
   > Read CLAUDE.md and docs/PLAN.md, then let's do Milestone 0.
4. Do **one milestone per session** (split big ones in half). After each one, open the game, play it, and tell Claude Code what felt wrong.
5. Commit to git after every milestone so you can always go back.

## Overview
| Milestone | Goal | Rough effort* |
|---|---|---|
| M0 | Project setup and phone test build | 0.5–1 day |
| M1 | Hiker walks and jumps on hilly terrain | 1–2 days |
| M2 | Stamina, daylight, obstacles, HUD | 2 days |
| M3 | Data-driven trails, menus, saving | 2 days |
| M4 | Viewpoints, photo mode, journal | 1–2 days |
| M5 | **Vertical slice**: one polished trail | 2–3 days |
| M6 | Full Season 1 and gear | 4–6 days |
| M7 | Mobile polish and store release | 3–5 days |
| M8 | Live seasons pipeline | ongoing |
*Focused working days. Expect about 2–3× that if you work part-time and are learning Godot along the way.

---

## M0 — Project setup
- [x] `git init`, plus a `.gitignore` covering `.godot/`, `export/`, `*.keystore`, `*.jks`, `*.tmp`, `.DS_Store`
- [x] Create the Godot project "Peak Rush":
  - Compatibility renderer
  - 1280×720, stretch `canvas_items` / `expand`, orientation `sensor_landscape`
  - *Emulate Touch From Mouse* on
  - `untyped_declaration` warning set to *Warn*
- [x] Create the folder structure from `CLAUDE.md`
- [x] Input map: `walk` (D, Right), `jump` (Space, W, Up), `pause` (Esc)
- [x] Autoload stubs: GameState, ContentDB, SaveService, AudioManager, SceneRouter (`SceneRouter.go_to(path)` with a simple fade)
- [x] Install GUT into `addons/gut/` and add one passing smoke test
- [x] Placeholder **main menu** with a Play button that opens an empty trail scene
- [x] `README.md`: Godot version, how to run, how to run the tests
- [x] **Android test build** (the user does these steps with Claude Code's guidance):
  - [x] Install Android Studio (for the SDK) and the JDK version that the Godot "Exporting for Android" docs specify for your Godot version
  - [x] Set the Android SDK and Java paths in Godot's Editor Settings, and install the export templates
  - [x] Create an Android export preset and turn on USB debugging on the phone
  - [x] Use one-click deploy to put the game on the phone
- [ ] (iOS testing needs a Mac with Xcode. Postpone it to M7 if you don't have one.)

**Done when:** the menu opens on desktop and on your Android phone, and the headless tests pass.

---

## M1 — Hiker and terrain
- [x] `world/terrain_strip.gd` (`@tool`): from editable points it builds
  - a `Polygon2D` fill down to the bottom of the screen,
  - a `Line2D` path edge on top,
  - a `StaticBody2D` + `CollisionPolygon2D`,
  - and it has an exported `surface` enum (dirt, rock, mud, ice, snow). The editor updates live when points change.
- [x] `systems/slope.gd`: speed and drain factors from the floor normal, with unit tests
- [x] `actors/hiker/`: a `CharacterBody2D` with a simple state machine (Idle, Walk, Rest, Jump, Fall, Stumble, Exhausted, Photo)
  - Floor snapping on, max floor angle about 50°, slope speed modifier applied
  - Placeholder look: a rounded body with an orange backpack, plus simple squash/stretch
- [x] `Camera2D` follow with look-ahead and limits taken from the trail bounds
- [x] `scenes/ui/touch_controls.tscn`: hold the left half to walk, tap the right half to jump, with faint on-screen hints; a left-handed swap flag
- [x] A test trail with gentle hills, a steep climb and a descent

**Done when:** on the phone you can walk up and down hills and jump at a smooth 60 fps.

---

## M2 — Hiking systems
- [x] `content/balance.tres` (`Balance` resource) holding every number from GAME_DESIGN §5
- [x] `systems/stamina.gd`: drain, regen, exhaustion and recovery threshold, with tests
- [x] `systems/daylight.gd`: timer, day phase (morning, midday, golden, dusk) and tint colour, with tests
- [x] Hook both into the hiker: exhausted state, dusk headlamp (a simple light-cone sprite), speed penalties
- [x] Obstacles as scenes in `world/obstacles/`: root, rock, mud patch, ice patch, gap plus `KillZone`, stepping stones
- [x] Interactables: bench, checkpoint (trail marker), finish (summit cairn)
- [x] Respawn at the last checkpoint after a fall (−15 stamina, short fade)
- [x] **HUD:** stamina bar (pulses when low), sun arc, photo counter, pause button, all inside the safe area
- [x] Pause menu (resume, restart, quit to menu); the Android back button opens it
- [x] Vibration on stumble (`Input.vibrate_handheld`), with a setting to turn it off

**Done when:** a 2–3 minute test trail can be completed, and choosing when to rest feels like a real decision.

---

## M3 — Data-driven trails, game flow and saving
- [x] Resource classes in `data/`:
  - `TrailData` (id, name_key, season_id, scene, length_m, daylight_seconds, par_time, weather, viewpoints[], postcard art, unlock order)
  - `SeasonData` (id, title_key, theme colour, banner, release_version, trails[])
  - `ViewpointData`, `WeatherProfile`, `GearData`, `ContentIndex`
- [x] `ContentDB` autoload: loads `content_index.tres` and offers lookup helpers
- [x] **Content validator** (`ContentDB.validate() -> Array[String]` errors): unique IDs, trail scenes exist, every scene has a Trailhead and a Finish, viewpoint IDs in the scene match the data. It's run by a test, so broken content can never ship.
- [x] `content/_templates/trail_template/` (a minimal valid trail to copy)
- [x] `scenes/trail_runner/`: loads a trail scene, spawns the hiker at the `Trailhead` marker, applies weather and daylight, handles finish and respawn
- [x] `systems/star_rating.gd` and TP calculation, with tests
- [x] **Results screen:** stars animate in, TP counts up, the stamp lands
- [x] `SaveService`: JSON at `user://save.json`, `save_version`, migration chain, corrupt-file fallback (back up the bad file and start fresh), with tests
- [x] `GameState`: unlocked trails, stars, best times, best photo quality, TP, owned and equipped gear, settings
- [x] **Trail select:** a tab per season, trail cards with stars and lock state

**Done when:** you can go menu → choose trail → hike → results, and progress survives closing and reopening the app.

---

## M4 — Viewpoints, photo mode and journal
- [ ] `world/interactables/viewpoint.tscn`: an `Area2D` with a 📷 prompt and an exported `viewpoint_id`
- [ ] **Photo mode** scene: viewfinder overlay, a moving subject (configurable path and speed per viewpoint), tap to shoot, shutter flash and sound, Good/Great/Perfect result, with tests for the quality maths
- [ ] Placeholder postcards (a coloured card with the trail and viewpoint name)
- [ ] **Journal screen:** a passport page per season (stamps) and a postcard gallery with quality borders; tap a postcard to enlarge it

**Done when:** you can photograph viewpoints, results count towards ★2, and the postcards show up in the journal.

---

## M5 — Vertical slice: "Lapland Fell" ⭐
Make one trail feel like the finished game before building more.
- [ ] Build Trail 3 *Lapland Fell* from the template: a full-length climb with benches and two checkpoints
- [ ] `Parallax2D` background with 4 layers in the ruska autumn palette, plus drifting clouds
- [ ] Weather system: `WeatherProfile` applies drain multipliers and visuals (fog overlay first, then rain, snow and wind)
- [ ] Reindeer viewpoint subject with a simple walk animation
- [ ] `AudioManager`: buses (Master, Music, SFX, Ambience), ambience loop, footsteps by surface, shutter, summit sting
- [ ] Game feel: footstep dust particles, a small camera shake on stumble, a smooth day-tint transition, a summit celebration
- [ ] Settings screen: volumes, left-handed controls, vibration
- [ ] **Playtest with 3–5 people** on their phones. Write the feedback into `docs/PLAYTEST_NOTES.md` and tune `balance.tres`.

**Done when:** you'd happily show this trail to friends. Don't start M6 until it feels good.

---

## M6 — Season 1 content and meta
- [ ] Trail 1 *Forest Lake Loop* with tutorial prompts (walk → rest → jump → photo)
- [ ] Trail 2 *Archipelago Rocks* (wind, stepping stones)
- [ ] Trail 4 *Fjord Ridge* (rain, mud, ledges)
- [ ] Trail 5 *Aurora Summit* (night, ice, aurora window)
- [ ] **Gear screen:** buy and equip (2 slots); the effects plug into the stamina and slope systems via modifiers, with tests
- [ ] Main menu polish: a season banner and a "Continue" button that resumes the next unfinished trail
- [ ] Every string goes through `translations/strings.csv`
- [ ] Balance pass: a full season run takes about 30–45 minutes for a new player

**Done when:** Season 1 can be completed from start to finish on the phone without bugs.

---

## M7 — Mobile polish and release
- [ ] Profile on a low-end Android phone: hold 60 fps, keep texture sizes sensible, and keep startup under 5 s
- [ ] Check the layout at 16:9, 19.5:9, 20:9 and 4:3 (iPad), with notches and safe areas
- [ ] App icon (including the Android adaptive icon) and a splash screen
- [ ] **Android release:**
  - [ ] Create a release keystore, **back it up somewhere safe**, and keep it out of git
  - [ ] Turn on Gradle build and export an **AAB**
  - [ ] Set the target SDK to the level Google Play currently requires
  - [ ] Google Play Console: app listing, content rating, data-safety form, **internal testing** track
- [ ] **iOS release** (needs a Mac with Xcode, or a cloud Mac build service):
  - [ ] Join the Apple Developer Program
  - [ ] Export the Xcode project from Godot, sign it and archive it
  - [ ] App Store Connect: listing, privacy labels, **TestFlight**
- [ ] A simple privacy policy page (v1 collects no data)
- [ ] Store screenshots and a short trailer clip
- [ ] Version **1.0.0 = Season 1**

**Done when:** both stores have a build in internal testing or TestFlight, then submit for review.

---

## M8 — Live seasons pipeline (after launch)
- [ ] Turn Appendix A below into `docs/ADDING_CONTENT.md`
- [ ] A "What's new" banner on the main menu (compares `season.release_version` with the last version the player has seen)
- [ ] Version scheme: `1.x` = new trails or fixes within a season, `2.0` = Season 2, and so on
- [ ] A save migration test for every release
- [ ] **Season 2 – Tea Country** (see GAME_DESIGN §7)
- [ ] Decide on monetisation (paid vs free with season in-app purchases). If IAP, use Godot's official Google Play Billing plugin and an iOS StoreKit plugin.
- [ ] *(Advanced, optional)* Download new seasons as `.pck` resource packs (`ProjectSettings.load_resource_pack`) without an app update

---

## Appendix A — Adding content

### Add a new trail
1. Copy `content/_templates/trail_template/` to `content/seasons/<season>/trails/tNN_<name>/`.
2. Fill in `trail.tres`: id, name key, length, `daylight_seconds`, `par_time`, weather profile, viewpoints, postcard art.
3. Build the level in `trail.tscn`: TerrainStrips, obstacles, checkpoints, Viewpoint nodes (with matching `viewpoint_id`), Finish.
4. Add the trail to its `season.tres` → `trails`.
5. Add the strings to `translations/strings.csv`.
6. Run the tests (the content validator must pass), playtest on the phone, and tune `par_time` and `daylight_seconds`.

### Add a new season
1. Create `content/seasons/sNN_<name>/season.tres` (id, title key, theme colour, banner, `release_version`).
2. Add it to `content/content_index.tres`.
3. Add its trails (see above), plus any new gear (`GearData`) or weather profiles.
4. Bump the app version, run all tests, playtest, then release.

## Appendix B — Good prompts for Claude Code
- "Read CLAUDE.md and docs/PLAN.md. Start Milestone 1. Give me a short plan first."
- "The hiker feels too slow uphill. Adjust balance.tres and explain what you changed."
- "Add a new trail called 'Ella Rock' to Season 2 following Appendix A."
- "Run the tests and fix any failures."
- "Explain how the stamina system works. I'm learning Godot."
