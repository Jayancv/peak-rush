class_name CosmeticData
extends Resource
## One colour option for one part of the hiker's outfit. Free when stars_required is 0;
## otherwise it unlocks once the player has earned that many stars in total.

enum Slot { HAT, JACKET, PACK, PANTS, SKIN }

@export var id: StringName
@export var slot: Slot = Slot.HAT
@export var color: Color = Color.WHITE
@export var stars_required: int = 0
