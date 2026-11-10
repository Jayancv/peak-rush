class_name DailyChallenge
extends RefCounted
## The trail of the day: each date picks one unlocked trail and a twist that changes
## how it plays (or what counts as done). Pure and deterministic, so everyone with the
## same trails gets the same challenge on the same day, and tests can pin dates.

enum Twist { HEADWIND, FOG, SHORT_DAY, FORAGER, BEAT_PAR }

const SECONDS_PER_DAY: int = 86400


## { "trail_id": StringName, "twist": Twist } for `date` ("YYYY-MM-DD").
static func for_date(date: String, trail_ids: Array[StringName]) -> Dictionary:
	if trail_ids.is_empty():
		return {}
	# A simple stable hash of the date string (String.hash can differ between versions).
	var h: int = 0
	for c: int in date.to_utf8_buffer():
		h = (h * 31 + c) % 1000003
	return {"trail_id": trail_ids[h % trail_ids.size()], "twist": (h / 7) % Twist.size()}


## Whether a finished hike meets the day's goal.
static func goal_met(twist: Twist, result: TrailResult, par_time: float, balance: Balance) -> bool:
	if not result.finished:
		return false
	match twist:
		Twist.FORAGER:
			return result.finds.size() >= balance.daily_forager_finds
		Twist.BEAT_PAR:
			return result.time_seconds <= par_time
	return true


## The streak after completing today's challenge.
## A daily counts as done for `today` if it was done that day or a day or two
## *later*: the clock moved back (time-zone travel, or fiddling) mustn't re-open a
## paid-out daily. A bigger jump back means the clock was plainly wrong; let it go.
const CLOCK_BACK_GRACE_DAYS: int = 2


static func is_done(last_done: String, today: String) -> bool:
	if last_done.is_empty():
		return false
	var ahead: int = day_number(last_done) - day_number(today)
	return ahead >= 0 and ahead <= CLOCK_BACK_GRACE_DAYS


static func next_streak(last_done: String, today: String, streak: int) -> int:
	if last_done == today:
		return streak
	if not last_done.is_empty() and day_number(today) - day_number(last_done) == 1:
		return streak + 1
	return 1


## Today's reward: the base bonus plus a little per streak day (capped).
static func reward(streak: int, balance: Balance) -> int:
	return balance.daily_bonus_tp + balance.daily_streak_tp * mini(maxi(streak - 1, 0), balance.daily_streak_cap)


static func day_number(date: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / SECONDS_PER_DAY)
