class_name StarRating
extends RefCounted
## Stars and Trail Points for a finished hike (GAME_DESIGN §5.6).
## Stars are a bitmask so a trail's record can merge stars earned on different runs:
## ★1 reach the summit, ★2 photograph every viewpoint, ★3 summit before dusk.

enum PhotoQuality { NONE, GOOD, GREAT, PERFECT }

const STAR_SUMMIT: int = 1
const STAR_PHOTOS: int = 2
const STAR_BEFORE_DUSK: int = 4
const ALL_STARS: int = 7

var _balance: Balance


func _init(balance: Balance) -> void:
	_balance = balance


static func stars_mask(result: TrailResult) -> int:
	if not result.finished:
		return 0
	var mask: int = STAR_SUMMIT
	if result.photographed_all():
		mask |= STAR_PHOTOS
	if result.before_dusk:
		mask |= STAR_BEFORE_DUSK
	return mask


static func count(mask: int) -> int:
	return (mask & 1) + ((mask >> 1) & 1) + ((mask >> 2) & 1)


func photo_tp(quality: int) -> int:
	match quality:
		PhotoQuality.GOOD:
			return _balance.tp_photo_good
		PhotoQuality.GREAT:
			return _balance.tp_photo_great
		PhotoQuality.PERFECT:
			return _balance.tp_photo_perfect
	return 0


## TP earned by `result` given the trail's record before this hike.
## Stars pay once each; photos pay only the improvement over the best earlier shot,
## so replaying always pays the finish bonus but can't farm the rest.
func award(result: TrailResult, previous_mask: int, previous_photos: Dictionary) -> Dictionary:
	var mask: int = stars_mask(result)
	var new_mask: int = mask & ~previous_mask
	var out: Dictionary = {"finish": 0, "stars": 0, "photos": 0, "total": 0, "stars_mask": mask, "new_stars_mask": new_mask}
	if not result.finished:
		return out
	out.finish = _balance.tp_finish
	out.stars = count(new_mask) * _balance.tp_per_new_star
	var photo_total: int = 0
	for vp: Variant in result.photos:
		var before: int = int(previous_photos.get(vp, PhotoQuality.NONE))
		var now: int = int(result.photos[vp])
		if now > before:
			photo_total += photo_tp(now) - photo_tp(before)
	out.photos = photo_total
	out.total = out.finish + out.stars + out.photos
	return out
