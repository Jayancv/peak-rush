@tool
class_name Boardwalk
extends Node2D
## A wooden walkway on stilts: the "ridge route" of a fork, or a small hidden lookout.
## `points` (local, left to right) is the walking surface. It's one-way: the hiker
## can jump up through it from below and land on top, and walks off its ends.
## Put it under the level's Scenery node (drawn before the ground), so the stilts
## vanish into the earth and a hiker on the path below passes in front of it.

@export var points: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(400, 0)]):
	set(v):
		points = v
		_rebuild()
## Stilts down into the ground (off for a lookout fixed to a rock face).
@export var stilts: bool = true:
	set(v):
		stilts = v
		_rebuild()
@export var rails: bool = true:
	set(v):
		rails = v
		_rebuild()

const DECK_H: float = 7.0
const PLANK_STEP: float = 12.0
const POST_STEP: float = 48.0
const STILT_STEP: float = 140.0
const STILT_DEPTH: float = 700.0
const RAIL_HEIGHT: float = 26.0
const WOOD: Color = Color("#9A6B43")
const WOOD_DARK: Color = Color("#6E4A2E")
const WOOD_LIGHT: Color = Color("#B88A5C")
const STILT: Color = Color("#5C4332")

var _ready_done: bool = false


func _ready() -> void:
	_ready_done = true
	_rebuild()


func _rebuild() -> void:
	if not _ready_done or points.size() < 2:
		return
	ShapeUtil.clear_internal(self)
	var x0: float = points[0].x
	var x1: float = points[points.size() - 1].x
	if stilts:
		var sx: float = x0 + 10.0
		while sx <= x1:
			var y: float = surface_y(sx)
			ShapeUtil.add_poly(self, PackedVector2Array([Vector2(sx - 3, y), Vector2(sx + 3, y), Vector2(sx + 4, y + STILT_DEPTH), Vector2(sx - 4, y + STILT_DEPTH)]), STILT)
			# Cross-bracing between stilt pairs.
			if sx + STILT_STEP <= x1:
				var y2: float = surface_y(sx + STILT_STEP)
				var brace: Line2D = Line2D.new()
				brace.points = PackedVector2Array([Vector2(sx, y + 20), Vector2(sx + STILT_STEP, y2 + 90), Vector2(sx, y + 160)])
				brace.width = 3.0
				brace.default_color = STILT.darkened(0.1)
				add_child(brace, false, Node.INTERNAL_MODE_BACK)
			sx += STILT_STEP
	# Deck: a dark beam under light planks.
	var beam: Line2D = Line2D.new()
	beam.points = _offset(DECK_H * 0.5 + 2.0)
	beam.width = 5.0
	beam.default_color = WOOD_DARK
	add_child(beam, false, Node.INTERNAL_MODE_BACK)
	var x: float = x0
	var i: int = 0
	while x < x1:
		var w: float = minf(PLANK_STEP - 1.5, x1 - x)
		var a: Vector2 = Vector2(x, surface_y(x))
		var b: Vector2 = Vector2(x + w, surface_y(x + w))
		var col: Color = WOOD.lerp(WOOD_LIGHT, 0.3 if i % 3 == 0 else 0.0)
		ShapeUtil.add_poly(self, PackedVector2Array([a, b, b + Vector2(0, DECK_H), a + Vector2(0, DECK_H)]), col)
		x += PLANK_STEP
		i += 1
	if rails:
		var px: float = x0 + 4.0
		while px <= x1:
			var py: float = surface_y(px)
			ShapeUtil.add_poly(self, PackedVector2Array([Vector2(px - 1.8, py), Vector2(px + 1.8, py), Vector2(px + 1.8, py - RAIL_HEIGHT), Vector2(px - 1.8, py - RAIL_HEIGHT)]), WOOD_DARK)
			px += POST_STEP
		var rail: Line2D = Line2D.new()
		rail.points = _offset(-RAIL_HEIGHT)
		rail.width = 3.0
		rail.default_color = WOOD_DARK
		add_child(rail, false, Node.INTERNAL_MODE_BACK)
	# One-way walking surface.
	var body: StaticBody2D = StaticBody2D.new()
	add_child(body, false, Node.INTERNAL_MODE_BACK)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var segs: ConcavePolygonShape2D = ConcavePolygonShape2D.new()
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in range(1, points.size()):
		pts.append(points[k - 1])
		pts.append(points[k])
	segs.segments = pts
	shape.shape = segs
	shape.one_way_collision = true
	shape.one_way_collision_margin = 6.0
	body.add_child(shape)


## Height of the walking surface at local x.
func surface_y(x: float) -> float:
	for k: int in range(1, points.size()):
		if x <= points[k].x:
			var a: Vector2 = points[k - 1]
			var b: Vector2 = points[k]
			return lerpf(a.y, b.y, clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0))
	return points[points.size() - 1].y


func _offset(dy: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		out.append(p + Vector2(0, dy))
	return out
