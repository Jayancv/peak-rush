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
7. **Input goes through actions only:** `walk`, `jump`, `pause`. The `TouchControls` scene turns touches into `Input.action_press/release`, and gameplay code never reads raw touch events. Keyboard mapping for desktop testing: D/Right = walk, Space/W/Up = jump, Esc = pause. Turn on *Emulate Touch From Mouse*.
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
- Milestone: **M6 – built, 189 tests green, on Pixel 7 Pro; awaiting a full Season 1 run on the phone (done-when)**. M5 playtest still open. Next: M7.
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
  Bot-measured times (incl. 2 photos + rests): T1 114 s, T2 117, T3 112, T4 132, T5 116. Daylight ~1.45x, par ~1.05x.
  Gaps must stay under the jump distance at the slowest normal speed (snow 85% -> keep gaps < ~75 px).
  `.tres` typed arrays of custom resources use `Array[ExtResource("<script id>")]([...])`.
  Buttons over the play area must join group `touch_blocker`. Physics interpolation is on: use `Hiker.teleport()` to move instantly.
  On this machine, git over HTTPS needs `-c http.sslBackend=schannel`.
  Android: SDK at `%LOCALAPPDATA%\Android\Sdk` (installed with the new `android sdk install pkg/ver` CLI; `sdkmanager` is deprecated),
  Godot uses JDK 17. Preset "Android" in `export_presets.cfg` (`org.jcv.peakrush`, arm64). `window/size/mode.mobile=3` gives immersive fullscreen.
  Headless deploy: `godot --headless --path . --export-debug "Android" export/android/peak-rush-debug.apk`, then `adb install -r`.
