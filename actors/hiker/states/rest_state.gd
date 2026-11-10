class_name HikerRestState
extends HikerState
## Standing still on purpose; stamina refills (faster at a bench).


func physics_update(delta: float) -> int:
	ground_stop(hiker.balance.walk_decel, delta)
	apply_gravity(delta)
	var common: int = grounded_transition()
	if common != Hiker.STAY:
		return common
	if hiker.wants_walk():
		return Hiker.State.WALK
	return Hiker.STAY
