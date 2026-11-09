class_name TreeArt
extends RefCounted
## Tree silhouettes for the backdrop layers, appended into one Polygon2D's point,
## colour and polygon lists (so a whole forest is still a single draw). Light comes
## from the left: the left half of every crown is a touch lighter than the right.

## How much lighter / darker the lit and shaded halves are than the base colour.
const LIGHT: float = 0.1
const SHADE: float = 0.12
const BIRCH_BARK: Color = Color("#ECE7DB")
const BARK: Color = Color("#4A3A2C")


## A spruce: a short trunk and four tiers of drooping boughs with ragged undersides.
static func pine(x: float, ground: float, h: float, col: Color, rng: RandomNumberGenerator, out: Batch) -> void:
	var w: float = h * rng.randf_range(0.5, 0.6)
	var lean: float = rng.randf_range(-0.04, 0.04) * h
	var trunk_w: float = maxf(h * 0.035, 1.0)
	_add(PackedVector2Array([Vector2(x - trunk_w, ground), Vector2(x + trunk_w, ground),
		Vector2(x + trunk_w, ground - h * 0.16), Vector2(x - trunk_w, ground - h * 0.16)]), BARK.lerp(col, 0.5), out)
	var tiers: int = 4
	for tier: int in tiers:
		var t: float = float(tier) / float(tiers)
		var tier_w: float = w * (1.0 - t * 0.7) * rng.randf_range(0.92, 1.06)
		var base: float = ground - h * (0.1 + t * 0.66)
		var top: float = base - h * (0.4 - t * 0.12)
		var apex: Vector2 = Vector2(x + lean * (1.0 - t * 0.5), top)
		var droop: float = h * 0.045
		# Each tier is two halves sharing the centre line, so the halves can be shaded.
		for side: float in [-1.0, 1.0]:
			var half: float = tier_w * 0.5 * side
			var pts: PackedVector2Array = PackedVector2Array([
				apex,
				Vector2(x + half * 0.55, base - h * 0.08),
				Vector2(x + half * 1.0, base + droop),
				Vector2(x + half * 0.72, base - h * 0.015),
				Vector2(x + half * 0.42, base + droop * 0.4),
				Vector2(x + half * 0.18, base - h * 0.01),
				Vector2(x, base + droop * 0.2),
			])
			if side > 0.0:
				pts.reverse()
			_add(pts, col.lightened(LIGHT) if side < 0.0 else col.darkened(SHADE), out)


## A birch: a pale trunk with dark marks and a crown of overlapping leafy clumps.
static func birch(x: float, ground: float, h: float, crown: Color, haze: Color, rng: RandomNumberGenerator, out: Batch) -> void:
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


## A slightly lumpy ellipse, so clumps don't look like perfect circles.
static func _blob(centre: Vector2, radii: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in 10:
		var a: float = TAU * float(k) / 10.0
		var r: float = rng.randf_range(0.88, 1.08)
		pts.append(centre + Vector2(cos(a) * radii.x, sin(a) * radii.y) * r)
	return pts


## Everything for one Polygon2D: points, per-point colours and the polygon index lists.
class Batch:
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var polys: Array = []


static func _add(shape: PackedVector2Array, col: Color, out: Batch) -> void:
	var idx: PackedInt32Array = PackedInt32Array()
	for p: Vector2 in shape:
		idx.append(out.pts.size())
		out.pts.append(p)
		out.cols.append(col)
	out.polys.append(idx)
