extends GutTest
## Momentum: builds downhill, fades on the flat, drains uphill, stops dead when standing.

var _b: Balance
var _m: Momentum


func before_each() -> void:
	_b = Balance.new()
	_m = Momentum.new(_b)


func _run(seconds: float, grade: float, walking: bool = true, on_floor: bool = true, grip: float = 1.0) -> void:
	var t: float = 0.0
	while t < seconds:
		_m.update(1.0 / 60.0, grade, walking, on_floor, grip)
		t += 1.0 / 60.0


func test_builds_downhill_up_to_the_cap() -> void:
	_run(0.5, -0.4)
	assert_gt(_m.bonus, 0.0)
	_run(10.0, -0.4)
	assert_almost_eq(_m.bonus, _b.momentum_max, 0.01)


func test_steeper_descents_build_faster() -> void:
	_run(0.3, -0.2)
	var gentle: float = _m.bonus
	_m.reset()
	_run(0.3, -0.6)
	assert_gt(_m.bonus, gentle)


func test_fades_on_the_flat_and_drains_faster_uphill() -> void:
	_run(10.0, -0.5)
	_run(0.5, 0.0)
	var after_flat: float = _m.bonus
	assert_lt(after_flat, _b.momentum_max)
	_m.bonus = _b.momentum_max
	_run(0.5, 0.4)
	assert_lt(_m.bonus, after_flat, "climbing eats momentum faster than flat ground")


func test_kept_in_the_air_and_lost_when_stopping() -> void:
	_run(10.0, -0.5)
	_run(0.5, 0.0, true, false)
	assert_almost_eq(_m.bonus, _b.momentum_max, 0.01, "airborne keeps it")
	_run(1.0, 0.0, false)
	assert_eq(_m.bonus, 0.0, "standing still drops it")


func test_grip_reduces_build_up() -> void:
	_run(0.3, -0.4, true, true, 0.5)
	var muddy: float = _m.bonus
	_m.reset()
	_run(0.3, -0.4)
	assert_gt(_m.bonus, muddy)


func test_near_level_ground_counts_as_flat() -> void:
	_run(2.0, -0.01)
	assert_eq(_m.bonus, 0.0)
