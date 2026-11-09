class_name HikerStumbleState
extends HikerState
## Tripped on a root: a short forced stop. Input is ignored until it ends.


func physics_update(delta: float) -> int:
	hiker.stop_horizontal(hiker.balance.walk_decel * 2.0, delta)
	hiker.apply_gravity(delta)
	if hiker.state_time >= hiker.balance.stumble_seconds:
		return Hiker.State.IDLE
	return Hiker.STAY
