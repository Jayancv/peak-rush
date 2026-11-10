class_name HikerWalkState
extends HikerState


func physics_update(delta: float) -> int:
	move_horizontal(hiker.walk_target_speed(), hiker.balance.walk_accel, delta)
	apply_gravity(delta)
	var common: int = grounded_transition()
	if common != Hiker.STAY:
		return common
	if hiker.can_slide():
		return Hiker.State.SLIDE
	if not hiker.wants_walk():
		return Hiker.State.IDLE
	return Hiker.STAY
