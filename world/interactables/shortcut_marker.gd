@tool
class_name ShortcutMarker
extends HikerArea
## Marks a trail's hidden shortcut (usually on a high boardwalk reached with a held jump).
## Passing it counts the shortcut as taken; HikeTracker records it and the trail record keeps
## it found. A little stone cairn with a flag shows the spot to anyone who gets up there.

signal taken(id: StringName)

@export var shortcut_id: StringName = &"shortcut"

const STONE: Color = Color("#8D8A84")
const STONE_LIGHT: Color = Color("#ABA79F")
const FLAG: Color = Color("#E8B83A")


func build() -> void:
	for i: int in 3:
		var w: float = 9.0 - i * 2.0
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(0, -4 - i * 7), Vector2(w, 4.0), 10), STONE_LIGHT if i % 2 else STONE)
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-1, -22), Vector2(1, -22), Vector2(1, -40), Vector2(-1, -40)]), STONE.darkened(0.4))
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(1, -40), Vector2(13, -36), Vector2(1, -32)]), FLAG)
	ShapeUtil.add_rect_shape(self, Rect2(-24.0, -70.0, 48.0, 70.0))


func _hiker_entered(_hiker: Hiker) -> void:
	taken.emit(shortcut_id)
