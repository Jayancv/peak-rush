class_name Slope
extends RefCounted
## Turns the floor under the hiker into speed and stamina-drain multipliers.
## "Grade" is rise over run (tan of the slope angle): 0 is flat, 1 is 45°.
## It's signed relative to the walking direction: positive is uphill.

## Normals flatter than this (a wall or ceiling) are treated as a very steep climb
## instead of dividing by ~0.
const MIN_NORMAL_UP: float = 0.05
const WALL_GRADE: float = 20.0

var _balance: Balance


func _init(balance: Balance) -> void:
	_balance = balance


## Floor normal is in Godot's y-down space (flat ground is (0, -1)).
## direction is +1 walking right, -1 walking left.
static func signed_grade(floor_normal: Vector2, direction: float) -> float:
	var up: float = -floor_normal.y
	if up < MIN_NORMAL_UP:
		return WALL_GRADE
	# Ground rising to the right has a normal leaning left (x < 0).
	return -floor_normal.x / up * signf(direction)


func speed_factor(grade: float) -> float:
	if grade >= 0.0:
		return maxf(1.0 - _balance.uphill_speed_per_grade * grade, _balance.min_uphill_speed_mult)
	return 1.0 + minf(-grade * _balance.downhill_bonus_per_grade, _balance.max_downhill_bonus)


## Downhill doesn't refund stamina; it just costs the flat rate.
func drain_factor(grade: float) -> float:
	return 1.0 + _balance.uphill_drain_per_grade * maxf(grade, 0.0)
