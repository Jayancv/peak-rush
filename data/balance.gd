class_name Balance
extends Resource
## Every tuning number in the game. The live values are in content/balance.tres;
## the defaults here mirror GAME_DESIGN.md so tests don't break when the game is tuned.

@export_group("Walking")
## Base walk speed on flat ground (px/s).
@export var walk_speed: float = 140.0
## How fast the hiker reaches walk speed (px/s²).
@export var walk_accel: float = 600.0
## How fast the hiker stops after letting go (px/s²).
@export var walk_decel: float = 900.0

@export_group("Slope")
## Uphill speed = 1 − this × grade.
@export var uphill_speed_per_grade: float = 0.5
## Uphill speed never drops below this fraction of walk speed.
@export var min_uphill_speed_mult: float = 0.5
## Downhill bonus = this × grade, capped by max_downhill_bonus.
@export var downhill_bonus_per_grade: float = 0.3
@export var max_downhill_bonus: float = 0.15
## Stamina drain multiplier = 1 + this × uphill grade.
@export var uphill_drain_per_grade: float = 2.0
## Steeper than this is a wall, not a floor.
@export var max_floor_angle_deg: float = 50.0
@export var floor_snap_px: float = 16.0

@export_group("Momentum")
## Downhill build-up (px/s² per unit of grade), cap (px/s), fade on the flat (px/s²)
## and extra drain per unit of uphill grade (px/s²).
@export var momentum_gain_per_grade: float = 220.0
@export var momentum_max: float = 45.0
@export var momentum_decay: float = 30.0
@export var momentum_uphill_decay: float = 140.0

@export_group("Wind and sliding")
## On an exposed ridge (WindZone) gusts are this many times stronger.
@export var exposed_gust_mult: float = 2.2
## Snow slide: steepest-descent needed to start sliding, acceleration per unit of
## grade (px/s²), top speed (px/s), and braking on the flat run-out (px/s²).
@export var slide_min_grade: float = 0.15
@export var slide_accel_per_grade: float = 420.0
@export var slide_max_speed: float = 320.0
@export var slide_brake: float = 260.0

@export_group("Jumping")
@export var gravity: float = 1600.0
## Initial upward speed. Jump height ≈ jump_velocity² / (2 × gravity).
@export var jump_velocity: float = 540.0
@export var max_fall_speed: float = 1400.0
## Horizontal acceleration in the air while walk is held, and drag while it isn't.
@export var air_accel: float = 400.0
@export var air_decel: float = 150.0
## Share of the wind push felt while airborne (gusts mustn't wreck a committed jump).
@export_range(0.0, 1.0) var air_wind_scale: float = 0.4
## Grace period to still jump after walking off an edge.
@export var coyote_seconds: float = 0.1
## A jump pressed this long before landing still fires on landing.
@export var jump_buffer_seconds: float = 0.12

@export_group("States")
## Standing still this long turns Idle into Rest.
@export var rest_delay_seconds: float = 0.5
@export var stumble_seconds: float = 0.6
## Forced rest when stamina hits 0.
@export var exhausted_rest_seconds: float = 2.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
## Walking drain per second before slope, terrain, weather and gear multipliers.
@export var walk_drain: float = 4.0
## Regen per second standing still, and sitting at a bench.
@export var rest_regen: float = 15.0
@export var bench_regen: float = 30.0
## After hitting 0: walk speed multiplier until stamina climbs back above recovery_threshold.
@export var exhausted_speed_mult: float = 0.5
@export var recovery_threshold: float = 30.0
@export var stumble_cost: float = 10.0
@export var fall_cost: float = 15.0
## Below this fraction of max the HUD bar pulses.
@export var low_stamina_fraction: float = 0.25

@export_group("Water")
## The bottle: size, drink per second of walking, refill per second in a spring/stream.
@export var water_max: float = 100.0
@export var water_drain: float = 0.9
@export var water_refill: float = 45.0
## Thirsty (empty bottle): stamina drain and rest regen multipliers.
@export var thirsty_drain_mult: float = 1.3
@export var thirsty_regen_mult: float = 0.5
## Below this fraction the HUD gauge warns.
@export var water_low_fraction: float = 0.2

@export_group("Finds")
## TP for each find the first time it's collected.
@export var tp_per_new_find: int = 15
## TP for each trail challenge met for the first time (three per trail, then a medal).
@export var tp_per_challenge: int = 40
## Seconds of standing still near an animal to spot it, and how long it tolerates a
## walking hiker before it runs off.
@export var animal_spot_seconds: float = 1.2
@export var animal_patience_seconds: float = 0.8

@export_group("Daily trail")
## Reward for completing the daily trail, extra TP per streak day (up to the cap).
@export var daily_bonus_tp: int = 60
@export var daily_streak_tp: int = 10
@export var daily_streak_cap: int = 5
## Twists: steady headwind (px/s), daylight multiplier for a short day, finds to collect.
@export var daily_headwind: float = 24.0
@export var daily_short_day_mult: float = 0.75
@export var daily_forager_finds: int = 2
@export var daily_fog_density: float = 0.55
## Dry spell: water drain multiplier. Heavy pack: stamina drain multiplier.
@export var daily_thirsty_water_mult: float = 2.0
@export var daily_heavy_pack_mult: float = 1.3
## Gusty day: gust strength (px/s) and seconds between gusts.
@export var daily_gust_strength: float = 105.0
@export var daily_gust_interval: Vector2 = Vector2(3.5, 6.0)

@export_group("First-time hints")
## How close (px) the hiker gets to a find or a fork sign before its hint shows.
@export var hint_near_px: float = 280.0
## How long a hint stays up, and the gap before the next one may show.
@export var hint_seconds: float = 4.5
## Water fraction that triggers the water hint; delay after the first checkpoint toast.
@export var hint_water_fraction: float = 0.6
@export var hint_back_delay: float = 2.6

@export_group("Terrain effects")
@export var mud_speed_mult: float = 0.6
@export var mud_drain_mult: float = 2.0
@export var ice_speed_mult: float = 0.85
@export var snow_speed_mult: float = 0.85
## On ice the hiker stops slowly, and slides back down uphill ice when not walking.
@export var ice_decel: float = 120.0
@export var ice_slip_speed: float = 45.0
## Missing a stepping stone: extra drain fraction and how long it lasts.
@export var wet_feet_drain_bonus: float = 0.2
@export var wet_feet_seconds: float = 10.0

@export_group("Daylight")
## Phase boundaries as a fraction of the trail's daylight_seconds. Dusk starts at 1.0.
@export var midday_start: float = 0.2
@export var golden_start: float = 0.6
## Fraction of daylight over which golden hour fades into dusk.
@export var dusk_fade: float = 0.12
@export var dusk_speed_mult: float = 0.7
@export var tint_morning: Color = Color("#FFE6D2")
@export var tint_midday: Color = Color("#FFFFFF")
@export var tint_golden: Color = Color("#FFDDB5")
@export var tint_dusk: Color = Color("#6C74A6")
## Night trails: the tint during the window, and after it closes.
@export var tint_night: Color = Color("#7E8BC4")
@export var tint_night_late: Color = Color("#4E5888")

@export_group("Feedback")
@export var stumble_vibrate_ms: int = 60
@export var fall_vibrate_ms: int = 120

@export_group("Photos")
## Shots on the film roll each time photo mode opens at a viewpoint.
@export var photo_shots_per_visit: int = 3
## Half the viewfinder height in viewport pixels; distances are measured against it.
@export var photo_frame_half: float = 190.0
## Subject distance from the frame centre (as a fraction of photo_frame_half) for each grade.
@export var photo_perfect_radius: float = 0.14
@export var photo_great_radius: float = 0.32
@export var photo_good_radius: float = 0.62
## Camera zoom while framing a shot.
@export var photo_zoom: float = 1.2

@export_group("Gear")
@export var gear_slots: int = 2

@export_group("Rewards")
## Trail Points (GAME_DESIGN §5.6): every finish, each star the first time it's
## earned, and photos by quality (only improvements on the best shot count).
@export var tp_finish: int = 50
@export var tp_per_new_star: int = 25
@export var tp_photo_good: int = 10
@export var tp_photo_great: int = 20
@export var tp_photo_perfect: int = 30

@export_group("Real steps")
## Steps from the phone's health app (GAME_DESIGN §5.10): a small TP bonus, never the main source.
@export var steps_per_tp: int = 500
@export var step_tp_daily_cap: int = 40
## Unclaimed days stay claimable this long (today counts as one).
@export var step_claim_window_days: int = 7
## For the "real km walked" stat and the km badges.
@export var step_length_m: float = 0.75

@export_group("Camera")
@export var camera_look_ahead_px: float = 220.0
## Keeps the hiker below the screen centre so the climb ahead is visible.
@export var camera_height_px: float = 110.0
@export var camera_smoothing_speed: float = 4.0
@export var camera_look_ahead_speed: float = 1.5
## Shake on a stumble / fall: peak offset (px) and how long it lasts.
@export var shake_stumble_px: float = 7.0
@export var shake_fall_px: float = 12.0
@export var shake_seconds: float = 0.3

@export_group("Flow")
## Seconds of steady walking per flow level, the top level, and speed per level.
@export var flow_step_seconds: float = 6.0
@export var flow_max_level: int = 5
@export var flow_speed_per_level: float = 0.025
## Standing still: seconds before flow starts draining, then seconds per level lost.
@export var flow_idle_grace: float = 1.2
@export var flow_decay_seconds: float = 1.5

@export_group("Wildlife moments")
## How many wildlife moments (flock, eagle, reindeer) a hike gets, at random spots.
@export var moments_min: int = 2
@export var moments_max: int = 3

@export_group("Ads")
## Rewarded ad on the results screen: share of the hike's TP it adds, and a floor.
@export var ad_reward_tp_mult: float = 0.5
@export var ad_reward_min_tp: int = 20
## Interstitials: at most one every N finished hikes, this many seconds apart, and none
## until the player has done this many hikes in total.
@export var ad_interstitial_every: int = 3
@export var ad_interstitial_min_seconds: float = 180.0
@export var ad_grace_hikes: int = 5
## Ask for a store review after this many different summits (once ever, after a first summit).
@export var review_after_summits: int = 3

@export_group("Summit moment")
## How long the summit moment lasts before the results (a tap skips it sooner).
@export var summit_seconds: float = 3.6
## Camera pull-back: zoom level, and how far back along the trail / up it frames.
@export var summit_zoom: float = 0.62
@export var summit_pull_px: float = 380.0
@export var summit_rise_px: float = 140.0

@export_group("Feel")
@export var jump_stretch: Vector2 = Vector2(0.85, 1.15)
@export var land_squash: Vector2 = Vector2(1.2, 0.8)
@export var squash_recover_rate: float = 12.0
@export var walk_bob_px: float = 2.5
## Leg and arm swing amplitude in the walk cycle (radians).
@export var walk_leg_swing: float = 0.5
@export var walk_arm_swing: float = 0.45
## How quickly limbs blend between poses (higher is snappier).
@export var pose_blend_rate: float = 14.0
## Body lean per unit of slope grade, and when stumbling or exhausted (radians, + leans forward).
@export var slope_lean: float = 0.12
@export var stumble_lean: float = 0.35
@export var exhausted_lean: float = 0.2
## Steps per second at full walk speed.
@export var walk_bob_hz: float = 2.2
## The mug hanging off the backpack: spring stiffness, damping, and how much the
## hiker's own acceleration (px/s²) swings it (radians per px/s²).
@export var mug_stiffness: float = 70.0
@export var mug_damping: float = 5.0
@export var mug_swing_per_accel: float = 0.0006
## Chance per footstep on rock (and on dirt) of kicking a loose pebble.
@export var pebble_chance_rock: float = 0.4
@export var pebble_chance_dirt: float = 0.08
@export var pebble_seconds: float = 2.5
## Footprints in snow and mud: how long they take to fade, and how many at once.
@export var footprint_seconds: float = 7.0
@export var footprint_max: int = 24
## Rest breathing: vertical scale wobble and breaths per second.
@export var rest_breath_amount: float = 0.025
@export var rest_breath_hz: float = 0.4
