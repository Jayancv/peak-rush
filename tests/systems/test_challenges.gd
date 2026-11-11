extends GutTest
## Trail challenges: all finds in one hike, beat par, clean hike; TP once each; medal.

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func _result(trail: TrailData, seconds: float, finds: Array[StringName], stumbles: int = 0) -> TrailResult:
	var r: TrailResult = TrailResult.new(trail.id)
	r.finished = true
	r.time_seconds = seconds
	r.finds = finds
	r.stumbles = stumbles
	return r


func test_rules() -> void:
	var trail: TrailData = ContentDB.first_trail()
	var all: Array[StringName] = trail.find_ids()
	var r: TrailResult = _result(trail, trail.par_time + 10.0, all, 1)
	assert_true(TrailChallenges.met(TrailChallenges.Kind.ALL_FINDS, r, trail))
	assert_false(TrailChallenges.met(TrailChallenges.Kind.BEAT_PAR, r, trail))
	assert_false(TrailChallenges.met(TrailChallenges.Kind.CLEAN, r, trail), "a stumble spoils a clean hike")
	r.stumbles = 0
	r.falls = 1
	assert_false(TrailChallenges.met(TrailChallenges.Kind.CLEAN, r, trail), "so does a fall")
	r.finished = false
	assert_false(TrailChallenges.met(TrailChallenges.Kind.ALL_FINDS, r, trail), "only finished hikes count")


func test_each_challenge_pays_once_and_three_make_a_medal() -> void:
	var trail: TrailData = ContentDB.first_trail()
	var b: Balance = ContentDB.balance
	# Hike 1: fast and clean, but missed a find.
	var out: Dictionary = GameState.record_result(_result(trail, trail.par_time - 5.0, [] as Array[StringName]))
	assert_eq(int(out.challenge_tp), 2 * b.tp_per_challenge)
	assert_false(bool(out.medal))
	# Hike 2: same again pays nothing new.
	out = GameState.record_result(_result(trail, trail.par_time - 5.0, [] as Array[StringName]))
	assert_eq(int(out.challenge_tp), 0)
	# Hike 3: slow and stumbly, but every find: the last one, and the medal.
	out = GameState.record_result(_result(trail, trail.par_time + 50.0, trail.find_ids(), 3))
	assert_eq(int(out.challenge_tp), b.tp_per_challenge)
	assert_true(bool(out.medal))
	assert_true(TrailChallenges.has_medal(int(GameState.record(trail.id).challenges)))


func test_challenges_survive_a_save_and_old_saves_start_with_none() -> void:
	var trail: TrailData = ContentDB.first_trail()
	GameState.record_result(_result(trail, trail.par_time - 5.0, [] as Array[StringName]))
	var mask: int = int(GameState.record(trail.id).challenges)
	GameState.from_dict(GameState.to_dict())
	assert_eq(int(GameState.record(trail.id).challenges), mask)
	var v4: Dictionary = {"save_version": 4, "trails": {"t01_forest_lake": {"stars": 1, "best_time": 90.0}}}
	assert_eq(int(SaveService.migrate(v4).trails.t01_forest_lake.challenges), 0)


func test_pause_rows_show_done_open_and_missed() -> void:
	var trail: TrailData = ContentDB.first_trail()
	GameState.record_result(_result(trail, trail.par_time + 50.0, trail.find_ids(), 1))
	var tracker: HikeTracker = add_child_autofree(HikeTracker.new()) as HikeTracker
	tracker.set("_trail", trail)
	tracker.stumbles = 1
	var rows: Array = tracker.challenge_rows(trail.par_time - 1.0)
	assert_eq(rows[TrailChallenges.Kind.ALL_FINDS][1], PauseMenu.Goal.DONE)
	assert_eq(rows[TrailChallenges.Kind.BEAT_PAR][1], PauseMenu.Goal.OPEN)
	assert_eq(rows[TrailChallenges.Kind.CLEAN][1], PauseMenu.Goal.MISSED)
