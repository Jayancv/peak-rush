extends GutTest

var balance: Balance
var day: Daylight


func before_each() -> void:
	balance = Balance.new()
	day = Daylight.new(balance, 100.0)


func test_starts_in_the_morning() -> void:
	assert_eq(day.phase(), Daylight.Phase.MORNING)
	assert_false(day.is_dusk())


func test_phases_follow_balance_fractions() -> void:
	day.advance(25.0)
	assert_eq(day.phase(), Daylight.Phase.MIDDAY)
	day.advance(40.0)
	assert_eq(day.phase(), Daylight.Phase.GOLDEN)
	day.advance(35.0)
	assert_eq(day.phase(), Daylight.Phase.DUSK)
	assert_true(day.is_dusk())


func test_phase_changed_fires_once_per_phase() -> void:
	watch_signals(day)
	for i: int in 120:
		day.advance(1.0)
	assert_signal_emit_count(day, "phase_changed", 3)


func test_sun_progress_clamps_after_dusk() -> void:
	day.advance(50.0)
	assert_almost_eq(day.sun_progress(), 0.5, 0.0001)
	day.advance(500.0)
	assert_eq(day.sun_progress(), 1.0)


func test_tint_is_clear_at_midday() -> void:
	day.advance(40.0)
	assert_true(day.tint().is_equal_approx(balance.tint_midday))


func test_tint_starts_warm_and_ends_at_dusk_colour() -> void:
	assert_true(day.tint().is_equal_approx(balance.tint_morning))
	day.advance(100.0)
	assert_true(day.tint().is_equal_approx(balance.tint_dusk))


func test_tint_blends_through_golden_hour() -> void:
	day.advance(85.0)
	var t: Color = day.tint()
	assert_ne(t, balance.tint_midday)
	assert_ne(t, balance.tint_dusk)
	assert_lt(t.b, 1.0, "golden hour is warmer (less blue) than midday")


func test_zero_daylight_is_guarded() -> void:
	var odd: Daylight = Daylight.new(balance, 0.0)
	odd.advance(0.5)
	assert_false(odd.is_dusk())
