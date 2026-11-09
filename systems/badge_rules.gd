class_name BadgeRules
extends RefCounted
## Decides which badges a player has earned from a "facts" dictionary of totals
## (built by GameState from the save). Pure, so it's easy to test.
## Facts keys: trails_finished, stars, photos, perfect_photos, hikes, night_trails,
## gear_owned, hike_minutes (all ints; missing keys count as 0).

const FACT_FOR_RULE: Dictionary = {
	BadgeData.Rule.TRAILS_FINISHED: "trails_finished",
	BadgeData.Rule.STARS: "stars",
	BadgeData.Rule.PHOTOS: "photos",
	BadgeData.Rule.PERFECT_PHOTOS: "perfect_photos",
	BadgeData.Rule.HIKES: "hikes",
	BadgeData.Rule.NIGHT_TRAILS: "night_trails",
	BadgeData.Rule.GEAR_OWNED: "gear_owned",
	BadgeData.Rule.HIKE_MINUTES: "hike_minutes",
}


## How far along a badge is: the counted value, capped at what's needed.
static func progress(badge: BadgeData, facts: Dictionary) -> int:
	var value: int = int(facts.get(FACT_FOR_RULE.get(badge.rule, ""), 0))
	return mini(value, badge.amount)


static func is_earned(badge: BadgeData, facts: Dictionary) -> bool:
	return progress(badge, facts) >= badge.amount


## Badges that are earned now but weren't in `already` (ids), in catalog order.
static func newly_earned(badges: Array[BadgeData], facts: Dictionary, already: Array[String]) -> Array[BadgeData]:
	var out: Array[BadgeData] = []
	for badge: BadgeData in badges:
		if not already.has(String(badge.id)) and is_earned(badge, facts):
			out.append(badge)
	return out
