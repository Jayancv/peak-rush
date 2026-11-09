class_name HikerExhaustedState
extends HikerState
## Stamina hit zero: a forced rest. M2 adds the slow walk afterwards (via speed_multiplier).


func physics_update(delta: float) -> int:
	hiker.stop_horizontal(hiker.balance.walk_decel, delta)
	hiker.apply_gravity(delta)
	if hiker.state_time >= hiker.balance.exhausted_rest_seconds:
		return Hiker.State.REST
	return Hiker.STAY
