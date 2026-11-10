class_name TreeArt
extends RefCounted
## Tree silhouettes for the backdrop layers and the trail-side trees, appended into one Polygon2D's point,
## colour and polygon lists (so a whole forest is still a single draw). Light comes
## from the left: the left half of every crown is a touch lighter than the right.

## How much lighter / darker the lit and shaded halves are than the base colour.
const LIGHT: float = 0.1
const SHADE: float = 0.12
const BIRCH_BARK: Color = Color("#ECE7DB")
const BARK: Color = Color("#4A3A2C")
const SNOW: Color = Color("#F4F8FB")
const SNOW_SHADE: Color = Color("#D5E2EE")


## A spruce: a trunk and tiers of drooping boughs with ragged undersides. Taller
## trees get more tiers. Each bough is lighter at the top and darker underneath, and
## `snow` lays a white load along the top of every tier.
static func pine(x: float, ground: float, h: float, col: Color, rng: RandomNumberGenerator, out: Batch, snow: bool = false) -> void:
	out.begin_plant(ground, h, rng.randf() * TAU)
	var w: float = h * rng.randf_range(0.5, 0.6)
	var lean: float = rng.randf_range(-0.04, 0.04) * h
	var trunk_w: float = maxf(h * 0.035, 1.0)
	var bark: Color = BARK.lerp(col, 0.4)
	_add_cols(PackedVector2Array([Vector2(x - trunk_w, ground), Vector2(x + trunk_w, ground),
		Vector2(x + trunk_w * 0.7, ground - h * 0.2), Vector2(x - trunk_w * 0.7, ground - h * 0.2)]),
		PackedColorArray([bark, bark.darkened(0.3), bark.darkened(0.3), bark]), out)
	var tiers: int = clampi(int(h / 45.0) + 3, 4, 6)
	for tier: int in tiers:
		var t: float = float(tier) / float(tiers)
		var tier_w: float = w * (1.0 - t * 0.72) * rng.randf_range(0.9, 1.08)
		var base: float = ground - h * (0.12 + t * 0.66)
		var top: float = base - h * (0.38 - t * 0.12)
		var apex: Vector2 = Vector2(x + lean * (1.0 - t * 0.5), top)
		var droop: float = h * 0.045 * rng.randf_range(0.8, 1.2)
		# Two halves sharing the centre line, so the lit and shaded sides can differ.
		for side: float in [-1.0, 1.0]:
			var half: float = tier_w * 0.5 * side
			var base_col: Color = col.lightened(LIGHT) if side < 0.0 else col.darkened(SHADE)
			var top_col: Color = base_col.lightened(0.14)
			var under: Color = base_col.darkened(0.18)
			var pts: PackedVector2Array = PackedVector2Array([
				apex,
				Vector2(x + half * 0.55, base - h * 0.08),
				Vector2(x + half * 1.0, base + droop),
				Vector2(x + half * 0.72, base - h * 0.015),
				Vector2(x + half * 0.42, base + droop * 0.4),
				Vector2(x + half * 0.18, base - h * 0.01),
				Vector2(x, base + droop * 0.2),
			])
			var cols: PackedColorArray = PackedColorArray([top_col, base_col, base_col, under, under, under, under])
			if side > 0.0:
				pts.reverse()
				cols.reverse()
			_add_cols(pts, cols, out)
			if snow:
				var th: float = h * 0.04
				var p1: Vector2 = Vector2(x + half * 0.55, base - h * 0.08)
				var p2: Vector2 = Vector2(x + half * 0.92, base + droop * 0.6)
				var cap: PackedVector2Array = PackedVector2Array([apex, p1, p2, p2 + Vector2(-half * 0.08, th * 0.6), p1 + Vector2(0, th), apex + Vector2(0, th * 1.4)])
				if side > 0.0:
					cap.reverse()
				_add(cap, SNOW if side < 0.0 else SNOW_SHADE, out)


## A birch: a pale trunk with dark marks and a crown of overlapping leafy clumps.
static func birch(x: float, ground: float, h: float, crown: Color, haze: Color, rng: RandomNumberGenerator, out: Batch) -> void:
	out.begin_plant(ground, h, rng.randf() * TAU)
	var stem_w: float = maxf(h * 0.04, 1.2)
	var bark: Color = BIRCH_BARK.lerp(haze, 0.35)
	var lean: float = rng.randf_range(-0.05, 0.05) * h
	var top: Vector2 = Vector2(x + lean, ground - h * 0.72)
	_add(PackedVector2Array([Vector2(x - stem_w, ground), Vector2(x + stem_w, ground),
		top + Vector2(stem_w * 0.6, 0), top - Vector2(stem_w * 0.6, 0)]), bark, out)
	for k: int in 2:
		var y: float = ground - h * rng.randf_range(0.12, 0.5)
		var mx: float = lerpf(x, top.x, (ground - y) / (h * 0.72))
		_add(PackedVector2Array([Vector2(mx - stem_w, y), Vector2(mx + stem_w * 0.2, y), Vector2(mx + stem_w * 0.2, y + h * 0.025), Vector2(mx - stem_w, y + h * 0.025)]), crown.darkened(0.55), out)
	if h > 90.0:
		# Big birches show a few dark branches reaching into the crown.
		for k: int in 3:
			var from: Vector2 = Vector2(lerpf(x, top.x, 0.7), ground - h * rng.randf_range(0.45, 0.62))
			var dir: float = -1.0 if k % 2 == 0 else 1.0
			var to: Vector2 = from + Vector2(dir * h * rng.randf_range(0.12, 0.2), -h * rng.randf_range(0.1, 0.18))
			var bw: float = stem_w * 0.45
			_add(PackedVector2Array([from + Vector2(0, -bw), to, from + Vector2(0, bw)]), bark.darkened(0.25), out)
	var cx: float = top.x
	var cy: float = ground - h * 0.66
	var rx: float = h * 0.24
	var ry: float = h * 0.3
	# Shaded clumps first (lower right), then lit ones on top (upper left).
	var clumps: Array[Vector3] = [
		Vector3(0.35, 0.25, 0.75), Vector3(-0.1, 0.35, 0.8), Vector3(0.3, -0.25, 0.7),
		Vector3(-0.35, 0.05, 0.7), Vector3(-0.1, -0.35, 0.65), Vector3(0.0, -0.05, 0.8),
	]
	for i: int in clumps.size():
		var c: Vector3 = clumps[i]
		var lit: bool = c.x < 0.0 and c.y <= 0.05 or i == clumps.size() - 1
		var col: Color = crown.lightened(LIGHT) if lit else crown.darkened(SHADE * (0.5 if c.y < 0.0 else 1.0))
		var centre: Vector2 = Vector2(cx + c.x * rx, cy + c.y * ry)
		_add(_blob(centre, Vector2(rx, ry) * c.z * 0.62, rng), col, out)


## Big trees spaced along a stretch of trail (TerrainStrip's trail-side trees).
## `edge_y` gives the path height at an x; trees stand just behind it. No tree is
## placed inside a `clear` span (local x from..to). kind follows
## TerrainStrip.TreeKind: 1 = pines, 2 = birches, 3 = mixed.
static func along(edge_y: Callable, x0: float, x1: float, kind: int, spacing: Vector2, height: Vector2,
		col: Color, alt: Color, snow: bool, seed_value: int, clear: Array[Vector2] = []) -> Batch:
	var batch: Batch = Batch.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var x: float = x0 + rng.randf_range(40.0, spacing.x)
	var i: int = 0
	while x < x1 - 30.0:
		var blocked: bool = false
		for span: Vector2 in clear:
			if x > span.x and x < span.y:
				# Skip past a landmark or viewpoint so nothing hides it.
				x = span.y + rng.randf_range(20.0, 80.0)
				blocked = true
		if blocked:
			continue
		var h: float = rng.randf_range(height.x, height.y)
		# Sink the base a little so the ground fill hides where the trunk meets it.
		var ground: float = float(edge_y.call(x)) + h * 0.05
		# Small colour shifts so neighbouring trees don't look stamped.
		var shift: float = rng.randf_range(-0.06, 0.08)
		var birch_here: bool = kind == 2 or (kind == 3 and i % 3 == 1)
		if birch_here:
			birch(x, ground, h * 0.85, alt.darkened(shift), Color("#F2EEE4"), rng, batch)
		else:
			pine(x, ground, h, col.darkened(shift), rng, batch, snow)
		x += rng.randf_range(spacing.x, spacing.y)
		i += 1
	return batch


## A slightly lumpy ellipse, so clumps don't look like perfect circles.
static func _blob(centre: Vector2, radii: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in 10:
		var a: float = TAU * float(k) / 10.0
		var r: float = rng.randf_range(0.88, 1.08)
		pts.append(centre + Vector2(cos(a) * radii.x, sin(a) * radii.y) * r)
	return pts


## Everything for one Polygon2D: points, per-point colours and the polygon index lists.
## Each point also gets a UV for the sway shader: x = phase, y = sway weight
## (0 at the root, 1 at the tip), from the current sway_root/sway_height.
class Batch:
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var uvs: PackedVector2Array = PackedVector2Array()
	var polys: Array = []
	## Set before adding a plant's shapes: its root y and height (INF = doesn't sway).
	var sway_root: float = 0.0
	var sway_height: float = INF
	var sway_phase: float = 0.0

	func begin_plant(root_y: float, height: float, phase: float) -> void:
		sway_root = root_y
		sway_height = height
		sway_phase = phase

	func uv_for(p: Vector2) -> Vector2:
		if is_inf(sway_height):
			return Vector2.ZERO
		return Vector2(sway_phase, clampf((sway_root - p.y) / sway_height, 0.0, 1.0))


## Like _add, with one colour per point (smooth shading across the shape).
static func _add_cols(shape: PackedVector2Array, cols: PackedColorArray, out: Batch) -> void:
	var idx: PackedInt32Array = PackedInt32Array()
	for i: int in shape.size():
		idx.append(out.pts.size())
		out.pts.append(shape[i])
		out.cols.append(cols[i])
		out.uvs.append(out.uv_for(shape[i]))
	out.polys.append(idx)


static func _add(shape: PackedVector2Array, col: Color, out: Batch) -> void:
	var idx: PackedInt32Array = PackedInt32Array()
	for p: Vector2 in shape:
		idx.append(out.pts.size())
		out.pts.append(p)
		out.cols.append(col)
		out.uvs.append(out.uv_for(p))
	out.polys.append(idx)
