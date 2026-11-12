@tool
class_name TerrainStrip
extends Line2D
## A stretch of walkable ground. It's a Line2D, so select it and drag, add or
## delete points right in the 2D editor: the fill, collision and path edge rebuild live.
## Points must run left to right.

enum Surface { DIRT, ROCK, MUD, ICE, SNOW }
## New kinds go at the END (scenes store the number).
enum TreeKind { NONE, PINE, BIRCH, MIXED, PALM, TEA }

const GROUP: StringName = &"terrain_strip"
const SWAY_SHADER: Shader = preload("res://world/fx/sway.gdshader")
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

@export_group("Trail-side trees")
## Big trees standing just behind this stretch of path (none, pines, birches or mixed).
@export var side_trees: TreeKind = TreeKind.NONE:
	set(value):
		side_trees = value
		_rebuild()
## Gap between trees (random between x and y, px).
@export var side_tree_spacing: Vector2 = Vector2(280, 640):
	set(value):
		side_tree_spacing = value
		_rebuild()
@export var side_tree_height: Vector2 = Vector2(150, 270):
	set(value):
		side_tree_height = value
		_rebuild()
@export var side_tree_color: Color = Color("#2F5A43"):
	set(value):
		side_tree_color = value
		_rebuild()
## Birch crowns (BIRCH / MIXED).
@export var side_tree_color_alt: Color = Color("#D9A441"):
	set(value):
		side_tree_color_alt = value
		_rebuild()
@export var side_tree_snow: bool = false:
	set(value):
		side_tree_snow = value
		_rebuild()

## How much darker the rim under the path edge is.
const RIM_DARKEN: float = 0.3

var _side_trees: Polygon2D
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
	# Again once the whole level is in: viewpoints and landmarks that keep trees away
	# may come later in the scene than this strip.
	_build_side_trees.call_deferred()
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
	# Trail-side trees come first so they draw behind the ground fill and the path.
	_side_trees = Polygon2D.new()
	_side_trees.name = "SideTrees"
	_side_trees.antialiased = true
	_side_trees.show_behind_parent = true
	apply_sway(_side_trees, 0.0, 1.2, 9.0)
	add_child(_side_trees, false, Node.INTERNAL_MODE_FRONT)
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
	# Grass tufts sway, lean in gusts and bend away from the hiker's boots.
	apply_sway(_decor, 9.0, 1.4, 5.0)
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
	_build_side_trees()
	_built_points = points.duplicate()


func _build_decor() -> void:
	var batch: TreeArt.Batch = TerrainDecor.build(self)
	_decor.polygon = batch.pts
	_decor.vertex_colors = batch.cols
	_decor.uv = batch.uvs
	_decor.polygons = batch.polys


## Godot only passes a Polygon2D's UVs (the sway data) when it has a texture, so swaying
## shapes get this 1x1 white one; it leaves their colours unchanged.
static var _white: ImageTexture


## Makes `poly` sway: grass and reeds brush aside (brush px), trees don't (brush 0).
static func apply_sway(poly: Polygon2D, brush: float, sway: float, gust: float) -> void:
	if _white == null:
		var img: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	poly.texture = _white
	poly.material = sway_material(brush, sway, gust)


static func sway_material(brush: float, sway: float, gust: float) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = SWAY_SHADER
	mat.set_shader_parameter("brush_px", brush)
	mat.set_shader_parameter("sway_px", sway)
	mat.set_shader_parameter("gust_px", gust)
	return mat


func _build_side_trees() -> void:
	var batch: TreeArt.Batch = TreeArt.Batch.new()
	if side_trees != TreeKind.NONE and points.size() >= 2:
		batch = TreeArt.along(edge_y_at, points[0].x, points[points.size() - 1].x, side_trees, side_tree_spacing,
			side_tree_height, side_tree_color, side_tree_color_alt, side_tree_snow, decor_seed * 31 + 7,
			TerrainDecor.clear_spans(self))
	_side_trees.polygon = batch.pts
	_side_trees.vertex_colors = batch.cols
	_side_trees.uv = batch.uvs
	_side_trees.polygons = batch.polys


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
