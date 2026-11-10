extends GutTest
## Water bottle: drains while walking, refills at springs, thirsty when empty.

var _b: Balance
var _h: Hydration


func before_each() -> void:
	_b = Balance.new()
	_h = Hydration.new(_b)


func _run(seconds: float, walking: bool, refilling: bool) -> void:
	var t: float = 0.0
	while t < seconds:
		_h.tick(0.1, walking, refilling)
		t += 0.1


func test_starts_full_and_drains_only_while_walking() -> void:
	assert_eq(_h.value, _b.water_max)
	_run(5.0, false, false)
	assert_eq(_h.value, _b.water_max, "standing still doesn't drink")
	_run(10.0, true, false)
	assert_almost_eq(_h.value, _b.water_max - _b.water_drain * 10.0, 0.5)


func test_empty_bottle_makes_you_thirsty_and_tired() -> void:
	watch_signals(_h)
	_run(_b.water_max / _b.water_drain + 2.0, true, false)
	assert_true(_h.is_thirsty())
	assert_signal_emitted_with_parameters(_h, "thirst_changed", [true])
	assert_eq(_h.drain_multiplier(), _b.thirsty_drain_mult)
	assert_eq(_h.regen_multiplier(), _b.thirsty_regen_mult)


func test_spring_refills_and_ends_thirst() -> void:
	_run(_b.water_max / _b.water_drain + 2.0, true, false)
	_run(1.0, false, true)
	assert_false(_h.is_thirsty())
	assert_almost_eq(_h.value, minf(_b.water_refill * 1.0, _b.water_max), _b.water_refill * 0.15)
	_run(10.0, false, true)
	assert_eq(_h.value, _b.water_max, "never overfills")
	assert_eq(_h.drain_multiplier(), 1.0)
