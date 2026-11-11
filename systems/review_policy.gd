class_name ReviewPolicy
extends RefCounted
## When to ask for a Play Store review: once ever, at a happy moment (just after a
## first-time summit), and only once the player knows the game (N different summits).


static func should_ask(first_completion: bool, completed_trails: int, already_asked: bool, balance: Balance) -> bool:
	return first_completion and not already_asked and completed_trails >= balance.review_after_summits


static func completed_trails(trails: Dictionary) -> int:
	var n: int = 0
	for id: String in trails:
		if int(trails[id].get("stars", 0)) & StarRating.STAR_SUMMIT != 0:
			n += 1
	return n
