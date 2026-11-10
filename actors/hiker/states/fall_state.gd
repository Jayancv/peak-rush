class_name HikerFallState
extends HikerState
## Airborne and going down: after a jump's peak or after walking off an edge.


func physics_update(delta: float) -> int:
	air_control(delta)
	apply_gravity(delta)
	if hiker.is_on_floor():
		# A jump pressed just before touching down fires straight away.
		if hiker.has_buffered_jump():
			return Hiker.State.JUMP
		return Hiker.State.WALK if hiker.wants_walk() else Hiker.State.IDLE
	return Hiker.STAY
