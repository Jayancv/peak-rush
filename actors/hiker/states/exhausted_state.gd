class_name HikerExhaustedState
extends HikerState
## Stamina hit zero: a forced rest with no regen. Afterwards HikerCondition keeps the
## hiker at half speed until stamina is back above the recovery threshold.


func physics_update(delta: float) -> int:
	hiker.ground_stop(hiker.balance.walk_decel, delta)
	hiker.apply_gravity(delta)
	if hiker.state_time >= hiker.balance.exhausted_rest_seconds:
		return Hiker.State.REST
	return Hiker.STAY
