class_name HikerCamera
extends Camera2D
## Follows the hiker, looking ahead up the trail, clamped to the trail's bounds.

@export var target: CharacterBody2D

var _balance: Balance
## When set, the camera frames this point (photo mode) instead of following the target.
var _frame_point: Variant = null
var _zoom_tween: Tween
## Look-ahead / framing offset; shake is added on top so it never drifts the view.
var _base_offset: Vector2 = Vector2.ZERO
var _shake_left: float = 0.0
var _shake_px: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


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
	_base_offset = Vector2(_balance.camera_look_ahead_px, 0.0)
	offset = _base_offset
	global_position = _follow_point()
	reset_smoothing()
	reset_physics_interpolation()


## A short decaying jolt (stumbles, falls).
func shake(strength_px: float) -> void:
	if UiMotion.reduced():
		return
	_shake_px = maxf(_shake_px if _shake_left > 0.0 else 0.0, strength_px)
	_shake_left = _balance.shake_seconds


func is_shaking() -> bool:
	return _shake_left > 0.0


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
	_apply_shake(delta)
	if _frame_point != null:
		_base_offset = _base_offset.lerp(Vector2.ZERO, 1.0 - exp(-_balance.camera_look_ahead_speed * 4.0 * delta))
		global_position = _frame_point
		return
	if target == null:
		return
	# Look further ahead while moving so the next obstacle comes into view in time.
	var moving: float = clampf(target.velocity.x / _balance.walk_speed, 0.0, 1.0)
	var ahead: float = _balance.camera_look_ahead_px * (0.5 + 0.5 * moving)
	_base_offset.x = lerpf(_base_offset.x, ahead, 1.0 - exp(-_balance.camera_look_ahead_speed * delta))
	global_position = _follow_point()


func _apply_shake(delta: float) -> void:
	var jitter: Vector2 = Vector2.ZERO
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		var k: float = _shake_left / _balance.shake_seconds
		jitter = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _shake_px * k
	offset = _base_offset + jitter


func _follow_point() -> Vector2:
	return target.global_position + Vector2(0.0, -_balance.camera_height_px)
