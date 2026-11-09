class_name HikerIdleState
extends HikerState
## Just stopped. After a short pause this becomes Rest (where stamina will refill in M2).


func physics_update(delta: float) -> int:
	hiker.stop_horizontal(hiker.balance.walk_decel, delta)
	hiker.apply_gravity(delta)
	var common: int = hiker.grounded_transition()
	if common != Hiker.STAY:
		return common
	if hiker.wants_walk():
		return Hiker.State.WALK
	if hiker.state_time >= hiker.balance.rest_delay_seconds:
		return Hiker.State.REST
	return Hiker.STAY
