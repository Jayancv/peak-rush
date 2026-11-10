class_name HikerSlideState
extends HikerState
## Sliding down a steep snowy slope (inside a SnowSlide zone): no stamina is used and
## speed builds with the steepness; on the run-out it brakes back to walking pace.
## Jumping still works.


func physics_update(delta: float) -> int:
	var b: Balance = hiker.balance
	if hiker.signed_grade < 0.0:
		hiker.velocity.x = minf(hiker.velocity.x - hiker.signed_grade * b.slide_accel_per_grade * delta, b.slide_max_speed)
	else:
		hiker.velocity.x = maxf(hiker.velocity.x - b.slide_brake * delta, 0.0)
	apply_gravity(delta)
	var common: int = grounded_transition()
	if common != Hiker.STAY:
		return common
	var slowed: bool = hiker.velocity.x <= hiker.balance.walk_speed and hiker.signed_grade > -b.slide_min_grade * 0.5
	if not hiker.in_slide_zone() or slowed:
		return Hiker.State.WALK if hiker.wants_walk() else Hiker.State.IDLE
	return Hiker.STAY
