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


func _init(id: StringName = &"") -> void:
	trail_id = id


func photographed_all() -> bool:
	# A trail without viewpoints can't withhold ★2.
	return photos.size() >= viewpoint_total
