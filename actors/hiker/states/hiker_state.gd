class_name HikerState
extends RefCounted
## One state of the hiker's state machine. States set velocity and pick the next
## state; Hiker owns move_and_slide() and the shared movement helpers.

var hiker: Hiker


func _init(owner_hiker: Hiker) -> void:
	hiker = owner_hiker


func enter() -> void:
	pass


func exit() -> void:
	pass


## Returns the next Hiker.State, or Hiker.STAY to remain in this one.
func physics_update(_delta: float) -> int:
	return Hiker.STAY


# --- Shared movement (used by several states) ---

## Shared exits from the on-foot states: jumping, or walking off an edge.
func grounded_transition() -> int:
	if hiker.has_buffered_jump() and hiker.coyote_left() > 0.0:
		return Hiker.State.JUMP
	if not hiker.is_on_floor() and hiker.coyote_left() <= 0.0:
		return Hiker.State.FALL
	return Hiker.STAY


func move_horizontal(target: float, accel: float, delta: float) -> void:
	hiker.velocity.x = move_toward(hiker.velocity.x, target, accel * delta)


func stop_horizontal(decel: float, delta: float) -> void:
	hiker.velocity.x = move_toward(hiker.velocity.x, 0.0, decel * delta)


## Standing still: stops quickly on grip, slides on ice (and back down uphill ice).
func ground_stop(decel: float, delta: float) -> void:
	if hiker.is_on_floor() and HikeModifiers.is_slippery(hiker.effective_surface()):
		# Grip boots shrink both the slide back and the long stop.
		var grip: float = hiker.condition.modifiers.gear.slip_scale
		var slide: float = -hiker.balance.ice_slip_speed * grip * hiker.facing if hiker.signed_grade > 0.05 else 0.0
		move_horizontal(slide, lerpf(decel, hiker.balance.ice_decel, grip), delta)
	else:
		stop_horizontal(decel, delta)


func air_control(delta: float) -> void:
	if hiker.wants_walk():
		move_horizontal(hiker.walk_target_speed(hiker.balance.air_wind_scale), hiker.balance.air_accel, delta)
	else:
		move_horizontal(hiker.condition.wind_push * hiker.balance.air_wind_scale, hiker.balance.air_decel, delta)


func apply_gravity(delta: float) -> void:
	if not hiker.is_on_floor():
		hiker.velocity.y = minf(hiker.velocity.y + hiker.balance.gravity * delta, hiker.balance.max_fall_speed)
