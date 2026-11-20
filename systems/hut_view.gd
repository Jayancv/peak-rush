class_name HutView
extends RefCounted
## What the hut on the title screen shows: the light outside the window by the real
## clock, the weather by the real month, and the keepsakes (finds on the shelf,
## the best postcards on the wall). Pure, so the rules are testable.

enum Phase { DAWN, DAY, DUSK, NIGHT }
enum Weather { NONE, SNOW, BLOSSOM, LEAVES }


static func phase(hour: float, b: Balance) -> Phase:
	if hour < b.hut_dawn_hour or hour >= b.hut_night_hour:
		return Phase.NIGHT
	if hour < b.hut_day_hour:
		return Phase.DAWN
	if hour < b.hut_dusk_hour:
		return Phase.DAY
	return Phase.DUSK


## 0 when the sun rises (dawn), 1 when it has set (night), for the backdrop's sun arc.
static func sun_progress(hour: float, b: Balance) -> float:
	return clampf(inverse_lerp(b.hut_dawn_hour, b.hut_night_hour, hour), 0.0, 1.0)


## The colour the view outside is multiplied by: the trail daylight tints, keyed to the hour.
static func tint(hour: float, b: Balance) -> Color:
	var keys: Array[Array] = [
		[b.hut_dawn_hour - 1.0, b.hut_night_tint],
		[b.hut_dawn_hour + 0.5, b.tint_morning],
		[b.hut_day_hour, b.tint_midday],
		# Plain daylight until the afternoon, then the golden hour builds toward dusk.
		[b.hut_dusk_hour - 2.0, b.tint_midday],
		[b.hut_dusk_hour, b.tint_golden],
		[b.hut_night_hour - 0.5, b.tint_dusk],
		[b.hut_night_hour + 0.5, b.hut_night_tint],
	]
	if hour <= float(keys[0][0]) or hour >= float(keys[-1][0]):
		return b.hut_night_tint
	for i: int in range(1, keys.size()):
		if hour <= float(keys[i][0]):
			var t: float = inverse_lerp(float(keys[i - 1][0]), float(keys[i][0]), hour)
			return (keys[i - 1][1] as Color).lerp(keys[i][1] as Color, t)
	return b.hut_night_tint


## Snow from November to February, blossom in spring, falling leaves in autumn.
static func weather(month: int) -> Weather:
	if month >= 11 or month <= 2:
		return Weather.SNOW
	if month >= 3 and month <= 5:
		return Weather.BLOSSOM
	if month >= 9:
		return Weather.LEAVES
	return Weather.NONE


## Finds the player has, for the shelf: Elsa's traces first (they matter most), then the
## rest in trail order. `records` maps trail id -> TrailRecord dictionary.
static func shelf_finds(records: Dictionary, trails: Array[TrailData], limit: int) -> Array[FindData]:
	var traces: Array[FindData] = []
	var others: Array[FindData] = []
	for t: TrailData in trails:
		var have: Array = (records.get(String(t.id), {}) as Dictionary).get("finds", [])
		for f: FindData in t.finds:
			if have.has(String(f.id)):
				(traces if f.kind == FindData.Kind.TRACE else others).append(f)
	var out: Array[FindData] = traces + others
	return out.slice(0, maxi(limit, 0))


## The best photos for the wall, best quality first (ties: trail order), as
## {"trail": TrailData, "viewpoint": ViewpointData, "quality": int, "order": int}.
## "order" is the tie-break, because sort_custom isn't stable.
static func wall_postcards(records: Dictionary, trails: Array[TrailData], limit: int) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for t: TrailData in trails:
		var photos: Dictionary = (records.get(String(t.id), {}) as Dictionary).get("photos", {})
		for vp: ViewpointData in t.viewpoints:
			var q: int = int(photos.get(String(vp.id), 0))
			if q > StarRating.PhotoQuality.NONE:
				cards.append({"trail": t, "viewpoint": vp, "quality": q, "order": cards.size()})
	cards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.quality > b.quality or (a.quality == b.quality and a.order < b.order))
	return cards.slice(0, maxi(limit, 0))
