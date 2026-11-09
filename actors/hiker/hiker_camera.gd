class_name HikerCamera
extends Camera2D
## Follows the hiker, looking ahead up the trail, clamped to the trail's bounds.

@export var target: CharacterBody2D

var _balance: Balance
## When set, the camera frames this point (photo mode) instead of following the target.
var _frame_point: Variant = null
var _zoom_tween: Tween


func _ready() -> void:
	_balance = ContentDB.balance
	# Follow on physics ticks so it moves in step with the (interpolated) hiker.
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = true
	position_smoothing_speed = _balance.camera_smoothing_speed
	limit_smoothed = true


func set_bounds(bounds: Rect2) -> void:
	limit_left = floori(bounds.position.x)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
	# Sky above is open, so there is no top limit.


## Jump straight to the target (on spawn) instead of gliding in from wherever we were.
func snap_to_target() -> void:
	if target == null:
		return
	offset = Vector2(_balance.camera_look_ahead_px, 0.0)
	global_position = _follow_point()
	reset_smoothing()
	reset_physics_interpolation()


## Glide to `point` and zoom in, e.g. to compose a photo.
func frame(point: Vector2, zoom_level: float) -> void:
	_frame_point = point
	_tween_zoom(zoom_level)


## Back to following the hiker.
func release_frame() -> void:
	_frame_point = null
	_tween_zoom(1.0)


func _tween_zoom(level: float) -> void:
	if _zoom_tween != null:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "zoom", Vector2(level, level), 0.45).set_trans(Tween.TRANS_SINE)


func _physics_process(delta: float) -> void:
	if _frame_point != null:
		offset = offset.lerp(Vector2.ZERO, 1.0 - exp(-_balance.camera_look_ahead_speed * 4.0 * delta))
		global_position = _frame_point
		return
	if target == null:
		return
	# Look further ahead while moving so the next obstacle comes into view in time.
	var moving: float = clampf(target.velocity.x / _balance.walk_speed, 0.0, 1.0)
	var ahead: float = _balance.camera_look_ahead_px * (0.5 + 0.5 * moving)
	offset.x = lerpf(offset.x, ahead, 1.0 - exp(-_balance.camera_look_ahead_speed * delta))
	global_position = _follow_point()


func _follow_point() -> Vector2:
	return target.global_position + Vector2(0.0, -_balance.camera_height_px)
