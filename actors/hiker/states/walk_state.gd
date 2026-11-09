class_name HikerWalkState
extends HikerState


func physics_update(delta: float) -> int:
	hiker.move_horizontal(hiker.walk_target_speed(), hiker.balance.walk_accel, delta)
	hiker.apply_gravity(delta)
	var common: int = hiker.grounded_transition()
	if common != Hiker.STAY:
		return common
	if not hiker.wants_walk():
		return Hiker.State.IDLE
	return Hiker.STAY
