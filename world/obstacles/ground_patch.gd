@tool
class_name GroundPatch
extends HikerArea
## A stretch of mud, ice or snow lying on the path. While the hiker is in it, the
## patch's surface replaces the ground's (mud: slow and tiring, ice: slippery).
## The art follows the path's slope, read from the TerrainStrip underneath.

@export var surface: TerrainStrip.Surface = TerrainStrip.Surface.MUD:
	set(v):
		surface = v
		rebuild()
@export var width: float = 160.0:
	set(v):
		width = v
		rebuild()

const MUD_DRY: Color = Color("#7D6048")
const MUD_WET: Color = Color("#4B3626")
const MUD_DARK: Color = Color("#33241A")
const MUD_DAMP: Color = Color(0.32, 0.22, 0.14, 0.28)
const PUDDLE: Color = Color(0.64, 0.74, 0.78, 0.92)
const ICE: Color = Color(0.64, 0.83, 0.91, 0.92)
const ICE_LIGHT: Color = Color("#E4F6FC")
const ICE_CRACK: Color = Color(0.36, 0.58, 0.72, 0.8)
const SNOW: Color = Color("#F4F8FB")
const SNOW_SHADE: Color = Color("#C9D7E3")
const SHINE: Color = Color(1, 1, 1, 0.7)
const SAMPLES: int = 24
## How far above the path line the hiker's feet are (half the TerrainStrip edge width).
const PATH_TOP: float = TerrainStrip.EDGE_WIDTH * 0.5

var _strip: TerrainStrip
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func build() -> void:
	_strip = _find_strip()
	_rng.seed = hash(Vector2i(roundi(position.x), roundi(position.y)))
	var half: float = width * 0.5
	match surface:
		TerrainStrip.Surface.ICE:
			_build_ice(half)
		TerrainStrip.Surface.SNOW:
			_build_snow(half)
		_:
			_build_mud(half)
	ShapeUtil.add_rect_shape(self, Rect2(-half, -40.0, width, 44.0))


func _build_mud(half: float) -> void:
	# Damp darker path around it, a dried splatter edge, a wet dark middle,
	# sky-coloured puddles, footprints and clods.
	ShapeUtil.add_poly(self, _band(-half - 26.0, half + 26.0, PATH_TOP, PATH_TOP - 1.0, 0.0, 0.8), MUD_DAMP, 1)
	ShapeUtil.add_poly(self, _band(-half - 8.0, half + 8.0, PATH_TOP + 1.5, 6.0, 1.2), MUD_DRY, 1)
	ShapeUtil.add_poly(self, _band(-half * 0.92, half * 0.92, PATH_TOP - 0.5, 4.5, 0.6), MUD_WET, 1)
	for i: int in 2 + _rng.randi() % 2:
		var cx: float = _rng.randf_range(-half * 0.6, half * 0.6)
		var r: float = _rng.randf_range(width * 0.07, width * 0.14)
		ShapeUtil.add_poly(self, _band(cx - r, cx + r, PATH_TOP - 0.5, -2.5), PUDDLE, 1)
		ShapeUtil.add_poly(self, _band(cx - r * 0.7, cx + r * 0.1, PATH_TOP - 0.7, -PATH_TOP + 1.7), SHINE, 1)
	for i: int in 3:
		var fx: float = lerpf(-half * 0.7, half * 0.7, (float(i) + _rng.randf_range(0.2, 0.8)) / 3.0)
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(fx, _ground(fx) - PATH_TOP + 3.0), Vector2(5.0, 1.4), 10), MUD_DARK, 1)
	for i: int in 4:
		var cx: float = _rng.randf_range(-half, half)
		var r: float = _rng.randf_range(2.0, 3.6)
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(cx, _ground(cx) - PATH_TOP - r * 0.4), Vector2(r * 1.3, r), 8), MUD_DRY.lightened(0.08), 1)
	for side: float in [-1.0, 1.0]:
		for i: int in 3:
			var sx: float = side * (half + _rng.randf_range(10.0, 22.0))
			ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(sx, _ground(sx) - PATH_TOP - _rng.randf_range(0.0, 3.0)), Vector2.ONE * _rng.randf_range(1.0, 1.8), 6), MUD_WET, 1)


func _build_ice(half: float) -> void:
	# Glassy sheet: pale base, bright top edge, diagonal glints, a few cracks, frosty ends.
	ShapeUtil.add_poly(self, _band(-half, half, PATH_TOP + 1.0, 5.0, 0.0, 0.35), ICE, 1)
	ShapeUtil.add_poly(self, _band(-half * 0.96, half * 0.96, PATH_TOP + 1.0, -PATH_TOP + 2.0, 0.0, 0.35), ICE_LIGHT, 1)
	for i: int in 4:
		var x: float = lerpf(-half * 0.75, half * 0.75, (float(i) + _rng.randf_range(0.0, 0.6)) / 4.0)
		var w: float = _rng.randf_range(4.0, 9.0)
		var top: float = _ground(x) - PATH_TOP
		ShapeUtil.add_poly(self, PackedVector2Array([Vector2(x, top + 1.0), Vector2(x + w, top + 1.0),
			Vector2(x + w - 5.0, _ground(x) + 4.0), Vector2(x - 5.0, _ground(x) + 4.0)]), Color(1, 1, 1, 0.5), 1)
	for i: int in 2:
		var line: Line2D = Line2D.new()
		line.width = 1.0
		line.default_color = ICE_CRACK
		line.antialiased = true
		line.z_index = 1
		var x: float = _rng.randf_range(-half * 0.6, half * 0.5)
		for k: int in 4:
			var px: float = x + float(k) * _rng.randf_range(6.0, 11.0)
			line.add_point(Vector2(px, _ground(px) - PATH_TOP + 2.0 + _rng.randf_range(0.0, PATH_TOP + 2.0)))
		add_child(line, false, Node.INTERNAL_MODE_BACK)
	for side: float in [-1.0, 1.0]:
		var ex: float = side * half * 0.97
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(ex, _ground(ex) - PATH_TOP + 1.0), Vector2(7.0, 2.4), 10), Color(1, 1, 1, 0.85), 1)


func _build_snow(half: float) -> void:
	# A soft drift: blue-grey shadow underneath, white mound, a few sparkles.
	ShapeUtil.add_poly(self, _band(-half - 4.0, half + 4.0, PATH_TOP + 3.0, 6.0, 0.0, 0.5), SNOW_SHADE, 1)
	ShapeUtil.add_poly(self, _band(-half, half, PATH_TOP + 6.0, 3.5, 1.0, 0.6), SNOW, 1)
	for i: int in 5:
		var x: float = _rng.randf_range(-half * 0.8, half * 0.8)
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(x, _ground(x) - PATH_TOP - 2.0), Vector2(1.2, 1.2), 6), Color("#BFE6F5"), 1)


## A strip lying along the path from x0 to x1: `up` px above the path line and `down`
## below it, rounded at the ends. `jitter` roughens the top edge; `taper` < 1 makes
## the ends squarer.
func _band(x0: float, x1: float, up: float, down: float, jitter: float = 0.0, taper: float = 0.5) -> PackedVector2Array:
	var top: PackedVector2Array = PackedVector2Array()
	var bottom: PackedVector2Array = PackedVector2Array()
	for i: int in SAMPLES + 1:
		var t: float = float(i) / float(SAMPLES)
		var x: float = lerpf(x0, x1, t)
		var f: float = pow(sin(PI * t), taper)
		var g: float = _ground(x)
		var mid: float = g + (down - up) * 0.5
		top.append(Vector2(x, lerpf(mid, g - up - _rng.randf_range(0.0, jitter), f)))
		bottom.append(Vector2(x, lerpf(mid, g + down, f)))
	bottom.reverse()
	top.append_array(bottom)
	return top


## Path line height (in this patch's local space) at local x; flat if no strip is found.
func _ground(x: float) -> float:
	if _strip == null:
		return 0.0
	var sx: float = _strip.to_local(to_global(Vector2(x, 0.0))).x
	sx = clampf(sx, _strip.points[0].x, _strip.points[_strip.points.size() - 1].x)
	return to_local(_strip.to_global(Vector2(sx, _strip.edge_y_at(sx)))).y


## The strip whose path passes closest to this patch's origin.
func _find_strip() -> TerrainStrip:
	if not is_inside_tree():
		return null
	var best: TerrainStrip = null
	var best_dist: float = 60.0
	for node: Node in get_tree().get_nodes_in_group(TerrainStrip.GROUP):
		var strip: TerrainStrip = node as TerrainStrip
		if strip == null or strip.points.size() < 2:
			continue
		var sx: float = strip.to_local(global_position).x
		if sx < strip.points[0].x or sx > strip.points[strip.points.size() - 1].x:
			continue
		var dist: float = absf(to_local(strip.to_global(Vector2(sx, strip.edge_y_at(sx)))).y)
		if dist < best_dist:
			best = strip
			best_dist = dist
	return best


func _hiker_entered(hiker: Hiker) -> void:
	hiker.condition.enter_patch(surface)


func _hiker_exited(hiker: Hiker) -> void:
	hiker.condition.exit_patch(surface)
