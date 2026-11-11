extends GutTest
## Flow: steady walking builds speed; stumbles and falls break it; standing still drains it.

var _b: Balance = Balance.new()


func _walk(flow: Flow, seconds: float) -> void:
	var t: float = 0.0
	while t < seconds:
		flow.tick(0.25, true)
		t += 0.25


func test_steady_walking_builds_levels_up_to_the_cap() -> void:
	var flow: Flow = Flow.new(_b)
	assert_eq(flow.speed_multiplier(), 1.0)
	_walk(flow, _b.flow_step_seconds * 2.0)
	assert_eq(flow.level, 2)
	_walk(flow, _b.flow_step_seconds * 10.0)
	assert_eq(flow.level, _b.flow_max_level)
	assert_true(flow.is_max())
	assert_almost_eq(flow.speed_multiplier(), 1.0 + _b.flow_speed_per_level * _b.flow_max_level, 0.0001)


func test_a_stumble_breaks_it() -> void:
	var flow: Flow = Flow.new(_b)
	_walk(flow, _b.flow_step_seconds * 3.0)
	watch_signals(flow)
	flow.break_flow()
	assert_eq(flow.level, 0)
	assert_signal_emitted_with_parameters(flow, "level_changed", [0])


func test_a_short_pause_is_free_but_standing_drains_it() -> void:
	var flow: Flow = Flow.new(_b)
	_walk(flow, _b.flow_step_seconds * 3.0)
	flow.tick(_b.flow_idle_grace * 0.9, false)
	assert_eq(flow.level, 3, "a quick stop for a jump or a look costs nothing")
	flow.tick(_b.flow_idle_grace * 0.1 + _b.flow_decay_seconds + 0.01, false)
	assert_eq(flow.level, 2)
	for i: int in 20:
		flow.tick(_b.flow_decay_seconds, false)
	assert_eq(flow.level, 0)


func test_hiker_stumble_and_fall_break_flow() -> void:
	var hiker: Hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	await wait_physics_frames(2)
	_walk(hiker.condition.flow, _b.flow_step_seconds * 2.0)
	assert_gt(hiker.condition.flow.level, 0)
	hiker.respawn(Vector2.ZERO)
	assert_eq(hiker.condition.flow.level, 0, "a fall (respawn) breaks flow")


func test_flow_speeds_the_hiker_up() -> void:
	var c: HikerCondition = HikerCondition.new(_b)
	var before: float = c.speed_multiplier(0.0, TerrainStrip.Surface.DIRT)
	_walk(c.flow, _b.flow_step_seconds * 2.0)
	assert_almost_eq(c.speed_multiplier(0.0, TerrainStrip.Surface.DIRT), before * (1.0 + 2.0 * _b.flow_speed_per_level), 0.0001)
