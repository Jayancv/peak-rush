# Peak Rush — Claude Code project guide

## What this project is
A 2D side-scrolling **hiking game** for **Android and iOS**, built with **Godot 4**.
The player hikes trails from trailhead to summit, paces their **stamina** against the **daylight**,
jumps roots and rocks, and stops at scenic **viewpoints** to take photos that fill a **travel journal**.
New trails ship as **Seasons** (e.g. Season 1: Nordic Trails) through app updates.

- Design: `docs/GAME_DESIGN.md` (source of truth for rules and numbers)
- Roadmap: `docs/PLAN.md` (milestones with checkboxes; tick them as tasks are finished)

Work **one milestone at a time**. Before starting, read that milestone in `docs/PLAN.md`,
give the user a short plan, then implement.

## Tech stack
- **Godot 4.x, latest stable** (4.3 or newer is required: we use `Parallax2D` and `--import`). Record the exact version in `README.md`.
- **GDScript**, statically typed.
- Renderer: **Compatibility** (best support on older Android phones, and it allows a web export for quick tests).
- Orientation: **landscape** (`sensor_landscape`). Base viewport **1280×720**, stretch mode `canvas_items`, aspect `expand`.
- Tests: **GUT** addon in `addons/gut/`, tests in `res://tests/`.

## Commands
```bash
# Import assets / rebuild the .godot cache without opening the editor
godot --headless --path . --import

# Run the game
godot --path .

# Run all unit tests
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```
If `godot` is not on PATH, ask the user for the path to their Godot executable rather than guessing.
After running, scan the output for `SCRIPT ERROR`, `Parse Error` and `Failed to load`. A run is only green if none appear.

## Folder structure
```
res://
  autoload/          game_state.gd, content_db.gd, save_service.gd, audio_manager.gd, scene_router.gd
  actors/hiker/      hiker.tscn, hiker.gd, states/
  systems/           stamina.gd, daylight.gd, star_rating.gd, weather_effects.gd, slope.gd   (pure logic, no nodes)
  world/             terrain_strip.gd (@tool), obstacles/, interactables/ (viewpoint, bench, checkpoint, finish)
  data/              Resource classes: trail_data.gd, season_data.gd, viewpoint_data.gd, weather_profile.gd, gear_data.gd, content_index.gd, balance.gd
  content/
    content_index.tres
    balance.tres
    _templates/trail_template/
    seasons/s01_nordic/season.tres
    seasons/s01_nordic/trails/t01_forest_lake/{trail.tres, trail.tscn, art/}
  scenes/            main_menu/, trail_select/, trail_runner/, results/, journal/, gear/, settings/, ui/
  shared_art/  audio/  fonts/  translations/
  tests/
docs/                GAME_DESIGN.md, PLAN.md
```

## Architecture rules (important)
1. **Content is data.** A trail is `trail.tscn` (the level) plus `trail.tres` (a `TrailData` resource). Game code never hard-codes a trail or season ID. Adding a new season must not require code changes outside `content/` (apart from the version bump).
2. **Content is listed explicitly.** `ContentDB` loads `content/content_index.tres`, which lists every `SeasonData`, and each season lists its trails. Do **not** scan folders with `DirAccess` at runtime: exported builds remap and convert resources (`.remap` files, binary `.res`), so folder scanning breaks on phones.
3. **Rules live in `systems/`** as small `RefCounted` classes with no node dependencies, so they can be unit-tested. Nodes call into them. Every system has tests.
4. **All tuning numbers live in `content/balance.tres`** (a `Balance` resource). Don't put magic numbers in scripts.
5. **Signals go up, calls go down.** The hiker emits signals (`stamina_changed`, `exhausted`, `stumbled`, `fell`, `reached_finish`) and the HUD listens. Don't use `get_node("../..")` across scenes. Use `@export` references, groups or signals instead.
6. **Autoloads are limited to** GameState, ContentDB, SaveService, AudioManager and SceneRouter. Ask the user before adding another one.
7. **Input goes through actions only:** `walk`, `walk_back`, `jump`, `pause`. The `TouchControls` scene turns touches into `Input.action_press/release`, and gameplay code never reads raw touch events. Keyboard mapping for desktop testing: D/Right = walk, A/Left = walk back, Space/W/Up = jump, Esc = pause. Turn on *Emulate Touch From Mouse*.
8. **Mobile requirements:**
   - Keep UI inside the safe area (`DisplayServer.get_display_safe_area()`).
   - Save on `NOTIFICATION_APPLICATION_PAUSED` and `NOTIFICATION_WM_CLOSE_REQUEST`.
   - Map the Android back button (`NOTIFICATION_WM_GO_BACK_REQUEST`) to pause/back.
   - Target 60 fps on a mid-range phone. Prefer `CPUParticles2D` and avoid allocating memory every frame in `_process`/`_physics_process`.
9. **Saves are sacred.** Saves go to `user://save.json` with a `save_version` field. `SaveService` migrates old versions forward, and every format change gets a migration plus a test. Players keep their progress across all seasons.
10. **Wrap every player-facing string in `tr("KEY")`.** Keys live in `translations/strings.csv` (English only for now).

## Code style
- Files, functions and variables use `snake_case`. Classes and node names use `PascalCase`. Constants use `UPPER_CASE`.
- Add `class_name` to every Resource and system class. Use typed variables, parameters and returns.
- Keep scripts under about 300 lines; split them when they grow.
- Comments explain *why*, not *what*.

## Working rules for Claude Code
- **You can't see the game running.** After each task, run the tests, then tell the user exactly what to try in the editor or on the phone ("walk up the first hill and hold still; the stamina bar should refill").
- Use **placeholder art** made from flat `Polygon2D`/`ColorRect` shapes in the palette from `GAME_DESIGN.md`. Don't download assets unless the user provides them.
- Keep hand-written `.tscn`/`.tres` files simple and valid. You can leave out `uid=` values and Godot will add them. Ask the user to open new scenes in the editor once so Godot re-saves them.
- Never hand-edit `.godot/` or `*.import` files. Do commit `*.uid` files (Godot 4.4+).
- Never commit keystores, passwords, `.godot/` or build output.
- Commit after each finished task if the user agrees, with messages like `M2: stamina system + tests`.
- At the end of each session, update **Current status** below and tick the boxes in `docs/PLAN.md`.

## Current status
- Milestone: **M7.5 (trail depth) + polish (sounds, trail map, finds page, daily trail) built, 375 tests green; M7.6 automated part done (phone checklist, low-end phone, playtest open); M7.7 done**. M7 non-release part done. Release steps
  (keystore, AAB, stores, iOS, screenshots, 1.0.0) deliberately not started; low-end phone profiling still open.
  M5/M6 full-season phone playtest still open. Launch plan in PLAN.md: M7.6 stabilisation -> M7.7 launch features -> M7.8 ads -> M7.9 Google Play (Android first, free with ads, iOS after launch in M8).
- Godot 4.7.2-stable (not on PATH; ask the user for the executable path if unknown); GUT 9.7.1.
- Notes: Autoloads are stubs except SceneRouter (fade + `go_to`, scene path consts `MAIN_MENU`/`TRAIL_RUNNER`).
  `scenes/ui/safe_area_margin.gd` (`SafeAreaMargin`) wraps screen UI. Global theme: `shared_art/ui_theme.tres`.
  `quit_on_go_back=false`: each screen handles `NOTIFICATION_WM_GO_BACK_REQUEST` itself.
  Trail runner's Esc/back returns to the menu until the M2 pause menu exists.
  M1: `Balance` resource started early (movement/camera/feel numbers only; M2 adds stamina etc.), loaded as `ContentDB.balance`.
  TerrainStrip extends Line2D (edit points in the 2D editor); generated fill/body are INTERNAL children (not saved).
  Hiker states are RefCounted classes in actors/hiker/states/, returning Hiker.STAY or the next state.
  Visual pass (after M1): `world/backdrop/backdrop.tscn` (sky CanvasLayer + Parallax2D layers built by @tool RidgeLayer/CloudLayer,
  repeat_size.x must equal the layer `width`); each trail scene instances its own Backdrop (M5 makes per-trail palettes).
  Hiker art/animation lives in `actors/hiker/hiker_visual.gd` (HikerVisual). UI icons are drawn in code by `scenes/ui/ui_icon.gd`
  (phone fonts may lack arrow glyphs). Theme variations: PrimaryButton, IconButton, CardPanel. Title font: `shared_art/title_font.tres`.
  M2: Hiker owns a `HikerCondition` (stamina + wet feet/bench/patch effects + dusk); obstacles call Hiker methods
  (stumble, fall_out, touch_checkpoint, reach_finish, condition.enter_patch...), Hiker emits signals, TrailRunner listens.
  Obstacles/interactables extend `HikerArea` (@tool, build() makes art + shapes as INTERNAL children via `ShapeUtil`).
  No stamina regen during the forced EXHAUSTED rest (else the 50%-speed recovery never happens).
  Hiker ignores input on its first physics tick (a same-frame tap still reads as just_pressed).
  `SceneRouter.cover(callable)` = fade for in-scene jumps (respawn); it does not block touches.
  Day tint: CanvasModulate for the world; the sky (own CanvasLayer) takes a softened tint + horizon glow via `Backdrop.set_daylight`.
  Trail runner pauses on app focus-out.
  M3: flow = menu -> trail_select -> trail_runner (reads `GameState.current_trail_id`, falls back to first trail) -> results.
  Season 1 has t01 Forest Lake Loop (the old dev test level) and t02 Archipelago Rocks (placeholders until M6).
  TrailData.scene_path is a path string (not PackedScene) so menus don't load levels and the validator can report missing files.
  `ContentValidator` (systems/) instantiates levels; tests run it over the whole index + the template.
  Saves: `SaveService` writes via .tmp + .bak swap; bad JSON is moved to `save.corrupt-<time>.json`; under GUT it uses
  `user://save_test.json` and autosave is off. Format changes: bump SAVE_VERSION + add a step in `systems/save_migrations.gd` + a test.
  Stars are a bitmask (StarRating.STAR_*); a trail with 0 viewpoints grants the photo star automatically.
  M4: `Viewpoint` (HikerArea) emits hiker_entered/hiker_left -> runner shows HUD "Take photo" -> `PhotoMode` overlay.
  The subject (`PhotoSubject`) moves along `subject_path`, which is relative to `frame_offset` (the photo's centre).
  Shots are scored against the *screen* centre, so keep viewpoint frames away from trail ends (camera limits would
  stop the camera centring). `PhotoScoring` = grading + film roll; quality colours live in `Postcard.border_color`.
  Placeholder postcards/stamps are drawn in code (`Postcard`, `PassportStamp`); a ViewpointData.postcard texture replaces the art.
  In .tscn, PackedColorArray is a flat list of floats.
  M5: Audio = buses Music/SFX/Ambience (default_bus_layout.tres); `audio/synth_sounds.gd` builds placeholder sounds on first
  use (footsteps per surface, shutter, summit, 4 ambience loops, menu pad). Screens call `AudioManager.enter_menu()`;
  trails call `play_ambience(trail.ambience_kind())`. Swap in real AudioStreams later without touching callers.
  Weather: `WeatherEffects` (seeded gusts) -> `hiker.condition.wind_push` (applied only walking/airborne = resting braces).
  `WeatherFx` CanvasLayer (layer 1, UI is layer 2) does rain/snow/gust streaks + a faint veil; thick fog is a `FogBank`
  inserted into the level right after the Backdrop so the path stays clear.
  Per-trail looks: inherit `world/backdrop/backdrop.tscn` (see backdrop_ruska.tscn); RidgeLayer.tree_style PINE/BIRCH/MIXED;
  TerrainStrip.tuft_color. Game feel lives in HikerVisual (footstep sound + dust per step, landing puffs, celebrate()).
  M6: Gear = GearData scales -> `GearModifiers` (in HikeModifiers.gear); GameState.buy/equip (Balance.gear_slots).
  TrailData.tutorial (TutorialTrigger hints until finished once), .night (Daylight night tints, lamp from start,
  window = daylight_seconds), .star3_key. Backdrop variants: backdrop_ruska/_fjord/_aurora.tscn (inherited scenes).
  Trails 1, 2, 4, 5 were generated by a scratch Python level builder; edit them in the editor from now on.
  Bot-measured times (incl. photos + rests; after the length ramp): T1 116 s, T2 136, T3 162, T4 212, T5 229. Daylight ~1.45x, par ~1.05x.
  Length ramp: each trail had sections inserted mid-trail (nodes Ext*_*; T4/T5 gained viewpoints glacier/frozen_lake, T2-T5 one find each).
  Gaps must stay under the jump distance at the slowest normal speed (snow 85% -> keep gaps < ~75 px).
  `.tres` typed arrays of custom resources use `Array[ExtResource("<script id>")]([...])`.
  Buttons over the play area must join group `touch_blocker`. Physics interpolation is on: use `Hiker.teleport()` to move instantly.
  On this machine, git over HTTPS needs `-c http.sslBackend=schannel`.
  Android: SDK at `%LOCALAPPDATA%\Android\Sdk` (installed with the new `android sdk install pkg/ver` CLI; `sdkmanager` is deprecated),
  Godot uses JDK 17. Preset "Android" in `export_presets.cfg` (`org.jcv.peakrush`, arm64). `window/size/mode.mobile=3` gives immersive fullscreen.
  Deploy: `GODOT=<exe> tools/deploy.sh` (exports only if stale, waits for the phone, installs; `--force`, `--install-only`,
  `pair HOST:PORT CODE` / `connect HOST:PORT` for wireless debugging). Don't launch or drive the app on the phone.
  M7: `PerfProbe` (debug builds only) logs "PERF" lines every 5 s; read with `adb logcat -s godot`. Main menu logs startup ms.
  AudioManager synthesises all sounds on a WorkerThreadPool task at boot; loops asked for early start when ready.
  SynthSounds pads every buffer (TAIL_PAD) because the Android mixer reads past the end (it crashed the AudioTrack thread).
  `SafeAreaMargin.debug_insets` fakes notches on desktop for layout checks.
  Splash: main scene is `scenes/splash/splash.tscn` (~2 s, tap skips) -> main menu. Its first frame IS the boot image
  (`shared_art/icons/boot_splash.png`, 2560x1080, stretch Keep Height); re-render with `godot --path . -s tools/make_boot_splash.gd` (not headless)
  after changing the splash or icon. "PERF startup_to_menu_ms" now includes the splash.
  Icons: painted source `shared_art/icons/source/icon_source.png` (.gdignore, not exported) -> `tools/raster_icons.gd` makes the PNGs the export preset (launcher_icons/*) and
  boot splash use (adaptive = painting as background, framed by ADAPTIVE_VIEW/CENTRE so the hiker fits any mask, + empty foreground; themed icon from adaptive_monochrome.svg). Android 12+ shows its own system splash (adaptive icon on dark) first.
  Pixel 7 Pro (debug): 60 fps, worst frame 16.7 ms, startup ~0.8 s, ~84 MB static memory.
  UI motion: `UiMotion` (scenes/ui/ui_motion.gd, static). SceneRouter calls `UiMotion.watch()` so every BaseButton squishes on press
  (opt out with meta `no_press_motion`); screens call `UiMotion.intro([...])` for staggered ease-in (scale + alpha only, safe in containers).
  Profile: `PlayerProfile` (systems/, owned by GameState.profile: name, look slot->cosmetic id, hikes, hike_seconds, badges).
  Save v2 adds "profile" (migration _v1_to_v2). Cosmetics/badges are data: content/profile/cosmetics.tres + badges.tres
  (CosmeticCatalog/BadgeCatalog, referenced by ContentIndex). Stars unlock cosmetics; `BadgeRules` judges GameState.profile_facts().
  HikerVisual._ready applies GameState.look_colors() (LOOK_PARTS maps slots to polygons). Badges are awarded in record_result/buy
  and silently on load; results shows new ones as pills. UiIcon.cutout = colour of holes in icons (set it on coloured backs).
  Trail-side trees: TerrainStrip.side_trees (NONE/PINE/BIRCH/MIXED + spacing/height/colours/snow), built by TreeArt.along behind
  the fill; they skip Viewpoint frames and nodes in group "tree_clear" (meta tree_clear_radius; see TerrainDecor). Set per strip in each trail.tscn.
  Art helpers: `TreeArt` (backdrop pines/birches, two-tone, one Polygon2D per layer via TreeArt.Batch), `SubjectArt` (bird/reindeer/boat).
  Settings rows = icon badge + label + HSlider/`ToggleSwitch` (a toggle Button drawn as a switch; call sync() after set_pressed_no_signal).
  HSlider knob = `shared_art/ui/slider_knob.svg` (theme). New UiIcon kinds go at the END of the enum (scenes store the number).
  Physics pass: sway shader `world/fx/sway.gdshader` (global uniforms wind_strength/hiker_pos set by TrailRunner; sway weight in
  Polygon2D UV.y, which Godot only passes with a texture -> `TerrainStrip.apply_sway()` adds a 1x1 white one). `TrailFx` = kicked
  pebbles (RigidBody2D, layer 1<<5) + pooled footprints off HikerVisual.stepped. Mug on the pack = spring in HikerVisual.
  `Momentum` (systems/) adds downhill speed; grades within +-0.02 count as flat. Hiker.State.SLIDE inside `SnowSlide` zones;
  `WindZone` = exposed ridge (condition.exposed_wind). Obstacles: RopeBridge (deck = one ConcavePolygonShape2D reshaped
  each tick; planks are art), SteppingStones.wobble (SteppingStone), RollingBoulder (RigidBody2D layer 1<<6, release deferred
  out of the physics callback), FallenLog (wet = ICE patch). Bodies moved from code use sync_to_physics = false.
  Walk back: `walk_back` action (touch: Back pad above the walk hint). Hiker.facing (+1/-1) drives slopes/speed/momentum and
  mirrors HikerVisual; Hiker.back_limit_x = trailhead, then each checkpoint (it brakes to stop there); slides only forward.
  Movement helpers (gravity, air control, ground_stop, grounded_transition) live in HikerState.
  Polish pass: SFX chime/gulp/creak/thud/splash/pebble (`audio/synth_sfx.gd`, AudioManager.play_find/...); pause card has a
  `TrailMap` (scanned from the level at load); journal has a Postcards/Finds switch (`FindCard`, `FindArt`, facts FIND_<ID>_FACT).
  Daily trail: `DailyChallenge` (systems/, date -> trail + Twist), GameState.daily_today()/daily_active, profile daily_last/
  daily_streak (save v4), twists applied in TrailRunner via HikeTracker.daily_twist/twisted_weather; menu `DailyCard`.
  M7.5 trail depth: `Hydration` (systems/) in HikerCondition (springs/streams call enter_spring; thirsty = Balance mults);
  HUD water gauge + finds pill are built in Hud._build_extra_pills (copies of the photo pill). Finds: TrailData.finds
  (FindData) <-> `Find` pieces (find_id; animals need stillness, appear_chance per hike); `HikeTracker` (trail runner child)
  owns finds/springs/hints; save v3 adds record "finds"; `ProfileFacts` counts badge facts. Forks = `Boardwalk` (one-way
  ConcavePolygon deck, under the level's Scenery node so stilts hide behind the ground) + `ForkSign`; lookouts = short boardwalks.
  M7.6: trail bot `tools/bot/bot.tscn` (a scene, since `-s` scripts can't use autoload-dependent classes; jump routes in
  tools/bot/routes/<id>.json; run `godot --headless --path . --fixed-fps 60 tools/bot/bot.tscn [-- <trail_id> no_photos]`,
  ~30 s for all trails, exit 1 on failure). CI: .github/workflows/checks.yml (GUT + bot). `tools/*` is excluded from export.
  `TrailRecord` (systems/) = record shape/clean/merge. Buttons inside a ScrollContainer use `ScrollTap.connect_tap`
  (swipes pass through; a press that scrolled isn't a tap) — test_touch_audit checks every menu screen.
  M7.7: `FirstHints` (trail runner, via HikeTracker) shows each HINT_* once ever (profile.hints_seen, save v5), one at a time.
  Settings: Reduce motion (settings.reduce_motion; `UiMotion.reduced()` gates UI motion, camera shake, plant sway, menu pan)
  and an About popup (`AboutCard`: version from application/config/version, credits, privacy summary, licences,
  two-tap Reset progress = GameState.reset_progress, keeps settings; AboutCard.PRIVACY_URL set in M7.9).
  `SeasonFinale` on results when a first completion finishes a season. Long HUD toasts wrap at Hud.TOAST_MAX_WIDTH.
  Audio levels: AudioManager.AMBIENCE_DB per ambience kind; footstep presets carry a gain column.
  Popups opened over a screen must stop that screen's back handler (every node gets WM_GO_BACK_REQUEST).
  Excitement pass: `SummitMoment` (flag + camera pull-back + Hud.show_summit title; Balance summit_*; tap skips).
  `Flow` (systems/, in HikerCondition): steady walking adds levels (speed bonus), stumble/fall breaks it, idle drains;
  HUD "Flow N" pill. `TrailChallenges` (systems/): ALL_FINDS / BEAT_PAR / CLEAN per trail, record "challenges" bitmask
  (save v5), TP each once (tp_per_challenge), all three = medal; shown on trail cards, pause card row, results.
  Wildlife: `TrailMoments` (world/fx, added by HikeTracker under the level) places 2-3 `WildlifeMoment`s (FLOCK,
  EAGLE, REINDEER) per hike on open ground (clear of anything from world/obstacles|interactables and of real gaps,
  before the summit); reindeer graze on the path and a hiker who barges in stumbles. Sounds: flutter, cry.
  M7.8 ads (mocked): static `Ads` (scenes/ads/, no autoload) holds an `AdProvider`: `MockAdProvider` + `MockAdOverlay`
  in debug builds (TEST AD card, consent form), the plain no-ads AdProvider in release and under GUT (SaveService.is_test_run)
  until a real AdMob provider subclass arrives. `AdPolicy` (systems/) = interstitial cadence/grace/tutorial rule + reward TP
  (Balance ad_*). Results: "Watch an ad" in the button row (GameState.add_bonus_tp); every exit goes through
  Results._leave -> Ads.between_hikes. Main menu asks consent once (settings.ad_consent); About reopens it.
  Daily pick: trails and twists are dealt from shuffled decks per day (no repeats; `_shuffled` uses its own LCG so every
  app version agrees), `DailyChallenge.fits` keeps twists on trails that suit them, and the day's pick is pinned in
  profile.daily_pick (save v5) so unlocking a trail mid-day can't change it. 10 twists (DailyChallenge.TWIST_KEYS);
  HikeTracker.apply_daily applies hiker ones (Hydration.drain_scale, weather_drain_mult), twisted_weather the fog/gusts.
  Daily: `DailyChallenge.is_done` keeps a daily done if the clock moves back <= 2 days. A save from a newer app is copied
  to save.v<N>-backup.json before use. Phone-only checks: docs/PHONE_CHECKLIST.md.
  M7.9 prep: version 1.0.0 (project.godot; presets' version/name empty, bump version/code per upload). Preset "Android Release" =
  Gradle + AAB, keystore from GODOT_ANDROID_KEYSTORE_RELEASE_* env vars, Gradle's Windows-ROOT trust store + memory cap live in ~/.gradle/gradle.properties
  on this PC (docs/RELEASE.md). Store images: `godot --path . --resolution 1920x1080 tools/store_shots/store_shots.tscn` -> export/store/
  (fake progress in memory, autosave off). Listing text + rating/data-safety answers: docs/STORE_LISTING.md.
  Postcards: `PostcardArt` (scenes/journal) draws a scene per ViewpointData.motif (enum; new motifs at the END), night sky on
  night trails; a painted ViewpointData.postcard still wins. Airborne wind = wind_push * Balance.air_wind_scale (0.4) so a
  gust can't stall a jump. Jump gaps over water are <= 70 px (a scan found 4 at 80-84 px; widen nothing past 75).
  Trail 6 Crane Mire (t06_crane_mire, unlock_order 4 = played 5th; Aurora Summit is unlock_order 5, the finale): misty bog,
  weather mist.tres (light fog + gusts), backdrop_mire.tscn, duckboard fork (DuckboardsA/B + Lookout), Ditch* water polygons
  fill open gaps, motifs MARSH/TOWER/MISTY_POND. Built by a scratch builder; edit it in the editor from now on.
  Season 1 now: 6 trails, 15 postcards, 29 finds. Bot: T4 212 s, T6 224, T5 229 (daylight 320 / par 240).
  Production pass: ad consent is deferred (Ads.consent_pending; asked on the first "watch an ad" tap via
  Ads.request_rewarded, or instead of the first due interstitial; menu only asks past the grace period); providers get
  start() after consent and load nothing before. `PostcardPop` (photo mode) shows the postcard on a new/better shot.
  Store shots are captioned (raw in export/store/raw/). `ReviewPolicy` + `ReviewPrompt` (results, once, after a first summit
  at >= Balance.review_after_summits summits; plugin singleton checked, debug builds show a TEST card).
  About "Send feedback" = mailto with version/phone, hidden until AboutCard.SUPPORT_EMAIL is set.
  New settings keys with defaults (ad_consent, review_asked) need no save migration: settings merge over DEFAULT_SETTINGS.
  Postcard pictures are rendered from the real game: `godot --path . --resolution 1920x1080 tools/postcards/make_postcards.tscn
  -- <trail_id>` (one trail per run; it keeps the runner unpaused when the window loses focus) writes
  trails/<trail>/postcards/<viewpoint>.webp (900x600), linked as ViewpointData.postcard. Re-run after changing a viewpoint or
  backdrop. Postcard draws them as a printed photo + caption strip + stamp/postmark; PostcardArt is the fallback.
  M9 real steps (started early, Android built): `StepLedger` (systems/, GameState.steps, save v6 "steps") = steps->TP per
  day (Balance steps_per_tp/step_tp_daily_cap/step_claim_window_days), no backfill before first opt-in, claims store steps per day.
  Static `Steps` (scenes/steps/, no autoload) picks HealthConnectStepProvider (singleton PeakRushSteps) / MockStepProvider
  (debug desktop, 100 steps/min) / no-op StepProvider (GUT, release desktop). Settings switch (hidden if unsupported), menu
  "Steps today" claim button, profile "Real km walked", badges REAL_STEPS/REAL_KM (rules at the END of BadgeData.Rule).
  Kotlin plugin source: native/android/peak_rush_steps (.gdignore; build per its README) -> addons/peak_rush_steps/bin AAR,
  packaged by the addons/peak_rush_steps export plugin. Both Android presets now use the Gradle build, min SDK 26.
  Health Connect client pinned to 1.1.0-beta01: newer ones need AGP 8.9.1, Godot 4.7.2's template has 8.6.1.
  Menu claim = `StepsButton` (scenes/main_menu; re-reads on app focus-in/resume, count-up, badge pills). New-badge pills are
  shared: `BadgePills.show(parent, ids)` (results + step claims). Health Connect's rationale text lives in the plugin's
  res/values/strings.xml (runs outside the game, so not strings.csv). UI tests: tests/ui/test_steps_ui.gd (mock phone).
  Adding content: docs/ADDING_CONTENT.md. The template (content/_templates/trail_template) uses every common piece and is
  validated by the tests; ContentValidator._check_gaps fails open gaps over MAX_JUMP_GAP (75 px) not covered by stones/bridge/log/boardwalk.
  Weekly goals: `WeeklyGoals` (systems/) = 3 of 6 goals per Monday-week (seeded via DailyChallenge._shuffled), progress
  capped at targets, TP per goal + all-three bonus (Balance weekly_*); state in profile.weekly (save v7); paid in
  GameState.record_result (last_result.weekly), shown in the Daily card and the results TP breakdown.
  Season 2 Tea Country (s02_tea, ships at launch): t07 Tea Terraces, t08 Ella Rock, t09 Nine Arches (monsoon, viaduct art +
  TRAIN subject), t10 World's End (fog, cliff edge with Lowlands strip so the camera can frame the drop), t11 Pilgrim's Peak
  (night + TrailData.sunrise: Daylight lifts tint_night -> tint_sunrise from Balance.sunrise_start). Art: TreeKind/TreeStyle PALM, TEA
  (TreeArt.palm/tea_bush; RidgeLayer TEA lays bush rows), backdrops tea/monsoon/plains/pilgrim, weather monsoon.tres.
  Continue = keep going in a started season (newest first), else earliest season (new players start Season 1).
  Bot: S2 114 / 154 / 163 / 183 / 195 s. Postcard tool renders sunrise trails at the par-pace time of night.
  New moves: `HikerActions` (actors/hiker; hurrying/crouching/ladder + speed/effort mults; hiker.actions), HikerInput
  hurry double-tap + jump_held + duck (new input action `duck`, S/Down; Duck pad above Jump in TouchControls, UiIcon.DUCK).
  Hold jump: HikerState.apply_jump_gravity softens gravity only after Balance.jump_tap_seconds (taps unchanged ~96 px, held ~144).
  Hiker.State.CLIMB (HikerClimbState) via `Ladder` pieces (style LADDER/SCRAMBLE); `LowBranch` stumbles a non-crouching hiker.
  HikerCondition.effort_mult (hurry/climb drain). FirstHints: HINT_HURRY (after walking), HIGH_JUMP (group high_ledge), CLIMB, DUCK.
  Bot routes may list "ducks" ranges. Placed: T2 high lookout, T4/T6 branches, T7 high lookout, T8 ladder + branches,
  T9 branches, T11 scramble.
  Stroll + racing: settings stroll_mode/show_ghost (switches on trail select); GameState.stroll_hike() (never the daily);
  HikeTracker.start_run freezes Daylight (Daylight.freeze) and makes a `GhostTrack` (records every ghost_sample_seconds,
  replays user://ghosts/<trail>.json, keeps a new best via finish_run). TrailResult.stroll/shortcuts; TrailRecord.gold_time/
  has_gold (par x gold_time_ratio, tp_gold once), record "shortcuts" (save v8), TrailData.shortcut_count (validated);
  `ShortcutMarker` pieces on high "ShortcutDeck" boardwalks (placed by a scratch script, one per trail).
  game_state.gd is ~355 lines: split record_result out if it grows again.
  Seasonal events: `EventData` (data/, content/events/*.tres, ContentIndex.events, ContentDB.events()), `SeasonalEvents`
  (systems/: active by "MM-DD" (wraps New Year), key_for = id_startyear, days_left, record -> profile.events/events_done, save v9).
  HikeTracker._start_event places `EventToken`s via TrailMoments.open_ground and WeatherFx.add_seasonal particles; paid in
  GameState.record_result (last_result.event); Daily card + results line + menu banner. Balance event_*.
  Share: `PostcardShare` (scenes/journal) renders card + name into user://share/postcard.png (headless: blank) and calls
  PeakRushSteps.sharePicture (Kotlin, `ShareFileProvider` subclass: Godot's template already declares androidx FileProvider,
  and the manifest merger fails on two of the same class; authority <pkg>.peakrush.share, res/xml/peak_rush_share_paths.xml,
  androidx.core 1.13.1 added to plugin deps + export_plugin DEPENDENCIES; AAR rebuilt). Journal enlarged card has Share.
  Water: SteppingStones uses `world/obstacles/water.gdshader` (waves/depth/glints in local px). GroundPatch art follows the TerrainStrip slope.
  Long journey: `JourneyData`/`LandmarkData` (data/, content/journeys/kungsleden.tres, ContentIndex.journeys, ContentDB.journeys()),
  `Journey` (systems/: advance(profile, journeys, km) -> pages/tp/finished, km_from_steps, unread/mark_read, map_position;
  profile.journeys/journey_pages/journey_seen/journeys_done, save v10). Km from GameState.claim_steps (steps x4) and
  HikeRewards (8 km per finished hike). Screen `scenes/journey/` (journey.gd builds the layout, `JourneyMap` draws the map;
  map_pos is stylised, spaced by stop: regenerate with a script rather than real coordinates). Menu "Journey" button
  (New page! while unread), results line, steps-claim note, badge rule JOURNEYS. Story = Elsa's 1974 notebook (LM_* strings).
  `HikeRewards` (systems/) now does all of record_result's sums; GameState keeps saving, badges and the daily (~325 lines).
  Results breakdown shrinks its font past 5 lines (Results._fit_breakdown).
