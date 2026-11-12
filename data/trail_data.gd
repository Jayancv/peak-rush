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
## Background loop. "Auto" picks one from the weather.
@export_enum("Auto", "Forest", "Coast", "Fell", "Rain") var ambience: int = 0
@export var viewpoints: Array[ViewpointData] = []
## Things to discover on this trail (each matched by a `Find` piece in the level).
@export var finds: Array[FindData] = []
## Hidden shortcuts in the level (ShortcutMarker pieces; the validator checks the count).
@export var shortcut_count: int = 0
@export var postcard: Texture2D
## Trails unlock in this order within their season; the first is always open.
@export var unlock_order: int = 0
## Shows the level's TutorialTrigger hints (until the trail has been finished once).
@export var tutorial: bool = false
## Night trail: dark from the start, headlamp on; `daylight_seconds` is then the
## window (e.g. the aurora) to summit within for the third star.
@export var night: bool = false
## Night trails only: the dark lifts to a sunrise as the window runs out (a dawn climb).
@export var sunrise: bool = false
## Caption of the third star on the results screen.
@export var star3_key: String = "RESULTS_STAR_DUSK"


func find_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for f: FindData in finds:
		if f != null:
			out.append(f.id)
	return out


func get_find(id: StringName) -> FindData:
	for f: FindData in finds:
		if f != null and f.id == id:
			return f
	return null


func viewpoint_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for v: ViewpointData in viewpoints:
		ids.append(v.id)
	return ids


## The ambience to play (AudioManager.Ambience value).
func ambience_kind() -> int:
	return ambience if ambience > 0 else AudioManager.ambience_for(weather)


func weather_drain() -> float:
	return weather.drain_multiplier if weather != null else 1.0
