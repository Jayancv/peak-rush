class_name TrailRecord
extends RefCounted
## One trail's saved record, as a plain Dictionary (that's what the save JSON holds):
##   {"stars": bitmask, "best_time": seconds or 0, "photos": {viewpoint_id: quality},
##    "completions": n, "finds": [find ids], "challenges": TrailChallenges bitmask,
##    "shortcuts": [hidden shortcut ids found]}
## Pure helpers so GameState stays small and the rules are testable.


static func empty() -> Dictionary:
	return {"stars": 0, "best_time": 0.0, "photos": {}, "completions": 0, "finds": [], "challenges": 0, "shortcuts": []}


## A record read back from a save, with every field forced to the right type.
## Tolerant: a damaged field falls back to its default instead of failing the record.
static func clean(raw: Dictionary) -> Dictionary:
	var photos: Variant = raw.get("photos", {})
	return {
		"stars": int(raw.get("stars", 0)) & StarRating.ALL_STARS,
		"best_time": float(raw.get("best_time", 0.0)),
		"photos": photos if photos is Dictionary else {},
		"completions": int(raw.get("completions", 0)),
		"finds": string_list(raw.get("finds", [])),
		"challenges": int(raw.get("challenges", 0)) & TrailChallenges.ALL,
		"shortcuts": string_list(raw.get("shortcuts", [])),
	}


## Folds a finished hike into `rec` (in place): stars, best time, best photo per
## viewpoint, completions, finds and challenges (when `trail` is given).
## Returns {"new_finds": n, "new_challenges": bitmask, "new_shortcuts": n}.
static func merge_finished(rec: Dictionary, result: TrailResult, stars_mask: int, trail: TrailData = null) -> Dictionary:
	rec.stars = int(rec.stars) | stars_mask
	var previous_best: float = float(rec.best_time)
	# A stroll has no clock to beat.
	if not result.stroll and (previous_best <= 0.0 or result.time_seconds < previous_best):
		rec.best_time = result.time_seconds
	for vp: Variant in result.photos:
		var vp_key: String = String(vp)
		rec.photos[vp_key] = maxi(int(rec.photos.get(vp_key, 0)), int(result.photos[vp]))
	rec.completions = int(rec.completions) + 1
	var known: Array = rec.get("finds", [])
	var new_finds: int = 0
	for f: StringName in result.finds:
		if not known.has(String(f)):
			known.append(String(f))
			new_finds += 1
	rec["finds"] = known
	var found: Array = rec.get("shortcuts", [])
	var new_shortcuts: int = 0
	for sc: StringName in result.shortcuts:
		if not found.has(String(sc)):
			found.append(String(sc))
			new_shortcuts += 1
	rec["shortcuts"] = found
	var new_challenges: int = 0
	if trail != null:
		new_challenges = TrailChallenges.newly_met(int(rec.get("challenges", 0)), result, trail)
		rec["challenges"] = int(rec.get("challenges", 0)) | new_challenges
	return {"new_finds": new_finds, "new_challenges": new_challenges, "new_shortcuts": new_shortcuts}


## The Gold time for a trail (par x Balance.gold_time_ratio).
static func gold_time(trail: TrailData, balance: Balance) -> float:
	return trail.par_time * balance.gold_time_ratio


static func has_gold(rec: Dictionary, trail: TrailData, balance: Balance) -> bool:
	var best: float = float(rec.get("best_time", 0.0))
	return trail != null and best > 0.0 and best <= gold_time(trail, balance)


## A JSON array as Array[String] (anything else becomes an empty list).
static func string_list(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item: Variant in value:
			out.append(str(item))
	return out
