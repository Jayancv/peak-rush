class_name HikerIdleState
extends HikerState
## Just stopped (stamina already refills). After a short pause this becomes Rest.


func physics_update(delta: float) -> int:
	ground_stop(hiker.balance.walk_decel, delta)
	apply_gravity(delta)
	var common: int = grounded_transition()
	if common != Hiker.STAY:
		return common
	if hiker.wants_walk():
		return Hiker.State.WALK
	if hiker.state_time >= hiker.balance.rest_delay_seconds:
		return Hiker.State.REST
	return Hiker.STAY
