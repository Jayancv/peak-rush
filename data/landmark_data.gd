class_name LandmarkData
extends Resource
## A stop on a long journey (a hut, a pass, a village) and the notebook page it unlocks.

@export var id: StringName
@export var name_key: String
## Kilometres from the start of the journey.
@export var km: float = 0.0
## The notebook page: a dated heading ("Alesjaure, 5 July 1974") and the entry.
@export var page_title_key: String
@export var page_text_key: String
## Where the landmark sits on the journey map (0..1 across and down the map area).
@export var map_pos: Vector2 = Vector2.ZERO
