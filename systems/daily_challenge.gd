class_name DailyChallenge
extends RefCounted
## The trail of the day: each date picks one unlocked trail and a twist that changes
## how it plays (or what counts as done). Pure and deterministic, so everyone with the
## same trails gets the same challenge on the same day, and tests can pin dates.

## Append only: a day's twist is computed, never saved, but keep the order stable anyway.
enum Twist { HEADWIND, FOG, SHORT_DAY, FORAGER, BEAT_PAR, THIRSTY, HEAVY_PACK, GUSTY, PHOTO_HUNT, SURE_FOOTED }

## Short description of each twist (Twist order).
const TWIST_KEYS: Array[String] = ["DAILY_TWIST_HEADWIND", "DAILY_TWIST_FOG", "DAILY_TWIST_SHORT_DAY",
	"DAILY_TWIST_FORAGER", "DAILY_TWIST_BEAT_PAR", "DAILY_TWIST_THIRSTY", "DAILY_TWIST_HEAVY_PACK",
	"DAILY_TWIST_GUSTY", "DAILY_TWIST_PHOTO_HUNT", "DAILY_TWIST_SURE_FOOTED"]

const SECONDS_PER_DAY: int = 86400
## Salts so the trail order and the twist order shuffle differently.
const _TRAIL_SALT: int = 17
const _TWIST_SALT: int = 53


## { "trail_id": StringName, "twist": Twist } for `date` ("YYYY-MM-DD").
## No repeats: trails and twists are each dealt from a shuffled deck, one card a day,
## and a new deck never starts with the card the last one ended on. A twist that
## doesn't suit the day's trail is swapped for the next one that does (and that isn't
## yesterday's or tomorrow's).
static func for_date(date: String, trails: Array[TrailData], balance: Balance) -> Dictionary:
	if trails.is_empty():
		return {}
	var day: int = day_number(date)
	var twist: int = _twist_for(day, trails, balance)
	var yesterday: int = _twist_for(day - 1, trails, balance)
	if twist == yesterday:
		twist = _next_fitting(twist, [yesterday, _deal(day + 1, Twist.size(), _TWIST_SALT)], _trail_for(day, trails), balance)
	return {"trail_id": _trail_for(day, trails).id, "twist": twist}


## Whether `twist` makes sense on `trail` (a photo hunt needs viewpoints, and so on).
static func fits(twist: int, trail: TrailData, balance: Balance) -> bool:
	match twist:
		Twist.FORAGER:
			return trail.finds.size() >= balance.daily_forager_finds
		Twist.PHOTO_HUNT:
			return not trail.viewpoints.is_empty()
		Twist.SHORT_DAY:
			# Night trails are timed by the aurora, not the sun: shortening it reads oddly.
			return not trail.night
	return true


static func _trail_for(day: int, trails: Array[TrailData]) -> TrailData:
	return trails[_deal(day, trails.size(), _TRAIL_SALT)]


## The day's twist from the deck, or the next one that suits the trail.
static func _twist_for(day: int, trails: Array[TrailData], balance: Balance) -> int:
	var twist: int = _deal(day, Twist.size(), _TWIST_SALT)
	var trail: TrailData = _trail_for(day, trails)
	if fits(twist, trail, balance):
		return twist
	return _next_fitting(twist, [_deal(day - 1, Twist.size(), _TWIST_SALT), _deal(day + 1, Twist.size(), _TWIST_SALT)], trail, balance)


static func _next_fitting(from: int, avoid: Array, trail: TrailData, balance: Balance) -> int:
	for step: int in range(1, Twist.size() + 1):
		var t: int = (from + step) % Twist.size()
		if not avoid.has(t) and fits(t, trail, balance):
			return t
	return from


## Card `day` from a deck of `n`, reshuffled every n days.
static func _deal(day: int, n: int, salt: int) -> int:
	if n <= 1:
		return 0
	if n == 2:
		# A two-card deck can't be reshuffled without risking a repeat: just alternate.
		return posmod(day, 2)
	var deck: int = floori(float(day) / n)
	return _deck(deck, n, salt)[posmod(day, n)]


## The shuffled order of deck `deck`. Swaps its first two cards if it would start with
## the previous deck's last card (no repeat across the join).
static func _deck(deck: int, n: int, salt: int) -> Array[int]:
	var order: Array[int] = _shuffled(deck, n, salt)
	if _shuffled(deck - 1, n, salt)[n - 1] == order[0]:
		var first: int = order[0]
		order[0] = order[1]
		order[1] = first
	return order


## Fisher-Yates with a small fixed generator (engine RNGs may change between versions;
## a daily must be the same for everyone, on every app version).
static func _shuffled(deck: int, n: int, salt: int) -> Array[int]:
	var order: Array[int] = []
	for i: int in n:
		order.append(i)
	var state: int = posmod(deck * 7919 + salt * 104729, 2147483647) + 1
	for i: int in range(n - 1, 0, -1):
		state = (state * 48271) % 2147483647
		var j: int = state % (i + 1)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	return order


## Settles a hike against today's daily `d` (from GameState.daily_today): {} if this
## hike wasn't today's open daily, {"done": false} if the goal was missed, else marks
## the profile and returns {"done": true, "bonus": tp, "streak": n}.
static func settle(d: Dictionary, result: TrailResult, trail: TrailData, profile: PlayerProfile, balance: Balance) -> Dictionary:
	if d.is_empty() or d.trail_id != result.trail_id or d.done:
		return {}
	if not goal_met(d.twist, result, trail.par_time if trail != null else 0.0, balance):
		return {"done": false}
	var streak: int = profile.complete_daily(d.date)
	return {"done": true, "bonus": reward(streak, balance), "streak": streak}


## Whether a finished hike meets the day's goal.
static func goal_met(twist: Twist, result: TrailResult, par_time: float, balance: Balance) -> bool:
	if not result.finished:
		return false
	match twist:
		Twist.FORAGER:
			return result.finds.size() >= balance.daily_forager_finds
		Twist.BEAT_PAR:
			return result.time_seconds <= par_time
		Twist.PHOTO_HUNT:
			return result.viewpoint_total > 0 and result.photos.size() >= result.viewpoint_total
		Twist.SURE_FOOTED:
			return result.falls == 0
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
