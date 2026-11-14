class_name HikeRewards
extends RefCounted
## Works out everything a hike pays: stars, finds, challenges, shortcuts, the Gold time,
## weekly goals, seasonal collectibles and journey kilometres. Merges the hike into `rec`
## and updates `profile`; returns the breakdown the results screen shows, with "total" =
## TP earned (the daily bonus and badges are GameState's, after this).
## Pure apart from the objects passed in, so the whole payout is testable without autoloads.


static func settle(result: TrailResult, rec: Dictionary, trail: TrailData, profile: PlayerProfile, b: Balance,
		date: String, daily_active: bool, events: Array[EventData], journeys: Array[JourneyData]) -> Dictionary:
	var award: Dictionary = StarRating.new(b).award(result, int(rec.stars), rec.photos)
	var previous_best: float = float(rec.best_time)
	var merged: Dictionary = {"new_finds": 0, "new_challenges": 0}
	if result.finished:
		merged = TrailRecord.merge_finished(rec, result, int(award.stars_mask), trail)
	var new_finds: int = merged.new_finds
	var challenge_tp: int = TrailChallenges.count(merged.new_challenges) * b.tp_per_challenge
	var find_tp: int = new_finds * b.tp_per_new_find
	var shortcut_tp: int = int(merged.get("new_shortcuts", 0)) * b.tp_shortcut
	var gold: float = TrailRecord.gold_time(trail, b) if result.finished else 0.0
	var gold_new: bool = result.finished and not result.stroll and result.time_seconds <= gold and (previous_best <= 0.0 or previous_best > gold)
	var gold_tp: int = b.tp_gold if gold_new else 0
	# Unfinished hikes earn nothing: award and merged are all zeros then. A stroll earns a share.
	var earned: int = int(award.total) + find_tp + challenge_tp + shortcut_tp + gold_tp
	if result.stroll:
		earned = roundi(earned * b.stroll_tp_mult)
	var out: Dictionary = award.duplicate()
	out.merge({
		"trail_id": result.trail_id,
		"finished": result.finished,
		"time": result.time_seconds,
		"before_dusk": result.before_dusk,
		"previous_best": previous_best,
		"new_best": result.finished and not result.stroll and (previous_best <= 0.0 or result.time_seconds < previous_best),
		"stroll": result.stroll,
		"gold_new": gold_new,
		"gold_tp": gold_tp,
		"new_shortcuts": int(merged.get("new_shortcuts", 0)),
		"shortcut_tp": shortcut_tp,
		"first_completion": result.finished and int(rec.completions) == 1,
		"new_finds": new_finds,
		"find_tp": find_tp,
		"new_challenges": merged.new_challenges,
		"challenge_tp": challenge_tp,
		"medal": TrailChallenges.has_medal(int(rec.get("challenges", 0))) and merged.new_challenges != 0,
	})
	out["total"] = earned
	if not result.finished:
		return out
	var weekly: Dictionary = WeeklyGoals.record(profile, result, trail, daily_active, date, b)
	_add(out, "weekly", weekly)
	var ev: EventData = SeasonalEvents.active(events, date)
	if ev != null and result.event_tokens > 0:
		var gathered: Dictionary = SeasonalEvents.record(profile, ev, date, result.event_tokens, b)
		gathered["token_key"] = ev.token_key
		gathered["name_key"] = ev.name_key
		_add(out, "event", gathered)
	var walked: Dictionary = Journey.advance(profile, journeys, b.journey_km_per_hike, b)
	if not walked.is_empty():
		_add(out, "journey", walked)
	return out


static func _add(out: Dictionary, key: String, part: Dictionary) -> void:
	out[key] = part
	out["total"] = int(out.total) + int(part.get("tp", 0))
