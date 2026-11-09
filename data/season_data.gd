class_name SeasonData
extends Resource
## A season: a themed set of trails released together in an app update.

@export var id: StringName
@export var title_key: String
@export var theme_color: Color = Color("#5E8C7A")
@export var banner: Texture2D
## App version that first shipped this season (for the "What's new" banner, M8).
@export var release_version: String = "1.0.0"
@export var trails: Array[TrailData] = []


## Trails in unlock order.
func ordered_trails() -> Array[TrailData]:
	var list: Array[TrailData] = trails.duplicate()
	list.sort_custom(func(a: TrailData, b: TrailData) -> bool: return a.unlock_order < b.unlock_order)
	return list
