extends GutTest
## Drives a real hiker on real physics over a flat strip.

var hiker: Hiker


func before_each() -> void:
	var ground: TerrainStrip = TerrainStrip.new()
	ground.points = PackedVector2Array([Vector2(-2000, 0), Vector2(4000, 0)])
	add_child_autofree(ground)
	var scene: PackedScene = load("res://actors/hiker/hiker.tscn") as PackedScene
	hiker = add_child_autofree(scene.instantiate()) as Hiker
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(10)


func after_each() -> void:
	Input.action_release(&"walk")
	Input.action_release(&"jump")


func test_settles_on_ground_idle() -> void:
	assert_true(hiker.is_on_floor())
	assert_eq(hiker.state, Hiker.State.IDLE)


func test_holding_walk_moves_right() -> void:
	var start_x: float = hiker.global_position.x
	Input.action_press(&"walk")
	await wait_physics_frames(30)
	assert_eq(hiker.state, Hiker.State.WALK)
	assert_gt(hiker.global_position.x, start_x + 20.0)
	assert_lt(hiker.velocity.x, hiker.balance.walk_speed + 0.01, "never faster than walk speed on flat ground")


func test_letting_go_stops_then_rests() -> void:
	Input.action_press(&"walk")
	await wait_physics_frames(10)
	Input.action_release(&"walk")
	await wait_physics_frames(3)
	assert_eq(hiker.state, Hiker.State.IDLE)
	await wait_seconds(hiker.balance.rest_delay_seconds + 0.2)
	assert_eq(hiker.state, Hiker.State.REST)


func test_jump_leaves_the_ground_and_lands() -> void:
	watch_signals(hiker)
	Input.action_press(&"jump")
	await wait_physics_frames(3)
	Input.action_release(&"jump")
	assert_eq(hiker.state, Hiker.State.JUMP)
	assert_lt(hiker.velocity.y, 0.0)
	assert_signal_emitted(hiker, "jumped")
	await wait_seconds(1.2)
	assert_true(hiker.is_on_floor())
	assert_signal_emitted(hiker, "landed")
	assert_true(hiker.state == Hiker.State.IDLE or hiker.state == Hiker.State.REST)


func test_stumble_stops_the_hiker_briefly() -> void:
	watch_signals(hiker)
	Input.action_press(&"walk")
	await wait_physics_frames(20)
	assert_true(hiker.stumble())
	assert_eq(hiker.state, Hiker.State.STUMBLE)
	assert_signal_emitted(hiker, "stumbled")
	await wait_seconds(hiker.balance.stumble_seconds + 0.1)
	assert_ne(hiker.state, Hiker.State.STUMBLE)


func test_cannot_stumble_in_the_air() -> void:
	Input.action_press(&"jump")
	await wait_physics_frames(3)
	assert_false(hiker.stumble())


func test_exhausted_forces_rest_even_while_walk_held() -> void:
	Input.action_press(&"walk")
	await wait_physics_frames(5)
	hiker.exhaust()
	await wait_seconds(hiker.balance.exhausted_rest_seconds * 0.5)
	assert_eq(hiker.state, Hiker.State.EXHAUSTED)
	assert_almost_eq(hiker.velocity.x, 0.0, 1.0)
	await wait_seconds(hiker.balance.exhausted_rest_seconds * 0.5 + 0.2)
	assert_ne(hiker.state, Hiker.State.EXHAUSTED)


func test_photo_holds_until_exit() -> void:
	assert_true(hiker.enter_photo())
	Input.action_press(&"walk")
	await wait_physics_frames(20)
	assert_eq(hiker.state, Hiker.State.PHOTO)
	hiker.exit_photo()
	await wait_physics_frames(2)
	assert_ne(hiker.state, Hiker.State.PHOTO)


func test_walks_slower_uphill() -> void:
	var ramp: TerrainStrip = TerrainStrip.new()
	# Rises 0.5 per px to the right (grade 0.5) from x=100.
	ramp.points = PackedVector2Array([Vector2(-200, -1000), Vector2(100, -1000), Vector2(1100, -1500)])
	add_child_autofree(ramp)
	hiker.teleport(Vector2(0, -1004))
	Input.action_press(&"walk")
	await wait_physics_frames(90)
	assert_almost_eq(hiker.signed_grade, 0.5, 0.05)
	# Measure distance actually covered along the slope over exactly 0.5 s of physics.
	var before: Vector2 = hiker.global_position
	await wait_physics_frames(30)
	var speed: float = (hiker.global_position - before).length() / 0.5
	var expected: float = hiker.balance.walk_speed * 0.75
	assert_almost_eq(speed, expected, 8.0, "uphill speed = walk × (1 − 0.5 × 0.5)")
