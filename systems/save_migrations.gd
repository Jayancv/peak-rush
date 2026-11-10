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
