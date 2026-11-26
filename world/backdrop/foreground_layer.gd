class_name ForegroundLayer
extends Parallax2D
## Dark grass, ferns and rocks passing close to the camera along the bottom of the
## screen, in front of the hiker. They scroll faster than the trail, which is what
## sells the depth. Built in code by the Backdrop from the level's own ground colours,
## so every trail gets one without a level edit. Sparse on purpose: a clump every few
## seconds of walking, never over the path.

## One tile; clumps repeat every WIDTH px of layer scroll.
const WIDTH: float = 3600.0
const SCROLL: float = 1.45
## The clumps' ground line: just above the bottom of the 720 px base view, so the bank shows.
const BASE_Y: float = 712.0
## Deep enough to cover the bottom of taller (4:3) screens too.
const DEPTH: float = 600.0
## Above everything in the level (the highest level z_index is 2).
const Z: int = 20
const CLUMPS: int = 2
## How dark the silhouettes are next to the deepest soil colour.
const DARKEN: float = 0.18

## Fade time when the camera zooms away from 1 (the summit pull-back), and back.
const FADE_SECONDS: float = 0.35

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _batch: TreeArt.Batch = TreeArt.Batch.new()
var _col: Color
var _lit: Color


## Null when there's no ground to take colours from (the menus).
static func create(strips: Array[TerrainStrip], seed_value: int) -> ForegroundLayer:
	if strips.is_empty():
		return null
	var layer: ForegroundLayer = ForegroundLayer.new()
	layer.name = "Foreground"
	layer.build(strips, seed_value)
	return layer


func build(strips: Array[TerrainStrip], seed_value: int) -> void:
	scroll_scale = Vector2(SCROLL, 0.0)
	repeat_size = Vector2(WIDTH, 0.0)
	repeat_times = 2
	z_index = Z
	# The trail's main ground (its longest strip) sets the colour; rock outcrops, shores
	# and boardwalk strips would muddy an average.
	var main: TerrainStrip = strips[0]
	var snowy: float = 0.0
	var total: float = 0.0
	for strip: TerrainStrip in strips:
		var length: float = _length(strip)
		total += length
		if length > _length(main):
			main = strip
		if strip.surface == TerrainStrip.Surface.SNOW or strip.surface == TerrainStrip.Surface.ICE:
			snowy += length
	_col = main.fill_bottom_color.darkened(DARKEN)
	_lit = _col.lightened(0.16)
	_rng.seed = seed_value
	var snow: bool = snowy * 2.0 > total
	var snow_col: Color = main.fill_color.darkened(0.25)
	for i: int in CLUMPS:
		var cx: float = WIDTH * (float(i) + _rng.randf_range(0.2, 0.8)) / float(CLUMPS)
		_clump(cx, snow, snow_col)
	var poly: Polygon2D = Polygon2D.new()
	poly.antialiased = true
	poly.polygon = _batch.pts
	poly.vertex_colors = _batch.cols
	poly.uv = _batch.uvs
	poly.polygons = _batch.polys
	TerrainStrip.apply_sway(poly, 0.0, 2.4, 8.0)
	add_child(poly)


## The layer is pinned to the bottom of an unzoomed view; once the camera pulls back it
## would float mid-screen, so it steps aside until the zoom returns.
func _process(delta: float) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	var zoomed: bool = cam != null and absf(cam.zoom.x - 1.0) > 0.01
	modulate.a = move_toward(modulate.a, 0.0 if zoomed else 1.0, delta / FADE_SECONDS)
	visible = modulate.a > 0.0


static func _length(strip: TerrainStrip) -> float:
	return 0.0 if strip.points.size() < 2 else strip.points[strip.points.size() - 1].x - strip.points[0].x


func _clump(cx: float, snow: bool, snow_col: Color) -> void:
	var w: float = _rng.randf_range(200.0, 320.0)
	var h: float = _rng.randf_range(14.0, 26.0)
	_batch.begin_plant(0.0, INF, 0.0)
	# A low bank the grass grows out of, running off the bottom of the screen.
	var bank: PackedVector2Array = PackedVector2Array()
	for k: int in 13:
		var t: float = float(k) / 12.0
		bank.append(Vector2(cx - w * 0.5 + w * t, BASE_Y - sin(t * PI) * h))
	bank.append(Vector2(cx + w * 0.5, BASE_Y + DEPTH))
	bank.append(Vector2(cx - w * 0.5, BASE_Y + DEPTH))
	_add(bank, _col)
	if snow or _rng.randf() < 0.3:
		_rock(cx + _rng.randf_range(-0.3, 0.3) * w, BASE_Y - h * 0.4, _rng.randf_range(34.0, 56.0), snow, snow_col)
	# A tuft or two of long grass fanning out from just under the bank.
	for tuft: int in (1 if snow else _rng.randi_range(1, 2)):
		var tx: float = cx + _rng.randf_range(-0.22, 0.22) * w
		var blades: int = _rng.randi_range(7, 10) if snow else _rng.randi_range(16, 24)
		for b: int in blades:
			var t: float = float(b) / float(blades - 1)
			var spread: float = t * 2.0 - 1.0
			var tall: float = _rng.randf_range(90.0, 190.0) * (1.0 - absf(spread) * 0.45) * (0.6 if snow else 1.0)
			_blade(tx + spread * 26.0, BASE_Y + 14.0, tall, spread * _rng.randf_range(0.35, 0.8) + _rng.randf_range(-0.15, 0.15),
				absf(spread) > 0.5)


## One long grass blade curving over, tapering to a point, lit on its left edge.
## `lean` is how far the tip bends sideways (fraction of its height).
func _blade(x: float, ground: float, h: float, lean: float, behind: bool) -> void:
	_batch.begin_plant(ground, h, _rng.randf() * TAU)
	var base_w: float = _rng.randf_range(9.0, 14.0)
	var col: Color = _col.darkened(0.08) if behind else _col
	var lit: Color = _lit.darkened(0.08) if behind else _lit
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	const SEGMENTS: int = 6
	for k: int in SEGMENTS + 1:
		var t: float = float(k) / float(SEGMENTS)
		var p: Vector2 = Vector2(x + lean * h * t * t, ground - h * t * (1.0 - absf(lean) * 0.25 * t))
		var half: float = base_w * 0.5 * (1.0 - t)
		left.append(p - Vector2(half, 0))
		right.append(p + Vector2(half, 0))
	var shape: PackedVector2Array = left.duplicate()
	var cols: PackedColorArray = PackedColorArray()
	for k: int in left.size():
		cols.append(lit)
	for k: int in range(right.size() - 2, -1, -1):
		shape.append(right[k])
		cols.append(col)
	_add_cols(shape, cols)


func _rock(x: float, ground: float, r: float, snow: bool, snow_col: Color) -> void:
	_batch.begin_plant(0.0, INF, 0.0)
	var outline: PackedVector2Array = PackedVector2Array()
	for k: int in 11:
		var a: float = PI + PI * float(k) / 10.0
		outline.append(Vector2(x + cos(a) * r, ground + sin(a) * r * 0.75))
	outline.append(Vector2(x + r, ground + DEPTH))
	outline.append(Vector2(x - r, ground + DEPTH))
	_add(outline, _col.lightened(0.05))
	_add(PackedVector2Array([Vector2(x - r * 0.75, ground - r * 0.4), Vector2(x - r * 0.15, ground - r * 0.72),
		Vector2(x + r * 0.1, ground - r * 0.5), Vector2(x - r * 0.6, ground - r * 0.2)]), _lit.lightened(0.04))
	if snow:
		var cap: PackedVector2Array = PackedVector2Array()
		for k: int in 9:
			var a: float = PI * 1.12 + PI * 0.76 * float(k) / 8.0
			cap.append(Vector2(x + cos(a) * r * 0.98, ground + sin(a) * r * 0.75))
		for k: int in range(8, -1, -1):
			var a: float = PI * 1.12 + PI * 0.76 * float(k) / 8.0
			cap.append(Vector2(x + cos(a) * r * 0.8, ground + sin(a) * r * 0.55 + (4.0 if k % 2 == 0 else 0.0)))
		_add(cap, snow_col)


func _add(shape: PackedVector2Array, col: Color) -> void:
	var cols: PackedColorArray = PackedColorArray()
	cols.resize(shape.size())
	cols.fill(col)
	_add_cols(shape, cols)


func _add_cols(shape: PackedVector2Array, cols: PackedColorArray) -> void:
	var idx: PackedInt32Array = PackedInt32Array()
	for i: int in shape.size():
		idx.append(_batch.pts.size())
		_batch.pts.append(shape[i])
		_batch.cols.append(cols[i])
		_batch.uvs.append(_batch.uv_for(shape[i]))
	_batch.polys.append(idx)
