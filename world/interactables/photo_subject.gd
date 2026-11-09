@tool
class_name PhotoSubject
extends Node2D
## The thing worth photographing at a viewpoint: a placeholder bird, boat or
## walking reindeer that moves back and forth along a path. Always moving, so it's visible (and timing
## matters) before the player even opens photo mode.

enum Kind { BIRD, BOAT, REINDEER, STAR }

const INK: Color = Color("#2B2D42")
const BOAT_HULL: Color = Color("#8C3B2A")
const SAIL: Color = Color("#FFF6E5")
const FUR: Color = Color("#7A5A43")
const FUR_DARK: Color = Color("#5C4332")
const FUR_LIGHT: Color = Color("#D9C7A3")
const ANTLER: Color = Color("#E8DCC0")
## Reindeer stride: leg swing (radians) and steps per second at speed 60 px/s.
const STRIDE: float = 0.5
const STRIDE_HZ_PER_SPEED: float = 1.6 / 60.0
const FLAP_HZ: float = 3.0
const BOB_HZ: float = 0.8
const BOB_PX: float = 2.0

@export var kind: Kind = Kind.BIRD:
	set(v):
		kind = v
		_rebuild()
## Points (relative to the viewpoint's frame centre) the subject travels between.
@export var path: PackedVector2Array = PackedVector2Array([Vector2(-260, 0), Vector2(260, 0)]):
	set(v):
		path = v
		queue_redraw()
@export var speed: float = 90.0
## Body colour (birds); pick one that stands out against what's behind it.
@export var color: Color = INK:
	set(v):
		color = v
		_rebuild()
## Second colour (a woodpecker's red cap). Transparent = none.
@export var accent: Color = Color(0, 0, 0, 0):
	set(v):
		accent = v
		_rebuild()
@export var size: float = 1.0:
	set(v):
		size = v
		_rebuild()

var _forward: bool = true
var _segment: int = 0
var _body: Node2D
var _wings: Polygon2D
var _legs: Array[Node2D] = []
var _time: float = 0.0


func _ready() -> void:
	# Built on NOTIFICATION_ENTER_TREE; here we only put it at the start of its path.
	if path.size() > 0:
		position = path[0]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_advance(delta)
	if _wings != null:
		_wings.scale.y = cos(_time * TAU * FLAP_HZ)
	if kind == Kind.BOAT and _body != null:
		_body.position.y = sin(_time * TAU * BOB_HZ) * BOB_PX
	if not _legs.is_empty():
		# Diagonal pairs move together, like a real walk.
		var swing: float = sin(_time * TAU * speed * STRIDE_HZ_PER_SPEED) * STRIDE
		for i: int in _legs.size():
			_legs[i].rotation = swing if i % 3 == 0 else -swing


## Ping-pongs along the path at constant speed.
func _advance(delta: float) -> void:
	if path.size() < 2:
		return
	var step: float = speed * delta
	while step > 0.0:
		var a: Vector2 = path[_segment]
		var b: Vector2 = path[_segment + 1]
		var target: Vector2 = b if _forward else a
		var to_target: float = position.distance_to(target)
		if to_target > step:
			position = position.move_toward(target, step)
			step = 0.0
		else:
			position = target
			step -= to_target
			if _forward:
				_segment += 1
				if _segment >= path.size() - 1:
					_segment = path.size() - 2
					_forward = false
			else:
				_segment -= 1
				if _segment < 0:
					_segment = 0
					_forward = true
	# Face the way it's moving.
	if _body != null:
		_body.scale.x = size * (1.0 if _forward else -1.0)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	ShapeUtil.clear_internal(self)
	_wings = null
	_legs.clear()
	_body = Node2D.new()
	_body.scale = Vector2(size, size)
	add_child(_body, false, Node.INTERNAL_MODE_BACK)
	match kind:
		Kind.BIRD:
			ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2.ZERO, Vector2(13, 6), 12), color)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(12, -3), Vector2(20, 0), Vector2(12, 2)]), Color("#E8A33F"))
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-11, 0), Vector2(-20, -5), Vector2(-20, 5)]), color)
			_wings = ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-4, 0), Vector2(6, 0), Vector2(-2, -18)]), color.darkened(0.25))
			if accent.a > 0.0:
				ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(7, -2), Vector2(4, 3.5), 8), accent)
		Kind.REINDEER:
			_build_reindeer()
		Kind.STAR:
			# A shooting star: bright head, fading tail behind it.
			var tail: Polygon2D = ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(0, -3), Vector2(-60, 0), Vector2(0, 3)]), Color.WHITE)
			tail.vertex_colors = PackedColorArray([Color(1, 1, 0.9, 0.9), Color(1, 1, 1, 0), Color(1, 1, 0.9, 0.9)])
			ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2.ZERO, Vector2(9, 9), 12), Color(1, 0.98, 0.85, 0.35))
			ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2.ZERO, Vector2(4.5, 4.5), 10), Color(1, 1, 0.95, 1))
		Kind.BOAT:
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(22, 12), Vector2(-24, 12)]), BOAT_HULL)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-2, -4), Vector2(-2, -58), Vector2(24, -8)]), SAIL)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-6, -4), Vector2(-6, -44), Vector2(-26, -6)]), SAIL)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-3, 0), Vector2(-1, 0), Vector2(-1, -60), Vector2(-3, -60)]), INK)


## Origin at the hooves; faces right. Legs are pivots so they can swing.
func _build_reindeer() -> void:
	for x: float in [16.0, 11.0, -12.0, -17.0]:
		var leg: Node2D = Node2D.new()
		leg.position = Vector2(x, -24)
		_body.add_child(leg, false, Node.INTERNAL_MODE_BACK)
		ShapeUtil.add_poly(leg, PackedVector2Array([Vector2(-2, 0), Vector2(2, 0), Vector2(1.6, 24), Vector2(-1.6, 24)]), FUR_DARK)
		_legs.append(leg)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(0, -32), Vector2(25, 11), 16), FUR)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(2, -25), Vector2(17, 4), 12), FUR_LIGHT)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(-24, -36), Vector2(4, 3), 8), FUR_LIGHT)
	ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(13, -38), Vector2(22, -40), Vector2(30, -56), Vector2(21, -58)]), FUR)
	ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(15, -36), Vector2(21, -38), Vector2(24, -46), Vector2(18, -44)]), FUR_LIGHT)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(31, -57), Vector2(9, 5), 12), FUR)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(39, -56), Vector2(2.5, 2), 8), INK)
	# Antlers: a main beam each side with a couple of tines.
	for side: float in [0.0, -5.0]:
		var base: Vector2 = Vector2(28 + side, -61)
		for seg: PackedVector2Array in [
			PackedVector2Array([base, base + Vector2(-6, -16), base + Vector2(-4, -17), base + Vector2(2, -1)]),
			PackedVector2Array([base + Vector2(-3, -8), base + Vector2(4, -14), base + Vector2(5, -12), base + Vector2(-2, -6)]),
			PackedVector2Array([base + Vector2(-5, -14), base + Vector2(-1, -24), base + Vector2(1, -23), base + Vector2(-3, -13)]),
		]:
			ShapeUtil.add_poly(_body, seg, ANTLER)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_rebuild()
