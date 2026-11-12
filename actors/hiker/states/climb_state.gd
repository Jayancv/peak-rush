class_name HikerClimbState
extends HikerState
## On a ladder or rock scramble: walk climbs up, back climbs down, letting go clings.
## At the top the hiker hops forward onto the ledge.


func enter() -> void:
	hiker.velocity = Vector2.ZERO
	hiker.condition.flow.break_flow()


func physics_update(_delta: float) -> int:
	var ladder: Ladder = hiker.actions.ladder
	if ladder == null:
		return Hiker.State.FALL
	var b: Balance = hiker.balance
	var speed: float = b.climb_speed * (0.6 if hiker.condition.stamina.recovering else 1.0)
	# Stay on the rungs (works against a wall or on a free-standing lookout ladder).
	var hold_x: float = clampf((ladder.global_position.x - 6.0 - hiker.global_position.x) * 10.0, -60.0, 60.0)
	match hiker.climb_direction():
		1:
			hiker.velocity = Vector2(hold_x, -speed)
		-1:
			hiker.velocity = Vector2(hold_x, speed)
			if hiker.is_on_floor() and hiker.global_position.y >= ladder.global_position.y - 2.0:
				return Hiker.State.IDLE
		_:
			hiker.velocity = Vector2(hold_x, 0.0)
	if hiker.global_position.y <= ladder.top_y() + 4.0:
		hiker.velocity = Vector2(b.climb_top_hop.x, -b.climb_top_hop.y)
		return Hiker.State.FALL
	return Hiker.STAY
