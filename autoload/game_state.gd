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
	last_result = award.duplicate()
	last_result.merge({
		"trail_id": result.trail_id,
		"finished": result.finished,
		"time": result.time_seconds,
		"before_dusk": result.before_dusk,
		"previous_best": previous_best,
		"new_best": result.finished and (previous_best <= 0.0 or result.time_seconds < previous_best),
		"first_completion": result.finished and int(rec.completions) == 1,
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


static func _string_list(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item: Variant in value:
			out.append(str(item))
	return out
