class_name Flow
extends RefCounted
## Steady hiking builds "flow": every Balance.flow_step_seconds of walking without a
## stumble adds a level (up to flow_max_level), each worth a little extra speed.
## A stumble or a fall breaks it; standing still lets it drain away one level at a time
## (after a short grace, so pausing for a jump or a photo isn't punished).

signal level_changed(level: int)

var level: int = 0

var _balance: Balance
var _walked: float = 0.0
var _idle: float = 0.0


func _init(balance: Balance) -> void:
	_balance = balance


func tick(delta: float, walking: bool) -> void:
	if walking:
		_idle = 0.0
		_walked += delta
		if _walked >= _balance.flow_step_seconds:
			_walked = 0.0
			_set_level(level + 1)
		return
	_idle += delta
	if _idle >= _balance.flow_idle_grace + _balance.flow_decay_seconds:
		# Grace used up: drop a level every flow_decay_seconds.
		_idle = _balance.flow_idle_grace
		_walked = 0.0
		_set_level(level - 1)


## A stumble or a fall: flow is gone.
func break_flow() -> void:
	_walked = 0.0
	_set_level(0)


func speed_multiplier() -> float:
	return 1.0 + _balance.flow_speed_per_level * level


func is_max() -> bool:
	return level >= _balance.flow_max_level


func _set_level(value: int) -> void:
	value = clampi(value, 0, _balance.flow_max_level)
	if value != level:
		level = value
		level_changed.emit(level)
