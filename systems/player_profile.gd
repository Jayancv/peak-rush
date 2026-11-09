class_name PlayerProfile
extends RefCounted
## Who the player is: their hiker's name and outfit, totals that aren't kept per
## trail (hikes, time on the trail) and the badges they've earned. GameState owns
## one and saves it under "profile".

const MAX_NAME_LENGTH: int = 16

var hiker_name: String = ""
## Slot name ("HAT", "JACKET", ...) -> cosmetic id. Missing slots use the default.
var look: Dictionary = {}
var hikes: int = 0
var hike_seconds: float = 0.0
var badges: Array[String] = []


static func slot_key(slot: CosmeticData.Slot) -> String:
	return CosmeticData.Slot.keys()[slot]


## Trims and shortens a typed name; empty means "use the default name".
static func clean_name(raw: String) -> String:
	return raw.strip_edges().left(MAX_NAME_LENGTH)


static func is_unlocked(item: CosmeticData, total_stars: int) -> bool:
	return item.stars_required <= total_stars


func worn_id(slot: CosmeticData.Slot) -> StringName:
	return StringName(str(look.get(slot_key(slot), "")))


func wear(item: CosmeticData) -> void:
	look[slot_key(item.slot)] = String(item.id)


func add_hike(seconds: float) -> void:
	hikes += 1
	hike_seconds += maxf(seconds, 0.0)


func to_dict() -> Dictionary:
	return {
		"name": hiker_name,
		"look": look.duplicate(),
		"hikes": hikes,
		"hike_seconds": hike_seconds,
		"badges": badges.duplicate(),
	}


## Tolerant like GameState.from_dict: a bad field is dropped, not the whole profile.
func from_dict(data: Dictionary) -> void:
	hiker_name = clean_name(str(data.get("name", "")))
	look = {}
	var saved_look: Variant = data.get("look", {})
	if saved_look is Dictionary:
		for slot: Variant in saved_look:
			look[str(slot)] = str(saved_look[slot])
	hikes = maxi(int(data.get("hikes", 0)), 0)
	hike_seconds = maxf(float(data.get("hike_seconds", 0.0)), 0.0)
	badges = []
	var saved_badges: Variant = data.get("badges", [])
	if saved_badges is Array:
		for id: Variant in saved_badges:
			badges.append(str(id))
