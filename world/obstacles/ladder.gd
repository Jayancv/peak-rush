@tool
class_name Ladder
extends HikerArea
## A wooden ladder (or a rock scramble with iron rungs) up a wall too tall to jump.
## The origin is the foot, on the lower ground, just in front of the wall; walking into it
## starts a climb (Hiker CLIMB state) and the hiker hops onto the ledge `height` above.

enum Style { LADDER, SCRAMBLE }

@export var height: float = 140.0:
	set(v):
		height = v
		rebuild()
@export var style: Style = Style.LADDER:
	set(v):
		style = v
		rebuild()

const WOOD: Color = Color("#7A5233")
const WOOD_DARK: Color = Color("#563924")
const ROCK: Color = Color("#7D7F86")
const ROCK_DARK: Color = Color("#5E6067")
const IRON: Color = Color("#3A3A40")


## World y of the ledge the ladder leads to.
func top_y() -> float:
	return global_position.y - height


func build() -> void:
	if style == Style.SCRAMBLE:
		_build_scramble()
	else:
		_build_ladder()
	# Reaches a little past the top so the hiker is still "at the ladder" for the final hop.
	ShapeUtil.add_rect_shape(self, Rect2(-22.0, -height - 30.0, 30.0, height + 30.0))


func _build_ladder() -> void:
	for x: float in [-12.0, 6.0]:
		ShapeUtil.add_poly(self, PackedVector2Array([Vector2(x - 2.5, 2), Vector2(x + 2.5, 2), Vector2(x + 2.5, -height - 18.0), Vector2(x - 2.5, -height - 18.0)]), WOOD_DARK, 1)
	var rungs: int = maxi(int(height / 22.0), 3)
	for i: int in rungs:
		var y: float = -12.0 - i * (height / rungs)
		ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-12, y), Vector2(6, y), Vector2(6, y - 3.5), Vector2(-12, y - 3.5)]), WOOD, 1)


func _build_scramble() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(height * 13.0)
	var y: float = 0.0
	while y > -height:
		var w: float = rng.randf_range(16.0, 24.0)
		var h: float = rng.randf_range(18.0, 28.0)
		var c: Vector2 = Vector2(rng.randf_range(-8.0, 2.0), y - h * 0.5)
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(c, Vector2(w, h * 0.6), 10), ROCK_DARK if int(-y) % 2 == 0 else ROCK, 1)
		y -= h * 0.75
	var rungs: int = maxi(int(height / 34.0), 2)
	for i: int in rungs:
		var ry: float = -18.0 - i * (height / rungs)
		ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-10, ry), Vector2(4, ry), Vector2(4, ry - 3), Vector2(-10, ry - 3)]), IRON, 2)


func _hiker_entered(hiker: Hiker) -> void:
	hiker.actions.ladder = self


func _hiker_exited(hiker: Hiker) -> void:
	if hiker.actions.ladder == self:
		hiker.actions.ladder = null
