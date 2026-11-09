@tool
class_name PhotoSubject
extends Node2D
## The thing worth photographing at a viewpoint: a bird, boat, shooting star or
## walking reindeer (art in SubjectArt) that moves back and forth along a path. Always moving, so it's visible (and timing
## matters) before the player even opens photo mode.

enum Kind { BIRD, BOAT, REINDEER, STAR }

const INK: Color = Color("#2B2D42")
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
var _wings: Node2D
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
		# Full stroke up, shorter stroke down, so the wings never vanish edge-on for long.
		_wings.scale.y = lerpf(-0.55, 1.0, 0.5 + 0.5 * cos(_time * TAU * FLAP_HZ))
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
			_wings = SubjectArt.bird(_body, color, accent)
		Kind.REINDEER:
			_legs = SubjectArt.reindeer(_body)
		Kind.STAR:
			# A shooting star: bright head, fading tail behind it.
			var tail: Polygon2D = ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(0, -3), Vector2(-60, 0), Vector2(0, 3)]), Color.WHITE)
			tail.vertex_colors = PackedColorArray([Color(1, 1, 0.9, 0.9), Color(1, 1, 1, 0), Color(1, 1, 0.9, 0.9)])
			ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2.ZERO, Vector2(9, 9), 12), Color(1, 0.98, 0.85, 0.35))
			ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2.ZERO, Vector2(4.5, 4.5), 10), Color(1, 1, 0.95, 1))
		Kind.BOAT:
			SubjectArt.boat(_body)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_rebuild()
