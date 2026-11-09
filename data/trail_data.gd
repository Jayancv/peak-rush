class_name TrailData
extends Resource
## Everything the game needs to know about one trail besides the level itself.
## The level is `scene_path` (a trail.tscn with a Trailhead marker and a Finish).

@export var id: StringName
@export var name_key: String
@export var season_id: StringName
## The level. A path (not a PackedScene) so menus don't load every level up front
## and so the validator can report a missing file instead of failing to load.
@export_file("*.tscn") var scene_path: String
@export var length_m: int = 1000
## Seconds until dusk. Summiting before then earns ★3.
@export var daylight_seconds: float = 120.0
## A good time for this trail, shown on the results screen.
@export var par_time: float = 90.0
@export var weather: WeatherProfile
@export var viewpoints: Array[ViewpointData] = []
@export var postcard: Texture2D
## Trails unlock in this order within their season; the first is always open.
@export var unlock_order: int = 0


func viewpoint_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for v: ViewpointData in viewpoints:
		ids.append(v.id)
	return ids


func weather_drain() -> float:
	return weather.drain_multiplier if weather != null else 1.0
