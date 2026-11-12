extends GutTest
## Stroll mode (no clock, half TP, no best/Gold/beat-par), Gold times, hidden shortcuts,
## the ghost file, and the switches on trail select.

var _saved: Dictionary
var _t1: TrailData


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()
	GameState.daily_active = false
	_t1 = ContentDB.get_trail(&"t01_forest_lake")


func after_each() -> void:
	GameState.from_dict(_saved)
	GameState.daily_active = false


func _result(time: float, stroll: bool = false, shortcuts: Array[StringName] = []) -> TrailResult:
	var r: TrailResult = TrailResult.new(_t1.id)
	r.finished = true
	r.time_seconds = time
	r.before_dusk = not stroll
	r.stroll = stroll
	r.viewpoint_total = _t1.viewpoints.size()
	r.shortcuts = shortcuts
	return r


func test_frozen_daylight_never_reaches_dusk() -> void:
	var day: Daylight = Daylight.new(ContentDB.balance, 60.0)
	day.freeze(0.3)
	day.advance(500.0)
	assert_almost_eq(day.fraction(), 0.3, 0.001)
	assert_false(day.is_dusk())
	assert_almost_eq(day.elapsed, 500.0, 0.001, "the hike's time still counts")


func test_stroll_pays_half_and_sets_no_times() -> void:
	# A slow hike past dusk earns the same things a stroll can (no Gold, beat-par or dusk star).
	var slow: TrailResult = _result(300.0)
	slow.before_dusk = false
	GameState.record_result(slow)
	var normal_tp: int = GameState.tp
	GameState.reset()
	GameState.record_result(_result(300.0, true))
	assert_eq(GameState.tp, roundi(normal_tp * ContentDB.balance.stroll_tp_mult), "a stroll earns half")
	assert_eq(GameState.best_time(_t1.id), 0.0, "a stroll sets no best time")
	assert_false(bool(GameState.last_result.new_best))
	assert_true(bool(GameState.last_result.stroll))
	assert_eq(GameState.stars_mask(_t1.id) & StarRating.STAR_BEFORE_DUSK, 0, "no dusk star without a clock")
	assert_eq(int(GameState.record(_t1.id).challenges) & TrailChallenges.bit(TrailChallenges.Kind.BEAT_PAR), 0)


func test_daily_is_never_a_stroll() -> void:
	GameState.settings["stroll_mode"] = true
	assert_true(GameState.stroll_hike())
	GameState.daily_active = true
	assert_false(GameState.stroll_hike())


func test_gold_pays_once_when_first_beaten() -> void:
	var gold: float = TrailRecord.gold_time(_t1, ContentDB.balance)
	GameState.record_result(_result(gold + 5.0))
	assert_eq(int(GameState.last_result.gold_tp), 0, "not under Gold yet")
	GameState.record_result(_result(gold - 1.0))
	assert_eq(int(GameState.last_result.gold_tp), ContentDB.balance.tp_gold)
	assert_true(TrailRecord.has_gold(GameState.record(_t1.id), _t1, ContentDB.balance))
	GameState.record_result(_result(gold - 6.0))
	assert_eq(int(GameState.last_result.gold_tp), 0, "Gold pays only the first time")


func test_shortcut_is_recorded_and_paid_once() -> void:
	GameState.record_result(_result(200.0, false, [&"shortcut"] as Array[StringName]))
	assert_eq(int(GameState.last_result.shortcut_tp), ContentDB.balance.tp_shortcut)
	assert_eq(GameState.record(_t1.id).shortcuts, ["shortcut"] as Array[String])
	GameState.record_result(_result(200.0, false, [&"shortcut"] as Array[StringName]))
	assert_eq(int(GameState.last_result.shortcut_tp), 0)


func test_every_trail_has_its_hidden_shortcut() -> void:
	for season: SeasonData in ContentDB.seasons():
		for t: TrailData in season.trails:
			assert_eq(t.shortcut_count, 1, "%s has a shortcut" % t.id)
	var broken: TrailData = _t1.duplicate()
	broken.shortcut_count = 0
	var errors: Array[String] = ContentValidator.validate_trail(broken)
	assert_true(errors.any(func(e: String) -> bool: return e.contains("shortcut")), "the validator checks the count")


func test_ghost_run_round_trips_through_its_file() -> void:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(10, 500), Vector2(24.5, 498), Vector2(40, 490)])
	GhostTrack.save_run(&"test_trail", 0.1, pts)
	var run: Dictionary = GhostTrack.load_run(&"test_trail")
	assert_eq((run.points as PackedVector2Array).size(), 3)
	assert_almost_eq((run.points as PackedVector2Array)[1].x, 24.5, 0.01)
	assert_almost_eq(float(run.step), 0.1, 0.001)
	DirAccess.remove_absolute(GhostTrack.file_for(&"test_trail"))
	assert_eq(GhostTrack.load_run(&"test_trail"), {}, "no file, no ghost")


func test_trail_select_has_stroll_and_ghost_switches() -> void:
	var screen: Node = add_child_autofree((load(SceneRouter.TRAIL_SELECT) as PackedScene).instantiate())
	var stroll: ToggleSwitch = screen.find_child("StrollSwitch", true, false) as ToggleSwitch
	var ghost: ToggleSwitch = screen.find_child("GhostSwitch", true, false) as ToggleSwitch
	assert_not_null(stroll)
	assert_not_null(ghost)
	stroll.button_pressed = true
	assert_true(bool(GameState.settings.stroll_mode))
	ghost.button_pressed = false
	assert_false(bool(GameState.settings.show_ghost))
