extends GutTest
## Daily trail: deterministic pick, goals, streaks and rewards.

var _b: Balance = Balance.new()
var _ids: Array[StringName] = [&"a", &"b", &"c", &"d", &"e"]


func test_same_date_same_challenge_and_dates_vary() -> void:
	var one: Dictionary = DailyChallenge.for_date("2026-11-10", _ids)
	assert_eq(DailyChallenge.for_date("2026-11-10", _ids), one)
	var seen: Dictionary = {}
	for d: int in range(1, 29):
		var c: Dictionary = DailyChallenge.for_date("2026-02-%02d" % d, _ids)
		seen[String(c.trail_id) + str(c.twist)] = true
		assert_true(_ids.has(c.trail_id))
	assert_gt(seen.size(), 6, "a month of dailies isn't the same few repeated")


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
