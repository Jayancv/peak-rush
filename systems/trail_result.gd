class_name TrailResult
extends RefCounted
## What happened on one hike, handed from the trail runner to the rating and save code.

var trail_id: StringName
var finished: bool = false
var time_seconds: float = 0.0
var before_dusk: bool = false
var viewpoint_total: int = 0
## viewpoint id -> StarRating.PhotoQuality of the best shot this hike.
var photos: Dictionary = {}
## Find ids collected on this hike.
var finds: Array[StringName] = []
## Times the hiker fell off the trail (the Sure-footed daily wants none).
var falls: int = 0
## Times the hiker stumbled (the Clean hike challenge wants none).
var stumbles: int = 0


func _init(id: StringName = &"") -> void:
	trail_id = id


func photographed_all() -> bool:
	# A trail without viewpoints can't withhold ★2.
	return photos.size() >= viewpoint_total
