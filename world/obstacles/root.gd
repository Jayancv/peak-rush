@tool
class_name TrailRoot
extends HikerArea
## A small tree root across the path. Jump it, or walk into it and stumble
## (short stop, stamina cost).

@export var width: float = 46.0:
	set(v):
		width = v
		rebuild()

const WOOD: Color = Color("#6B4A33")
const WOOD_DARK: Color = Color("#4E3524")


func build() -> void:
	ShapeUtil.add_poly(self, ShapeUtil.arch(width * 0.5, 11.0, 7.0), WOOD_DARK)
	ShapeUtil.add_poly(self, ShapeUtil.arch(width * 0.42, 9.0, 4.0), WOOD)
	# Low and wide: a jump clears it easily, walking always catches the toe.
	ShapeUtil.add_rect_shape(self, Rect2(-width * 0.5, -14.0, width, 14.0))


func _hiker_entered(hiker: Hiker) -> void:
	if hiker.is_on_floor():
		hiker.stumble()
