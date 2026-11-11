class_name ProfileFacts
extends RefCounted
## Counts the totals badges are judged on from the saved trail records. Pure: the
## trail lookup is passed in, so tests can use hand-made trails.


## `trail_lookup` is a Callable(StringName) -> TrailData (ContentDB.get_trail in the game).
## `real_steps` / `real_km` come from the StepLedger (real-world steps from the phone).
static func build(trails: Dictionary, profile: PlayerProfile, gear_owned: int, stars: int, trail_lookup: Callable,
		real_steps: int = 0, real_km: float = 0.0) -> Dictionary:
	var finished: int = 0
	var night: int = 0
	var photos: int = 0
	var perfect: int = 0
	var found: int = 0
	var animals: int = 0
	for id: String in trails:
		var rec: Dictionary = trails[id]
		var trail: TrailData = trail_lookup.call(StringName(id)) as TrailData
		if int(rec.stars) & StarRating.STAR_SUMMIT != 0:
			finished += 1
			if trail != null and trail.night:
				night += 1
		for f: Variant in rec.get("finds", []):
			var data: FindData = trail.get_find(StringName(str(f))) if trail != null else null
			if data != null and data.kind == FindData.Kind.ANIMAL:
				animals += 1
			else:
				found += 1
		for vp: Variant in rec.photos:
			var q: int = int(rec.photos[vp])
			photos += 1 if q > StarRating.PhotoQuality.NONE else 0
			perfect += 1 if q == StarRating.PhotoQuality.PERFECT else 0
	return {
		"trails_finished": finished, "stars": stars, "photos": photos, "perfect_photos": perfect,
		"hikes": profile.hikes, "night_trails": night, "gear_owned": gear_owned,
		"hike_minutes": int(profile.hike_seconds / 60.0), "finds": found, "animals": animals,
		"real_steps": real_steps, "real_km": int(real_km),
	}
