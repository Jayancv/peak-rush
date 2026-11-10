class_name Hydration
extends RefCounted
## The hiker's water bottle. Walking drinks from it; standing in a spring or a stream
## refills it. An empty bottle means thirsty: walking tires faster and resting
## refills stamina more slowly (multipliers from Balance).

signal changed(value: float, max_value: float)
signal thirst_changed(thirsty: bool)

var value: float
var max_value: float

var _balance: Balance
var _thirsty: bool = false


func _init(balance: Balance) -> void:
	_balance = balance
	max_value = balance.water_max
	value = max_value


func tick(delta: float, walking: bool, refilling: bool) -> void:
	var before: float = value
	if refilling:
		value = minf(value + _balance.water_refill * delta, max_value)
	elif walking:
		value = maxf(value - _balance.water_drain * delta, 0.0)
	if not is_equal_approx(before, value):
		changed.emit(value, max_value)
	var now_thirsty: bool = value <= 0.0
	if now_thirsty != _thirsty:
		_thirsty = now_thirsty
		thirst_changed.emit(_thirsty)


func is_thirsty() -> bool:
	return _thirsty


func fraction() -> float:
	return value / max_value if max_value > 0.0 else 0.0


## Stamina drain multiplier while walking.
func drain_multiplier() -> float:
	return _balance.thirsty_drain_mult if _thirsty else 1.0


## Stamina regen multiplier while resting.
func regen_multiplier() -> float:
	return _balance.thirsty_regen_mult if _thirsty else 1.0
