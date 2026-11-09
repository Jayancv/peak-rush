class_name ContentIndex
extends Resource
## The one list of all shipped content. Adding a season = adding it here.
## Listed explicitly because exported builds can't reliably scan folders.

@export var seasons: Array[SeasonData] = []
