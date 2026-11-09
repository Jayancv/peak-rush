class_name Stamina
extends RefCounted
## The hiker's energy (0..max). Walking drains it, standing still refills it.
## Hitting 0 exhausts the hiker; they stay slow ("recovering") until stamina climbs
## back above the recovery threshold, so running dry always costs real time.

signal changed(value: float, max_value: float)
signal exhausted
signal recovered

var value: float
var max_value: float
## True from the moment stamina hits 0 until it's back above the threshold.
var recovering: bool = false

var _balance: Balance


func _init(balance: Balance) -> void:
	_balance = balance
	max_value = balance.max_stamina
	value = max_value


## Drain per second while walking; `multiplier` combines slope, terrain, weather and gear.
func drain_rate(multiplier: float) -> float:
	return _balance.walk_drain * multiplier


func walk(delta: float, multiplier: float) -> void:
	_set_value(value - drain_rate(multiplier) * delta)


func rest(delta: float, on_bench: bool) -> void:
	var rate: float = _balance.bench_regen if on_bench else _balance.rest_regen
	_set_value(value + rate * delta)


## One-off costs: stumbling, falling.
func spend(amount: float) -> void:
	_set_value(value - amount)


func refill() -> void:
	recovering = false
	_set_value(max_value)


func fraction() -> float:
	return value / max_value


func is_low() -> bool:
	return fraction() < _balance.low_stamina_fraction


## Walk speed multiplier from tiredness alone.
func speed_multiplier() -> float:
	return _balance.exhausted_speed_mult if recovering else 1.0


func _set_value(new_value: float) -> void:
	var old: float = value
	value = clampf(new_value, 0.0, max_value)
	if is_equal_approx(old, value):
		return
	changed.emit(value, max_value)
	if value <= 0.0 and not recovering:
		recovering = true
		exhausted.emit()
	elif recovering and value > _balance.recovery_threshold:
		recovering = false
		recovered.emit()
