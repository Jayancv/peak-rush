class_name TerrainDecor
extends RefCounted
## Generated dressing for a TerrainStrip: grass tufts and flowers, half-buried boulders,
## layered soil with stones set into it, and the spans that trail-side trees must leave
## clear. Split out of TerrainStrip so that script stays about the ground itself.

## Soil layers under the path: (depth below the edge in px, how far towards
## fill_bottom_color). Stepped bands read as earth in cross-section, not a flat slab.
const BANDS: Array[Vector2] = [Vector2(30, 0.24), Vector2(86, 0.44), Vector2(166, 0.62), Vector2(270, 0.78), Vector2(410, 0.92)]
## Each layer's top edge is a thin darker line, like the seam between two kinds of earth.
const SEAM_PX: float = 4.0
const BAND_STEP: float = 20.0
## Stone colour that every trail's soil is mixed towards.
const STONE: Color = Color("#9A9890")
const FLOWERS: Array[Color] = [Color("#F6F1E4"), Color("#F2C94C"), Color("#B994E0"), Color("#EE9AB0")]
const FLOWER_CHANCE: float = 0.2
const BOULDER_COLOR: Color = Color("#8C8B84")
const BOULDER_SHADE: Color = Color("#6F6E68")
## Landmarks in this group (with optional meta `tree_clear_radius`) keep trail-side trees away.
const TREE_CLEAR_GROUP: StringName = &"tree_clear"
## Half-width kept free of trees around a viewpoint's photo frame.
const VIEWPOINT_CLEAR: float = 330.0


static func build(strip: TerrainStrip) -> TreeArt.Batch:
	var out: TreeArt.Batch = TreeArt.Batch.new()
	var pts: PackedVector2Array = strip.points
	if not strip.decorate or pts.size() < 2:
		return out
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = strip.decor_seed
	var start_x: float = pts[0].x
	var end_x: float = pts[pts.size() - 1].x
	var grassy: bool = strip.surface == TerrainStrip.Surface.DIRT or strip.surface == TerrainStrip.Surface.MUD
	var x: float = start_x + rng.randf_range(10.0, 60.0)
	while grassy and x < end_x - 10.0:
		var y: float = strip.edge_y_at(x)
		out.begin_plant(y, 17.0, rng.randf() * TAU)
		# Three blades leaning slightly, poking up just behind the path.
		for b: int in 3:
			var bx: float = x + (b - 1) * 4.0
			var h: float = rng.randf_range(9.0, 17.0) * (1.25 if b == 1 else 0.8)
			_shape(PackedVector2Array([Vector2(bx - 2.2, y), Vector2(bx + 2.2, y), Vector2(bx + (b - 1) * 3.0, y - h)]), strip.tuft_color, out)
			if b == 1 and rng.randf() < FLOWER_CHANCE:
				var head: Vector2 = Vector2(bx, y - h - 1.5)
				_shape(ShapeUtil.ellipse(head, Vector2(3.2, 2.8), 7), FLOWERS[rng.randi() % FLOWERS.size()], out)
				_shape(ShapeUtil.ellipse(head, Vector2(1.1, 1.1), 5), Color("#E8A33A"), out)
		x += rng.randf_range(28.0, 95.0)
	# Boulders and pebbles don't sway.
	out.begin_plant(0.0, INF, 0.0)
	x = start_x + rng.randf_range(20.0, 60.0)
	while strip.surface == TerrainStrip.Surface.ROCK and x < end_x - 10.0:
		# Grey boulders half-buried along a rocky path.
		var r: float = rng.randf_range(10.0, 20.0)
		_lump(Vector2(x, strip.edge_y_at(x) + r * 0.15), r * rng.randf_range(1.1, 1.5), r, BOULDER_SHADE, out)
		_lump(Vector2(x - r * 0.15, strip.edge_y_at(x) + r * 0.05), r * 0.95, r * 0.8, BOULDER_COLOR, out)
		x += rng.randf_range(40.0, 120.0)
	x = start_x + rng.randf_range(20.0, 80.0)
	while x < end_x - 10.0:
		var depth: float = rng.randf_range(26.0, 140.0)
		var center: Vector2 = Vector2(x, strip.edge_y_at(x) + depth)
		var r: float = rng.randf_range(2.0, 4.5)
		_shape(ShapeUtil.ellipse(center, Vector2(r * 1.4, r), 8), soil_color(strip, depth).darkened(0.2), out)
		x += rng.randf_range(90.0, 220.0)
	# Stones set into the soil layers, lit from the upper left like everything else.
	x = start_x + rng.randf_range(60.0, 200.0)
	while x < end_x - 30.0:
		var depth: float = rng.randf_range(60.0, 330.0)
		var r: float = rng.randf_range(6.0, 17.0)
		var c: Vector2 = Vector2(x, strip.edge_y_at(x) + depth)
		# Lighter than the soil (a darker blob reads as a hole), with a shaded underside.
		var col: Color = soil_color(strip, depth).lerp(STONE, 0.45)
		var radii: Vector2 = Vector2(r * rng.randf_range(1.2, 1.7), r)
		_shape(_stone(c + Vector2(0, r * 0.18), radii * 1.06, rng), col.darkened(0.3), out)
		_shape(_stone(c, radii, rng), col, out)
		_shape(ShapeUtil.ellipse(c + Vector2(-r * 0.3, -r * 0.4), Vector2(r * 0.55, r * 0.3), 8), col.lightened(0.18), out)
		x += rng.randf_range(170.0, 420.0)
	return out


## The soil colour `depth` px below the path edge (the band it falls in).
static func soil_color(strip: TerrainStrip, depth: float) -> Color:
	var t: float = 0.0
	for band: Vector2 in BANDS:
		if depth >= band.x:
			t = band.y
	return strip.fill_color.lerp(strip.fill_bottom_color, t)


## The soil layers: one polygon per band, each from its wavy top down to the bottom of
## the fill, drawn in order so deeper (darker) bands cover the ones above.
static func strata(strip: TerrainStrip) -> TreeArt.Batch:
	var out: TreeArt.Batch = TreeArt.Batch.new()
	var pts: PackedVector2Array = strip.points
	if not strip.decorate or pts.size() < 2:
		return out
	var bottom: float = pts[0].y
	for p: Vector2 in pts:
		bottom = maxf(bottom, p.y)
	bottom += strip.fill_depth
	var x0: float = pts[0].x
	var x1: float = pts[pts.size() - 1].x
	# The path edge sampled once every BAND_STEP (walking the points, not searching them).
	var xs: PackedFloat32Array = PackedFloat32Array()
	var ys: PackedFloat32Array = PackedFloat32Array()
	var seg: int = 1
	var x: float = x0
	while true:
		while seg < pts.size() - 1 and x > pts[seg].x:
			seg += 1
		var a: Vector2 = pts[seg - 1]
		var b: Vector2 = pts[seg]
		xs.append(x)
		ys.append(lerpf(a.y, b.y, clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0)))
		if x >= x1:
			break
		x = minf(x + BAND_STEP, x1)
	var n: int = xs.size()
	# Waves keyed to world x with fixed phases, so the layers of two strips that meet
	# line up instead of showing a seam.
	var ox: float = strip.position.x
	for b: int in BANDS.size():
		var band: Vector2 = BANDS[b]
		var d: float = band.x
		var ph1: float = float(b) * 2.1
		var ph2: float = float(b) * 4.7
		var amp: float = 3.0 + d * 0.035
		# Deeper layers follow the path more loosely (averaged over a wider span). The span
		# narrows to nothing at the strip's ends, so the next strip's layers meet these.
		var k: int = maxi(1, roundi(d * 0.5 / BAND_STEP))
		var shape: PackedVector2Array = PackedVector2Array()
		for i: int in n:
			var ki: int = mini(k, mini(i, n - 1 - i))
			var edge: float = (ys[i - ki] + ys[i] + ys[i + ki]) / 3.0
			var wx: float = xs[i] + ox
			var y: float = edge + d + amp * sin(wx * 0.011 + ph1) + amp * 0.5 * sin(wx * 0.031 + ph2)
			shape.append(Vector2(xs[i], minf(maxf(y, ys[i] + 12.0), bottom)))
		var seam: PackedVector2Array = shape.duplicate()
		for i: int in range(n - 1, -1, -1):
			seam.append(shape[i] + Vector2(0, SEAM_PX))
		shape.append(Vector2(x1, bottom))
		shape.append(Vector2(x0, bottom))
		var col: Color = strip.fill_color.lerp(strip.fill_bottom_color, band.y)
		_shape(shape, col, out)
		_shape(seam, col.darkened(0.1), out)
	return out


## A rounded stone with a slightly lumpy outline.
static func _stone(c: Vector2, radii: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var ring: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var a: float = TAU * float(i) / 10.0
		ring.append(c + Vector2(cos(a) * radii.x, sin(a) * radii.y) * rng.randf_range(0.88, 1.08))
	return ring


## Local x ranges (in the strip's space) where trail-side trees would hide something.
static func clear_spans(strip: TerrainStrip) -> Array[Vector2]:
	var spans: Array[Vector2] = []
	if not strip.is_inside_tree():
		return spans
	for node: Node in strip.get_tree().get_nodes_in_group(TREE_CLEAR_GROUP):
		var mark: Node2D = node as Node2D
		if mark != null:
			var r: float = float(mark.get_meta("tree_clear_radius", 240.0))
			var lx: float = strip.to_local(mark.global_position).x
			spans.append(Vector2(lx - r, lx + r))
	for node: Node in strip.get_tree().get_nodes_in_group(Viewpoint.GROUP):
		var vp: Viewpoint = node as Viewpoint
		if vp != null:
			var lx: float = strip.to_local(vp.global_position + vp.frame_offset).x
			spans.append(Vector2(lx - VIEWPOINT_CLEAR, lx + VIEWPOINT_CLEAR))
	return spans


## Upper half of an ellipse, flat side down.
static func _lump(center: Vector2, rx: float, ry: float, col: Color, out: TreeArt.Batch) -> void:
	var ring: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		var a: float = PI + PI * float(i) / 8.0
		ring.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	_shape(ring, col, out)


static func _shape(shape: PackedVector2Array, col: Color, out: TreeArt.Batch) -> void:
	var idx: PackedInt32Array = PackedInt32Array()
	for p: Vector2 in shape:
		idx.append(out.pts.size())
		out.pts.append(p)
		out.cols.append(col)
		out.uvs.append(out.uv_for(p))
	out.polys.append(idx)
