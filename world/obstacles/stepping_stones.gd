@tool
class_name SteppingStones
extends Node2D
## A shallow stream crossed by hopping stone to stone. The origin is the left bank at
## path height; put terrain strips ending/starting at x = 0 and x = total_width().
## Missing a stone drops the hiker in the water: wet feet (extra drain for a while)
## and a jump out over the stone or the bank.

@export var stone_count: int = 3:
	set(v):
		stone_count = maxi(v, 1)
		_rebuild()
@export var stone_width: float = 44.0:
	set(v):
		stone_width = v
		_rebuild()
## Water between stones. Must be under the jump distance (about 90 px at walk speed).
@export var gap: float = 72.0:
	set(v):
		gap = v
		_rebuild()
@export var depth: float = 58.0:
	set(v):
		depth = v
		_rebuild()
## How far each stone sinks and tips under the hiker (px). 0 = solid stones.
@export var wobble: float = 0.0:
	set(v):
		wobble = v
		_rebuild()

const WATER_SHADER: Shader = preload("res://world/obstacles/water.gdshader")
const BANK: Color = Color("#6A5440")
const BANK_DARK: Color = Color("#2E261E")
const BED_PEBBLES: Array[Color] = [Color("#7E7A6E"), Color("#9B9079"), Color("#676B62"), Color("#8A8170")]
const STONE_LIGHT: Color = Color("#B9B6AC")
const STONE: Color = Color("#8C8A82")
const STONE_DARK: Color = Color("#55544F")
const MOSS: Color = Color("#6F8D4A")
const MOSS_LIGHT: Color = Color("#93AE5E")
const FOAM: Color = Color(1, 1, 1, 0.75)
const SPLASH_DROPS: int = 16
const WATER_LIGHT: Color = Color("#CFEAF2")
const REED: Color = Color("#6E8B4C")
const REED_LIGHT: Color = Color("#8FA75B")
const CATTAIL: Color = Color("#6B4A2F")
## Stone tops stand this far above the banks so they read as stepping stones.
const STONE_RISE: float = 10.0
## The water surface sits this far below the banks.
const WATER_DROP: float = 16.0
## How far the sloping banks reach into the stream at the bottom.
const BANK_REACH: float = 22.0
## The banks overlap the ends of the terrain a little so there's no seam.
const BANK_OVERLAP: float = 8.0

var _ready_done: bool = false


func _ready() -> void:
	_ready_done = true
	_rebuild()


func total_width() -> float:
	return gap + float(stone_count) * (stone_width + gap)


func _rebuild() -> void:
	if not _ready_done:
		return
	ShapeUtil.clear_internal(self)
	var w: float = total_width()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(roundi(position.x), roundi(position.y)))
	# Stream bed: solid ground under the water so a miss means wet feet, not a fall.
	var bed: StaticBody2D = StaticBody2D.new()
	add_child(bed, false, Node.INTERNAL_MODE_BACK)
	# Ground under the stream in the banks' own colours, then a thin earthy lining.
	var bank: TerrainStrip = _bank_strip()
	var fill_top: Color = bank.fill_color if bank != null else Color("#4A7359")
	var fill_bottom: Color = bank.fill_bottom_color if bank != null else Color("#22372C")
	# Reach as deep as the bank's fill so the colour gradient lines up with it.
	var ground_bottom: float = to_local(bank.get_global_bounds().end).y if bank != null else depth + 400.0
	ground_bottom = maxf(ground_bottom, depth + 60.0)
	var ground: Polygon2D = ShapeUtil.add_poly(bed, _channel(w, 3.0, ground_bottom), fill_top)
	ground.vertex_colors = _gradient(ground.polygon, fill_top, fill_bottom, ground_bottom)
	var lining: Polygon2D = ShapeUtil.add_poly(bed, _channel(w, 3.0, depth + 9.0), BANK)
	lining.vertex_colors = _gradient(lining.polygon, BANK, BANK_DARK, depth + 9.0)
	ShapeUtil.add_rect_shape(bed, Rect2(0, depth, w, 60))
	_add_bed_pebbles(w, rng)
	for i: int in stone_count:
		_add_stone(gap + float(i) * (stone_width + gap), rng)
	# Water draws over the hiker (z 1) so wading looks like wading.
	var water: Polygon2D = ShapeUtil.add_poly(self, _channel(w, WATER_DROP - 3.0, 0.0), Color.WHITE, 1)
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("surface_y", WATER_DROP)
	mat.set_shader_parameter("depth", depth)
	water.material = mat
	for i: int in stone_count:
		_add_foam(gap + float(i) * (stone_width + gap), rng)
	_add_reeds(-2.0, -1.0, rng)
	_add_reeds(w + 2.0, 1.0, rng)
	var area: Area2D = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = HikerArea.HIKER_LAYER
	area.monitorable = false
	add_child(area, false, Node.INTERNAL_MODE_BACK)
	ShapeUtil.add_rect_shape(area, Rect2(0, WATER_DROP + 6.0, w, depth - WATER_DROP))
	if not Engine.is_editor_hint():
		area.body_entered.connect(_on_water_entered)
		area.body_exited.connect(_on_water_exited)


## U-shaped stream channel from y = top: steep banks that flatten out into the bed.
## With bottom > depth it's the earth around and under the channel (closed down to
## `bottom`); otherwise it's the inside of the U, closed across at `top` (the water).
func _channel(w: float, top: float, bottom: float) -> PackedVector2Array:
	var left: PackedVector2Array = PackedVector2Array()
	var steps: int = 8
	for i: int in steps + 1:
		var a: float = PI * 0.5 * float(i) / float(steps)
		var p: Vector2 = Vector2(-BANK_OVERLAP + (BANK_REACH + BANK_OVERLAP) * (1.0 - cos(a)), 3.0 + (depth - 3.0) * sin(a))
		if p.y >= top:
			if left.is_empty() and i > 0:
				# Start exactly at `top` so the water surface meets the bank cleanly.
				var prev_a: float = PI * 0.5 * float(i - 1) / float(steps)
				var prev: Vector2 = Vector2(-BANK_OVERLAP + (BANK_REACH + BANK_OVERLAP) * (1.0 - cos(prev_a)), 3.0 + (depth - 3.0) * sin(prev_a))
				left.append(prev.lerp(p, (top - prev.y) / maxf(p.y - prev.y, 0.001)))
			left.append(p)
	var pts: PackedVector2Array = left.duplicate()
	for i: int in range(left.size() - 1, -1, -1):
		pts.append(Vector2(w - left[i].x, left[i].y))
	if bottom > depth:
		pts.append(Vector2(w + BANK_OVERLAP, bottom))
		pts.append(Vector2(-BANK_OVERLAP, bottom))
	return pts


func _gradient(pts: PackedVector2Array, top: Color, bottom: Color, bottom_y: float) -> PackedColorArray:
	var cols: PackedColorArray = PackedColorArray()
	for p: Vector2 in pts:
		cols.append(top.lerp(bottom, clampf(p.y / bottom_y, 0.0, 1.0)))
	return cols


## The terrain strip that ends at the left bank, so the ground under the stream matches it.
func _bank_strip() -> TerrainStrip:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(TerrainStrip.GROUP):
		var strip: TerrainStrip = node as TerrainStrip
		if strip != null and strip.points.size() >= 2:
			var end: Vector2 = strip.to_global(strip.points[strip.points.size() - 1])
			if end.distance_to(global_position) < 40.0:
				return strip
	return null


func _add_bed_pebbles(w: float, rng: RandomNumberGenerator) -> void:
	var x: float = BANK_REACH * 0.6
	while x < w - BANK_REACH * 0.6:
		var r: float = rng.randf_range(3.0, 7.0)
		var col: Color = BED_PEBBLES[rng.randi() % BED_PEBBLES.size()]
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(x, depth - r * 0.45), Vector2(r * 1.4, r * 0.75), 10), col)
		x += rng.randf_range(9.0, 26.0)


func _add_stone(x: float, rng: RandomNumberGenerator) -> void:
	var stone: SteppingStone = SteppingStone.new()
	add_child(stone, false, Node.INTERNAL_MODE_BACK)
	var top: float = -STONE_RISE
	var bottom: float = depth + 4.0
	var centre: Vector2 = Vector2(x + stone_width * 0.5, (top + bottom) * 0.5)
	var radii: Vector2 = Vector2(stone_width * 0.5, (bottom - top) * 0.5)
	# A squarish boulder: flat enough on top to stand on, bulging and wider at the base.
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var segments: int = 22
	for i: int in segments:
		var a: float = TAU * float(i) / float(segments)
		var c: float = cos(a)
		var s: float = sin(a)
		var sx: float = signf(c) * pow(absf(c), 0.55) * radii.x * (1.0 + 0.16 * maxf(s, 0.0))
		var sy: float = signf(s) * pow(absf(s), 0.55) * radii.y
		var p: Vector2 = centre + Vector2(sx, sy)
		if s > -0.5:
			p.x += rng.randf_range(-1.6, 1.6)
		p.y = maxf(p.y, top)
		pts.append(p)
		var shade: float = clampf((p.y - top) / (bottom - top), 0.0, 1.0)
		cols.append(STONE_LIGHT.lerp(STONE, minf(shade * 3.0, 1.0)).lerp(STONE_DARK, maxf(shade - 0.35, 0.0) * 1.4 + maxf(c, 0.0) * 0.15))
	var body: Polygon2D = ShapeUtil.add_poly(stone, pts, STONE)
	body.vertex_colors = cols
	# Wet band just above the water, moss and a highlight on top.
	ShapeUtil.add_poly(stone, ShapeUtil.rounded_rect(Rect2(x + 1.0, WATER_DROP - 5.0, stone_width - 2.0, 5.0), 2.0), Color(STONE_DARK, 0.45))
	var moss_x: float = x + stone_width * rng.randf_range(0.28, 0.45)
	ShapeUtil.add_poly(stone, ShapeUtil.ellipse(Vector2(moss_x, top + 2.5), Vector2(stone_width * 0.3, 3.4), 12), MOSS)
	ShapeUtil.add_poly(stone, ShapeUtil.ellipse(Vector2(moss_x - 2.0, top + 1.6), Vector2(stone_width * 0.16, 1.5), 10), MOSS_LIGHT)
	ShapeUtil.add_poly(stone, ShapeUtil.ellipse(Vector2(x + stone_width * 0.72, top + 3.0), Vector2(stone_width * 0.12, 1.4), 8), Color(1, 1, 1, 0.35))
	ShapeUtil.add_rect_shape(stone, Rect2(x, top, stone_width, depth + STONE_RISE))
	stone.recentre(Vector2(x + stone_width * 0.5, top), stone_width * 0.5)
	stone.enable_wobble(wobble)


## Foam where the water parts around a stone (more on the downstream side).
func _add_foam(x: float, rng: RandomNumberGenerator) -> void:
	var y: float = WATER_DROP + 1.0
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(x - 2.0, y), Vector2(6.0, 1.8), 10), FOAM, 1)
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(x + stone_width + 4.0, y + 0.5), Vector2(10.0, 2.2), 12), FOAM, 1)
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(x + stone_width + 15.0 + rng.randf_range(0, 6), y + 2.0), Vector2(4.0, 1.2), 8), Color(FOAM, 0.5), 1)


## A clump of reeds on a bank; `side` -1 leans them left (left bank), +1 right.
func _add_reeds(x: float, side: float, rng: RandomNumberGenerator) -> void:
	# Reeds rock gently, lean in gusts and part for the hiker (sway shader).
	for i: int in 5:
		var bx: float = x + side * rng.randf_range(-4.0, 10.0)
		var h: float = rng.randf_range(16.0, 30.0)
		var lean: float = side * rng.randf_range(2.0, 9.0)
		var col: Color = REED if i % 2 == 0 else REED_LIGHT
		var phase: float = rng.randf() * TAU
		var blade: Polygon2D = ShapeUtil.add_poly(self, PackedVector2Array([Vector2(bx - 1.6, 4.0), Vector2(bx + 1.6, 4.0), Vector2(bx + lean, 4.0 - h)]), col)
		blade.uv = PackedVector2Array([Vector2(phase, 0.0), Vector2(phase, 0.0), Vector2(phase, 1.0)])
		TerrainStrip.apply_sway(blade, 8.0, 1.8, 6.0)
		if i == 1 or i == 3:
			var tip: Vector2 = Vector2(bx + lean * 0.8, 4.0 - h * 0.8)
			var head: Polygon2D = ShapeUtil.add_poly(self, ShapeUtil.ellipse(tip, Vector2(2.0, 4.5), 8), CATTAIL)
			var uvs: PackedVector2Array = PackedVector2Array()
			for p: Vector2 in head.polygon:
				uvs.append(Vector2(phase, clampf((4.0 - p.y) / h, 0.0, 1.0)))
			head.uv = uvs
			TerrainStrip.apply_sway(head, 8.0, 1.8, 6.0)


func _on_water_entered(body: Node2D) -> void:
	var hiker: Hiker = body as Hiker
	if hiker != null:
		hiker.condition.soak_feet()
		# Standing in the stream fills the bottle (at the price of wet feet).
		hiker.condition.enter_spring()
		_splash(to_local(hiker.global_position).x)
		AudioManager.play_splash()


func _on_water_exited(body: Node2D) -> void:
	var hiker: Hiker = body as Hiker
	if hiker != null:
		hiker.condition.exit_spring()


## Droplets thrown up where the hiker went in, and rings spreading on the surface.
func _splash(x: float) -> void:
	var drops: CPUParticles2D = CPUParticles2D.new()
	drops.position = Vector2(x, WATER_DROP)
	drops.z_index = 2
	drops.emitting = false
	drops.one_shot = true
	drops.explosiveness = 1.0
	drops.amount = SPLASH_DROPS
	drops.lifetime = 0.7
	drops.direction = Vector2.UP
	drops.spread = 55.0
	drops.initial_velocity_min = 90.0
	drops.initial_velocity_max = 190.0
	drops.gravity = Vector2(0, 700)
	drops.scale_amount_min = 1.6
	drops.scale_amount_max = 3.2
	drops.color = WATER_LIGHT
	add_child(drops)
	drops.emitting = true
	drops.finished.connect(drops.queue_free)
	for i: int in 2:
		var ring: Line2D = Line2D.new()
		var pts: PackedVector2Array = ShapeUtil.ellipse(Vector2.ZERO, Vector2(10, 2.2), 20)
		pts.append(pts[0])
		ring.points = pts
		ring.width = 1.4
		ring.default_color = Color(1, 1, 1, 0.75)
		ring.antialiased = true
		ring.position = Vector2(x, WATER_DROP + 1.0)
		ring.z_index = 2
		add_child(ring)
		var grow: Tween = ring.create_tween().set_parallel()
		grow.tween_property(ring, "scale", Vector2(3.4, 1.8), 0.9).set_delay(0.15 * float(i)).set_ease(Tween.EASE_OUT)
		grow.tween_property(ring, "modulate:a", 0.0, 0.9).set_delay(0.15 * float(i))
		grow.chain().tween_callback(ring.queue_free)
