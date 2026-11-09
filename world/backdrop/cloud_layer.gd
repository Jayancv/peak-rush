@tool
class_name CloudLayer
extends Polygon2D
## A band of soft flat-bottomed clouds, all in one Polygon2D (one draw call).
## Put it in a Parallax2D with repeat_size.x = width and some autoscroll to drift.

@export var width: float = 2560.0:
	set(v):
		width = v
		_queue()
@export var cloud_count: int = 6:
	set(v):
		cloud_count = v
		_queue()
## Vertical band the clouds float in.
@export var y_range: Vector2 = Vector2(60, 230):
	set(v):
		y_range = v
		_queue()
@export var size_range: Vector2 = Vector2(60, 140):
	set(v):
		size_range = v
		_queue()
@export var seed_value: int = 3:
	set(v):
		seed_value = v
		_queue()

const SEGMENTS: int = 14
var _pending: bool = false


func _ready() -> void:
	antialiased = true
	_rebuild()


func _queue() -> void:
	if _pending or not is_node_ready():
		return
	_pending = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_pending = false
	var pts: PackedVector2Array = PackedVector2Array()
	var polys: Array = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for c: int in cloud_count:
		# Spread clouds evenly with jitter so they never bunch up.
		var cx: float = (float(c) + rng.randf_range(0.1, 0.9)) * width / float(cloud_count)
		var cy: float = rng.randf_range(y_range.x, y_range.y)
		var size: float = rng.randf_range(size_range.x, size_range.y)
		# A cloud: a few overlapping puffs sitting on a flat base.
		var puffs: int = rng.randi_range(3, 5)
		for p: int in puffs:
			var t: float = (float(p) + 0.5) / float(puffs) - 0.5
			var r: float = size * rng.randf_range(0.22, 0.36) * (1.0 - absf(t) * 0.8)
			var px: float = cx + t * size * 1.1
			var py: float = cy - r * 0.55
			_add_puff(Vector2(px, py), r, cy, pts, polys)
	polygon = pts
	polygons = polys


## A circle with everything below `base_y` cut flat.
func _add_puff(center: Vector2, radius: float, base_y: float, pts: PackedVector2Array, polys: Array) -> void:
	var indices: PackedInt32Array = PackedInt32Array()
	for i: int in SEGMENTS:
		var a: float = TAU * float(i) / float(SEGMENTS)
		var p: Vector2 = center + Vector2(cos(a), sin(a)) * radius
		p.y = minf(p.y, base_y)
		indices.append(pts.size())
		pts.append(p)
	polys.append(indices)
