class_name Momentum
extends RefCounted
## Speed the hiker carries from going downhill: it builds on descents, fades on the
## flat, drains fast on climbs (so a run-up helps on a short rise) and is lost when
## the hiker stops. Kept in the air, so a jump off a descent goes further.

## Stopping sheds momentum this many times faster than walking on the flat.
const STOP_DECAY_MULT: float = 6.0
## Grades this close to zero count as flat (floor normals are never exactly level).
const FLAT_GRADE: float = 0.02

var bonus: float = 0.0

var _balance: Balance


func _init(balance: Balance) -> void:
	_balance = balance


## `grade` is signed (+ uphill). `grip` scales the build-up (mud and snow give less).
## Returns the bonus in px/s to add to the walk speed.
func update(delta: float, grade: float, walking: bool, on_floor: bool, grip: float = 1.0) -> float:
	if not on_floor:
		return bonus
	if not walking:
		bonus = maxf(bonus - _balance.momentum_decay * STOP_DECAY_MULT * delta, 0.0)
	elif grade < -FLAT_GRADE:
		bonus = minf(bonus - grade * _balance.momentum_gain_per_grade * grip * delta, _balance.momentum_max)
	else:
		bonus = maxf(bonus - (_balance.momentum_decay + maxf(grade, 0.0) * _balance.momentum_uphill_decay) * delta, 0.0)
	return bonus


func reset() -> void:
	bonus = 0.0

