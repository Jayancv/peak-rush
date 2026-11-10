@tool
class_name SnowSlide
extends HikerArea
## A steep snowy descent the hiker slides down instead of walking (Hiker.State.SLIDE):
## no stamina, speed builds with the slope. Place it over the descent and its
## run-out; a blue diamond marker post shows where the slide starts.

const POLE: Color = Color("#5C4A3A")
const MARKER: Color = Color("#2F6690")

@export var width: float = 700.0:
	set(v):
		width = v
		rebuild()
@export var height: float = 500.0:
	set(v):
		height = v
		rebuild()


func build() -> void:
	ShapeUtil.add_rect_shape(self, Rect2(0, -height, width, height + 40.0))
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-2, 6), Vector2(2, 6), Vector2(1.5, -46), Vector2(-1.5, -46)]), POLE)
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(0, -60), Vector2(9, -50), Vector2(0, -40), Vector2(-9, -50)]), MARKER)
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(0, -55), Vector2(4, -50), Vector2(0, -45), Vector2(-4, -50)]), Color("#FFF6E5"))


func _hiker_entered(hiker: Hiker) -> void:
	hiker.enter_slide_zone()


func _hiker_exited(hiker: Hiker) -> void:
	hiker.exit_slide_zone()
