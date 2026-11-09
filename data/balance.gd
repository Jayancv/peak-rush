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

@export_group("Jumping")
@export var gravity: float = 1600.0
## Initial upward speed. Jump height ≈ jump_velocity² / (2 × gravity).
@export var jump_velocity: float = 540.0
@export var max_fall_speed: float = 1400.0
## Horizontal acceleration in the air while walk is held, and drag while it isn't.
@export var air_accel: float = 400.0
@export var air_decel: float = 150.0
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

@export_group("Rewards")
## Trail Points (GAME_DESIGN §5.6): every finish, each star the first time it's
## earned, and photos by quality (only improvements on the best shot count).
@export var tp_finish: int = 50
@export var tp_per_new_star: int = 25
@export var tp_photo_good: int = 10
@export var tp_photo_great: int = 20
@export var tp_photo_perfect: int = 30

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
## Rest breathing: vertical scale wobble and breaths per second.
@export var rest_breath_amount: float = 0.025
@export var rest_breath_hz: float = 0.4
