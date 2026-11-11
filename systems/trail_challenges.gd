class_name TrailChallenges
extends RefCounted
## Three goals every trail has, judged from its own data: all its finds in one hike,
## beating its par time, and a clean hike (no stumbles, no falls). They can be met on
## different hikes; each pays TP once, and all three earn the trail's medal.
## Saved per trail as a bitmask under record "challenges".

enum Kind { ALL_FINDS, BEAT_PAR, CLEAN }

const KEYS: Array[String] = ["CHALLENGE_ALL_FINDS", "CHALLENGE_BEAT_PAR", "CHALLENGE_CLEAN"]
## Short names for tight spots (the pause card).
const SHORT_KEYS: Array[String] = ["CHALLENGE_ALL_FINDS_SHORT", "CHALLENGE_BEAT_PAR_SHORT", "CHALLENGE_CLEAN_SHORT"]
const ALL: int = 0b111


static func bit(kind: Kind) -> int:
	return 1 << kind


static func met(kind: Kind, result: TrailResult, trail: TrailData) -> bool:
	if not result.finished:
		return false
	match kind:
		Kind.ALL_FINDS:
			for f: FindData in trail.finds:
				if not result.finds.has(f.id):
					return false
			return true
		Kind.BEAT_PAR:
			return result.time_seconds <= trail.par_time
		Kind.CLEAN:
			return result.stumbles == 0 and result.falls == 0
	return false


## Bits met on this hike that weren't already in `mask`.
static func newly_met(mask: int, result: TrailResult, trail: TrailData) -> int:
	var out: int = 0
	for kind: int in Kind.values():
		if mask & bit(kind) == 0 and met(kind, result, trail):
			out |= bit(kind)
	return out


static func count(mask: int) -> int:
	var n: int = 0
	for kind: int in Kind.values():
		n += 1 if mask & bit(kind) != 0 else 0
	return n


static func has_medal(mask: int) -> bool:
	return mask & ALL == ALL
