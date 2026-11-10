class_name TerrainDecor
extends RefCounted
## Generated dressing for a TerrainStrip: grass tufts, half-buried boulders and pebbles
## in the ground, and the spans that trail-side trees must leave clear. Split out of
## TerrainStrip so that script stays about the ground itself.

const PEBBLE_COLOR: Color = Color("#6C8E73")
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
		var center: Vector2 = Vector2(x, strip.edge_y_at(x) + rng.randf_range(26.0, 140.0))
		var r: float = rng.randf_range(2.0, 4.5)
		_shape(ShapeUtil.ellipse(center, Vector2(r * 1.4, r), 8), PEBBLE_COLOR, out)
		x += rng.randf_range(90.0, 220.0)
	return out


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
