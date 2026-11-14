# Peak Rush — Game Design Document (v0.1)

*Working title. Platform: Android and iOS (landscape). Engine: Godot 4.*

## 1. Pitch
A cozy 2D hiking game. You walk real-world-inspired trails from trailhead to summit, pace your
stamina against the setting sun, and stop at viewpoints to take the perfect photo for your travel journal.
New trails arrive in **Seasons**, each one a new part of the world.

**Session length:** 3–8 minutes per trail. **Tone:** calm and rewarding, not punishing. You can't die, only get tired or lose time.

## 2. Design pillars
1. **The feeling of the hike.** The skill is in pacing, not fast reflexes. You decide when to push, when to rest and when to slow down for the view.
2. **Collect the view.** Photos, postcards and passport stamps are the main reward.
3. **There's always a new trail.** The content pipeline makes adding trails and seasons cheap.

## 3. Core loop
```
Choose trail → Hike (pace stamina, jump obstacles, rest, photograph viewpoints) → Reach summit
   → Stars + passport stamp + Trail Points (TP) → Unlock next trail / buy gear → New season arrives
```

## 4. Controls (landscape)
| Input | Action |
|---|---|
| Hold left half of screen | Walk forward |
| Release | Stop and rest (stamina refills) |
| Tap right half of screen | Jump |
| Tap 📷 prompt at a viewpoint | Enter photo mode |
| Tap in photo mode | Take the photo |
A **left-handed** setting swaps the two halves. On desktop: D/Right = walk, Space = jump.

**Stroll mode** (trail select switch): no daylight clock or dusk; finds and photos count, TP x0.5;
no best time, Gold, beat-par goal or dusk star. The daily trail is never a stroll.
**Racing your best:** Gold time = par x 0.85 (one-time TP); a ghost replays your best run (cached
in user://ghosts/, not the save); every trail hides one shortcut on a high boardwalk (TP once, save v8).

**Seasonal events** (calendar, every year, no update needed; content/events/*.tres): Autumn on the
trails (Oct–Nov, falling leaves, golden leaves), Winter lights (Dec–mid Jan, snow, lanterns), Spring blossom
(mid Mar–mid May, petals, blossoms), Midsummer (mid Jun–Jul, fireflies, wild strawberries). 4 collectibles per
hike on open ground, TP each, goal 25 per event-year pays a bonus (save v9). Shown in the Daily card,
results and the main menu banner.
**Share a postcard:** Journal > enlarge a postcard > Share renders a picture (card + game name) and opens
the Android share sheet (PeakRushSteps.sharePicture via FileProvider).

**Extra moves** (added after launch prep; no new buttons except Duck):
- **Hold to jump higher:** a tap is the normal jump (~96 px); holding past tap length (0.12 s) softens
  gravity on the way up (~144 px). High lookouts with hidden finds sit ~115–120 px up.
- **Hurry:** double-tap and hold Walk: x1.35 speed, x1.8 energy drain; not while exhausted.
- **Climb:** walk into a `Ladder` (wooden or rock scramble) at a wall too tall to jump; release to cling,
  Back climbs down, x1.6 energy; the hiker hops onto the ledge at the top.
- **Duck:** the Duck pad (above Jump; S/Down on keyboards) crouch-walks at x0.55 under a `LowBranch`;
  walking into one upright = stumble, jumping into one = bumped back down.

## 5. Systems
All numbers are starting values. They live in `content/balance.tres` and will be tuned in playtests.

### 5.1 Movement
- Base walk speed **140 px/s**. Uphill the speed is multiplied by `1 − 0.5 × uphill_grade` (minimum 50%); downhill it gets up to +15%.
- Jump: clears small roots and rocks; big rocks need a well-timed jump.
- Exhausted hikers walk at 50% speed.

### 5.2 Stamina (0–100)
- Walking drains **4/s × slope factor × weather multiplier × gear modifiers**, where slope factor = `1 + 2 × uphill_grade`.
- Resting (standing still) restores **15/s**. Resting at a **bench** restores 30/s.
- At **0 the hiker is Exhausted**: a forced 2-second rest, then 50% speed until stamina is back above 30.
- Stumbling costs **10 stamina** plus a short stop.

### 5.3 Daylight
- Each trail has `daylight_seconds`. A sun icon moves along an arc in the HUD, and the world tint shifts from morning to golden hour to dusk.
- At **dusk** the headlamp turns on, walk speed drops by 30%, and you lose the ★3 star. It's not a fail, so you can always finish.

### 5.4 Obstacles and terrain
| Element | Effect |
|---|---|
| Root (small) | Jump over it, or stumble (−10 stamina, short stop) |
| Rock (large) | Needs a jump; hitting it blocks you until you jump |
| Mud | 60% speed, 2× stamina drain |
| Ice / snow patch | Slip back slightly unless wearing grip boots |
| Stepping stones | Timed jumps; a miss means "wet feet" (+20% drain for 10 s) |
| Gap / ledge | A fall respawns you at the last checkpoint with −15 stamina |
| Bench | Fast stamina regen |
| Checkpoint (trail marker) | Respawn point |
| Viewpoint | Photo opportunity |
| Finish (summit cairn) | Ends the trail |

### 5.5 Viewpoints and photo mode
- A trail has **2–4 viewpoints**. Walking into one shows the 📷 prompt (optional; you can skip it).
- **Photo mode:** a viewfinder over the scene, with a subject that moves (a reindeer walking, the aurora shimmering, a waterfall mist burst). Tap when the subject is centred in the frame.
- The quality is **Good, Great or Perfect** (bronze, silver or gold postcard border). Replaying a trail can improve it.
- Each photo unlocks a **postcard** illustration in the journal. These are pre-drawn art, not screenshots.

### 5.6 Stars and rewards
- ★1 **Reach the summit**
- ★2 **Photograph every viewpoint**
- ★3 **Summit before dusk**
- **Trail Points (TP):** 50 for finishing, +25 per star the first time you earn it, +10/20/30 per photo by quality (best result only).
- **Passport stamp:** one per trail, shown in the journal.

### 5.7 Gear (Season 1 set; 2 equip slots)
| Gear | Effect | Cost |
|---|---|---|
| Grip boots | Ice/snow slip −75% | 150 TP |
| Hiking poles | Uphill drain −20% | 200 TP |
| Rain shell | Weather drain multiplier halved | 200 TP |
| Thermos | Rest regen +25% | 150 TP |
| Bright headlamp | Dusk speed penalty halved | 250 TP |
Two slots means each trail's weather makes you choose your loadout.

### 5.8 Weather profiles
| Weather | Effect |
|---|---|
| Clear | none |
| Rain | drain ×1.3, wet surfaces |
| Fog | limited view (overlay gradient), viewpoints harder to spot |
| Snow | drain ×1.2, ice patches |
| Wind | gusts push you back; resting braces you |

### 5.9 Progression
- Trails unlock **in order within a season**. Trail 1 of every season is always open, so new players can jump straight into the latest season.
- The journal shows each season as a passport page.

### 5.10 Real-world steps (M9)
The player's real steps from the phone's health app become a small TP bonus, so a walk in real life helps your hiker.
- **Source:** Android **Health Connect**, iOS **HealthKit**. Read-only, steps only.
- **Opt-in:** a "Real steps give TP" switch in Settings (only on phones with a step source). The game is fully playable without it, and saying no costs nothing.
- **Rate:** **1 TP per 500 steps**, capped at **40 TP per day** (≈ 20,000 steps). Both numbers live in `balance.tres`.
- **No backfill:** only steps taken after the player opts in count. History from before that is ignored.
- **Claiming:** on the main menu, a "Steps today" button that lights up with "+N TP"; one tap claims. Unclaimed steps from the last **7 days** can still be claimed (each day capped separately); anything older is lost.
- **Fairness:** the cap keeps steps a bonus. Trails, stars and photos stay the main source of TP. The cap, plus the stored last-sync time, is enough anti-cheat for a single-player game.
- **Profile stat:** "Real km walked" (steps × 0.75 m), counting every claimed step, past the TP cap too.
- **Badges:** Step Outside (10,000 steps), Marathon Legs (42 km), Long Walker (200 km).
- **Privacy:** step data is used only on the device and never leaves it. The privacy policy and store forms must say so.

### 5.11 The long journey and Elsa's notebook
Peak Rush's heart: **every step you take in real life walks you deeper into a story.**
- **The journey:** a famous long-distance trail walked over weeks. The first is **Kungsleden** (Abisko to Hemavan,
  440 km, Swedish Lapland). A main-menu **Journey** screen shows a sketched map with the walked part, landmarks and
  the walker.
- **Kilometres come from two places:** claimed real steps count **4x** (steps x 0.75 m x `journey_real_km_mult`), and
  every finished hike adds **8 km** (`journey_km_per_hike`; strolls count, giving up doesn't). So players without a
  step source can still finish, and walkers get there in about three weeks of everyday walking.
- **The story:** each landmark (11 on Kungsleden: huts, a pass, villages) unlocks a page of **Grandma Elsa's
  notebook**. She walked Kungsleden in summer 1974 with her sister Kerstin, went on alone after Kvikkjokk, and had to
  stop at Ammarnäs. Her last page asks someone to finish the trail for her; the Hemavan page is the player's own.
- **Rewards:** +30 TP per landmark (not the opening page), +300 TP and the **The Notebook** badge for finishing.
  A new page lights up the menu button ("Journey · New page!") until it's read.
- **Data:** `JourneyData` + `LandmarkData` in `content/journeys/`, listed in ContentIndex.journeys and walked in
  order; future seasons can add their own journey (a Sri Lankan pilgrim route for Tea Country, for example).

## 6. Season 1 — Nordic Trails (launch content)
| # | Trail | Biome / weather | Teaches / special | Viewpoints |
|---|---|---|---|---|
| 1 | Forest Lake Loop | Summer pine forest, clear | Tutorial: walk, rest, jump, photo | Lake mirror, woodpecker |
| 2 | Archipelago Rocks | Granite coast, wind | Wind gusts, stepping stones | Lighthouse, seabirds |
| 3 | Lapland Fell | Autumn "ruska" colours, fog | Fog, longer climb, benches | Reindeer herd, fell top |
| 4 | Fjord Ridge | Steep and green, rain | Rain, mud, ledges | Waterfall, fjord panorama |
| 5 | Crane Mire | Misty autumn bog, light mist + gusts | Duckboard fork (dry boards vs muddy valley), bog pools, all mechanics mixed | Dancing cranes, fire lookout tower, misty pond |
| 6 | Aurora Summit | Winter night, snow | Ice, headlamp; daylight = aurora window (the finale) | Aurora, snowy cabin |

## 6b. Season 2 — Tea Country (also at launch)
Hill country inspired by Sri Lanka. Its first trail is open from the start, like every season's.
| # | Trail | Biome / weather | Teaches / special | Viewpoints |
|---|---|---|---|---|
| 1 | Tea Terraces | Tea estate, clear morning | Terrace ledges, stepping stones, tea factory | Pickers' hillside, old tea factory |
| 2 | Ella Rock | Railway line and eucalyptus forest, breezy | Walking the rails, rope bridge, fork, steep climb, rolling boulder | Ella Gap, top of the rock |
| 3 | Nine Arches | Jungle valley, monsoon rain | Mud, swollen stream, passing under the viaduct, gorge bridge | Train on the arches (TRAIN subject), jungle valley |
| 4 | World's End | Misty grassland plains, fog | Open wind, log and stones, duckboard fork over the bog, the cliff edge | Baker's Falls, World's End |
| 5 | Pilgrim's Peak | Night climb to sunrise | Lantern-lit steps, tea stalls (springs), rest houses; `sunrise` night = dark lifts to dawn, 3rd star = top before sunrise | Lantern path, sunrise from the top |

## 7. Future seasons (ideas)
- **S3 Alpine:** passes, glacier walk, cable-car finish.
- **S4 Canyon & Desert:** heat instead of cold (water bottle mechanic).
- **S5 Volcano & Jungle:** steam vents, rope bridges.
- Possible later mechanic: a **water bottle** that refills at springs (a good fit for the desert season).

## 8. Art direction
- **Flat and minimal**, with 4–5 layered parallax silhouettes, a limited palette per trail, and soft gradients. The time of day comes from tinting the whole scene with `CanvasModulate`.
- The hiker is a simple, readable silhouette with a coloured backpack.
- Placeholder palette (Season 1):
  - Sky `#A8D8EA`
  - Far hills `#7FA6A0`
  - Mid hills `#5E8C7A`
  - Near ground `#3B5B4A`
  - Path `#C9B28F`
  - Hiker accent `#E85D3F`
  - UI cream `#FFF6E5`
  - UI ink `#2B2D42`

## 9. Audio
Ambient loops per biome (birds, wind, waves), footsteps that change with the surface, a satisfying camera shutter, soft acoustic music on menus, and a gentle sting at the summit.

## 10. Screens
Main menu · Season & trail select (illustrated map with trail pins) · Trail HUD (stamina bar, sun arc, photo counter, pause) · Photo mode · Results (stars, TP, stamp) · Journal (passport stamps and postcards) · Gear · Settings (music/SFX volume, left-handed controls, vibration, language).

## 11. Out of scope for v1
Multiplayer, online leaderboards, accounts, ads, procedurally generated trails, cloud saves.

## 12. Open decisions
- Final name (alternatives: *Trail Journal*, *Wayfarer*, *Summit Postcards*)
- Monetisation: paid up front, or free with Season 1 included and later seasons as in-app purchases
- Whether the final art keeps the flat style or moves to hand-drawn
