class_name HikerJumpState
extends HikerState
## Rising part of a jump. Turns into Fall at the top of the arc.


func enter() -> void:
	hiker.start_jump()


func physics_update(delta: float) -> int:
	air_control(delta)
	apply_jump_gravity(delta)
	if hiker.velocity.y >= 0.0 or hiker.is_on_ceiling():
		return Hiker.State.FALL
	return Hiker.STAY
