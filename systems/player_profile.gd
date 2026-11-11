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
## Daily trail: the last date ("YYYY-MM-DD") it was completed, and the streak.
var daily_last: String = ""
var daily_streak: int = 0
## Today's daily, pinned when first worked out ({date, trail_id, twist}), so finishing a
## trail (which unlocks the next) can't swap the daily for another one mid-day.
var daily_pick: Dictionary = {}
## First-time hints already shown (hint keys), so each explains itself only once ever.
var hints_seen: Array[String] = []


static func slot_key(slot: CosmeticData.Slot) -> String:
	return CosmeticData.Slot.keys()[slot]


## Trims and shortens a typed name; empty means "use the default name".
static func clean_name(raw: String) -> String:
	return raw.strip_edges().left(MAX_NAME_LENGTH)


static func is_unlocked(item: CosmeticData, total_stars: int) -> bool:
	return item.stars_required <= total_stars


func worn_id(slot: CosmeticData.Slot) -> StringName:
	return StringName(str(look.get(slot_key(slot), "")))


## What the hiker wears in `slot`: the chosen item, or the default if it's unknown or
## still locked. `lookup(id)` and `fallback(slot)` come from ContentDB.
func worn_item(slot: CosmeticData.Slot, total_stars: int, lookup: Callable, fallback: Callable) -> CosmeticData:
	var item: CosmeticData = lookup.call(worn_id(slot)) as CosmeticData
	if item == null or item.slot != slot or not is_unlocked(item, total_stars):
		return fallback.call(slot) as CosmeticData
	return item


## CosmeticData.Slot -> Color for every slot (what HikerVisual paints).
func look_colors(total_stars: int, lookup: Callable, fallback: Callable) -> Dictionary:
	var out: Dictionary = {}
	for slot: int in CosmeticData.Slot.values():
		var item: CosmeticData = worn_item(slot, total_stars, lookup, fallback)
		if item != null:
			out[slot] = item.color
	return out


func wear(item: CosmeticData) -> void:
	look[slot_key(item.slot)] = String(item.id)


func daily_done_on(date: String) -> bool:
	return DailyChallenge.is_done(daily_last, date)


## Records today's daily as done; returns the new streak.
func complete_daily(today: String) -> int:
	daily_streak = DailyChallenge.next_streak(daily_last, today, daily_streak)
	daily_last = today
	return daily_streak


## The daily for `date`: the pinned one if it's for that date (and `still_valid` accepts
## its trail id), else `pick_new` is called and its answer pinned.
func daily_for(date: String, pick_new: Callable, still_valid: Callable) -> Dictionary:
	if daily_pick.get("date", "") == date and still_valid.call(StringName(daily_pick.trail_id)):
		return {"trail_id": StringName(daily_pick.trail_id), "twist": int(daily_pick.twist)}
	var c: Dictionary = pick_new.call()
	if not c.is_empty():
		daily_pick = {"date": date, "trail_id": String(c.trail_id), "twist": int(c.twist)}
	return c


func has_seen_hint(key: String) -> bool:
	return hints_seen.has(key)


func mark_hint_seen(key: String) -> void:
	if not hints_seen.has(key):
		hints_seen.append(key)


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
		"daily_last": daily_last,
		"daily_streak": daily_streak,
		"hints_seen": hints_seen.duplicate(),
		"daily_pick": daily_pick.duplicate(),
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
	daily_last = str(data.get("daily_last", ""))
	daily_streak = maxi(int(data.get("daily_streak", 0)), 0)
	hints_seen = TrailRecord.string_list(data.get("hints_seen", []))
	var pick: Variant = data.get("daily_pick", {})
	daily_pick = {}
	if pick is Dictionary and pick.has("date") and pick.has("trail_id") and pick.has("twist"):
		daily_pick = {"date": str(pick.date), "trail_id": str(pick.trail_id), "twist": int(pick.twist)}
	badges = []
	var saved_badges: Variant = data.get("badges", [])
	if saved_badges is Array:
		for id: Variant in saved_badges:
			badges.append(str(id))
