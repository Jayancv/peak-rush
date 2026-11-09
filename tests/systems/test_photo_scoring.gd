extends GutTest

const CENTER: Vector2 = Vector2(640, 360)

var balance: Balance
var scoring: PhotoScoring


func before_each() -> void:
	balance = Balance.new()
	scoring = PhotoScoring.new(balance)


## A point `fraction` of the frame's half height away from the centre.
func _at(fraction: float) -> Vector2:
	return CENTER + Vector2(0, balance.photo_frame_half * fraction)


func test_offset_is_relative_to_frame_half_height() -> void:
	assert_almost_eq(scoring.normalized_offset(_at(0.5), CENTER), 0.5, 0.0001)
	assert_almost_eq(scoring.normalized_offset(CENTER, CENTER), 0.0, 0.0001)


func test_grades_by_distance() -> void:
	assert_eq(scoring.quality_for(0.0), StarRating.PhotoQuality.PERFECT)
	assert_eq(scoring.quality_for(balance.photo_perfect_radius), StarRating.PhotoQuality.PERFECT)
	assert_eq(scoring.quality_for(balance.photo_perfect_radius + 0.01), StarRating.PhotoQuality.GREAT)
	assert_eq(scoring.quality_for(balance.photo_great_radius + 0.01), StarRating.PhotoQuality.GOOD)
	assert_eq(scoring.quality_for(balance.photo_good_radius + 0.01), StarRating.PhotoQuality.NONE)


func test_subject_out_of_frame_misses() -> void:
	assert_eq(scoring.shoot(CENTER + Vector2(900, 0), CENTER), StarRating.PhotoQuality.NONE)


func test_roll_has_limited_film() -> void:
	for i: int in balance.photo_shots_per_visit:
		assert_true(scoring.has_film())
		scoring.shoot(CENTER, CENTER)
	assert_false(scoring.has_film())
	assert_eq(scoring.shoot(CENTER, CENTER), StarRating.PhotoQuality.NONE, "no film, no photo")


func test_best_shot_is_kept() -> void:
	scoring.shoot(_at(0.5), CENTER)
	scoring.shoot(_at(0.05), CENTER)
	scoring.shoot(_at(0.9), CENTER)
	assert_eq(scoring.best, StarRating.PhotoQuality.PERFECT)
