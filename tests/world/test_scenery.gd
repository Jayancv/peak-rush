extends GutTest
## The visual pass: layered soil under the path, contact shadows, shaded mountain faces
## and the foreground layer. Art, but with rules worth keeping (layers meet between
## strips, shadows sit on the ground, the foreground steps aside when the camera zooms).


func _strip(pts: PackedVector2Array) -> TerrainStrip:
	var strip: TerrainStrip = TerrainStrip.new()
	strip.points = pts
	add_child_autofree(strip)
	return strip


func test_the_ground_under_the_path_is_layered() -> void:
	var strip: TerrainStrip = _strip(PackedVector2Array([Vector2(0, 0), Vector2(300, -60), Vector2(600, 20)]))
	var strata: Polygon2D = strip.get_node_or_null("Strata") as Polygon2D
	assert_not_null(strata)
	# A band and its darker seam line per layer.
	assert_eq(strata.polygons.size(), TerrainDecor.BANDS.size() * 2)
	for p: Vector2 in strata.polygon:
		assert_true(p.y >= strip.edge_y_at(p.x) + 11.9, "no layer pokes up through the path at %s" % p)
	assert_eq(TerrainDecor.soil_color(strip, 0.0), strip.fill_color, "the top is the plain ground colour")
	assert_true(TerrainDecor.soil_color(strip, 1000.0).get_luminance() < strip.fill_color.get_luminance(), "deeper is darker")


func test_the_layers_of_neighbouring_strips_meet() -> void:
	var a: TerrainStrip = _strip(PackedVector2Array([Vector2(0, 0), Vector2(200, -40)]))
	var b: TerrainStrip = _strip(PackedVector2Array([Vector2(200, -40), Vector2(400, 30)]))
	var pa: Polygon2D = a.get_node("Strata") as Polygon2D
	var pb: Polygon2D = b.get_node("Strata") as Polygon2D
	for band: int in TerrainDecor.BANDS.size():
		var ia: PackedInt32Array = pa.polygons[band * 2]
		var ib: PackedInt32Array = pb.polygons[band * 2]
		# A's top edge ends at x = 200 three points before its bottom corners; B's starts there.
		var end_a: Vector2 = pa.polygon[ia[ia.size() - 3]]
		var start_b: Vector2 = pb.polygon[ib[0]]
		assert_almost_eq(end_a.x, 200.0, 0.01)
		assert_almost_eq(start_b.x, 200.0, 0.01)
		assert_almost_eq(end_a.y, start_b.y, 0.5, "layer %d lines up across the join" % band)


func test_the_hiker_casts_a_shadow_on_the_ground() -> void:
	_strip(PackedVector2Array([Vector2(-400, 0), Vector2(400, 0)]))
	var hiker: Hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate())
	hiker.teleport(Vector2(0, -30))
	await wait_physics_frames(3)
	var shadow: ContactShadow = hiker.get_node("Shadow") as ContactShadow
	assert_true(shadow.visible)
	assert_almost_eq(shadow.global_position.y, 0.0, 1.0, "on the ground, not at the boots")


func test_no_ground_no_shadow() -> void:
	var hiker: Hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate())
	hiker.teleport(Vector2(0, -5000))
	await wait_physics_frames(2)
	assert_false((hiker.get_node("Shadow") as ContactShadow).visible)


func test_rocks_sit_on_a_shadow() -> void:
	var rock: TrailRock = TrailRock.new()
	add_child_autofree(rock)
	var found: bool = false
	for i: int in rock.get_child_count(true):
		found = found or rock.get_child(i, true) is ContactShadow
	assert_true(found)


func test_mountains_have_a_shadow_side() -> void:
	var peaks: RidgeLayer = RidgeLayer.new()
	peaks.ridged = true
	add_child_autofree(peaks)
	assert_gt((peaks.get_node("Shade") as Polygon2D).polygons.size(), 0)
	var hills: RidgeLayer = RidgeLayer.new()
	add_child_autofree(hills)
	assert_eq((hills.get_node("Shade") as Polygon2D).polygons.size(), 0, "rolling hills stay unshaded")


func test_trails_get_a_foreground_and_menus_do_not() -> void:
	GameState.current_trail_id = &"t01_forest_lake"
	var runner: Node = add_child_autofree((load(SceneRouter.TRAIL_RUNNER) as PackedScene).instantiate())
	await wait_process_frames(2)
	var fg: Node = runner.find_child("Foreground", true, false)
	assert_true(fg is ForegroundLayer)
	assert_gt((fg as ForegroundLayer).z_index, 2, "in front of everything in the level")
	runner.queue_free()
	await wait_process_frames(1)
	var menu: Node = add_child_autofree((load(SceneRouter.MAIN_MENU) as PackedScene).instantiate())
	await wait_process_frames(2)
	assert_null(menu.find_child("Foreground", true, false), "the hut has a strip too, but no grass indoors")
	assert_null(ForegroundLayer.create([], 1), "no ground, no foreground")


func test_the_foreground_steps_aside_when_the_camera_zooms() -> void:
	var fg: ForegroundLayer = ForegroundLayer.create([_strip(PackedVector2Array([Vector2(0, 0), Vector2(500, 0)]))], 3)
	add_child_autofree(fg)
	var cam: Camera2D = Camera2D.new()
	# Physics interpolation is on: a camera left in idle mode warns (an "unexpected error").
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child_autofree(cam)
	cam.make_current()
	cam.zoom = Vector2(0.7, 0.7)
	fg._process(1.0)
	assert_false(fg.visible, "the summit pull-back would leave it floating mid-screen")
	cam.zoom = Vector2.ONE
	fg._process(1.0)
	assert_true(fg.visible)
