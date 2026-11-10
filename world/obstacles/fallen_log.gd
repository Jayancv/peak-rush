@tool
class_name FallenLog
extends Node2D
## A fallen tree trunk lying across a small gap or stream. Its origin is the left end
## at path height. It dips and rolls a little under the hiker, and when `wet` (rainy
## trails) the bark is slippery, like ice.

@export var length: float = 220.0:
	set(v):
		length = maxf(v, 60.0)
		_rebuild()
## Height difference of the right end (px, + lower).
@export var end_drop: float = 0.0:
	set(v):
		end_drop = v
		_rebuild()
@export var thickness: float = 18.0:
	set(v):
		thickness = v
		_rebuild()
@export var wet: bool = false
## How far it dips and rolls (radians) when stood on.
@export var dip: float = 3.0
@export var roll: float = 0.05

const BARK: Color = Color("#6E4A2E")
const BARK_LIGHT: Color = Color("#8E6440")
const BARK_DARK: Color = Color("#4A3020")
const RING: Color = Color("#D9B98A")
const RING_DARK: Color = Color("#A9824F")
const MOSS: Color = Color("#6F8D4A")
const STIFFNESS: float = 70.0
const DAMPING: float = 8.0

var _body: AnimatableBody2D
var _hiker: Hiker
var _sink: float = 0.0
var _sink_vel: float = 0.0
var _rest: Vector2
var _ready_done: bool = false


func _ready() -> void:
	_ready_done = true
	_rebuild()


func _rebuild() -> void:
	if not _ready_done:
		return
	ShapeUtil.clear_internal(self)
	_body = AnimatableBody2D.new()
	# Moved directly every physics tick (sync_to_physics would ignore those moves).
	_body.sync_to_physics = false
	add_child(_body, false, Node.INTERNAL_MODE_BACK)
	var angle: float = atan2(end_drop, length)
	var true_len: float = Vector2(length, end_drop).length()
	# Built along +x around the log's middle, then rotated to lie between the ends.
	_rest = Vector2(length * 0.5, end_drop * 0.5 + thickness * 0.35)
	_body.position = _rest
	_body.rotation = angle
	var half: float = true_len * 0.5 + 10.0
	var t: float = thickness
	var trunk: Polygon2D = ShapeUtil.add_poly(_body, ShapeUtil.rounded_rect(Rect2(-half, -t * 0.5, half * 2.0, t), t * 0.45), BARK)
	var cols: PackedColorArray = PackedColorArray()
	for p: Vector2 in trunk.polygon:
		cols.append(BARK_LIGHT.lerp(BARK_DARK, clampf((p.y + t * 0.5) / t, 0.0, 1.0)))
	trunk.vertex_colors = cols
	# Bark grooves, a mossy patch, and the cut ring at the end facing the hiker.
	for i: int in int(half / 14.0):
		var x: float = -half + 10.0 + float(i) * 28.0 + float(i % 2) * 6.0
		ShapeUtil.add_poly(_body, PackedVector2Array([Vector2(x, -t * 0.25), Vector2(x + 16, -t * 0.28), Vector2(x + 16, -t * 0.2), Vector2(x, -t * 0.17)]), BARK_DARK)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(half * 0.3, -t * 0.42), Vector2(half * 0.22, 2.6), 14), MOSS)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(-half + 1.0, 0), Vector2(t * 0.22, t * 0.5), 14), RING)
	ShapeUtil.add_poly(_body, ShapeUtil.ellipse(Vector2(-half + 1.0, 0), Vector2(t * 0.1, t * 0.25), 10), RING_DARK)
	ShapeUtil.add_rect_shape(_body, Rect2(-half, -t * 0.5, half * 2.0, t))
	if Engine.is_editor_hint():
		return
	var sensor: Area2D = Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = HikerArea.HIKER_LAYER
	sensor.monitorable = false
	_body.add_child(sensor, false, Node.INTERNAL_MODE_BACK)
	ShapeUtil.add_rect_shape(sensor, Rect2(-half, -t * 0.5 - 22.0, half * 2.0, 24.0))
	sensor.body_entered.connect(_on_enter)
	sensor.body_exited.connect(_on_exit)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _body == null:
		return
	var target: float = 0.0
	var turn: float = 0.0
	if _hiker != null and _hiker.is_on_floor():
		var t: float = clampf(to_local(_hiker.global_position).x / length, 0.0, 1.0)
		target = dip * sin(PI * t)
		# Weight off-centre makes it roll a touch towards that end.
		turn = (t - 0.5) * roll
	_sink_vel += ((target - _sink) * STIFFNESS - _sink_vel * DAMPING) * delta
	_sink += _sink_vel * delta
	_body.position = _rest + Vector2(0.0, _sink)
	_body.rotation = atan2(end_drop, length) + turn * clampf(_sink / maxf(dip, 0.01), 0.0, 1.0)


func _on_enter(body: Node2D) -> void:
	var hiker: Hiker = body as Hiker
	if hiker == null:
		return
	_hiker = hiker
	if wet:
		hiker.condition.enter_patch(TerrainStrip.Surface.ICE)


func _on_exit(body: Node2D) -> void:
	if body != _hiker:
		return
	if wet:
		_hiker.condition.exit_patch(TerrainStrip.Surface.ICE)
	_hiker = null
