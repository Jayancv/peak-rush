extends GutTest

var balance: Balance
var stamina: Stamina


func before_each() -> void:
	balance = Balance.new()
	stamina = Stamina.new(balance)


func test_starts_full() -> void:
	assert_eq(stamina.value, 100.0)
	assert_false(stamina.recovering)


func test_walking_drains_4_per_second_on_flat() -> void:
	stamina.walk(1.0, 1.0)
	assert_almost_eq(stamina.value, 96.0, 0.001)


func test_drain_scales_with_multiplier() -> void:
	# Grade 0.5 uphill = slope factor 2 (GAME_DESIGN §5.2).
	stamina.walk(1.0, 2.0)
	assert_almost_eq(stamina.value, 92.0, 0.001)


func test_rest_regens_15_per_second() -> void:
	stamina.spend(50.0)
	stamina.rest(1.0, false)
	assert_almost_eq(stamina.value, 65.0, 0.001)


func test_bench_regens_30_per_second() -> void:
	stamina.spend(50.0)
	stamina.rest(1.0, true)
	assert_almost_eq(stamina.value, 80.0, 0.001)


func test_never_above_max_or_below_zero() -> void:
	stamina.rest(10.0, true)
	assert_eq(stamina.value, 100.0)
	stamina.spend(500.0)
	assert_eq(stamina.value, 0.0)


func test_hitting_zero_exhausts_once() -> void:
	watch_signals(stamina)
	stamina.spend(100.0)
	stamina.walk(1.0, 1.0)
	assert_signal_emit_count(stamina, "exhausted", 1)
	assert_true(stamina.recovering)


func test_recovering_halves_speed_until_above_threshold() -> void:
	stamina.spend(100.0)
	assert_eq(stamina.speed_multiplier(), 0.5)
	stamina.rest(2.0, false)  # 30: still not *above* the threshold
	assert_true(stamina.recovering)
	watch_signals(stamina)
	stamina.rest(0.1, false)
	assert_false(stamina.recovering)
	assert_signal_emitted(stamina, "recovered")
	assert_eq(stamina.speed_multiplier(), 1.0)


func test_spend_reports_change() -> void:
	watch_signals(stamina)
	stamina.spend(10.0)
	assert_signal_emitted_with_parameters(stamina, "changed", [90.0, 100.0])


func test_low_below_quarter() -> void:
	stamina.spend(74.0)
	assert_false(stamina.is_low())
	stamina.spend(2.0)
	assert_true(stamina.is_low())
