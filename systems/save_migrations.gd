class_name SaveMigrations
extends RefCounted
## One step per save format change. step(n, data) turns a version-n save into n + 1.
## Never edit an old step once it has shipped: players' files depend on it.


static func step(from_version: int, data: Dictionary) -> Dictionary:
	match from_version:
		0:
			return _v0_to_v1(data)
		1:
			return _v1_to_v2(data)
		2:
			return _v2_to_v3(data)
		3:
			return _v3_to_v4(data)
		4:
			return _v4_to_v5(data)
		5:
			return _v5_to_v6(data)
		6:
			return _v6_to_v7(data)
		7:
			return _v7_to_v8(data)
		8:
			return _v8_to_v9(data)
	push_error("SaveMigrations: no step from version %d" % from_version)
	return data


## v0 is the pre-release prototype shape (no save_version, stars stored as a count
## per trail under "stars", TP under "points"). No v0 file shipped to players;
## this first link exists so the chain is exercised by tests from day one.
static func _v0_to_v1(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if out.has("points") and not out.has("tp"):
		out["tp"] = out["points"]
	out.erase("points")
	var trails: Dictionary = out.get("trails", {}) if out.get("trails", {}) is Dictionary else {}
	var old_stars: Variant = out.get("stars", {})
	if old_stars is Dictionary:
		for id: Variant in old_stars:
			# A star count n becomes the lowest n bits (★1 summit first).
			var n: int = clampi(int(old_stars[id]), 0, 3)
			var rec: Dictionary = trails.get(id, {})
			rec["stars"] = (1 << n) - 1
			trails[id] = rec
	out.erase("stars")
	out["trails"] = trails
	return out


## v2 adds the player profile (name, outfit, hike totals, badges). Old saves start
## with an empty one; badges they already qualify for are awarded on the next check.
static func _v1_to_v2(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if not (out.get("profile") is Dictionary):
		out["profile"] = {"name": "", "look": {}, "hikes": 0, "hike_seconds": 0.0, "badges": []}
	return out


## v3 records which finds (flowers, items, animals) each trail has given up.
static func _v2_to_v3(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var trails: Variant = out.get("trails", {})
	if trails is Dictionary:
		for id: Variant in trails:
			var rec: Variant = trails[id]
			if rec is Dictionary and not (rec.get("finds") is Array):
				rec["finds"] = []
	return out


## v4 adds the daily trail streak to the profile.
static func _v3_to_v4(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var profile: Variant = out.get("profile", {})
	if not (profile is Dictionary):
		profile = {}
	if not profile.has("daily_last"):
		profile["daily_last"] = ""
	if not profile.has("daily_streak"):
		profile["daily_streak"] = 0
	out["profile"] = profile
	return out


## v5: first-time hints are remembered across hikes (profile.hints_seen), and the day's
## daily is pinned (profile.daily_pick), and trail records get "challenges". Existing players start with no hints seen: the
## hints cover mechanics added after their first hikes.
static func _v4_to_v5(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var profile: Variant = out.get("profile", {})
	if not (profile is Dictionary):
		profile = {}
	if not profile.has("hints_seen"):
		profile["hints_seen"] = []
	if not profile.has("daily_pick"):
		profile["daily_pick"] = {}
	out["profile"] = profile
	# Trail challenges (bitmask per trail record), none met yet.
	var trails: Variant = out.get("trails", {})
	if trails is Dictionary:
		for id: Variant in trails:
			if trails[id] is Dictionary and not trails[id].has("challenges"):
				trails[id]["challenges"] = 0
	return out


## v6 adds the real-world step counter (StepLedger), off until the player opts in.
static func _v5_to_v6(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if not (out.get("steps") is Dictionary):
		out["steps"] = {"enabled": false, "opt_in_unix": 0, "opt_in_date": "", "claimed": {}, "lifetime_steps": 0, "last_sync_unix": 0}
	return out


## v7: weekly goals live in the profile (an empty state = this week's goals start at zero).
static func _v6_to_v7(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if out.get("profile") is Dictionary and not (out.profile.get("weekly") is Dictionary):
		out.profile["weekly"] = {}
	return out


## v8: each trail record lists the hidden shortcuts found (none yet).
static func _v7_to_v8(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if out.get("trails") is Dictionary:
		for id: Variant in out.trails:
			if out.trails[id] is Dictionary and not (out.trails[id].get("shortcuts") is Array):
				out.trails[id]["shortcuts"] = []
	return out


## v9: seasonal event collectibles in the profile (none gathered yet).
static func _v8_to_v9(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	if out.get("profile") is Dictionary:
		if not (out.profile.get("events") is Dictionary):
			out.profile["events"] = {}
		if not (out.profile.get("events_done") is Array):
			out.profile["events_done"] = []
	return out
