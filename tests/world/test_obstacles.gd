extends GutTest
## Real physics: a hiker walking a flat strip into each obstacle.

var hiker: Hiker


func before_each() -> void:
	var ground: TerrainStrip = TerrainStrip.new()
	ground.points = PackedVector2Array([Vector2(-1000, 0), Vector2(3000, 0)])
	add_child_autofree(ground)
	hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(6)


func after_each() -> void:
	Input.action_release(&"walk")
	Input.action_release(&"jump")


func _place(path: String, pos: Vector2) -> Node2D:
	var node: Node2D = (load(path) as PackedScene).instantiate() as Node2D
	node.position = pos
	add_child_autofree(node)
	return node


func _walk_for(frames: int) -> void:
	Input.action_press(&"walk")
	await wait_physics_frames(frames)


func test_walking_into_a_root_stumbles_and_costs_stamina() -> void:
	_place("res://world/obstacles/root.tscn", Vector2(80, 0))
	watch_signals(hiker)
	await _walk_for(60)
	assert_signal_emitted(hiker, "stumbled")
	assert_lt(hiker.condition.stamina.value, 100.0 - hiker.balance.stumble_cost + 1.0)


func test_jumping_over_a_root_does_not_stumble() -> void:
	_place("res://world/obstacles/root.tscn", Vector2(110, 0))
	watch_signals(hiker)
	Input.action_press(&"walk")
	await wait_physics_frames(24)
	Input.action_press(&"jump")
	await wait_physics_frames(50)
	assert_signal_not_emitted(hiker, "stumbled")
	assert_gt(hiker.global_position.x, 140.0)


func test_rock_blocks_until_jumped() -> void:
	_place("res://world/obstacles/rock.tscn", Vector2(120, 0))
	await _walk_for(90)
	assert_lt(hiker.global_position.x, 90.0, "the boulder stops a walking hiker")
	Input.action_press(&"jump")
	await wait_physics_frames(70)
	assert_gt(hiker.global_position.x, 160.0, "a jump clears it")


func test_mud_slows_walking() -> void:
	var patch: Node2D = _place("res://world/obstacles/mud_patch.tscn", Vector2(0, 0))
	patch.set("width", 1200.0)
	await _walk_for(60)
	assert_eq(hiker.effective_surface(), TerrainStrip.Surface.MUD)
	assert_almost_eq(hiker.velocity.x, hiker.balance.walk_speed * 0.6, 3.0)


func test_bench_doubles_regen() -> void:
	_place("res://world/interactables/bench.tscn", Vector2(0, 0))
	await wait_physics_frames(2)
	hiker.condition.stamina.spend(60.0)
	await wait_physics_frames(60)
	# ~1 s at the bench: +30 (vs +15 standing anywhere else).
	assert_gt(hiker.condition.stamina.value, 40.0 + 24.0)


func test_kill_zone_reports_fall() -> void:
	_place("res://world/obstacles/kill_zone.tscn", Vector2(150, -40))
	watch_signals(hiker)
	await _walk_for(90)
	assert_signal_emitted(hiker, "fell")


func test_checkpoint_reports_respawn_point_once() -> void:
	_place("res://world/interactables/checkpoint.tscn", Vector2(60, 0))
	watch_signals(hiker)
	await _walk_for(60)
	assert_signal_emit_count(hiker, "checkpoint_reached", 1)
	var params: Array = get_signal_parameters(hiker, "checkpoint_reached")
	assert_almost_eq((params[0] as Vector2).x, 60.0, 0.01)


func test_finish_ends_the_hike_and_stops_input() -> void:
	_place("res://world/interactables/finish.tscn", Vector2(70, 0))
	watch_signals(hiker)
	await _walk_for(60)
	assert_signal_emitted(hiker, "reached_finish")
	assert_true(hiker.finished)
	assert_false(hiker.wants_walk())


func test_missing_a_stepping_stone_gives_wet_feet() -> void:
	# The flat strip ends at x = 3000; the stream starts there. Walking (not jumping)
	# off the bank drops the hiker into the water.
	hiker.teleport(Vector2(2950, -4))
	_place("res://world/obstacles/stepping_stones.tscn", Vector2(3000, 0))
	await wait_physics_frames(4)
	await _walk_for(80)
	assert_true(hiker.condition.has_wet_feet())


func test_respawn_costs_fall_stamina() -> void:
	hiker.respawn(Vector2(0, -10))
	assert_almost_eq(hiker.condition.stamina.value, 100.0 - hiker.balance.fall_cost, 0.01)


func test_regen_mode_reports_rest_and_bench() -> void:
	watch_signals(hiker)
	hiker.condition.stamina.spend(50.0)
	await wait_physics_frames(4)
	assert_eq(hiker.condition.regen, HikerCondition.Regen.REST, "standing still = resting")
	_place("res://world/interactables/bench.tscn", Vector2(0, 0))
	await wait_physics_frames(4)
	assert_eq(hiker.condition.regen, HikerCondition.Regen.BENCH, "at a bench = bench regen")
	assert_signal_emitted_with_parameters(hiker, "regen_changed", [HikerCondition.Regen.BENCH])
	Input.action_press(&"walk")
	await wait_physics_frames(4)
	assert_eq(hiker.condition.regen, HikerCondition.Regen.NONE, "walking = no regen")


func test_regen_stops_when_full() -> void:
	_place("res://world/interactables/bench.tscn", Vector2(0, 0))
	await wait_physics_frames(4)
	assert_eq(hiker.condition.regen, HikerCondition.Regen.NONE, "nothing to refill at full stamina")
