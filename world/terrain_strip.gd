@tool
class_name TerrainStrip
extends Line2D
## A stretch of walkable ground. It's a Line2D, so select it and drag, add or
## delete points right in the 2D editor: the fill, collision and path edge rebuild live.
## Points must run left to right.

enum Surface { DIRT, ROCK, MUD, ICE, SNOW }

const GROUP: StringName = &"terrain_strip"
const EDGE_WIDTH: float = 14.0
## Placeholder path-edge colours per surface (dirt is the palette's path colour).
const SURFACE_COLORS: Array[Color] = [
	Color("#C9B28F"),  # DIRT
	Color("#9C9A90"),  # ROCK
	Color("#6E5440"),  # MUD
	Color("#CDEBF5"),  # ICE
	Color("#F4F7FA"),  # SNOW
]

@export var surface: Surface = Surface.DIRT:
	set(value):
		surface = value
		default_color = SURFACE_COLORS[surface]
		_rebuild()
## Ground colour just under the path; it darkens towards fill_bottom_color with depth.
@export var fill_color: Color = Color("#4A7359"):
	set(value):
		fill_color = value
		_rebuild()
@export var fill_bottom_color: Color = Color("#22372C"):
	set(value):
		fill_bottom_color = value
		_rebuild()
## Colour of the grass tufts (golden for autumn trails).
@export var tuft_color: Color = Color("#6F9C5F"):
	set(value):
		tuft_color = value
		_rebuild()
## Grass tufts along the path and pebbles in the ground (placeholder art).
@export var decorate: bool = true:
	set(value):
		decorate = value
		_rebuild()
@export var decor_seed: int = 1:
	set(value):
		decor_seed = value
		_rebuild()
## How far below the lowest point the ground fill and collision reach.
@export var fill_depth: float = 800.0:
	set(value):
		fill_depth = value
		_rebuild()

const PEBBLE_COLOR: Color = Color("#6C8E73")
const BOULDER_COLOR: Color = Color("#8C8B84")
const BOULDER_SHADE: Color = Color("#6F6E68")
## How much darker the rim under the path edge is.
const RIM_DARKEN: float = 0.3

var _fill: Polygon2D
var _rim: Line2D
var _decor: Polygon2D
var _shape: CollisionPolygon2D
var _built_points: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	# Defaults for strips added from the "Add Node" dialog; saved scene values override these.
	width = EDGE_WIDTH
	default_color = SURFACE_COLORS[surface]
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND


func _ready() -> void:
	add_to_group(GROUP)
	_build_children()
	_rebuild()
	# Only the editor needs to watch for point edits; at runtime the ground never changes.
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if points != _built_points:
		_rebuild()
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if points.size() < 2:
		warnings.append("Add at least 2 points.")
	for i: int in range(1, points.size()):
		if points[i].x <= points[i - 1].x:
			warnings.append("Points must run left to right (point %d is not right of point %d)." % [i, i - 1])
			break
	return warnings


## Which surface the hiker is standing on, given the collider from a slide collision.
static func surface_of(collider: Object) -> Surface:
	var body: Node = collider as Node
	if body != null:
		var strip: TerrainStrip = body.get_parent() as TerrainStrip
		if strip != null:
			return strip.surface
	return Surface.DIRT


## World-space rectangle covering every strip under `root` (camera limits come from this).
static func bounds_under(root: Node) -> Rect2:
	var bounds: Rect2 = Rect2()
	var found: bool = false
	for node: Node in root.get_tree().get_nodes_in_group(GROUP):
		var strip: TerrainStrip = node as TerrainStrip
		if strip == null or not (root == strip or root.is_ancestor_of(strip)):
			continue
		var r: Rect2 = strip.get_global_bounds()
		bounds = r if not found else bounds.merge(r)
		found = true
	return bounds


func get_global_bounds() -> Rect2:
	var poly: PackedVector2Array = _solid_polygon()
	if poly.is_empty():
		return Rect2(global_position, Vector2.ZERO)
	var r: Rect2 = Rect2(global_transform * poly[0], Vector2.ZERO)
	for p: Vector2 in poly:
		r = r.expand(global_transform * p)
	return r


func _build_children() -> void:
	if _fill != null:
		return
	_fill = Polygon2D.new()
	_fill.name = "Fill"
	_fill.antialiased = true
	# Fill, rim and decor all draw behind the edge line so the path stays on top.
	_fill.show_behind_parent = true
	_rim = Line2D.new()
	_rim.name = "Rim"
	_rim.show_behind_parent = true
	_rim.joint_mode = Line2D.LINE_JOINT_ROUND
	_decor = Polygon2D.new()
	_decor.name = "Decor"
	_decor.show_behind_parent = true
	_decor.antialiased = true
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	_shape = CollisionPolygon2D.new()
	_shape.name = "Shape"
	body.add_child(_shape)
	# Internal children aren't saved into the scene file, so they're always regenerated.
	add_child(_fill, false, Node.INTERNAL_MODE_FRONT)
	add_child(_rim, false, Node.INTERNAL_MODE_FRONT)
	add_child(_decor, false, Node.INTERNAL_MODE_FRONT)
	add_child(body, false, Node.INTERNAL_MODE_FRONT)


func _rebuild() -> void:
	if _fill == null:
		return
	var poly: PackedVector2Array = _solid_polygon()
	_fill.polygon = poly
	# Top points get the light colour, the two bottom corners the dark one.
	var cols: PackedColorArray = PackedColorArray()
	for i: int in poly.size():
		cols.append(fill_bottom_color if i >= points.size() else fill_color)
	_fill.vertex_colors = cols
	_shape.polygon = poly
	var rim_points: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		rim_points.append(p + Vector2(0.0, width * 0.55))
	_rim.points = rim_points
	_rim.width = width * 0.6
	_rim.default_color = default_color.darkened(RIM_DARKEN)
	_build_decor()
	_built_points = points.duplicate()


func _build_decor() -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	var polys: Array = []
	if decorate and points.size() >= 2:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = decor_seed
		var start_x: float = points[0].x
		var end_x: float = points[points.size() - 1].x
		var grassy: bool = surface == Surface.DIRT or surface == Surface.MUD
		var x: float = start_x + rng.randf_range(10.0, 60.0)
		while grassy and x < end_x - 10.0:
			var y: float = edge_y_at(x)
			# Three blades leaning slightly, poking up just behind the path.
			for b: int in 3:
				var bx: float = x + (b - 1) * 4.0
				var h: float = rng.randf_range(9.0, 17.0) * (1.25 if b == 1 else 0.8)
				_add_tri(Vector2(bx - 2.2, y), Vector2(bx + 2.2, y), Vector2(bx + (b - 1) * 3.0, y - h), tuft_color, pts, cols, polys)
			x += rng.randf_range(28.0, 95.0)
		x = start_x + rng.randf_range(20.0, 60.0)
		while surface == Surface.ROCK and x < end_x - 10.0:
			# Grey boulders half-buried along a rocky path.
			var r: float = rng.randf_range(10.0, 20.0)
			_add_lump(Vector2(x, edge_y_at(x) + r * 0.15), r * rng.randf_range(1.1, 1.5), r, BOULDER_SHADE, pts, cols, polys)
			_add_lump(Vector2(x - r * 0.15, edge_y_at(x) + r * 0.05), r * 0.95, r * 0.8, BOULDER_COLOR, pts, cols, polys)
			x += rng.randf_range(40.0, 120.0)
		x = start_x + rng.randf_range(20.0, 80.0)
		while x < end_x - 10.0:
			var center: Vector2 = Vector2(x, edge_y_at(x) + rng.randf_range(26.0, 140.0))
			var r: float = rng.randf_range(2.0, 4.5)
			var start: int = pts.size()
			var ring: PackedInt32Array = PackedInt32Array()
			for i: int in 8:
				var a: float = TAU * float(i) / 8.0
				ring.append(start + i)
				pts.append(center + Vector2(cos(a) * r * 1.4, sin(a) * r))
				cols.append(PEBBLE_COLOR)
			polys.append(ring)
			x += rng.randf_range(90.0, 220.0)
	_decor.polygon = pts
	_decor.vertex_colors = cols
	_decor.polygons = polys


## Upper half of an ellipse, flat side down.
func _add_lump(center: Vector2, rx: float, ry: float, col: Color, pts: PackedVector2Array, cols: PackedColorArray, polys: Array) -> void:
	var ring: PackedInt32Array = PackedInt32Array()
	for i: int in 9:
		var a: float = PI + PI * float(i) / 8.0
		ring.append(pts.size())
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		cols.append(col)
	polys.append(ring)


func _add_tri(a: Vector2, b: Vector2, c: Vector2, col: Color, pts: PackedVector2Array, cols: PackedColorArray, polys: Array) -> void:
	var start: int = pts.size()
	pts.append_array(PackedVector2Array([a, b, c]))
	cols.append_array(PackedColorArray([col, col, col]))
	polys.append(PackedInt32Array([start, start + 1, start + 2]))


## Height of the path edge at a given local x (points are left to right).
func edge_y_at(x: float) -> float:
	for i: int in range(1, points.size()):
		if x <= points[i].x:
			var a: Vector2 = points[i - 1]
			var b: Vector2 = points[i]
			return lerpf(a.y, b.y, (x - a.x) / maxf(b.x - a.x, 0.001))
	return points[points.size() - 1].y


## The ground points closed off downwards into a solid shape.
func _solid_polygon() -> PackedVector2Array:
	if points.size() < 2:
		return PackedVector2Array()
	var bottom: float = points[0].y
	for p: Vector2 in points:
		bottom = maxf(bottom, p.y)
	bottom += fill_depth
	var poly: PackedVector2Array = points.duplicate()
	poly.append(Vector2(points[points.size() - 1].x, bottom))
	poly.append(Vector2(points[0].x, bottom))
	return poly
