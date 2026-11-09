extends GutTest


func _make_strip(pts: PackedVector2Array) -> TerrainStrip:
	var strip: TerrainStrip = TerrainStrip.new()
	strip.points = pts
	strip.fill_depth = 100.0
	add_child_autofree(strip)
	return strip


func _internal_child(strip: TerrainStrip, type_name: String) -> Node:
	for i: int in strip.get_child_count(true):
		var child: Node = strip.get_child(i, true)
		if child.is_class(type_name):
			return child
	return null


func test_builds_fill_closed_below_lowest_point() -> void:
	var strip: TerrainStrip = _make_strip(PackedVector2Array([Vector2(0, 10), Vector2(100, 50), Vector2(200, 0)]))
	var fill: Polygon2D = _internal_child(strip, "Polygon2D") as Polygon2D
	assert_not_null(fill)
	assert_eq(fill.polygon.size(), 5)
	assert_eq(fill.polygon[3], Vector2(200, 150), "bottom-right corner sits fill_depth below the lowest point")
	assert_eq(fill.polygon[4], Vector2(0, 150))


func test_builds_collision_matching_fill() -> void:
	var strip: TerrainStrip = _make_strip(PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]))
	var body: StaticBody2D = _internal_child(strip, "StaticBody2D") as StaticBody2D
	assert_not_null(body)
	var shape: CollisionPolygon2D = body.get_child(0) as CollisionPolygon2D
	assert_eq(shape.polygon.size(), 4)
	assert_eq(body.collision_layer, 1)


func test_generated_children_are_not_saved_into_scenes() -> void:
	var strip: TerrainStrip = _make_strip(PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]))
	assert_eq(strip.get_child_count(false), 0, "fill/body must be internal children")


func test_surface_sets_edge_colour() -> void:
	var strip: TerrainStrip = _make_strip(PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]))
	strip.surface = TerrainStrip.Surface.ICE
	assert_eq(strip.default_color, TerrainStrip.SURFACE_COLORS[TerrainStrip.Surface.ICE])


func test_surface_of_collider() -> void:
	var strip: TerrainStrip = _make_strip(PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]))
	strip.surface = TerrainStrip.Surface.MUD
	var body: Node = _internal_child(strip, "StaticBody2D")
	assert_eq(TerrainStrip.surface_of(body), TerrainStrip.Surface.MUD)
	assert_eq(TerrainStrip.surface_of(null), TerrainStrip.Surface.DIRT)


func test_bounds_cover_all_strips() -> void:
	var root: Node2D = add_child_autofree(Node2D.new())
	for pts: PackedVector2Array in [
		PackedVector2Array([Vector2(-50, 0), Vector2(100, 20)]),
		PackedVector2Array([Vector2(100, 20), Vector2(400, -80)]),
	]:
		var strip: TerrainStrip = TerrainStrip.new()
		strip.points = pts
		strip.fill_depth = 100.0
		root.add_child(strip)
	var bounds: Rect2 = TerrainStrip.bounds_under(root)
	assert_eq(bounds.position.x, -50.0)
	assert_eq(bounds.end.x, 400.0)
	assert_eq(bounds.position.y, -80.0)
	assert_eq(bounds.end.y, 120.0)


func test_warns_when_points_go_backwards() -> void:
	var strip: TerrainStrip = _make_strip(PackedVector2Array([Vector2(0, 0), Vector2(-10, 0)]))
	assert_eq(strip._get_configuration_warnings().size(), 1)
