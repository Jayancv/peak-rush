@tool
class_name PhotoSubject
extends Node2D
## The thing worth photographing at a viewpoint: a placeholder bird or boat that
## moves back and forth along a path. Always moving, so it's visible (and timing
## matters) before the player even opens photo mode.

enum Kind { BIRD, BOAT }

const INK: Color = Color("#2B2D42")
const BOAT_HULL: Color = Color("#8C3B2A")
const SAIL: Color = Color("#FFF6E5")
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
@export var size: float = 1.0:
	set(v):
		size = v
		_rebuild()

var _forward: bool = true
var _segment: int = 0
var _body: Node2D
var _wings: Polygon2D
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
	_body = Node2D.new()
	_body.scale = Vector2(size, size)
	add_child(_body, false, Node.INTERNAL_MODE_BACK)
	match kind:
		Kind.BIRD:
			ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2.ZERO, Vector2(13, 6), 12), color)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(12, -3), Vector2(20, 0), Vector2(12, 2)]), Color("#E8A33F"))
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-11, 0), Vector2(-20, -5), Vector2(-20, 5)]), color)
			_wings = ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-4, 0), Vector2(6, 0), Vector2(-2, -18)]), color.darkened(0.25))
			ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(7, -2), Vector2(4, 3.5), 8), Color("#D9483B") if color != INK else INK)
		Kind.BOAT:
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-30, 0), Vector2(30, 0), Vector2(22, 12), Vector2(-24, 12)]), BOAT_HULL)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-2, -4), Vector2(-2, -58), Vector2(24, -8)]), SAIL)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-6, -4), Vector2(-6, -44), Vector2(-26, -6)]), SAIL)
			ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(-3, 0), Vector2(-1, 0), Vector2(-1, -60), Vector2(-3, -60)]), INK)


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_rebuild()
