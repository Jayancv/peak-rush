class_name HikerActions
extends RefCounted
## The hiker's extra moves, kept out of hiker.gd: hurrying (double-tapped walk), ducking
## (crouch-walk under low branches) and climbing ladders/scrambles. Hiker updates this every
## physics tick and folds its speed and energy multipliers into walking and stamina.

var hurrying: bool = false
var crouching: bool = false
## The Ladder the hiker is standing at (set by the ladder piece), or null.
var ladder: Ladder = null


func update(hiker: Hiker, input: HikerInput, allowed: bool) -> void:
	var on_foot: bool = hiker.is_on_floor() and hiker.state in [Hiker.State.IDLE, Hiker.State.WALK, Hiker.State.REST]
	hurrying = input.hurrying and on_foot and hiker.state == Hiker.State.WALK and hiker.facing > 0.0 \
		and not hiker.condition.stamina.recovering
	crouching = input.wants_duck(allowed) and on_foot


func speed_mult(balance: Balance) -> float:
	if crouching:
		return balance.crouch_speed_mult
	return balance.hurry_speed_mult if hurrying else 1.0


## Extra stamina cost of what the hiker is doing (1 = a normal walk).
func effort_mult(state: Hiker.State, balance: Balance) -> float:
	if state == Hiker.State.CLIMB:
		return balance.climb_drain_mult
	return balance.hurry_drain_mult if hurrying else 1.0


## At a ladder, pushing on towards the summit, with the top still above.
func can_climb(hiker: Hiker, input: HikerInput, allowed: bool) -> bool:
	return ladder != null and hiker.facing > 0.0 and input.wants_walk(allowed) \
		and hiker.global_position.y > ladder.top_y() + 8.0


## +1 climbing up, -1 climbing down, 0 clinging.
func climb_direction(input: HikerInput, allowed: bool) -> int:
	if input.wants_walk(allowed):
		return 1
	return -1 if input.wants_back(allowed) else 0
