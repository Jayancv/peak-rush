class_name TrailRecord
extends RefCounted
## One trail's saved record, as a plain Dictionary (that's what the save JSON holds):
##   {"stars": bitmask, "best_time": seconds or 0, "photos": {viewpoint_id: quality},
##    "completions": n, "finds": [find ids]}
## Pure helpers so GameState stays small and the rules are testable.


static func empty() -> Dictionary:
	return {"stars": 0, "best_time": 0.0, "photos": {}, "completions": 0, "finds": []}


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
	}


## Folds a finished hike into `rec` (in place): stars, best time, best photo per
## viewpoint, completions and finds. Returns how many finds were new.
static func merge_finished(rec: Dictionary, result: TrailResult, stars_mask: int) -> int:
	rec.stars = int(rec.stars) | stars_mask
	var previous_best: float = float(rec.best_time)
	if previous_best <= 0.0 or result.time_seconds < previous_best:
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
	return new_finds


## A JSON array as Array[String] (anything else becomes an empty list).
static func string_list(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item: Variant in value:
			out.append(str(item))
	return out
