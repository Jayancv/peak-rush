extends GutTest

var hiker: Hiker
var vp: Viewpoint


func before_each() -> void:
	var ground: TerrainStrip = TerrainStrip.new()
	ground.points = PackedVector2Array([Vector2(-1000, 0), Vector2(3000, 0)])
	add_child_autofree(ground)
	vp = (load("res://world/interactables/viewpoint.tscn") as PackedScene).instantiate() as Viewpoint
	vp.viewpoint_id = &"test_view"
	vp.position = Vector2(140, 0)
	add_child_autofree(vp)
	hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(4)


func after_each() -> void:
	Input.action_release(&"walk")


func test_walking_in_and_out_reports_to_listeners() -> void:
	watch_signals(vp)
	Input.action_press(&"walk")
	await wait_physics_frames(50)
	assert_signal_emitted(vp, "hiker_entered")
	await wait_physics_frames(90)
	assert_signal_emitted(vp, "hiker_left")


func test_subject_moves_along_its_path() -> void:
	var start: Vector2 = vp.subject().position
	await wait_seconds(0.5)
	assert_ne(vp.subject().position, start)


func test_frame_centre_uses_offset() -> void:
	vp.frame_offset = Vector2(200, -150)
	assert_eq(vp.frame_center(), vp.global_position + Vector2(200, -150))


func test_is_found_by_the_validator() -> void:
	# The validator reads `viewpoint_id` off scene nodes.
	assert_eq(vp.get("viewpoint_id"), &"test_view")
