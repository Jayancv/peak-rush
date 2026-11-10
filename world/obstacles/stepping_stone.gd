class_name SteppingStone
extends AnimatableBody2D
## One stone in a SteppingStones stream. With `wobble` > 0 it sinks a little and
## tips towards whichever side the hiker stands on, springing back when they hop off,
## so standing still on it feels unsafe. Its origin is the middle of its top.

## How far it sinks under the hiker (px) and the most it tips (radians).
var wobble: float = 0.0
var max_tilt: float = 0.14

const STIFFNESS: float = 90.0
const DAMPING: float = 9.0

var _hiker: Hiker
var _rest: Vector2
var _half_width: float = 20.0
var _sink: float = 0.0
var _sink_vel: float = 0.0
var _tilt: float = 0.0
var _tilt_vel: float = 0.0


func _init() -> void:
	# Placed and moved directly from code (sync_to_physics would ignore those moves).
	sync_to_physics = false


## Moves everything built at parent coordinates so the stone pivots on `pivot`.
func recentre(pivot: Vector2, half_width: float) -> void:
	for child: Node in get_children(true):
		var node: Node2D = child as Node2D
		if node != null:
			node.position -= pivot
	position = pivot
	_rest = pivot
	_half_width = half_width


func enable_wobble(amount: float) -> void:
	wobble = amount
	if wobble <= 0.0 or Engine.is_editor_hint():
		set_physics_process(false)
		return
	var sensor: Area2D = Area2D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = HikerArea.HIKER_LAYER
	sensor.monitorable = false
	add_child(sensor, false, Node.INTERNAL_MODE_BACK)
	ShapeUtil.add_rect_shape(sensor, Rect2(-_half_width, -24.0, _half_width * 2.0, 26.0))
	sensor.body_entered.connect(func(b: Node2D) -> void:
		if b is Hiker:
			_hiker = b as Hiker)
	sensor.body_exited.connect(func(b: Node2D) -> void:
		if b == _hiker:
			_hiker = null)


func _physics_process(delta: float) -> void:
	var sink_target: float = 0.0
	var tilt_target: float = 0.0
	if _hiker != null and _hiker.is_on_floor():
		sink_target = wobble
		var off: float = (_hiker.global_position.x - global_position.x) / _half_width
		tilt_target = clampf(off, -1.0, 1.0) * max_tilt
	_sink_vel += ((sink_target - _sink) * STIFFNESS - _sink_vel * DAMPING) * delta
	_sink += _sink_vel * delta
	_tilt_vel += ((tilt_target - _tilt) * STIFFNESS - _tilt_vel * DAMPING) * delta
	_tilt += _tilt_vel * delta
	position = _rest + Vector2(0.0, _sink)
	rotation = _tilt
