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
| M9 | Real-world step rewards (Health Connect / HealthKit) | 4–6 days (Android side built) |
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
- [x] `world/interactables/viewpoint.tscn`: an `Area2D` with a 📷 prompt and an exported `viewpoint_id`
- [x] **Photo mode** scene: viewfinder overlay, a moving subject (configurable path and speed per viewpoint), tap to shoot, shutter flash and sound, Good/Great/Perfect result, with tests for the quality maths
- [x] Placeholder postcards (a coloured card with the trail and viewpoint name)
- [x] **Journal screen:** a passport page per season (stamps) and a postcard gallery with quality borders; tap a postcard to enlarge it

**Done when:** you can photograph viewpoints, results count towards ★2, and the postcards show up in the journal.

---

## M5 — Vertical slice: "Lapland Fell" ⭐
Make one trail feel like the finished game before building more.
- [x] Build Trail 3 *Lapland Fell* from the template: a full-length climb with benches and two checkpoints
- [x] `Parallax2D` background with 4 layers in the ruska autumn palette, plus drifting clouds
- [x] Weather system: `WeatherProfile` applies drain multipliers and visuals (fog overlay first, then rain, snow and wind)
- [x] Reindeer viewpoint subject with a simple walk animation
- [x] `AudioManager`: buses (Master, Music, SFX, Ambience), ambience loop, footsteps by surface, shutter, summit sting
- [x] Game feel: footstep dust particles, a small camera shake on stumble, a smooth day-tint transition, a summit celebration
- [x] Settings screen: volumes, left-handed controls, vibration
- [ ] **Playtest with 3–5 people** on their phones. Write the feedback into `docs/PLAYTEST_NOTES.md` and tune `balance.tres`.

**Done when:** you'd happily show this trail to friends. Don't start M6 until it feels good.

---

## M6 — Season 1 content and meta
- [x] Trail 1 *Forest Lake Loop* with tutorial prompts (walk → rest → jump → photo)
- [x] Trail 2 *Archipelago Rocks* (wind, stepping stones)
- [x] Trail 4 *Fjord Ridge* (rain, mud, ledges)
- [x] Trail 5 *Aurora Summit* (night, ice, aurora window)
- [x] **Gear screen:** buy and equip (2 slots); the effects plug into the stamina and slope systems via modifiers, with tests
- [x] Main menu polish: a season banner and a "Continue" button that resumes the next unfinished trail
- [x] Every string goes through `translations/strings.csv`
- [x] Balance pass: a full season run takes about 30–45 minutes for a new player

**Done when:** Season 1 can be completed from start to finish on the phone without bugs.

---

## M7 — Mobile polish and release
- [ ] Profile on a low-end Android phone: hold 60 fps, keep texture sizes sensible, and keep startup under 5 s
  - [x] Debug-build `PerfProbe` ("PERF" lines in logcat) + startup/synth timings; sounds synthesised on a worker thread
  - [x] Pixel 7 Pro: steady 60 fps, worst frame 16.7 ms, startup to menu ~0.8 s, ~84 MB static memory
  - [ ] Repeat on a low-end phone
- [x] Check the layout at 16:9, 19.5:9, 20:9 and 4:3 (iPad), with notches and safe areas
- [x] App icon (including the Android adaptive icon) and a splash screen
- [x] A simple privacy policy (`docs/PRIVACY.md`, v1 collects no data); host it at a public URL when submitting
- Android release steps moved to **M7.9**, iOS to **M8** (launch plan decided below: Google Play first, free with ads,
  polish the current code-drawn style, no fixed date — quality first).

**Done when:** the remaining profiling item is done (the release itself is M7.9).

---

## M7.5 — Trail depth (exploration, water, route choice)
- [x] **Finds:** `FindData` per trail (flowers, mushrooms, lost items, one rare animal); `Find` pieces in levels;
      collected on contact (animals: stand still nearby to spot them, walk on and they flee); TP for new finds;
      journal shows them; save v3 stores finds per trail (+ migration and test); badges Forager / Wildlife Watcher
- [x] **Water:** `Hydration` system (drains while walking; thirsty = faster tiring, slower rest); `Spring` pieces and
      streams refill it; HUD water gauge; tests
- [x] **Forked paths:** one-way `Boardwalk` ridge routes above slower valley paths (T01, T02, T04, T05; T03 is open fell),
      with a `ForkSign`; falling off a gap lands on the valley path; hidden lookouts with a secret find on every trail
- [x] Place on all Season 1 trails; every trail still completes (bot), times retuned if needed

**Done when:** each trail has a real route choice, 3–4 finds (one hidden) and a spring, and Season 1 still plays through.

---

## Launch plan (Google Play first)
Decided with the user: **Android first** (iOS after launch, M8), **free with ads**, keep and polish the code-drawn
art and synth audio, **no fixed date**. Order: M7.6 → M7.7 → M7.8 → M7.9. Start the Play Console account and the
closed test early: **new personal developer accounts must run a closed test with at least 12 testers for 14 days in a
row before production access**, so the testers' fortnight overlaps with the last polish work.

## M7.6 — Stabilisation
Make what exists solid before adding more. Most items are checks plus fixes.
- [x] **Regression bot in the repo:** move the scratch play-bot into `tools/bot/`; one command plays all five trails
      headless and fails on a fall-through, a stuck hiker, a missed finish or a time over par
- [x] **CI:** a GitHub Actions workflow runs GUT + the content validator (+ the bot) on every push
- [x] **Split the long scripts** (`TrailRecord` out of GameState, hints into HikeTracker, facing into HikerInput; hiker.gd 306)
- [x] **Save safety:** tests for a killed app mid-save, an unreadable save, a save from a *newer* app version
      (must not be wiped), and the clock moved backwards/forwards (daily streak can't be farmed or lost unfairly)
- [ ] **App lifecycle on the phone** (code checked: back on every screen, Daily card back fixed; phone run = `docs/PHONE_CHECKLIST.md`): incoming call, notification shade, app switch, screen lock, long background
      (daylight and timers mustn't jump), audio resumes, Android back on every screen goes somewhere sensible
- [x] **Touch audit** (`ScrollTap`, tests/ui/test_touch_audit.gd): every scroll area scrolls by swiping (Postcards page still catches swipes on its buttons —
      use the gear screen's tap guard), no button too small (≥ 48 dp), no accidental double taps
- [x] **Layout audit:** 4:3 HUD crowding (unchecked since the water/finds pills), notches, 20:9, large system font
- [ ] **Release-build check** (code checked: debug output is debug-only; the signed release run waits for the M7.9 keystore): export a *release* build and play the season: no debug-only output (PerfProbe off),
      no `print` spam, no first-use shader hitches (warm up materials during the splash if needed)
- [ ] **Low-end phone:** a 2–3 GB RAM Android phone (borrowed, or Play's pre-launch report / Firebase Test Lab):
      60 fps target, 30 fps floor, startup < 5 s, no out-of-memory; a 30-minute session for heat and battery
- [ ] **Playtest with 5–10 people** (open since M5): notes in `docs/PLAYTEST_NOTES.md`, then a balance pass
- [ ] Fix everything above that's red; full test suite + bot green

**Done when:** the bot completes every trail in a release build, the phone survives the lifecycle checklist, and
playtesters finish Season 1 without hitting a bug.

## M7.7 — Launch features
Small things players and the store expect. Keep the list short; bigger ideas wait for after launch.
- [x] **New-mechanic hints** (`FirstHints`, once ever, save v5 `profile.hints_seen`): first-time hints for walking back, finds (stand still for animals), water and forks
- [x] **About screen** (from Settings; privacy *link* waits for the hosted URL in M7.9): version number, credits, privacy policy link (required once ads are in),
      "Reset progress" with a confirm step
- [x] **Season 1 finale** (`SeasonFinale` on the results screen): a short ending moment after the fifth summit (journal page or postcard) so the season feels finished
- [x] **Accessibility:** "reduce motion" toggle (UiMotion, screen shake, sway), check colour-only signals (map, gauges)
- [x] **Audio pass** (measured: loops already seamless; ambience levelled to ~-35 dB, soft footsteps raised): smooth out the synth music/ambience loops, balance volumes between sounds
- [ ] *(Should, moved to M7.9: needs Google's plugin — ask first)* In-app review prompt after the third summit (Google Play In-App Review plugin)
- [ ] *(Later, after launch)* Play Games achievements and cloud save, a ghost of your best run, more languages

**Done when:** a new player can learn every mechanic without help and finish the season to a proper ending.

## M7.8 — Ads (free with ads)
Ads must never interrupt a hike. Rewarded ads are opt-in; interstitials are rare.
- [ ] **Decide (user):** AdMob account; target audience 13+ (simplest) or also under-13s (Families policy:
      certified ad SDKs only, child-directed settings)
- [x] **Decided:** no sixth autoload: a static `Ads` class holds the provider (where the ad code lives — `AdService` would be a sixth autoload (ask first), or a plain
      class owned by an existing autoload
- [x] Provider seam with a **mock** (`MockAdProvider`, debug builds only) and a no-ads stub for tests/release; real AdMob plugin still to plug in (M7.9). Was: AdMob through a Godot Android plugin (v2), with a desktop/GUT stub so the editor and tests never load ads
- [~] **Consent** (mock form + About > Ad privacy choices; real UMP with the SDK): Google UMP consent form (EEA/UK) on first launch + "Privacy choices" in Settings
- [x] **Rewarded (opt-in)** (results +50% TP; the daily doubling folded into it, the bonus includes the daily): "Watch an ad: +50% TP" on the results screen; double the daily-trail reward
- [x] **Interstitial (rare):** only between hikes, at most one every 3 hikes, never in the first session or the tutorial trail
- [x] Ad rules (cooldowns, caps, first-session grace) as a pure `AdPolicy` system with tests; numbers in `balance.tres`
- [x] Game works fully offline and with ads failing to load (rewards simply aren't offered)
- [~] Privacy policy drafted in docs/PRIVACY.md (advertising ID, AdMob); AD_ID permission + data safety at release. Was: Privacy policy updated (advertising ID, AdMob), `AD_ID` permission, data-safety answers updated
- [ ] *(Later)* "Remove ads" in-app purchase (Google Play Billing plugin)

**Done when:** test ads show on the phone at the right moments only, consent works, and tests cover the ad rules.

## M7.9 — Google Play launch
- [x] **Production pass** (from genre research): consent deferred until ads matter, postcard pop on new shots,
      captioned store screenshots, feedback mail button (needs SUPPORT_EMAIL), review prompt seam (needs the plugin)
- [x] **Trail 6, Crane Mire** (added before launch to round out Season 1; played 5th, Aurora Summit stays the finale)
- [ ] **Play Console developer account** (user; one-time fee, identity verification can take days — start early)
- [ ] Release keystore: create it, **back it up in two safe places**, never commit it or its passwords
- [x] Gradle build + **AAB** export (preset "Android Release", docs/RELEASE.md; checked with the debug key standing in); target SDK 36 (Play's requirement since Aug 2026); 16 KB page-size support (Godot 4.7 templates)
- [x] Version **1.0.0** (versionCode 1) = Season 1 (project.godot config/version; presets read it)
- [ ] Privacy policy hosted at a public URL (e.g. GitHub Pages)
- [~] Store listing (text drafted in docs/STORE_LISTING.md; images from tools/store_shots, user to approve and upload): name, short description (80 chars), full description, 512 px icon, 1024×500 feature graphic,
      4–8 phone screenshots (taken with a screenshot script), optional trailer
- [~] Content rating questionnaire (mentions ads), target audience, data-safety form, ads declaration (expected answers in docs/STORE_LISTING.md)
- [ ] **Internal testing** track: install from the Play Store on the Pixel, check the pre-launch report
- [ ] **Closed test: ≥ 12 testers for 14 continuous days**; fix what they report; answer the production-access questions
- [ ] **Production** release (staged rollout, e.g. 20% → 100%); watch Android vitals (crashes, ANRs) for the first week

**Done when:** Peak Rush 1.0.0 is live on Google Play.

---

## M8 — Live seasons pipeline (after launch)
- [ ] Turn Appendix A below into `docs/ADDING_CONTENT.md`
- [ ] A "What's new" banner on the main menu (compares `season.release_version` with the last version the player has seen)
- [ ] Version scheme: `1.x` = new trails or fixes within a season, `2.0` = Season 2, and so on
- [ ] A save migration test for every release
- [ ] **Season 2 – Tea Country** (see GAME_DESIGN §7)
- [x] Decide on monetisation: **free with ads** (M7.8); a "Remove ads" purchase can follow (Google Play Billing / StoreKit plugins)
- [ ] **iOS release** (needs a Mac with Xcode, or a cloud Mac build service):
  - [ ] Join the Apple Developer Program
  - [ ] AdMob + consent on iOS (App Tracking Transparency prompt)
  - [ ] Export the Xcode project from Godot, sign it and archive it
  - [ ] App Store Connect: listing, privacy labels, **TestFlight**, then review
- [ ] *(Advanced, optional)* Download new seasons as `.pck` resource packs (`ProjectSettings.load_resource_pack`) without an app update

---

## M9 — Real-world step rewards
Turn the player's real steps into a small TP bonus (GAME_DESIGN §5.10). Started early (before 1.0) at the user's request;
it can ship in 1.0 or a 1.x update. Android comes first because it can be built on Windows; iOS needs a Mac.
- [x] `systems/step_ledger.gd` (`StepLedger`): steps → TP per day, daily cap, 7-day claim window, no steps from before opt-in, with tests (including clock moved backwards and duplicate syncs)
- [x] `balance.tres`: `steps_per_tp` (500), `step_tp_daily_cap` (40), `step_claim_window_days` (7), `step_length_m` (0.75)
- [x] Save v6: top-level `steps` (enabled, opt-in time/date, claimed steps per day, lifetime steps, last sync); migration `_v5_to_v6` + test
- [x] Step bridge without a new autoload: static `Steps` (scenes/steps/, like `Ads`) picks `HealthConnectStepProvider` (plugin singleton), `MockStepProvider` (debug builds) or the no-op `StepProvider` (release desktop, GUT)
- [x] **Android plugin** (Godot Android plugin v2, Kotlin, `native/android/peak_rush_steps`): Health Connect status, `READ_STEPS` request, daily totals; packaged by `addons/peak_rush_steps`; both presets now use the Gradle build with min SDK 26
- [x] Settings: "Real steps give TP" switch (hidden without a step source); switching off disconnects
- [x] Main menu: "Steps today" button, highlighted with "+N TP" while there is TP to claim; a tap claims it
- [x] "Real km walked" stat (on the profile screen, next to the other totals)
- [x] Step badges: Step Outside (10,000 steps), Marathon Legs (42 km), Long Walker (200 km)
- [x] Strings in `translations/strings.csv`
- [ ] Phone test on the Pixel 7 Pro (see the list below)
- [ ] Store paperwork: update the privacy policy (step data stays on the device), the Google Play data-safety form and the **Health Connect permission declaration**
- [x] Polish: claim count-up + new-badge pills, re-read when the app returns, UI tests with a mock phone, rationale text as Android string resources
- [ ] Later, if wanted: step cosmetics, streak protection on 5,000-step days
- [ ] **iOS plugin** (Swift, HealthKit) with the entitlement and `NSHealthShareUsageDescription`; needs a Mac with Xcode, so postpone if there isn't one

Phone test: switch on in Settings (Health Connect asks), go back to the menu (button shows today's steps since switching on),
walk 500+ steps, reopen the menu and claim; deny the permission (switch flips back off); revoke it in Health Connect (the menu
button disappears, no TP); check the game still plays normally throughout.

**Done when:** on the phone, real steps turn into TP up to the daily cap, the game works normally when the permission is denied or revoked, and all tests pass.

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
