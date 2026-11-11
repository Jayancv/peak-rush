extends GutTest
## Daily trail: deterministic pick, goals, streaks and rewards.

var _b: Balance = Balance.new()


func _trail(id: StringName, viewpoints: int = 2, finds: int = 4, night: bool = false) -> TrailData:
	var t: TrailData = TrailData.new()
	t.id = id
	t.night = night
	for i: int in viewpoints:
		t.viewpoints.append(ViewpointData.new())
	for i: int in finds:
		t.finds.append(FindData.new())
	return t


func _trails(n: int) -> Array[TrailData]:
	var out: Array[TrailData] = []
	for i: int in n:
		out.append(_trail(StringName("t%d" % i)))
	return out


func _date(day_offset: int) -> String:
	return Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string("2026-01-01T00:00:00") + day_offset * DailyChallenge.SECONDS_PER_DAY)


func test_same_date_same_challenge() -> void:
	var trails: Array[TrailData] = _trails(5)
	assert_eq(DailyChallenge.for_date("2026-11-10", trails, _b), DailyChallenge.for_date("2026-11-10", trails, _b))


func test_no_trail_or_twist_two_days_running() -> void:
	for n: int in [2, 3, 5, 8]:
		var trails: Array[TrailData] = _trails(n)
		var prev: Dictionary = DailyChallenge.for_date(_date(-1), trails, _b)
		for d: int in 730:
			var c: Dictionary = DailyChallenge.for_date(_date(d), trails, _b)
			assert_ne(c.trail_id, prev.trail_id, "%d trails: same trail on %s and the day before" % [n, _date(d)])
			assert_ne(c.twist, prev.twist, "%d trails: same twist on %s and the day before" % [n, _date(d)])
			prev = c


func test_every_trail_and_twist_comes_round_fairly() -> void:
	var trails: Array[TrailData] = _trails(5)
	var trail_count: Dictionary = {}
	var twist_count: Dictionary = {}
	for d: int in 365:
		var c: Dictionary = DailyChallenge.for_date(_date(d), trails, _b)
		trail_count[c.trail_id] = int(trail_count.get(c.trail_id, 0)) + 1
		twist_count[c.twist] = int(twist_count.get(c.twist, 0)) + 1
	assert_eq(trail_count.size(), 5)
	assert_eq(twist_count.size(), DailyChallenge.Twist.size(), "every twist shows up within a year")
	for id: Variant in trail_count:
		assert_between(int(trail_count[id]), 55, 90, "%s comes round about once in 5 days" % id)
	for tw: Variant in twist_count:
		assert_between(int(twist_count[tw]), 20, 60, "twist %d comes round about once in 10 days" % tw)


func test_twists_only_land_where_they_fit() -> void:
	var bare: TrailData = _trail(&"bare", 0, 1, true)
	assert_false(DailyChallenge.fits(DailyChallenge.Twist.PHOTO_HUNT, bare, _b), "no viewpoints, no photo hunt")
	assert_false(DailyChallenge.fits(DailyChallenge.Twist.FORAGER, bare, _b), "one find can't make two")
	assert_false(DailyChallenge.fits(DailyChallenge.Twist.SHORT_DAY, bare, _b), "night trails keep their aurora")
	var only: Array[TrailData] = [bare]
	for d: int in 120:
		var tw: int = int(DailyChallenge.for_date(_date(d), only, _b).twist)
		assert_true(DailyChallenge.fits(tw, bare, _b), "%s picked twist %d" % [_date(d), tw])


func test_every_twist_has_text() -> void:
	assert_eq(DailyChallenge.TWIST_KEYS.size(), DailyChallenge.Twist.size())
	for key: String in DailyChallenge.TWIST_KEYS:
		assert_ne(tr(key), key)


func test_new_goals() -> void:
	var r: TrailResult = TrailResult.new(&"a")
	r.finished = true
	r.viewpoint_total = 2
	r.photos = {"v1": 2}
	assert_false(DailyChallenge.goal_met(DailyChallenge.Twist.PHOTO_HUNT, r, 0.0, _b))
	r.photos["v2"] = 1
	assert_true(DailyChallenge.goal_met(DailyChallenge.Twist.PHOTO_HUNT, r, 0.0, _b))
	assert_true(DailyChallenge.goal_met(DailyChallenge.Twist.SURE_FOOTED, r, 0.0, _b))
	r.falls = 1
	assert_false(DailyChallenge.goal_met(DailyChallenge.Twist.SURE_FOOTED, r, 0.0, _b))


func test_gusty_and_dry_spell_change_the_hike() -> void:
	var w: WeatherProfile = HikeTracker.twisted_weather(WeatherProfile.new(), DailyChallenge.Twist.GUSTY, _b)
	assert_true(w.wind)
	assert_eq(w.gust_strength, _b.daily_gust_strength)
	var h: Hydration = Hydration.new(_b)
	var plain: Hydration = Hydration.new(_b)
	h.drain_scale = _b.daily_thirsty_water_mult
	h.tick(1.0, true, false)
	plain.tick(1.0, true, false)
	assert_almost_eq(h.max_value - h.value, (plain.max_value - plain.value) * _b.daily_thirsty_water_mult, 0.001)


func test_goals() -> void:
	var r: TrailResult = TrailResult.new(&"a")
	r.finished = true
	r.time_seconds = 100.0
	assert_true(DailyChallenge.goal_met(DailyChallenge.Twist.HEADWIND, r, 90.0, _b))
	assert_false(DailyChallenge.goal_met(DailyChallenge.Twist.BEAT_PAR, r, 90.0, _b))
	assert_true(DailyChallenge.goal_met(DailyChallenge.Twist.BEAT_PAR, r, 110.0, _b))
	assert_false(DailyChallenge.goal_met(DailyChallenge.Twist.FORAGER, r, 0.0, _b))
	r.finds = [&"x", &"y"] as Array[StringName]
	assert_true(DailyChallenge.goal_met(DailyChallenge.Twist.FORAGER, r, 0.0, _b))
	r.finished = false
	assert_false(DailyChallenge.goal_met(DailyChallenge.Twist.HEADWIND, r, 999.0, _b), "you have to finish")


func test_streak_grows_on_consecutive_days_and_resets_after_a_gap() -> void:
	assert_eq(DailyChallenge.next_streak("", "2026-11-10", 0), 1)
	assert_eq(DailyChallenge.next_streak("2026-11-09", "2026-11-10", 3), 4)
	assert_eq(DailyChallenge.next_streak("2026-11-10", "2026-11-10", 4), 4, "twice in a day doesn't count")
	assert_eq(DailyChallenge.next_streak("2026-11-07", "2026-11-10", 4), 1)
	assert_eq(DailyChallenge.next_streak("2026-12-31", "2027-01-01", 2), 3, "across a year end")


func test_reward_grows_with_streak_up_to_a_cap() -> void:
	assert_eq(DailyChallenge.reward(1, _b), _b.daily_bonus_tp)
	assert_eq(DailyChallenge.reward(3, _b), _b.daily_bonus_tp + 2 * _b.daily_streak_tp)
	assert_eq(DailyChallenge.reward(99, _b), _b.daily_bonus_tp + _b.daily_streak_cap * _b.daily_streak_tp)


func test_completing_today_pays_once_and_starts_a_streak() -> void:
	var saved: Dictionary = GameState.to_dict()
	GameState.reset()
	var d: Dictionary = GameState.daily_today()
	assert_false(d.is_empty(), "the first trail is always open")
	GameState.daily_active = true
	var r: TrailResult = TrailResult.new(d.trail_id)
	r.finished = true
	r.time_seconds = 1.0
	r.finds = [&"x", &"y", &"z"] as Array[StringName]
	var out: Dictionary = GameState.record_result(r)
	assert_true(out.daily.done)
	assert_eq(int(out.daily.streak), 1)
	assert_true(GameState.daily_today().done)
	GameState.daily_active = true
	var again: Dictionary = GameState.record_result(r)
	assert_false(again.has("daily"), "no second payout on the same day")
	GameState.from_dict(saved)


func test_unlocking_a_trail_does_not_change_todays_daily() -> void:
	var saved: Dictionary = GameState.to_dict()
	GameState.reset()
	var before: Dictionary = GameState.daily_today()
	# Finishing trail 1 opens trail 2: more trails to pick from, but today stays today.
	var r: TrailResult = TrailResult.new(ContentDB.first_trail().id)
	r.finished = true
	r.time_seconds = 100.0
	GameState.record_result(r)
	var after: Dictionary = GameState.daily_today()
	assert_eq(after.trail_id, before.trail_id)
	assert_eq(after.twist, before.twist)
	var reloaded: PlayerProfile = PlayerProfile.new()
	reloaded.from_dict(GameState.profile.to_dict())
	assert_eq(reloaded.daily_pick, GameState.profile.daily_pick, "and it survives a restart")
	GameState.from_dict(saved)


func test_clock_moved_back_a_day_does_not_reopen_a_paid_daily() -> void:
	# Done on the 10th; the clock (or a flight west) says it's the 9th again.
	assert_true(DailyChallenge.is_done("2026-11-10", "2026-11-10"))
	assert_true(DailyChallenge.is_done("2026-11-10", "2026-11-09"), "a day back stays done")
	assert_true(DailyChallenge.is_done("2026-11-10", "2026-11-08"), "two days back stays done")
	assert_false(DailyChallenge.is_done("2026-11-09", "2026-11-10"), "tomorrow is a new daily")
	assert_false(DailyChallenge.is_done("", "2026-11-10"))


func test_clock_far_ahead_then_fixed_does_not_lock_the_daily() -> void:
	# The phone thought it was next year when the daily was done; the clock is fixed now.
	assert_false(DailyChallenge.is_done("2027-11-10", "2026-11-10"))
	assert_eq(DailyChallenge.next_streak("2027-11-10", "2026-11-10", 5), 1, "the streak starts over")


func test_profile_uses_the_clock_rules() -> void:
	var p: PlayerProfile = PlayerProfile.new()
	p.complete_daily("2026-11-10")
	assert_true(p.daily_done_on("2026-11-09"))
	assert_false(p.daily_done_on("2026-11-11"))


func test_android_back_closes_the_daily_card_not_the_app() -> void:
	var menu: Node = add_child_autofree((load(SceneRouter.MAIN_MENU) as PackedScene).instantiate())
	await wait_process_frames(2)
	DailyCard.open(menu as Control)
	assert_true(menu.call("_popup_open"))
	var card: Node = null
	for child: Node in menu.get_children():
		if child is DailyCard:
			card = child
	# The menu checks before the card frees itself, so back must not quit here.
	card.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(card.is_queued_for_deletion(), "back closes the card")
	await wait_process_frames(2)
	assert_false(menu.call("_popup_open"), "and the menu sees it gone")
