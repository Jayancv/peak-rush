extends GutTest
## GameState is global, so each test snapshots it and puts it back.

var _saved: Dictionary
var _t1: TrailData
var _t2: TrailData


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()
	_t1 = ContentDB.get_trail(&"t01_forest_lake")
	_t2 = ContentDB.get_trail(&"t02_archipelago_rocks")


func after_each() -> void:
	GameState.from_dict(_saved)


## Finishes `trail`, photographing every viewpoint at `quality` (NONE = no photos).
func _finish(trail: TrailData, time: float, before_dusk: bool = true, quality: int = StarRating.PhotoQuality.GOOD) -> Dictionary:
	var r: TrailResult = TrailResult.new(trail.id)
	r.finished = true
	r.time_seconds = time
	r.before_dusk = before_dusk
	r.viewpoint_total = trail.viewpoints.size()
	if quality > StarRating.PhotoQuality.NONE:
		for vp: ViewpointData in trail.viewpoints:
			r.photos[String(vp.id)] = quality
	return GameState.record_result(r)


func test_first_trail_open_second_locked() -> void:
	assert_true(GameState.is_unlocked(_t1))
	assert_false(GameState.is_unlocked(_t2))


func test_finishing_unlocks_the_next_trail() -> void:
	_finish(_t1, 80.0)
	assert_true(GameState.is_completed(_t1.id))
	assert_true(GameState.is_unlocked(_t2))


func test_tp_accumulates_and_stars_merge() -> void:
	_finish(_t1, 90.0, false)
	assert_eq(GameState.stars_mask(_t1.id), StarRating.STAR_SUMMIT | StarRating.STAR_PHOTOS)
	var tp_after_first: int = GameState.tp
	var photo_tp: int = _t1.viewpoints.size() * ContentDB.balance.tp_photo_good
	assert_eq(tp_after_first, 50 + 50 + photo_tp)
	_finish(_t1, 95.0, true)
	assert_eq(GameState.stars_mask(_t1.id), StarRating.ALL_STARS, "a dusk star earned on a later run is kept")
	assert_eq(GameState.tp, tp_after_first + 50 + 25, "same photos again pay nothing extra")


func test_missing_photos_withholds_the_photo_star() -> void:
	_finish(_t1, 90.0, true, StarRating.PhotoQuality.NONE)
	assert_eq(GameState.stars_mask(_t1.id), StarRating.STAR_SUMMIT | StarRating.STAR_BEFORE_DUSK)


func test_best_photo_quality_is_saved_per_viewpoint() -> void:
	_finish(_t1, 90.0, true, StarRating.PhotoQuality.PERFECT)
	_finish(_t1, 90.0, true, StarRating.PhotoQuality.GOOD)
	var vp_id: String = String(_t1.viewpoints[0].id)
	assert_eq(int(GameState.record(_t1.id).photos[vp_id]), StarRating.PhotoQuality.PERFECT)


func test_best_time_only_improves() -> void:
	_finish(_t1, 90.0)
	var slower: Dictionary = _finish(_t1, 120.0)
	assert_eq(GameState.best_time(_t1.id), 90.0)
	assert_false(slower.new_best)
	var faster: Dictionary = _finish(_t1, 70.0)
	assert_true(faster.new_best)
	assert_eq(GameState.best_time(_t1.id), 70.0)


func test_progress_changed_fires() -> void:
	watch_signals(GameState)
	_finish(_t1, 80.0)
	assert_signal_emitted(GameState, "progress_changed")


func test_dict_round_trip() -> void:
	_finish(_t1, 80.0)
	GameState.owned_gear = ["grip_boots"] as Array[String]
	GameState.set_setting("vibration", false)
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(data)
	assert_eq(GameState.best_time(_t1.id), 80.0)
	assert_eq(GameState.stars_mask(_t1.id), StarRating.ALL_STARS)
	assert_eq(GameState.owned_gear, ["grip_boots"] as Array[String])
	assert_false(bool(GameState.settings.vibration))


func test_from_dict_tolerates_junk() -> void:
	GameState.from_dict({"tp": "lots", "trails": {"t01_forest_lake": "broken", "x": {"stars": 15}}, "owned_gear": 5})
	assert_eq(GameState.tp, 0)
	assert_false(GameState.trails.has("t01_forest_lake"))
	assert_eq(GameState.stars_mask(&"x"), StarRating.ALL_STARS, "star bits are clamped to the 3 valid ones")
