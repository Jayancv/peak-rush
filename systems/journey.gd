class_name Journey
extends RefCounted
## The long journey walked over weeks (Kungsleden first): real steps and finished hikes
## add kilometres, and each landmark passed unlocks a notebook page. Journeys are played
## in ContentIndex order; the profile keeps km per journey, the pages unlocked and read,
## and the journeys finished (save v10). Pure: content and balance come in as arguments.


## The journey being walked now (the first not finished), or null when all are done.
static func active(journeys: Array[JourneyData], profile: PlayerProfile) -> JourneyData:
	for j: JourneyData in journeys:
		if j != null and not profile.journeys_done.has(String(j.id)):
			return j
	return null


static func km(profile: PlayerProfile, j: JourneyData) -> float:
	return float(profile.journeys.get(String(j.id), 0.0))


static func page_key(j: JourneyData, lm: LandmarkData) -> String:
	return "%s/%s" % [j.id, lm.id]


static func is_reached(profile: PlayerProfile, j: JourneyData, lm: LandmarkData) -> bool:
	return profile.journey_pages.has(page_key(j, lm))


## The next landmark not reached yet (null once at the end).
static func next_landmark(profile: PlayerProfile, j: JourneyData) -> LandmarkData:
	for lm: LandmarkData in j.landmarks:
		if not is_reached(profile, j, lm):
			return lm
	return null


## Real steps -> journey km: real kilometres count journey_real_km_mult times over, so a
## few weeks of everyday walking covers a trail that takes a month on foot.
static func km_from_steps(steps: int, balance: Balance) -> float:
	return maxf(steps, 0) * balance.step_length_m / 1000.0 * balance.journey_real_km_mult


## Walks `add_km` further on the active journey (0 just opens it: the km-0 page).
## Returns {} when there is nothing to walk, else {journey_id, name_key, added, km, length,
## pages: [LandmarkData], tp, finished}.
static func advance(profile: PlayerProfile, journeys: Array[JourneyData], add_km: float, balance: Balance) -> Dictionary:
	var j: JourneyData = active(journeys, profile)
	if j == null:
		return {}
	var before: float = km(profile, j)
	var now: float = minf(before + maxf(add_km, 0.0), j.length_km)
	profile.journeys[String(j.id)] = now
	var pages: Array[LandmarkData] = []
	var tp: int = 0
	for lm: LandmarkData in j.landmarks:
		if lm.km <= now + 0.001 and not is_reached(profile, j, lm):
			profile.journey_pages.append(page_key(j, lm))
			pages.append(lm)
			# The opening page is a welcome, not a reward.
			tp += balance.journey_landmark_tp if lm.km > 0.0 else 0
	var finished: bool = now >= j.length_km and next_landmark(profile, j) == null
	if finished:
		profile.journeys_done.append(String(j.id))
		tp += balance.journey_finish_tp
	return {"journey_id": j.id, "name_key": j.name_key, "added": now - before, "km": now,
		"length": j.length_km, "pages": pages, "tp": tp, "finished": finished}


## Pages unlocked but not opened yet (the menu's "new page" dot).
static func unread(profile: PlayerProfile) -> int:
	var count: int = 0
	for key: String in profile.journey_pages:
		if not profile.journey_seen.has(key):
			count += 1
	return count


static func mark_read(profile: PlayerProfile, j: JourneyData, lm: LandmarkData) -> void:
	var key: String = page_key(j, lm)
	if profile.journey_pages.has(key) and not profile.journey_seen.has(key):
		profile.journey_seen.append(key)


## Where the walker stands on the map: between the two landmarks around `at_km`.
static func map_position(j: JourneyData, at_km: float) -> Vector2:
	if j.landmarks.is_empty():
		return Vector2.ZERO
	var prev: LandmarkData = j.landmarks[0]
	for lm: LandmarkData in j.landmarks:
		if lm.km >= at_km:
			var span: float = lm.km - prev.km
			var t: float = 0.0 if span <= 0.0 else (at_km - prev.km) / span
			return prev.map_pos.lerp(lm.map_pos, clampf(t, 0.0, 1.0))
		prev = lm
	return prev.map_pos
