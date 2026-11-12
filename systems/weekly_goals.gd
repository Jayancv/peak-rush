class_name WeeklyGoals
extends RefCounted
## Three small goals a week (the same for everyone that week, new ones each Monday) that
## reward playing more of the game: finds, good photos, summits, par, dailies, clean hikes.
## The state is a plain Dictionary in PlayerProfile.weekly:
##   {"week": week number, "progress": {goal: n}, "done": [goals], "bonus": bool}

enum Goal { FINDS, GREAT_PHOTOS, SUMMITS, BEAT_PAR, DAILIES, CLEAN_HIKES }

const KEYS: Array[String] = ["WEEKLY_FINDS", "WEEKLY_GREAT_PHOTOS", "WEEKLY_SUMMITS",
	"WEEKLY_BEAT_PAR", "WEEKLY_DAILIES", "WEEKLY_CLEAN_HIKES"]
## Salt so the weekly deck doesn't follow the daily one.
const _SALT: int = 211


## Weeks since the epoch, starting on Mondays (1970-01-01 was a Thursday). -1 for a bad date.
static func week_of(date: String) -> int:
	if date.length() != 10 or date[4] != "-" or date[7] != "-":
		return -1
	var unix: int = Time.get_unix_time_from_datetime_string(date + "T00:00:00")
	return floori((floori(unix / 86400.0) + 3) / 7.0)


## Records a finished hike on the profile's weekly goals; returns add_hike's result.
static func record(profile: PlayerProfile, result: TrailResult, trail: TrailData, daily: bool, today: String, balance: Balance) -> Dictionary:
	profile.weekly = current(profile.weekly, week_of(today))
	return add_hike(profile.weekly, hike_counts(result, trail.par_time if trail != null else 0.0, daily), balance)


## This week's goals: `balance.weekly_goal_count` different ones, the same on every phone.
static func goals_for(week: int, balance: Balance) -> Array[int]:
	var order: Array[int] = DailyChallenge._shuffled(week, Goal.size(), _SALT)
	return order.slice(0, mini(balance.weekly_goal_count, Goal.size()))


static func target(goal: int, balance: Balance) -> int:
	match goal:
		Goal.FINDS:
			return balance.weekly_finds
		Goal.GREAT_PHOTOS:
			return balance.weekly_great_photos
		Goal.SUMMITS:
			return balance.weekly_summits
		Goal.BEAT_PAR:
			return balance.weekly_beat_par
		Goal.DAILIES:
			return balance.weekly_dailies
	return balance.weekly_clean_hikes


## What one hike adds to each goal (unfinished hikes add nothing).
static func hike_counts(result: TrailResult, par_time: float, daily: bool) -> Dictionary:
	if not result.finished:
		return {}
	var great: int = 0
	for vp: Variant in result.photos:
		if int(result.photos[vp]) >= StarRating.PhotoQuality.GREAT:
			great += 1
	return {
		Goal.FINDS: result.finds.size(),
		Goal.GREAT_PHOTOS: great,
		Goal.SUMMITS: 1,
		Goal.BEAT_PAR: 1 if par_time > 0.0 and result.time_seconds <= par_time else 0,
		Goal.DAILIES: 1 if daily else 0,
		Goal.CLEAN_HIKES: 1 if result.falls == 0 and result.stumbles == 0 else 0,
	}


## `state` for `week`, starting over when the week has turned.
static func current(state: Dictionary, week: int) -> Dictionary:
	if int(state.get("week", -1)) == week:
		return state
	return {"week": week, "progress": {}, "done": [], "bonus": false}


## Adds a hike to `state` (in place, after current()). Returns {"done": [goals finished now],
## "tp": paid now, "bonus": true if that made all of them}.
static func add_hike(state: Dictionary, counts: Dictionary, balance: Balance) -> Dictionary:
	var out: Dictionary = {"done": [], "tp": 0, "bonus": false}
	var goals: Array[int] = goals_for(int(state.week), balance)
	var progress: Dictionary = state.progress
	var done: Array = state.done
	for goal: int in goals:
		var key: String = str(goal)
		progress[key] = mini(int(progress.get(key, 0)) + int(counts.get(goal, 0)), target(goal, balance))
		if int(progress[key]) >= target(goal, balance) and not done.has(goal):
			done.append(goal)
			out.done.append(goal)
			out.tp += balance.weekly_goal_tp
	if done.size() >= goals.size() and not bool(state.bonus):
		state.bonus = true
		out.bonus = true
		out.tp += balance.weekly_all_bonus_tp
	return out


## Cleans a saved state (types from JSON, unknown goals dropped).
static func clean(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not (raw as Dictionary).has("week"):
		return {}
	var progress: Dictionary = {}
	var saved: Variant = raw.get("progress", {})
	if saved is Dictionary:
		for k: Variant in saved:
			if str(k).is_valid_int() and int(str(k)) >= 0 and int(str(k)) < Goal.size():
				progress[str(int(str(k)))] = maxi(int(saved[k]), 0)
	var done: Array = []
	var saved_done: Variant = raw.get("done", [])
	if saved_done is Array:
		for g: Variant in saved_done:
			if int(g) >= 0 and int(g) < Goal.size() and not done.has(int(g)):
				done.append(int(g))
	return {"week": int(raw.week), "progress": progress, "done": done, "bonus": bool(raw.get("bonus", false))}
