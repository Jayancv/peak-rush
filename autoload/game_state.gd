extends Node
## The player's progress and settings while the game runs. SaveService turns this
## into JSON and back; nothing here touches files.
## Trail records are keyed by trail id (String, since that's what JSON gives back); see TrailRecord.

signal settings_changed
signal progress_changed

const DEFAULT_SETTINGS: Dictionary = {
	"left_handed": false,
	"vibration": true,
	"reduce_motion": false,
	## "" until asked, then "personalized" / "non_personalized" (Ads.ensure_consent).
	"ad_consent": "",
	## Set once the store review request has been made (ReviewPrompt; never asked twice).
	"review_asked": false,
	## Trail select's Stroll switch: hikes without the daylight clock (never for the daily).
	"stroll_mode": false,
	## Show the ghost of your best run on a trail.
	"show_ghost": true,
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
## Real-world steps from the phone (saved under "steps"; see Steps for the reading side).
var steps: StepLedger = StepLedger.new()

## Not saved: which trail the runner should load next, and the last results for the results screen.
var current_trail_id: StringName = &""
## True while the current hike is today's daily trail.
var daily_active: bool = false
var last_result: Dictionary = {}


func reset() -> void:
	settings = DEFAULT_SETTINGS.duplicate()
	tp = 0
	trails = {}
	owned_gear = []
	equipped_gear = []
	seen_version = ""
	profile = PlayerProfile.new()
	steps = StepLedger.new()
	last_result = {}


## "Reset progress" in About: everything goes except the settings (volumes, controls).
func reset_progress() -> void:
	var keep: Dictionary = settings.duplicate()
	reset()
	settings = keep
	progress_changed.emit()


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	settings_changed.emit()


# --- Progress queries ---

func record(trail_id: StringName) -> Dictionary:
	return trails.get(String(trail_id), TrailRecord.empty())


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


func unlocked_trails() -> Array[TrailData]:
	var open: Array[TrailData] = []
	for season: SeasonData in ContentDB.seasons():
		open.append_array(season.ordered_trails().filter(is_unlocked))
	return open


func total_stars() -> int:
	var n: int = 0
	for id: String in trails:
		n += StarRating.count(int(trails[id].stars))
	return n


## Whether the hike being started is a stroll (the daily trail is always a real hike).
func stroll_hike() -> bool:
	return bool(settings.get("stroll_mode", false)) and not daily_active


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


## What the hiker wears in a slot (locked or unknown choices fall back to the default).
func worn(slot: CosmeticData.Slot) -> CosmeticData:
	return profile.worn_item(slot, total_stars(), ContentDB.get_cosmetic, ContentDB.default_cosmetic)


## False (and nothing changes) if the item is still locked.
func wear(item: CosmeticData) -> bool:
	if not PlayerProfile.is_unlocked(item, total_stars()):
		return false
	profile.wear(item)
	progress_changed.emit()
	return true


func look_colors() -> Dictionary:
	return profile.look_colors(total_stars(), ContentDB.get_cosmetic, ContentDB.default_cosmetic)


## Totals the badges are judged on (see BadgeRules / ProfileFacts).
func profile_facts() -> Dictionary:
	return ProfileFacts.build(trails, profile, owned_gear.size(), total_stars(), ContentDB.get_trail,
		steps.lifetime_steps, steps.lifetime_km(ContentDB.balance))


## Adds any badges earned since the last check and returns them.
func refresh_badges() -> Array[BadgeData]:
	var earned: Array[BadgeData] = BadgeRules.newly_earned(ContentDB.badge_list(), profile_facts(), profile.badges)
	for badge: BadgeData in earned:
		profile.badges.append(String(badge.id))
	return earned


# --- Daily trail ---

func today() -> String:
	return Time.get_date_string_from_system()


## Today's challenge: trail_id, twist, date, done (empty if nothing is unlocked).
## Pinned for the day once worked out (unlocking a trail mustn't change it).
func daily_today() -> Dictionary:
	var date: String = today()
	var c: Dictionary = profile.daily_for(date,
		func() -> Dictionary: return DailyChallenge.for_date(date, unlocked_trails(), ContentDB.balance), ContentDB.has_trail)
	if not c.is_empty():
		c["date"] = date
		c["done"] = profile.daily_done_on(date)
	return c


func _record_daily(result: TrailResult) -> void:
	daily_active = false
	var out: Dictionary = DailyChallenge.settle(daily_today(), result, ContentDB.get_trail(result.trail_id), profile, ContentDB.balance)
	if not out.is_empty():
		last_result["daily"] = out
		tp += int(out.get("bonus", 0))
		last_result["total"] = int(last_result.get("total", 0)) + int(out.get("bonus", 0))


# --- Recording a hike ---

## Merges a finished hike into the trail's record and pays out TP (HikeRewards does the sums).
## Returns the breakdown the results screen shows (also kept in last_result).
func record_result(result: TrailResult) -> Dictionary:
	var rec: Dictionary = record(result.trail_id).duplicate(true)
	last_result = HikeRewards.settle(result, rec, ContentDB.get_trail(result.trail_id), profile, ContentDB.balance,
		today(), daily_active, ContentDB.events(), ContentDB.journeys())
	if result.finished:
		trails[String(result.trail_id)] = rec
	tp += int(last_result.total)
	profile.add_hike(result.time_seconds)
	var new_badges: Array[String] = []
	for badge: BadgeData in refresh_badges():
		new_badges.append(String(badge.id))
	last_result["new_badges"] = new_badges
	if daily_active:
		_record_daily(result)
	progress_changed.emit()
	return last_result


## TP from a watched rewarded ad on the results screen (Ads / AdPolicy decide the amount).
func add_bonus_tp(amount: int) -> void:
	tp += maxi(amount, 0)
	last_result["ad_bonus"] = amount
	progress_changed.emit()


## Pays out real-world steps read from the phone (`totals`: date -> steps). Returns {tp, steps, badges}
## and "journey" (Journey.advance) when the steps moved the journey on.
func claim_steps(totals: Dictionary) -> Dictionary:
	var out: Dictionary = steps.claim(totals, today(), int(Time.get_unix_time_from_system()), ContentDB.balance)
	tp += int(out.tp)
	# Real steps also walk the long journey (Journey).
	var walked: Dictionary = Journey.advance(profile, ContentDB.journeys(), Journey.km_from_steps(int(out.steps), ContentDB.balance), ContentDB.balance)
	if not walked.is_empty() and float(walked.added) > 0.0:
		tp += int(walked.tp)
		out["journey"] = walked
	out["badges"] = refresh_badges()
	progress_changed.emit()
	return out


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
		"steps": steps.to_dict(),
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
			if saved_trails[id] is Dictionary:
				trails[String(id)] = TrailRecord.clean(saved_trails[id])
	owned_gear = TrailRecord.string_list(data.get("owned_gear", []))
	equipped_gear = TrailRecord.string_list(data.get("equipped_gear", []))
	seen_version = str(data.get("seen_version", ""))
	var saved_profile: Variant = data.get("profile", {})
	if saved_profile is Dictionary:
		profile.from_dict(saved_profile)
	var saved_steps: Variant = data.get("steps", {})
	if saved_steps is Dictionary:
		steps.from_dict(saved_steps)
	# Saves from before badges existed get what they've already earned, quietly.
	refresh_badges()


# --- The long journey ---

## The journey being walked (null when all are done); opening it unlocks its first page.
func journey() -> JourneyData:
	Journey.advance(profile, ContentDB.journeys(), 0.0, ContentDB.balance)
	return Journey.active(ContentDB.journeys(), profile)
