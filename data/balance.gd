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

@export_group("Camera")
@export var camera_look_ahead_px: float = 220.0
## Keeps the hiker below the screen centre so the climb ahead is visible.
@export var camera_height_px: float = 110.0
@export var camera_smoothing_speed: float = 4.0
@export var camera_look_ahead_speed: float = 1.5

@export_group("Feel")
@export var jump_stretch: Vector2 = Vector2(0.85, 1.15)
@export var land_squash: Vector2 = Vector2(1.2, 0.8)
@export var squash_recover_rate: float = 12.0
@export var walk_bob_px: float = 3.0
## Steps per second at full walk speed.
@export var walk_bob_hz: float = 2.2
## Rest breathing: vertical scale wobble and breaths per second.
@export var rest_breath_amount: float = 0.025
@export var rest_breath_hz: float = 0.4
