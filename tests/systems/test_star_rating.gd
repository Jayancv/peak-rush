extends GutTest

const GOOD: int = StarRating.PhotoQuality.GOOD
const GREAT: int = StarRating.PhotoQuality.GREAT
const PERFECT: int = StarRating.PhotoQuality.PERFECT

var rating: StarRating


func before_each() -> void:
	rating = StarRating.new(Balance.new())


func _result(finished: bool, before_dusk: bool, total: int = 0, photos: Dictionary = {}) -> TrailResult:
	var r: TrailResult = TrailResult.new(&"t")
	r.finished = finished
	r.before_dusk = before_dusk
	r.viewpoint_total = total
	r.photos = photos
	return r


func test_unfinished_earns_nothing() -> void:
	var r: TrailResult = _result(false, true)
	assert_eq(StarRating.stars_mask(r), 0)
	assert_eq(rating.award(r, 0, {}).total, 0)


func test_summit_only_after_dusk_with_missing_photos() -> void:
	var mask: int = StarRating.stars_mask(_result(true, false, 2, {"a": GOOD}))
	assert_eq(mask, StarRating.STAR_SUMMIT)


func test_all_three_stars() -> void:
	var mask: int = StarRating.stars_mask(_result(true, true, 2, {"a": GOOD, "b": PERFECT}))
	assert_eq(mask, StarRating.ALL_STARS)
	assert_eq(StarRating.count(mask), 3)


func test_trail_without_viewpoints_grants_photo_star() -> void:
	assert_true(StarRating.stars_mask(_result(true, false, 0)) & StarRating.STAR_PHOTOS != 0)


func test_first_clear_pays_finish_and_new_stars() -> void:
	# GAME_DESIGN §5.6: 50 + 25 per star the first time.
	var award: Dictionary = rating.award(_result(true, true, 0), 0, {})
	assert_eq(award.finish, 50)
	assert_eq(award.stars, 75)
	assert_eq(award.total, 125)


func test_replay_only_pays_finish_and_genuinely_new_stars() -> void:
	var award: Dictionary = rating.award(_result(true, true, 0), StarRating.STAR_SUMMIT | StarRating.STAR_PHOTOS, {})
	assert_eq(award.stars, 25, "only the dusk star is new")
	assert_eq(award.new_stars_mask, StarRating.STAR_BEFORE_DUSK)
	assert_eq(award.total, 75)


func test_photos_pay_by_quality() -> void:
	var award: Dictionary = rating.award(_result(true, false, 3, {"a": GOOD, "b": GREAT, "c": PERFECT}), 0, {})
	assert_eq(award.photos, 60)


func test_photos_only_pay_the_improvement() -> void:
	var previous: Dictionary = {"a": GOOD, "b": PERFECT}
	var award: Dictionary = rating.award(_result(true, false, 2, {"a": PERFECT, "b": GOOD}), 0, previous)
	assert_eq(award.photos, 20, "a: good -> perfect = +20; b got worse = 0")
