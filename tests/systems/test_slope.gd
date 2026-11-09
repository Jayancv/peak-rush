extends GutTest

const FLAT: Vector2 = Vector2(0.0, -1.0)

var slope: Slope


func before_each() -> void:
	slope = Slope.new(Balance.new())


## Floor normal for ground that rises `grade` (rise over run) towards +x.
func _normal_rising_right(grade: float) -> Vector2:
	return Vector2(-grade, -1.0).normalized()


func test_flat_ground_has_zero_grade() -> void:
	assert_almost_eq(Slope.signed_grade(FLAT, 1.0), 0.0, 0.0001)


func test_ground_rising_right_is_uphill_when_walking_right() -> void:
	assert_almost_eq(Slope.signed_grade(_normal_rising_right(0.5), 1.0), 0.5, 0.0001)


func test_same_slope_is_downhill_when_walking_left() -> void:
	assert_almost_eq(Slope.signed_grade(_normal_rising_right(0.5), -1.0), -0.5, 0.0001)


func test_45_degrees_is_grade_one() -> void:
	var normal: Vector2 = Vector2.UP.rotated(deg_to_rad(-45.0))
	assert_almost_eq(Slope.signed_grade(normal, 1.0), 1.0, 0.0001)


func test_wall_normal_does_not_divide_by_zero() -> void:
	assert_eq(Slope.signed_grade(Vector2(-1.0, 0.0), 1.0), Slope.WALL_GRADE)


func test_flat_speed_is_full() -> void:
	assert_almost_eq(slope.speed_factor(0.0), 1.0, 0.0001)


func test_uphill_speed_follows_design_formula() -> void:
	# GAME_DESIGN §5.1: 1 − 0.5 × grade
	assert_almost_eq(slope.speed_factor(0.4), 0.8, 0.0001)


func test_uphill_speed_never_below_half() -> void:
	assert_almost_eq(slope.speed_factor(1.0), 0.5, 0.0001)
	assert_almost_eq(slope.speed_factor(3.0), 0.5, 0.0001)


func test_downhill_gives_bonus_capped_at_15_percent() -> void:
	assert_almost_eq(slope.speed_factor(-0.2), 1.06, 0.0001)
	assert_almost_eq(slope.speed_factor(-2.0), 1.15, 0.0001)


func test_drain_factor_uphill() -> void:
	# GAME_DESIGN §5.2: 1 + 2 × uphill_grade
	assert_almost_eq(slope.drain_factor(0.5), 2.0, 0.0001)


func test_drain_factor_flat_and_downhill_is_one() -> void:
	assert_almost_eq(slope.drain_factor(0.0), 1.0, 0.0001)
	assert_almost_eq(slope.drain_factor(-0.7), 1.0, 0.0001)


func test_uses_balance_values() -> void:
	var b: Balance = Balance.new()
	b.uphill_speed_per_grade = 0.25
	assert_almost_eq(Slope.new(b).speed_factor(1.0), 0.75, 0.0001)
