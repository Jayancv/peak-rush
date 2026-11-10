extends GutTest
## Walking back towards the last checkpoint (the walk_back action).

var hiker: Hiker


func before_each() -> void:
	var ground: TerrainStrip = TerrainStrip.new()
	ground.points = PackedVector2Array([Vector2(-2000, 0), Vector2(2000, 0)])
	ground.decorate = false
	add_child_autofree(ground)
	hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(8)


func after_each() -> void:
	Input.action_release(&"walk")
	Input.action_release(&"walk_back")


func test_walks_back_and_turns_around() -> void:
	hiker.back_limit_x = -1000.0
	Input.action_press(&"walk_back")
	await wait_physics_frames(40)
	assert_eq(hiker.facing, -1.0)
	assert_lt(hiker.global_position.x, -20.0)
	assert_lt(hiker.velocity.x, 0.0)


func test_stops_at_the_last_checkpoint_and_says_so() -> void:
	hiker.back_limit_x = -60.0
	watch_signals(hiker)
	Input.action_press(&"walk_back")
	await wait_physics_frames(120)
	assert_gt(hiker.global_position.x, -60.0 - 2.0, "never past the limit")
	assert_lt(hiker.global_position.x, -30.0, "but it did walk back to it")
	assert_signal_emitted(hiker, "back_blocked")


func test_forward_wins_when_both_are_held() -> void:
	hiker.back_limit_x = -1000.0
	Input.action_press(&"walk_back")
	Input.action_press(&"walk")
	await wait_physics_frames(30)
	assert_eq(hiker.facing, 1.0)
	assert_gt(hiker.global_position.x, 10.0)
