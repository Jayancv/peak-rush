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


func _finish(trail: TrailData, time: float, before_dusk: bool = true) -> Dictionary:
	var r: TrailResult = TrailResult.new(trail.id)
	r.finished = true
	r.time_seconds = time
	r.before_dusk = before_dusk
	r.viewpoint_total = trail.viewpoints.size()
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
	assert_eq(tp_after_first, 50 + 50)
	_finish(_t1, 95.0, true)
	assert_eq(GameState.stars_mask(_t1.id), StarRating.ALL_STARS, "a dusk star earned on a later run is kept")
	assert_eq(GameState.tp, tp_after_first + 50 + 25)


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
