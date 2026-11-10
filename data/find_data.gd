class_name FindData
extends Resource
## Something to discover on a trail: a wildflower, a mushroom, a lost item, or an
## animal that only shows up on some hikes. Listed in TrailData.finds; the level holds
## a `Find` piece with the same id.

enum Kind { FLOWER, MUSHROOM, ITEM, ANIMAL }

@export var id: StringName
@export var name_key: String
@export var kind: Kind = Kind.FLOWER
## Main colour of the art (petals, cap, item, fur).
@export var color: Color = Color("#D96C8E")
## Animals: chance per hike that it's there at all (1 = always).
@export_range(0.0, 1.0) var appear_chance: float = 1.0
