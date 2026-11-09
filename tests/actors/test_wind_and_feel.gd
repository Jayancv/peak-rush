extends GutTest
## Wind on the hiker, and the camera shake.

var hiker: Hiker


func before_each() -> void:
	var ground: TerrainStrip = TerrainStrip.new()
	ground.points = PackedVector2Array([Vector2(-3000, 0), Vector2(3000, 0)])
	add_child_autofree(ground)
	hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(6)


func after_each() -> void:
	Input.action_release(&"walk")


func test_headwind_slows_walking() -> void:
	hiker.condition.wind_push = -60.0
	Input.action_press(&"walk")
	await wait_physics_frames(60)
	assert_almost_eq(hiker.velocity.x, hiker.balance.walk_speed - 60.0, 3.0)


func test_standing_still_braces_against_wind() -> void:
	hiker.condition.wind_push = -90.0
	var x: float = hiker.global_position.x
	await wait_physics_frames(60)
	assert_almost_eq(hiker.global_position.x, x, 1.0, "a resting hiker isn't blown along")


func test_strong_gust_pushes_back_while_walking() -> void:
	hiker.condition.wind_push = -200.0
	var x: float = hiker.global_position.x
	Input.action_press(&"walk")
	await wait_physics_frames(60)
	assert_lt(hiker.global_position.x, x, "a gust stronger than walking speed pushes the hiker back")


func test_camera_shake_decays_back_to_the_view() -> void:
	var cam: HikerCamera = HikerCamera.new()
	# Physics interpolation needs the physics process mode before entering the tree.
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.target = hiker
	add_child_autofree(cam)
	cam.snap_to_target()
	var base: Vector2 = cam.offset
	cam.shake(10.0)
	await wait_physics_frames(3)
	assert_true(cam.is_shaking())
	await wait_seconds(ContentDB.balance.shake_seconds + 0.1)
	assert_false(cam.is_shaking())
	assert_almost_eq(cam.offset.y, base.y, 0.01, "no leftover shake")
