extends Node
## The player's progress and settings while the game runs. SaveService turns this
## into JSON and back; nothing here touches files.
## Trail records are keyed by trail id (String, since that's what JSON gives back):
##   {"stars": bitmask, "best_time": seconds or 0, "photos": {viewpoint_id: quality}, "completions": n}

signal settings_changed
signal progress_changed

const DEFAULT_SETTINGS: Dictionary = {
	"left_handed": false,
	"vibration": true,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"ambience_volume": 0.8,
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var tp: int = 0
var trails: Dictionary = {}
var owned_gear: Array[String] = []
var equipped_gear: Array[String] = []
## Last app version whose "What's new" the player saw (M8).
var seen_version: String = ""
## Name, outfit, hike totals and badges (saved under "profile").
var profile: PlayerProfile = PlayerProfile.new()

## Not saved: which trail the runner should load next, and the last results for the results screen.
var current_trail_id: StringName = &""
var last_result: Dictionary = {}


func reset() -> void:
	settings = DEFAULT_SETTINGS.duplicate()
	tp = 0
	trails = {}
	owned_gear = []
	equipped_gear = []
	seen_version = ""
	profile = PlayerProfile.new()
	last_result = {}


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	settings_changed.emit()


# --- Progress queries ---

func record(trail_id: StringName) -> Dictionary:
	return trails.get(String(trail_id), {"stars": 0, "best_time": 0.0, "photos": {}, "completions": 0})


func stars_mask(trail_id: StringName) -> int:
	return int(record(trail_id).stars)


func best_time(trail_id: StringName) -> float:
	return float(record(trail_id).best_time)


func is_completed(trail_id: StringName) -> bool:
	return stars_mask(trail_id) & StarRating.STAR_SUMMIT != 0


## Trails unlock in order within a season; the first trail of every season is always
## open so new players can jump straight into the newest season.
func is_unlocked(trail: TrailData) -> bool:
	var previous: TrailData = ContentDB.previous_trail(trail.id)
	return previous == null or is_completed(previous.id)


func total_stars() -> int:
	var n: int = 0
	for id: String in trails:
		n += StarRating.count(int(trails[id].stars))
	return n


# --- Gear ---

func is_owned(gear_id: StringName) -> bool:
	return owned_gear.has(String(gear_id))


func is_equipped(gear_id: StringName) -> bool:
	return equipped_gear.has(String(gear_id))


## Spends TP on `gear_id`. False if unknown, already owned, or not enough TP.
func buy(gear_id: StringName) -> bool:
	var g: GearData = ContentDB.get_gear(gear_id)
	if g == null or is_owned(gear_id) or tp < g.cost:
		return false
	tp -= g.cost
	owned_gear.append(String(gear_id))
	refresh_badges()
	progress_changed.emit()
	return true


## Equips owned gear. False if not owned or both slots are full.
func equip(gear_id: StringName) -> bool:
	if not is_owned(gear_id) or is_equipped(gear_id) or equipped_gear.size() >= ContentDB.balance.gear_slots:
		return false
	equipped_gear.append(String(gear_id))
	progress_changed.emit()
	return true


func unequip(gear_id: StringName) -> void:
	if is_equipped(gear_id):
		equipped_gear.erase(String(gear_id))
		progress_changed.emit()


func equipped_items() -> Array[GearData]:
	var out: Array[GearData] = []
	for id: String in equipped_gear:
		var g: GearData = ContentDB.get_gear(StringName(id))
		if g != null:
			out.append(g)
	return out


## The trail "Continue" should open: the next unlocked, unfinished one (newest season first).
func next_trail_to_play() -> TrailData:
	return ContentDB.next_unfinished_trail(is_unlocked, is_completed)


# --- Profile ---

func hiker_display_name() -> String:
	return profile.hiker_name if not profile.hiker_name.is_empty() else tr("PROFILE_DEFAULT_NAME")


func set_hiker_name(raw: String) -> void:
	profile.hiker_name = PlayerProfile.clean_name(raw)
	progress_changed.emit()


## What the hiker wears in a slot; unknown or still-locked choices fall back to the default.
func worn(slot: CosmeticData.Slot) -> CosmeticData:
	var item: CosmeticData = ContentDB.get_cosmetic(profile.worn_id(slot))
	if item == null or item.slot != slot or not PlayerProfile.is_unlocked(item, total_stars()):
		return ContentDB.default_cosmetic(slot)
	return item


## False (and nothing changes) if the item is still locked.
func wear(item: CosmeticData) -> bool:
	if not PlayerProfile.is_unlocked(item, total_stars()):
		return false
	profile.wear(item)
	progress_changed.emit()
	return true


## CosmeticData.Slot -> Color for every slot (what HikerVisual paints).
func look_colors() -> Dictionary:
	var out: Dictionary = {}
	for slot: int in CosmeticData.Slot.values():
		var item: CosmeticData = worn(slot)
		if item != null:
			out[slot] = item.color
	return out


## Totals the badges are judged on (see BadgeRules).
func profile_facts() -> Dictionary:
	var finished: int = 0
	var night: int = 0
	var photos: int = 0
	var perfect: int = 0
	for id: String in trails:
		var rec: Dictionary = trails[id]
		if int(rec.stars) & StarRating.STAR_SUMMIT != 0:
			finished += 1
			var trail: TrailData = ContentDB.get_trail(StringName(id))
			if trail != null and trail.night:
				night += 1
		for vp: Variant in rec.photos:
			var q: int = int(rec.photos[vp])
			photos += 1 if q > StarRating.PhotoQuality.NONE else 0
			perfect += 1 if q == StarRating.PhotoQuality.PERFECT else 0
	return {
		"trails_finished": finished, "stars": total_stars(), "photos": photos, "perfect_photos": perfect,
		"hikes": profile.hikes, "night_trails": night, "gear_owned": owned_gear.size(),
		"hike_minutes": int(profile.hike_seconds / 60.0),
	}


## Adds any badges earned since the last check and returns them.
func refresh_badges() -> Array[BadgeData]:
	var earned: Array[BadgeData] = BadgeRules.newly_earned(ContentDB.badge_list(), profile_facts(), profile.badges)
	for badge: BadgeData in earned:
		profile.badges.append(String(badge.id))
	return earned


# --- Recording a hike ---

## Merges a finished hike into the trail's record and pays out TP.
## Returns the breakdown the results screen shows (also kept in last_result).
func record_result(result: TrailResult) -> Dictionary:
	var key: String = String(result.trail_id)
	var rec: Dictionary = record(result.trail_id).duplicate(true)
	var rating: StarRating = StarRating.new(ContentDB.balance)
	var award: Dictionary = rating.award(result, int(rec.stars), rec.photos)
	var previous_best: float = float(rec.best_time)
	if result.finished:
		rec.stars = int(rec.stars) | int(award.stars_mask)
		if previous_best <= 0.0 or result.time_seconds < previous_best:
			rec.best_time = result.time_seconds
		for vp: Variant in result.photos:
			var vp_key: String = String(vp)
			rec.photos[vp_key] = maxi(int(rec.photos.get(vp_key, 0)), int(result.photos[vp]))
		rec.completions = int(rec.completions) + 1
		trails[key] = rec
		tp += int(award.total)
	profile.add_hike(result.time_seconds)
	var new_badges: Array[String] = []
	for badge: BadgeData in refresh_badges():
		new_badges.append(String(badge.id))
	last_result = award.duplicate()
	last_result.merge({
		"trail_id": result.trail_id,
		"finished": result.finished,
		"time": result.time_seconds,
		"before_dusk": result.before_dusk,
		"previous_best": previous_best,
		"new_best": result.finished and (previous_best <= 0.0 or result.time_seconds < previous_best),
		"first_completion": result.finished and int(rec.completions) == 1,
		"new_badges": new_badges,
	})
	progress_changed.emit()
	return last_result


# --- Save format ---

func to_dict() -> Dictionary:
	return {
		"settings": settings.duplicate(),
		"tp": tp,
		"trails": trails.duplicate(true),
		"owned_gear": owned_gear.duplicate(),
		"equipped_gear": equipped_gear.duplicate(),
		"seen_version": seen_version,
		"profile": profile.to_dict(),
	}


## Tolerant of missing or oddly typed fields: a damaged save should lose a field,
## not the whole profile. JSON numbers come back as floats, hence the int() calls.
func from_dict(data: Dictionary) -> void:
	reset()
	var saved_settings: Variant = data.get("settings", {})
	if saved_settings is Dictionary:
		settings.merge(saved_settings, true)
	tp = int(data.get("tp", 0))
	var saved_trails: Variant = data.get("trails", {})
	if saved_trails is Dictionary:
		for id: Variant in saved_trails:
			var r: Variant = saved_trails[id]
			if r is Dictionary:
				trails[String(id)] = {
					"stars": int(r.get("stars", 0)) & StarRating.ALL_STARS,
					"best_time": float(r.get("best_time", 0.0)),
					"photos": r.get("photos", {}) if r.get("photos", {}) is Dictionary else {},
					"completions": int(r.get("completions", 0)),
				}
	owned_gear = _string_list(data.get("owned_gear", []))
	equipped_gear = _string_list(data.get("equipped_gear", []))
	seen_version = str(data.get("seen_version", ""))
	var saved_profile: Variant = data.get("profile", {})
	if saved_profile is Dictionary:
		profile.from_dict(saved_profile)
	# Saves from before badges existed get what they've already earned, quietly.
	refresh_badges()


static func _string_list(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item: Variant in value:
			out.append(str(item))
	return out
