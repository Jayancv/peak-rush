# Adding content to Peak Rush

New trails and seasons are **data, not code**: a trail is a level scene (`trail.tscn`) plus a
`TrailData` resource (`trail.tres`), listed in its season. No game script changes are needed.
The content validator (run by the tests) and the trail bot catch most mistakes before a build.

---

## Add a trail

### 1. Copy the template
Copy `content/_templates/trail_template/` to `content/seasons/<season>/trails/tNN_<name>/`.
The template is a short, working trail that uses every common piece with correct spacing
(rock, root, mud, bench, spring, checkpoints, rope bridge, a duckboard fork, a viewpoint,
stepping stones, a jump gap with water, a hidden lookout find, the finish). Keep what you need.

Rename the root node, then fix `scene_path` in the copied `trail.tres`.

### 2. Fill in `trail.tres`
| Field | Notes |
|---|---|
| `id` | Unique forever, e.g. `t07_birch_ridge`. **Saves are keyed by it: never rename after release.** |
| `name_key` | `TRAIL_T07_NAME`, add the string (step 5). |
| `season_id` | Must match the season's `id` (the validator checks). |
| `length_m` | Shown on the trail card; roughly the level width / 2.6. |
| `daylight_seconds`, `par_time` | Set from the bot time (step 6). |
| `weather` | A `WeatherProfile` in `content/weather/` (clear, windy, fog, mist, rain, snow) or a new one. |
| `ambience` | 0 = from the weather; or Forest / Coast / Fell / Rain. |
| `viewpoints` | One `ViewpointData` per photo spot: `id`, `name_key`, `motif` (fallback art), `postcard` (step 7). 2–3 per trail. |
| `finds` | `FindData`: `id`, `name_key`, `kind` (FLOWER / MUSHROOM / ITEM / ANIMAL), `color`, `appear_chance` (animals < 1). 4–5 per trail, one hidden off the main path. |
| `unlock_order` | Position in its season (0 = first). Unlocks after the previous trail's summit. |
| `night`, `tutorial`, `star3_key` | Night trails start dark with the headlamp; only the first trail of the game is a tutorial. |

### 3. Build the level (`trail.tscn`)
Open it in the Godot editor. Structure (keep these names):

- `Backdrop`: instance a backdrop look (`world/backdrop/backdrop*.tscn`), or make a new
  inherited one with its own sky gradient, ridge colours and tree style.
- `Scenery`: art behind the path: boardwalk decks (forks, lookouts), water polygons in open
  gaps, landmarks (a tower, a waterfall). Put landmarks in the `tree_clear` group with
  `metadata/tree_clear_radius` so trail-side trees keep away.
- `Trailhead` (Marker2D): where the hiker starts.
- `Ground`: `TerrainStrip` nodes (Line2D). Set `surface` (dirt, rock, mud, ice, snow),
  `fill_color`, `tuft_color`, `side_trees`.
- `Pieces`: everything the hiker touches.

**Rules the game depends on**
- **Jump gaps: at most 70 px of open water** between strips (the validator fails anything over
  75 px). Jumps must work at the slowest normal speed (snow, 85%). The hiker jumps about 91 px high.
- Wider crossings need **stepping stones** (origin on the left bank, the next strip starts at
  `origin + total_width()`, i.e. `(count + 1) * gap + count * 44`), a **rope bridge** (`span`),
  a **fallen log** (`length`), or a **boardwalk**.
- Put a `KillZone` under every drop you can fall into: centred on the gap, about 260 px below
  the path, `size` = gap + 40 wide.
- **Fork**: a `ForkSign`, then a `Boardwalk` deck about 48 px above the ground (one jump up),
  with the slower valley path below. Falling off the deck lands in the valley, never in a kill zone.
- **Viewpoints**: `viewpoint_id` must match the data. Keep the frame (`frame_offset`) away
  from the level ends so the camera can centre it. The subject moves along `subject_path`
  (relative to the frame centre).
- Each `Find` needs `find_id` matching the data. Hide one on a lookout or off the fork.
- **High lookouts** for a held jump: a boardwalk ~115–120 px above the path (a tap reaches ~96 px,
  a held jump ~144 px). Add a `Marker2D` in group `high_ledge` near it so the first-time hint fires.
- **Ladders** (`world/obstacles/ladder.tscn`): a vertical wall in the strip (two points 4 px apart)
  taller than a jump, with the ladder's foot on the lower ground just before the wall; `height` = wall
  height, `style` LADDER or SCRAMBLE. The bot climbs by walking into it.
- **Low branches** (`world/obstacles/low_branch.tscn`) on the path; add a `"ducks": [[x - 115, x + 75]]`
  entry to the bot route for each.
- **Checkpoints** every 1500–2500 px, **benches** before long climbs, a **spring** every
  3000–4000 px. The finish goes on flat ground near the end, with 300+ px of path after it.
- Long-range art like water or landmarks goes in `Scenery` (drawn behind the ground).

### 4. Add it to the season
Add the trail to `content/seasons/<season>/season.tres` → `trails`.

### 5. Strings
Add to `translations/strings.csv`: the trail name, each `VP_*` name, each `FIND_*` name and
`FIND_*_FACT` (a one-line fact for the journal). Every player-facing string goes through `tr()`.

### 6. Bot route and timing
1. Write `tools/bot/routes/<trail_id>.json`: `{"jumps": [x, ...], "end_x": <finish x>}`. Add a
   jump about 14 px before each gap edge, and for stepping stones `origin - 12 + i * (gap + 44)`
   for i = 0…count. The bot jumps rocks and roots by itself when blocked.
2. Set `daylight_seconds` and `par_time` to 600 for a first run, then:
   `godot --headless --path . --fixed-fps 60 tools/bot/bot.tscn -- <trail_id>`
3. Set **daylight ≈ 1.45 × bot time** and **par ≈ 1.05 × bot time**. Keep the season's trails
   ramping up in length (Season 1: 113 → 136 → 160 → 212 → 224 → 229 s).
4. Run the bot a few times: random weather and wildlife must never make it fail.

### 7. Postcards
Render the real view from each viewpoint (needs a window, not headless):
`godot --path . --resolution 1920x1080 tools/postcards/make_postcards.tscn -- <trail_id>`
This writes `postcards/<viewpoint>.webp` next to the trail. Run `--import`, then set each
`ViewpointData.postcard` to its file. Re-render whenever the viewpoint or backdrop changes.
A hand-painted or photographic texture can replace a picture at any time.

### 8. Check
- `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
  (the content validator runs over every trail and the template).
- The full bot: `godot --headless --path . --fixed-fps 60 tools/bot/bot.tscn`.
- Play it on the phone: the fork, every viewpoint, every find, the water and gaps.
- Optional: `tools/store_shots` for new store screenshots.

---

## Add a season
1. Create `content/seasons/sNN_<name>/season.tres` (`SeasonData`): `id`, `title_key`,
   `theme_color` (stamps, journal tabs), `banner` (optional), `release_version`.
2. Add it to `content/content_index.tres` → `seasons`.
3. Add its trails (above). The first trail of every season is always unlocked, so
   returning players can jump straight in.
4. New gear (`GearData` in `content/gear/`, listed in the index), weather profiles or backdrop
   looks as needed. New cosmetics and badges are data too (`content/profile/`).
5. Bump the version (`application/config/version` in `project.godot`, and **`version/code` in
   both export presets**). `1.x` = trails or fixes within a season, `2.0` = Season 2.
6. Run all tests and the bot, play the season on the phone, then build the release
   (`docs/RELEASE.md`).

## Saves
Players keep progress across updates. Records are keyed by trail and viewpoint ids, so never
rename or reuse an id. Any change to the save format needs a new `SAVE_VERSION`, a step in
`systems/save_migrations.gd` and a test.
