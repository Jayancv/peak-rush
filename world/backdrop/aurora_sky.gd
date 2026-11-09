@tool
class_name AuroraSky
extends Node2D
## Night-sky dressing for the aurora backdrop: a field of stars and a few aurora
## ribbons that sway and shimmer. Lives in the sky's CanvasLayer (screen space).
## Animation only sets transforms/colours each frame, so nothing is allocated.

const STAR_COUNT: int = 140
const SKY_SIZE: Vector2 = Vector2(2000, 460)
const RIBBONS: Array[Dictionary] = [
	{"y": 150.0, "height": 120.0, "color": Color(0.45, 1.0, 0.7), "speed": 0.05, "phase": 0.0},
	{"y": 210.0, "height": 90.0, "color": Color(0.35, 0.95, 0.85), "speed": 0.07, "phase": 2.1},
	{"y": 120.0, "height": 70.0, "color": Color(0.75, 0.55, 1.0), "speed": 0.04, "phase": 4.0},
]
const STEP: float = 60.0

@export var seed_value: int = 5:
	set(v):
		seed_value = v
		_build()

var _ribbons: Array[Polygon2D] = []
var _time: float = 0.0


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	_time += delta
	for i: int in _ribbons.size():
		var r: Dictionary = RIBBONS[i]
		var t: float = _time * TAU * float(r.speed) + float(r.phase)
		_ribbons[i].position.x = sin(t) * 60.0
		_ribbons[i].scale.y = 1.0 + 0.18 * sin(t * 1.7)
		_ribbons[i].modulate.a = 0.65 + 0.35 * sin(t * 2.3)


func _build() -> void:
	if not is_inside_tree():
		return
	ShapeUtil.clear_internal(self)
	_ribbons.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	# Stars: one Polygon2D of tiny diamonds, a few brighter than the rest.
	var stars: Polygon2D = Polygon2D.new()
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var polys: Array = []
	for i: int in STAR_COUNT:
		var p: Vector2 = Vector2(rng.randf() * SKY_SIZE.x - 200.0, rng.randf() * SKY_SIZE.y)
		var r: float = rng.randf_range(0.8, 2.2)
		var c: Color = Color(1, 1, 0.95, rng.randf_range(0.4, 1.0))
		var start: int = pts.size()
		for k: int in 4:
			var a: float = TAU * float(k) / 4.0
			pts.append(p + Vector2(cos(a), sin(a)) * r)
			cols.append(c)
		polys.append(PackedInt32Array([start, start + 1, start + 2, start + 3]))
	stars.polygon = pts
	stars.vertex_colors = cols
	stars.polygons = polys
	add_child(stars, false, Node.INTERNAL_MODE_BACK)
	# Ribbons: three rows (faint top, bright middle, fading bottom) with a wavy edge.
	for r: Dictionary in RIBBONS:
		var ribbon: Polygon2D = Polygon2D.new()
		ribbon.material = _additive()
		var rp: PackedVector2Array = PackedVector2Array()
		var rc: PackedColorArray = PackedColorArray()
		var col: Color = r.color
		var columns: int = int(SKY_SIZE.x / STEP) + 1
		for x_i: int in columns:
			var x: float = x_i * STEP - 200.0
			var wave: float = sin(x * 0.006 + float(r.phase)) * 40.0 + sin(x * 0.017) * 14.0
			var base: float = float(r.y) + wave
			rp.append(Vector2(x, base - float(r.height)))
			rc.append(Color(col, 0.0))
			rp.append(Vector2(x, base - float(r.height) * 0.3))
			rc.append(Color(col, 0.55))
			rp.append(Vector2(x, base))
			rc.append(Color(col, 0.0))
		var quads: Array = []
		for x_i: int in columns - 1:
			var a: int = x_i * 3
			var b: int = a + 3
			quads.append(PackedInt32Array([a, b, b + 1, a + 1]))
			quads.append(PackedInt32Array([a + 1, b + 1, b + 2, a + 2]))
		ribbon.polygon = rp
		ribbon.vertex_colors = rc
		ribbon.polygons = quads
		add_child(ribbon, false, Node.INTERNAL_MODE_BACK)
		_ribbons.append(ribbon)


static func _additive() -> CanvasItemMaterial:
	var m: CanvasItemMaterial = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
