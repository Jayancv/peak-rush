extends GutTest
## Weekly goals: the same three goals for everyone in a week, progress capped at the target,
## TP once per goal plus a bonus for all of them, and a clean start every Monday.

var _b: Balance = Balance.new()


func _hike(finds: int = 0, great: int = 0, time: float = 100.0, falls: int = 0) -> TrailResult:
	var r: TrailResult = TrailResult.new(&"t01_forest_lake")
	r.finished = true
	r.time_seconds = time
	for i: int in finds:
		r.finds.append(StringName("f%d" % i))
	for i: int in great:
		r.photos["vp%d" % i] = StarRating.PhotoQuality.GREAT
	r.falls = falls
	return r


func test_weeks_start_on_monday() -> void:
	assert_eq(WeeklyGoals.week_of("2026-11-09"), WeeklyGoals.week_of("2026-11-15"), "Monday to Sunday is one week")
	assert_eq(WeeklyGoals.week_of("2026-11-16"), WeeklyGoals.week_of("2026-11-15") + 1, "a new week on Monday")
	assert_eq(WeeklyGoals.week_of("garbage"), -1)


func test_goals_are_distinct_fixed_per_week_and_change() -> void:
	var w: int = WeeklyGoals.week_of("2026-11-11")
	var goals: Array[int] = WeeklyGoals.goals_for(w, _b)
	assert_eq(goals.size(), _b.weekly_goal_count)
	assert_eq(goals, WeeklyGoals.goals_for(w, _b), "every phone gets the same goals")
	var unique: Dictionary = {}
	for g: int in goals:
		unique[g] = true
	assert_eq(unique.size(), goals.size(), "no goal twice in a week")
	var changed: bool = false
	for k: int in range(1, 6):
		if WeeklyGoals.goals_for(w + k, _b) != goals:
			changed = true
	assert_true(changed, "the goals rotate")


func test_counts_from_a_hike() -> void:
	var c: Dictionary = WeeklyGoals.hike_counts(_hike(2, 1, 90.0), 100.0, true)
	assert_eq(c[WeeklyGoals.Goal.FINDS], 2)
	assert_eq(c[WeeklyGoals.Goal.GREAT_PHOTOS], 1)
	assert_eq(c[WeeklyGoals.Goal.SUMMITS], 1)
	assert_eq(c[WeeklyGoals.Goal.BEAT_PAR], 1)
	assert_eq(c[WeeklyGoals.Goal.DAILIES], 1)
	assert_eq(c[WeeklyGoals.Goal.CLEAN_HIKES], 1)
	assert_eq(WeeklyGoals.hike_counts(_hike(0, 0, 120.0, 1), 100.0, false)[WeeklyGoals.Goal.CLEAN_HIKES], 0)
	var dnf: TrailResult = _hike(3)
	dnf.finished = false
	assert_eq(WeeklyGoals.hike_counts(dnf, 100.0, false), {}, "an unfinished hike counts for nothing")


func test_pays_each_goal_once_and_a_bonus_for_all() -> void:
	var w: int = WeeklyGoals.week_of("2026-11-11")
	var state: Dictionary = WeeklyGoals.current({}, w)
	var everything: Dictionary = {}
	for g: int in WeeklyGoals.Goal.values():
		everything[g] = 99
	var out: Dictionary = WeeklyGoals.add_hike(state, everything, _b)
	assert_eq(out.done.size(), _b.weekly_goal_count)
	assert_true(out.bonus)
	assert_eq(int(out.tp), _b.weekly_goal_count * _b.weekly_goal_tp + _b.weekly_all_bonus_tp)
	for g: int in WeeklyGoals.goals_for(w, _b):
		assert_eq(int(state.progress[str(g)]), WeeklyGoals.target(g, _b), "progress stops at the target")
	var again: Dictionary = WeeklyGoals.add_hike(state, everything, _b)
	assert_eq(int(again.tp), 0, "never paid twice")


func test_a_new_week_starts_fresh_and_saves_round_trip() -> void:
	var w: int = WeeklyGoals.week_of("2026-11-11")
	var state: Dictionary = WeeklyGoals.current({}, w)
	WeeklyGoals.add_hike(state, {WeeklyGoals.Goal.SUMMITS: 2, WeeklyGoals.Goal.FINDS: 2}, _b)
	var back: Dictionary = WeeklyGoals.clean(JSON.parse_string(JSON.stringify(state)))
	assert_eq(back, state, "survives JSON (floats and string keys)")
	assert_eq(WeeklyGoals.current(back, w + 1).progress, {}, "next Monday: fresh goals")
	assert_eq(WeeklyGoals.clean("junk"), {})


func test_game_state_pays_weekly_goals_on_a_finished_hike() -> void:
	var saved: Dictionary = GameState.to_dict()
	GameState.reset()
	var w: int = WeeklyGoals.week_of(GameState.today())
	GameState.profile.weekly = WeeklyGoals.current({}, w)
	for g: int in WeeklyGoals.goals_for(w, ContentDB.balance):
		GameState.profile.weekly.progress[str(g)] = WeeklyGoals.target(g, ContentDB.balance) - 1
	var r: TrailResult = _hike(1, 1, 1.0)
	r.viewpoint_total = 1
	GameState.record_result(r)
	var weekly: Dictionary = GameState.last_result.weekly
	assert_gt(int(weekly.tp), 0, "the last step of a goal pays")
	assert_gte(GameState.tp, int(weekly.tp))
	GameState.from_dict(saved)
