class_name PhotoScoring
extends RefCounted
## Grades a photo by how well the subject is centred in the viewfinder
## (GAME_DESIGN §5.5), and keeps track of the film roll for one visit.


var shots_left: int
var best: int = StarRating.PhotoQuality.NONE

var _balance: Balance


func _init(balance: Balance) -> void:
	_balance = balance
	shots_left = balance.photo_shots_per_visit


## Distance from the frame centre as a fraction of the viewfinder's half height:
## 0 = dead centre, 1 = at the frame's top/bottom edge.
func normalized_offset(subject_screen: Vector2, frame_center: Vector2) -> float:
	return subject_screen.distance_to(frame_center) / maxf(_balance.photo_frame_half, 1.0)


func quality_for(offset: float) -> int:
	if offset <= _balance.photo_perfect_radius:
		return StarRating.PhotoQuality.PERFECT
	if offset <= _balance.photo_great_radius:
		return StarRating.PhotoQuality.GREAT
	if offset <= _balance.photo_good_radius:
		return StarRating.PhotoQuality.GOOD
	return StarRating.PhotoQuality.NONE


## Uses one frame of film. Returns this shot's quality (NONE once the roll is empty).
func shoot(subject_screen: Vector2, frame_center: Vector2) -> int:
	if shots_left <= 0:
		return StarRating.PhotoQuality.NONE
	shots_left -= 1
	var q: int = quality_for(normalized_offset(subject_screen, frame_center))
	best = maxi(best, q)
	return q


func has_film() -> bool:
	return shots_left > 0
