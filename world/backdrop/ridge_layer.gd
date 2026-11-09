@tool
class_name RidgeLayer
extends Polygon2D
## One silhouette layer of the backdrop (mountains, hills, treeline), generated from
## a seed so it can be tweaked in the Inspector. The skyline is built only from
## whole-number sine waves over `width`, so it tiles seamlessly in a Parallax2D whose
## repeat_size.x equals `width`.

@export var width: float = 2560.0:
	set(v):
		width = v
		_queue()
## Lowest point of the skyline (screen-ish y: layers sit near screen space at low scroll scales).
@export var base_y: float = 420.0:
	set(v):
		base_y = v
		_queue()
@export var amplitude: float = 120.0:
	set(v):
		amplitude = v
		_queue()
## Ridged = pointy mountain peaks; otherwise rolling hills.
@export var ridged: bool = false:
	set(v):
		ridged = v
		_queue()
## Number of sine waves layered together; more is more jagged.
@export_range(1, 6) var octaves: int = 3:
	set(v):
		octaves = v
		_queue()
@export var base_frequency: int = 3:
	set(v):
		base_frequency = v
		_queue()
@export var seed_value: int = 1:
	set(v):
		seed_value = v
		_queue()
## Colour the layer fades to at its base, so it reads as hazy and far away.
@export var haze_color: Color = Color("#CFEAF2"):
	set(v):
		haze_color = v
		_queue()
@export_range(0.0, 1.0) var haze_amount: float = 0.35:
	set(v):
		haze_amount = v
		_queue()

@export_group("Trees")
## Pines for evergreen forest, birches (round crowns) for ruska autumn, or a mix.
enum TreeStyle { PINE, BIRCH, MIXED }
@export var tree_style: TreeStyle = TreeStyle.PINE:
	set(v):
		tree_style = v
		_queue()
## Second colour, used for birch crowns in MIXED.
@export var tree_color_alt: Color = Color("#D9A441"):
	set(v):
		tree_color_alt = v
		_queue()
@export var tree_count: int = 0:
	set(v):
		tree_count = v
		_queue()
@export var tree_height: Vector2 = Vector2(30, 60):
	set(v):
		tree_height = v
		_queue()
@export var tree_color: Color = Color("#3B5B4A"):
	set(v):
		tree_color = v
		_queue()

@export_group("Snow")
## Peaks rising above this y get snow caps. Leave 0 for none.
@export var snow_line_y: float = 0.0:
	set(v):
		snow_line_y = v
		_queue()
@export var snow_color: Color = Color("#F4F7FA"):
	set(v):
		snow_color = v
		_queue()

const STEP: float = 16.0
const MAX_SNOW: float = 55.0
## Deep enough to cover the screen below the skyline on tall (4:3) screens.
const DEPTH: float = 2600.0

var _trees: Polygon2D
var _snow: Polygon2D
var _pending: bool = false


func _ready() -> void:
	antialiased = true
	_trees = _make_child("Trees")
	_snow = _make_child("Snow")
	_rebuild()


func _queue() -> void:
	# Several setters fire while a scene loads; build once at the end of the frame.
	if _pending or not is_node_ready():
		return
	_pending = true
	_rebuild.call_deferred()


func height_at(x: float) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var total: float = 0.0
	var weight_sum: float = 0.0
	var weight: float = 1.0
	for i: int in octaves:
		var freq: float = float(base_frequency * (i + 1) + rng.randi_range(0, 2))
		var phase: float = rng.randf() * TAU
		var wave: float = sin(TAU * freq * x / width + phase)
		# Ridged noise folds the wave so the peaks are sharp.
		var v: float = 1.0 - absf(wave) if ridged else 0.5 + 0.5 * wave
		total += v * weight
		weight_sum += weight
		weight *= 0.5
	return base_y - amplitude * total / weight_sum


func _rebuild() -> void:
	_pending = false
	if _trees == null:
		return
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var bottom_col: Color = color.lerp(haze_color, haze_amount)
	var x: float = 0.0
	# One step past `width` so neighbouring copies overlap instead of leaving a hairline.
	while x <= width + STEP:
		pts.append(Vector2(x, height_at(x)))
		cols.append(color)
		x += STEP
	pts.append(Vector2(x - STEP, base_y + DEPTH))
	cols.append(bottom_col)
	pts.append(Vector2(0.0, base_y + DEPTH))
	cols.append(bottom_col)
	polygon = pts
	# Vertex colours give a cheap vertical haze gradient with no texture.
	vertex_colors = cols
	_build_trees()
	_build_snow()


func _build_trees() -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var polys: Array = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 13
	for i: int in tree_count:
		var tx: float = rng.randf() * width
		var h: float = rng.randf_range(tree_height.x, tree_height.y)
		var w: float = h * 0.42
		var ground: float = height_at(tx) + h * 0.08
		var birch: bool = tree_style == TreeStyle.BIRCH or (tree_style == TreeStyle.MIXED and i % 2 == 1)
		if birch:
			# A birch: a thin stem and a round crown.
			var crown: Color = tree_color_alt if tree_style == TreeStyle.MIXED else tree_color
			var stem_w: float = maxf(h * 0.05, 1.5)
			_add_shape(PackedVector2Array([Vector2(tx - stem_w, ground), Vector2(tx + stem_w, ground), Vector2(tx + stem_w, ground - h * 0.7), Vector2(tx - stem_w, ground - h * 0.7)]), tree_color.darkened(0.3), pts, cols, polys)
			var ring: PackedVector2Array = PackedVector2Array()
			for k: int in 10:
				var a: float = TAU * float(k) / 10.0
				ring.append(Vector2(tx, ground - h * 0.62) + Vector2(cos(a) * w * 0.55, sin(a) * h * 0.36))
			_add_shape(ring, crown, pts, cols, polys)
		else:
			# A pine: three stacked triangles, each narrower and higher.
			for tier: int in 3:
				var t: float = float(tier)
				var tier_w: float = w * (1.0 - t * 0.22)
				var tier_base: float = ground - h * t * 0.28
				var tier_top: float = tier_base - h * 0.46
				_add_shape(PackedVector2Array([Vector2(tx - tier_w * 0.5, tier_base), Vector2(tx + tier_w * 0.5, tier_base), Vector2(tx, tier_top)]), tree_color, pts, cols, polys)
	_trees.polygon = pts
	_trees.vertex_colors = cols
	_trees.polygons = polys
	_trees.color = tree_color


func _add_shape(shape: PackedVector2Array, col: Color, pts: PackedVector2Array, cols: PackedColorArray, polys: Array) -> void:
	var idx: PackedInt32Array = PackedInt32Array()
	for p: Vector2 in shape:
		idx.append(pts.size())
		pts.append(p)
		cols.append(col)
	polys.append(idx)


func _build_snow() -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var polys: Array = []
	if snow_line_y != 0.0:
		var run: PackedVector2Array = PackedVector2Array()
		var prev: Vector2 = Vector2(0.0, height_at(0.0))
		if prev.y < snow_line_y:
			run.append(prev)
		var x: float = STEP
		while x <= width + STEP:
			var cur: Vector2 = Vector2(x, height_at(x))
			var was_above: bool = prev.y < snow_line_y
			var is_above: bool = cur.y < snow_line_y
			if was_above != is_above:
				# Start/end the cap exactly where the slope crosses the snow line,
				# otherwise steep peaks get boxy caps with vertical sides.
				var t: float = (snow_line_y - prev.y) / (cur.y - prev.y)
				run.append(Vector2(lerpf(prev.x, cur.x, t), snow_line_y))
				if was_above:
					if run.size() > 2:
						_add_cap(run, pts, polys)
					run = PackedVector2Array()
			if is_above:
				run.append(cur)
			prev = cur
			x += STEP
		if run.size() > 2:
			_add_cap(run, pts, polys)
	_snow.polygon = pts
	_snow.polygons = polys
	_snow.color = snow_color


## Turns a run of skyline points above the snow line into a cap with a jagged lower edge.
func _add_cap(run: PackedVector2Array, pts: PackedVector2Array, polys: Array) -> void:
	var start: int = pts.size()
	var indices: PackedInt32Array = PackedInt32Array()
	for p: Vector2 in run:
		indices.append(pts.size())
		pts.append(p)
	for i: int in range(run.size() - 1, -1, -1):
		var p: Vector2 = run[i]
		# The cap tapers to nothing at its edges and hangs lower (jagged) in the middle,
		# but never thicker than MAX_SNOW so tall peaks keep bare rock below the snow.
		var middle: float = 1.0 - absf(float(i) / float(maxi(run.size() - 1, 1)) * 2.0 - 1.0)
		var jag: float = middle * (18.0 if i % 2 == 0 else 6.0)
		var lower: float = minf(snow_line_y + jag, p.y + MAX_SNOW)
		lower = maxf(lower, p.y + 1.0)
		indices.append(pts.size())
		pts.append(Vector2(p.x, lower))
	if pts.size() - start >= 3:
		polys.append(indices)


func _make_child(child_name: String) -> Polygon2D:
	var child: Polygon2D = Polygon2D.new()
	child.name = child_name
	child.antialiased = true
	add_child(child, false, Node.INTERNAL_MODE_BACK)
	return child
