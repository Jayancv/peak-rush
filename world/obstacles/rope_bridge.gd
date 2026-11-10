@tool
class_name RopeBridge
extends Node2D
## A plank-and-rope bridge over a gap. The origin is the left anchor at path height;
## the right anchor is `span` px along and `end_drop` px lower (negative = higher).
## Put terrain strips ending/starting at the two anchors.
## The deck sags under its own weight and dips under the hiker, springing back with
## a bounce when they land (a damped spring). The walkable deck is one static
## collision line reshaped every physics tick (moving-platform bodies teleported
## each frame upset the hiker's floor detection); the planks are art laid along it.

@export var span: float = 300.0:
	set(v):
		span = maxf(v, 60.0)
		_rebuild()
@export var end_drop: float = 0.0:
	set(v):
		end_drop = v
		_rebuild()
## Slack in the middle with nobody on it (px).
@export var sag: float = 16.0:
	set(v):
		sag = v
		_rebuild()
## Extra dip under the hiker at mid-span (px).
@export var give: float = 22.0
## Spring stiffness and damping of the dip (per second); a landing kicks it.
@export var stiffness: float = 60.0
@export var damping: float = 7.0
@export var landing_kick: float = 90.0

const PLANK_W: float = 16.0
const PLANK_GAP: float = 2.0
const PLANK_H: float = 6.0
const RAIL_HEIGHT: float = 34.0
const WOOD: Color = Color("#9A6B43")
const WOOD_DARK: Color = Color("#6E4A2E")
const ROPE: Color = Color("#C9B28F")
const POST: Color = Color("#5C4332")

var _planks: Array[Node2D] = []
var _deck_shape: ConcavePolygonShape2D
var _segments: PackedVector2Array = PackedVector2Array()
var _rails: Array[Line2D] = []
var _hangers: Array[Line2D] = []
var _deck_rope: Line2D
var _hiker: Hiker
var _depth: float = 0.0
var _depth_vel: float = 0.0
var _was_on_floor: bool = false
var _ready_done: bool = false


func _ready() -> void:
	_ready_done = true
	_rebuild()


func _rebuild() -> void:
	if not _ready_done:
		return
	ShapeUtil.clear_internal(self)
	_planks.clear()
	_rails.clear()
	_hangers.clear()
	var count: int = maxi(int(span / (PLANK_W + PLANK_GAP)), 3)
	var pitch: float = span / float(count)
	for i: int in count:
		var plank: Node2D = Node2D.new()
		plank.position = Vector2((float(i) + 0.5) * pitch, 0.0)
		var w: float = pitch - PLANK_GAP
		var art: Polygon2D = ShapeUtil.add_poly(plank, ShapeUtil.rounded_rect(Rect2(-w * 0.5, -PLANK_H * 0.5, w, PLANK_H), 1.5), WOOD)
		art.vertex_colors = _plank_colors(art.polygon.size(), i)
		add_child(plank, false, Node.INTERNAL_MODE_BACK)
		_planks.append(plank)
	var deck_body: StaticBody2D = StaticBody2D.new()
	add_child(deck_body, false, Node.INTERNAL_MODE_BACK)
	var shape: CollisionShape2D = CollisionShape2D.new()
	_deck_shape = ConcavePolygonShape2D.new()
	shape.shape = _deck_shape
	deck_body.add_child(shape)
	# One segment per plank plus a little lip onto each bank.
	_segments.resize((count + 2) * 2)
	_deck_rope = _rope(2.0)
	for k: int in 2:
		_rails.append(_rope(2.4))
	for i: int in range(0, count + 1, 2):
		_hangers.append(_rope(1.2))
	for end: Vector2 in [Vector2(-4, 0), Vector2(span + 4, end_drop)]:
		ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(end.x - 3, end.y - RAIL_HEIGHT - 10, 6, RAIL_HEIGHT + 22), 2.0), POST)
	if not Engine.is_editor_hint():
		var sensor: Area2D = Area2D.new()
		sensor.collision_layer = 0
		sensor.collision_mask = HikerArea.HIKER_LAYER
		sensor.monitorable = false
		add_child(sensor, false, Node.INTERNAL_MODE_BACK)
		ShapeUtil.add_rect_shape(sensor, Rect2(0, minf(0.0, end_drop) - 80.0, span, absf(end_drop) + 110.0))
		sensor.body_entered.connect(func(b: Node2D) -> void:
			if b is Hiker:
				_hiker = b as Hiker)
		sensor.body_exited.connect(func(b: Node2D) -> void:
			if b == _hiker:
				_hiker = null)
	_layout()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _planks.is_empty():
		return
	var target: float = 0.0
	if _hiker != null:
		var hx: float = clampf(to_local(_hiker.global_position).x, 0.0, span)
		target = give * sin(PI * hx / span)
		var on_floor: bool = _hiker.is_on_floor()
		if on_floor and not _was_on_floor:
			_depth_vel += landing_kick
		_was_on_floor = on_floor
	else:
		_was_on_floor = false
	_depth_vel += ((target - _depth) * stiffness - _depth_vel * damping) * delta
	_depth += _depth_vel * delta
	_layout()


## Where the deck is at local x: a straight line between the anchors, the resting
## slack, and a dip that's deepest under the hiker and tapers to each anchor.
func deck_y(x: float) -> float:
	var t: float = clampf(x / span, 0.0, 1.0)
	var y: float = end_drop * t + sag * sin(PI * t)
	if _hiker != null and absf(_depth) > 0.01:
		var hx: float = clampf(to_local(_hiker.global_position).x, 1.0, span - 1.0)
		var load_shape: float = x / hx if x < hx else (span - x) / (span - hx)
		y += _depth * clampf(load_shape, 0.0, 1.0)
	elif absf(_depth) > 0.01:
		y += _depth * sin(PI * t)
	return y


func _layout() -> void:
	var deck: PackedVector2Array = PackedVector2Array()
	deck.append(Vector2(0, 0))
	var prev: Vector2 = Vector2(-6.0, -PLANK_H * 0.5)
	var seg: int = 0
	for i: int in _planks.size():
		var p: Node2D = _planks[i]
		var x: float = p.position.x
		var y: float = deck_y(x)
		p.position.y = y
		# Each plank follows the local slope of the deck.
		p.rotation = atan2(deck_y(x + 4.0) - deck_y(x - 4.0), 8.0)
		deck.append(Vector2(x, y + PLANK_H * 0.5))
		var top: Vector2 = Vector2(x, y - PLANK_H * 0.5)
		_segments[seg] = prev
		_segments[seg + 1] = top
		seg += 2
		prev = top
	_segments[seg] = prev
	_segments[seg + 1] = Vector2(span + 6.0, end_drop - PLANK_H * 0.5)
	_deck_shape.segments = _segments
	deck.append(Vector2(span, end_drop))
	_deck_rope.points = deck
	# Handrails hang less than the deck (they're tied higher on the posts).
	var rail: PackedVector2Array = PackedVector2Array()
	var steps: int = 16
	for i: int in steps + 1:
		var x: float = span * float(i) / float(steps)
		rail.append(Vector2(x, deck_y(x) * 0.55 + end_drop * 0.45 * x / span - RAIL_HEIGHT))
	for r: Line2D in _rails:
		r.points = rail
	_rails[1].position = Vector2(0, 5)
	for k: int in _hangers.size():
		var x: float = minf(float(k * 2) * span / float(_planks.size()), span)
		var top: float = deck_y(x) * 0.55 + end_drop * 0.45 * x / span - RAIL_HEIGHT
		_hangers[k].points = PackedVector2Array([Vector2(x, top), Vector2(x, deck_y(x))])


func _rope(width: float) -> Line2D:
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = ROPE
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line, false, Node.INTERNAL_MODE_BACK)
	return line


## Lighter top edge, darker underside, and a little variation from plank to plank.
static func _plank_colors(n: int, i: int) -> PackedColorArray:
	var base: Color = WOOD.darkened(0.08 * float(i % 3))
	var cols: PackedColorArray = PackedColorArray()
	for k: int in n:
		cols.append(base.lightened(0.1) if k < n / 2 else WOOD_DARK)
	return cols
