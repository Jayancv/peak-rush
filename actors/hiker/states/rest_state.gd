class_name HikerRestState
extends HikerState
## Standing still on purpose. M2 hooks stamina regen to this state.


func physics_update(delta: float) -> int:
	hiker.stop_horizontal(hiker.balance.walk_decel, delta)
	hiker.apply_gravity(delta)
	var common: int = hiker.grounded_transition()
	if common != Hiker.STAY:
		return common
	if hiker.wants_walk():
		return Hiker.State.WALK
	return Hiker.STAY
