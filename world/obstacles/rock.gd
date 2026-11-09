@tool
class_name TrailRock
extends StaticBody2D
## A large boulder: solid, too steep to walk up, so the hiker must jump it.
## Keep `size.y` below the jump height (about 90 px) so it can be cleared.

@export var size: Vector2 = Vector2(76, 56):
	set(v):
		size = v
		_rebuild()

const STONE: Color = Color("#8C8B84")
const STONE_LIGHT: Color = Color("#A9A79F")
const STONE_DARK: Color = Color("#6F6E68")

var _ready_done: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_ready_done = true
	_rebuild()


func _rebuild() -> void:
	if not _ready_done:
		return
	ShapeUtil.clear_internal(self)
	var outline: PackedVector2Array = ShapeUtil.dome(size)
	ShapeUtil.add_poly(self, outline, STONE_DARK)
	var inner: PackedVector2Array = ShapeUtil.dome(size * Vector2(0.86, 0.9))
	ShapeUtil.add_poly(self, inner, STONE)
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(-size.x * 0.12, -size.y * 0.72), size * Vector2(0.2, 0.1)), STONE_LIGHT)
	var shape: CollisionPolygon2D = CollisionPolygon2D.new()
	shape.polygon = outline
	add_child(shape, false, Node.INTERNAL_MODE_BACK)
