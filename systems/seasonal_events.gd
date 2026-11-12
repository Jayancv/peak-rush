class_name SeasonalEvents
extends RefCounted
## Which seasonal event is on for a date, and the bookkeeping for its collectibles:
## the profile keeps a count per event and year ("autumn_2026": 12) and a list of the
## event-years whose goal has been paid. Pure: dates come in as "YYYY-MM-DD" strings.


## The event running on `date`, or null.
static func active(events: Array[EventData], date: String) -> EventData:
	var md: String = date.substr(5, 5)
	for ev: EventData in events:
		if ev != null and covers(ev, md):
			return ev
	return null


## Whether "MM-DD" `md` falls inside the event (which may wrap over New Year).
static func covers(ev: EventData, md: String) -> bool:
	if ev.start <= ev.end:
		return md >= ev.start and md <= ev.end
	return md >= ev.start or md <= ev.end


## "autumn_2026": the year the event started (a winter event in January counts for the
## December it began in), so each year's event is a fresh collection.
static func key_for(ev: EventData, date: String) -> String:
	var year: int = int(date.substr(0, 4))
	if ev.start > ev.end and date.substr(5, 5) <= ev.end:
		year -= 1
	return "%s_%d" % [ev.id, year]


## Days left including today (for "ends in N days").
static func days_left(ev: EventData, date: String) -> int:
	var year: int = int(date.substr(0, 4))
	var end_year: int = year if ev.start <= ev.end or date.substr(5, 5) <= ev.end else year + 1
	var today: int = Time.get_unix_time_from_datetime_string(date + "T00:00:00")
	var last: int = Time.get_unix_time_from_datetime_string("%d-%s" % [end_year, ev.end] + "T00:00:00")
	return maxi(int((last - today) / 86400.0) + 1, 0)


## Adds `tokens` gathered on a hike. Returns {"key", "count", "goal", "tp", "done_now"}.
static func record(profile: PlayerProfile, ev: EventData, date: String, tokens: int, balance: Balance) -> Dictionary:
	var key: String = key_for(ev, date)
	var before: int = int(profile.events.get(key, 0))
	var count: int = mini(before + maxi(tokens, 0), ev.goal)
	profile.events[key] = count
	var tp: int = (count - before) * balance.event_token_tp
	var done_now: bool = count >= ev.goal and not profile.events_done.has(key)
	if done_now:
		profile.events_done.append(key)
		tp += balance.event_goal_tp
	return {"key": key, "count": count, "goal": ev.goal, "tp": tp, "done_now": done_now, "gathered": count - before}
