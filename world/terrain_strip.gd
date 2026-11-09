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
@export var fill_color: Color = Color("#3B5B4A"):
	set(value):
		fill_color = value
		if _fill != null:
			_fill.color = fill_color
## How far below the lowest point the ground fill and collision reach.
@export var fill_depth: float = 800.0:
	set(value):
		fill_depth = value
		_rebuild()

var _fill: Polygon2D
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
	_fill.color = fill_color
	# Fill draws behind the edge line so the path stays on top.
	_fill.show_behind_parent = true
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	_shape = CollisionPolygon2D.new()
	_shape.name = "Shape"
	body.add_child(_shape)
	# Internal children aren't saved into the scene file, so they're always regenerated.
	add_child(_fill, false, Node.INTERNAL_MODE_FRONT)
	add_child(body, false, Node.INTERNAL_MODE_FRONT)


func _rebuild() -> void:
	if _fill == null:
		return
	var poly: PackedVector2Array = _solid_polygon()
	_fill.polygon = poly
	_shape.polygon = poly
	_built_points = points.duplicate()


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
