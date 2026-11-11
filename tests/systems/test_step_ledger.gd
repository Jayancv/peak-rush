extends GutTest
## Real-world steps -> TP (GAME_DESIGN §5.10): rate, daily cap, claim window, no backfill,
## duplicate syncs, the clock moving, and the Steps door with a mock phone.

const DAY1: String = "2026-11-02"
const DAY2: String = "2026-11-03"
const DAY3: String = "2026-11-04"

var _b: Balance = Balance.new()
var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	Steps.use_provider(StepProvider.new())
	GameState.from_dict(_saved)


func _ledger(opt_in: String = DAY1) -> StepLedger:
	var l: StepLedger = StepLedger.new()
	l.turn_on(1000, opt_in)
	return l


func test_rate_and_daily_cap() -> void:
	assert_eq(StepLedger.tp_for_steps(499, _b), 0)
	assert_eq(StepLedger.tp_for_steps(_b.steps_per_tp * 3, _b), 3)
	assert_eq(StepLedger.tp_for_steps(10_000_000, _b), _b.step_tp_daily_cap, "a huge day pays only the cap")
	assert_eq(StepLedger.tp_for_steps(-5, _b), 0)


func test_off_reads_nothing_and_pays_nothing() -> void:
	var l: StepLedger = StepLedger.new()
	assert_eq(l.dates_to_read(DAY2, _b), [] as Array[String])
	assert_eq(int(l.claim({DAY2: 9000}, DAY2, 0, _b).tp), 0)


func test_no_backfill_before_opt_in() -> void:
	var l: StepLedger = _ledger(DAY2)
	assert_eq(l.dates_to_read(DAY3, _b), [DAY3, DAY2] as Array[String])
	assert_eq(l.pending_tp({DAY1: 20000, DAY2: 1000, DAY3: 1000}, DAY3, _b), 4, "the day before opting in is ignored")


func test_switching_off_and_on_keeps_the_first_opt_in() -> void:
	var l: StepLedger = _ledger(DAY1)
	l.turn_off()
	l.turn_on(99999, DAY3)
	assert_eq(l.opt_in_date, DAY1)
	assert_true(l.enabled)


func test_syncing_twice_pays_once_and_later_steps_top_up() -> void:
	var l: StepLedger = _ledger()
	assert_eq(int(l.claim({DAY1: 1200}, DAY1, 1, _b).tp), 2)
	assert_eq(int(l.claim({DAY1: 1200}, DAY1, 2, _b).tp), 0, "same read again pays nothing")
	# 1200 -> 1600: the 200 left over from before now make up the third TP.
	assert_eq(int(l.claim({DAY1: 1600}, DAY1, 3, _b).tp), 1)
	assert_eq(l.lifetime_steps, 1600)


func test_cap_applies_across_claims_in_one_day() -> void:
	var l: StepLedger = _ledger()
	var cap_steps: int = _b.steps_per_tp * _b.step_tp_daily_cap
	assert_eq(int(l.claim({DAY1: cap_steps - _b.steps_per_tp}, DAY1, 1, _b).tp), _b.step_tp_daily_cap - 1)
	assert_eq(int(l.claim({DAY1: cap_steps * 3}, DAY1, 2, _b).tp), 1)
	assert_eq(l.lifetime_steps, cap_steps * 3, "the km stat counts every step, past the cap too")


func test_unclaimed_days_in_the_window_pay_and_older_ones_are_lost() -> void:
	var l: StepLedger = _ledger("2026-10-01")
	var today: String = "2026-11-10"
	var dates: Array[String] = l.dates_to_read(today, _b)
	assert_eq(dates.size(), _b.step_claim_window_days)
	assert_eq(dates[0], today)
	assert_eq(dates[-1], "2026-11-04")
	var out: Dictionary = l.claim({"2026-11-04": 1000, "2026-11-03": 50000, today: 500}, today, 1, _b)
	assert_eq(int(out.tp), 3, "11-03 is outside the 7-day window")


func test_clock_set_back_cannot_pay_twice() -> void:
	var l: StepLedger = _ledger()
	l.claim({DAY3: 5000}, DAY3, 1, _b)
	# Clock back two days, then forward again: DAY3 is remembered either way.
	assert_eq(int(l.claim({DAY1: 0, DAY3: 5000}, DAY1, 2, _b).tp), 0)
	assert_eq(l.pending_tp({DAY3: 5000}, DAY3, _b), 0)
	assert_true(l.claimed.has(DAY3), "a 'future' day isn't pruned while the clock is behind")


func test_clock_before_opt_in_reads_nothing() -> void:
	var l: StepLedger = _ledger(DAY2)
	assert_eq(l.dates_to_read(DAY1, _b), [] as Array[String])


func test_round_trip_and_damaged_fields() -> void:
	var l: StepLedger = _ledger()
	l.claim({DAY1: 2500}, DAY1, 77, _b)
	var back: StepLedger = StepLedger.new()
	back.from_dict(JSON.parse_string(JSON.stringify(l.to_dict())))
	assert_eq(back.to_dict(), l.to_dict())
	var broken: StepLedger = StepLedger.new()
	broken.from_dict({"enabled": true, "claimed": "oops", "lifetime_steps": -4})
	assert_false(broken.enabled, "no opt-in date means no safe window: stays off")
	assert_eq(broken.claimed, {})
	assert_eq(broken.lifetime_steps, 0)


func test_tests_and_desktop_release_have_no_step_counter() -> void:
	Steps.use_provider(null)
	assert_false(Steps.is_supported(), "under GUT the no-op provider is used")


func test_steps_door_with_a_mock_phone() -> void:
	var phone: MockStepProvider = MockStepProvider.new()
	Steps.use_provider(phone)
	phone.grant = false
	var answers: Array[bool] = []
	Steps.turn_on(func(on: bool) -> void: answers.append(on))
	assert_eq(answers, [false] as Array[bool])
	assert_false(Steps.is_on(), "refused access leaves it off")
	phone.grant = true
	Steps.turn_on(func(on: bool) -> void: answers.append(on))
	assert_true(Steps.is_on())
	phone.fixed = {GameState.today(): 3000}
	var pending: Array[int] = []
	Steps.refresh(func(tp: int) -> void: pending.append(tp))
	assert_eq(pending, [6] as Array[int])
	assert_eq(Steps.today_steps(), 3000)
	var tp_before: int = GameState.tp
	assert_eq(int(Steps.claim().tp), 6)
	assert_eq(GameState.tp, tp_before + 6)
	assert_eq(Steps.pending_tp(), 0)


func test_revoked_access_pays_nothing() -> void:
	var phone: MockStepProvider = MockStepProvider.new()
	Steps.use_provider(phone)
	Steps.turn_on(func(_on: bool) -> void: pass)
	phone.access_ok = false
	phone.fixed = {GameState.today(): 9000}
	Steps.refresh(func(_tp: int) -> void: pass)
	assert_false(Steps.is_on())
	assert_eq(int(Steps.claim().tp), 0)


func test_step_badges() -> void:
	GameState.steps.turn_on(1, "2026-01-01")
	GameState.steps.lifetime_steps = 60000
	var facts: Dictionary = GameState.profile_facts()
	assert_eq(int(facts.real_steps), 60000)
	assert_eq(int(facts.real_km), 45)
	var ids: Array = GameState.refresh_badges().map(func(b: BadgeData) -> String: return String(b.id))
	assert_has(ids, "step_out")
	assert_has(ids, "marathon_legs")
	assert_does_not_have(ids, "long_walker")
