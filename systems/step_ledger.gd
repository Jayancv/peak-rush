class_name StepLedger
extends RefCounted
## Real-world steps (Health Connect / HealthKit) turned into TP (GAME_DESIGN §5.10).
## Pure: step counts come in as {"YYYY-MM-DD": steps}, read from the phone by Steps.
## GameState owns one and saves it under "steps".
## - Only steps after the first opt-in count (no backfill of years of history).
## - Each day pays at most Balance.step_tp_daily_cap; days older than the claim window are lost.
## - Claims remember steps, not TP, per day, so syncing twice or claiming again later the
##   same day only pays for the new steps, and leftover steps below one TP carry over.

## Whether the player has the step counter switched on.
var enabled: bool = false
## When the player first opted in (0 = never). Kept when they switch off and on again,
## so a reconnect can't pull in the days from before the first opt-in.
var opt_in_unix: int = 0
var opt_in_date: String = ""
## Date -> steps already paid out for that day.
var claimed: Dictionary = {}
## Every step claimed so far (beyond the daily TP cap too): the km stat and badges.
var lifetime_steps: int = 0
var last_sync_unix: int = 0


func turn_on(now_unix: int, today: String) -> void:
	enabled = true
	if opt_in_unix == 0:
		opt_in_unix = now_unix
		opt_in_date = today


func turn_off() -> void:
	enabled = false


## The days to read from the phone: the claim window ending today, never before opt-in.
## A clock set back before the opt-in day gets nothing.
func dates_to_read(today: String, balance: Balance) -> Array[String]:
	var out: Array[String] = []
	if not enabled or opt_in_date.is_empty():
		return out
	var today_n: int = DailyChallenge.day_number(today)
	var first_n: int = DailyChallenge.day_number(opt_in_date)
	for back: int in balance.step_claim_window_days:
		var n: int = today_n - back
		if n < first_n:
			break
		out.append(date_for_day(n))
	return out


## TP a day's step total is worth, with the daily cap applied.
static func tp_for_steps(steps: int, balance: Balance) -> int:
	if balance.steps_per_tp <= 0:
		return 0
	return mini(maxi(steps, 0) / balance.steps_per_tp, balance.step_tp_daily_cap)


## TP waiting to be claimed from `totals` (date -> steps read from the phone).
func pending_tp(totals: Dictionary, today: String, balance: Balance) -> int:
	var tp: int = 0
	for date: String in dates_to_read(today, balance):
		tp += _day_tp(date, int(totals.get(date, 0)), balance)
	return tp


## Pays out every day in the window. Returns {tp, steps} (new steps, uncapped).
func claim(totals: Dictionary, today: String, now_unix: int, balance: Balance) -> Dictionary:
	var tp: int = 0
	var new_steps: int = 0
	for date: String in dates_to_read(today, balance):
		var steps: int = int(totals.get(date, 0))
		var before: int = int(claimed.get(date, 0))
		if steps <= before:
			continue
		tp += _day_tp(date, steps, balance)
		new_steps += steps - before
		claimed[date] = steps
	lifetime_steps += new_steps
	last_sync_unix = now_unix
	_prune(today, balance)
	return {"tp": tp, "steps": new_steps}


func lifetime_km(balance: Balance) -> float:
	return lifetime_steps * balance.step_length_m / 1000.0


func _day_tp(date: String, steps: int, balance: Balance) -> int:
	return maxi(tp_for_steps(steps, balance) - tp_for_steps(int(claimed.get(date, 0)), balance), 0)


## Days that fell out of the window can never pay again; forget them. Dates *after*
## today stay: if the clock was set back, they must not pay twice when it's put right.
func _prune(today: String, balance: Balance) -> void:
	var oldest: int = DailyChallenge.day_number(today) - balance.step_claim_window_days + 1
	for date: Variant in claimed.keys():
		if DailyChallenge.day_number(str(date)) < oldest:
			claimed.erase(date)


static func date_for_day(day: int) -> String:
	return Time.get_date_string_from_unix_time(day * DailyChallenge.SECONDS_PER_DAY)


func to_dict() -> Dictionary:
	return {
		"enabled": enabled,
		"opt_in_unix": opt_in_unix,
		"opt_in_date": opt_in_date,
		"claimed": claimed.duplicate(),
		"lifetime_steps": lifetime_steps,
		"last_sync_unix": last_sync_unix,
	}


## Tolerant like GameState.from_dict: a bad field is dropped, not the whole ledger.
func from_dict(data: Dictionary) -> void:
	enabled = bool(data.get("enabled", false))
	opt_in_unix = maxi(int(data.get("opt_in_unix", 0)), 0)
	opt_in_date = str(data.get("opt_in_date", ""))
	if opt_in_unix == 0 or opt_in_date.is_empty():
		# Without a known opt-in there is no safe window to read.
		enabled = false
	lifetime_steps = maxi(int(data.get("lifetime_steps", 0)), 0)
	last_sync_unix = maxi(int(data.get("last_sync_unix", 0)), 0)
	claimed = {}
	var saved: Variant = data.get("claimed", {})
	if saved is Dictionary:
		for date: Variant in saved:
			claimed[str(date)] = maxi(int(saved[date]), 0)
