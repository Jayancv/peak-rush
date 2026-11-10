extends GutTest
## Real physics: the hiker on the physics obstacles (bridge, wobbly stones, boulder,
## log, exposed ridge, snow slide).

var hiker: Hiker


func after_each() -> void:
	Input.action_release(&"walk")
	Input.action_release(&"jump")


func _ground(points: PackedVector2Array) -> TerrainStrip:
	var strip: TerrainStrip = TerrainStrip.new()
	strip.points = points
	strip.decorate = false
	add_child_autofree(strip)
	return strip


func _spawn(at: Vector2) -> void:
	hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	hiker.teleport(at)
	await wait_physics_frames(8)


func _place(path: String, pos: Vector2) -> Node2D:
	var node: Node2D = (load(path) as PackedScene).instantiate() as Node2D
	node.position = pos
	add_child_autofree(node)
	return node


func test_hiker_crosses_a_rope_bridge_without_falling() -> void:
	_ground(PackedVector2Array([Vector2(-600, 0), Vector2(0, 0)]))
	_ground(PackedVector2Array([Vector2(300, 0), Vector2(1200, 0)]))
	_place("res://world/obstacles/rope_bridge.tscn", Vector2.ZERO)
	await _spawn(Vector2(-60, -4))
	watch_signals(hiker)
	Input.action_press(&"walk")
	var lowest: float = -INF
	for i: int in 220:
		await wait_physics_frames(1)
		lowest = maxf(lowest, hiker.global_position.y)
	assert_gt(hiker.global_position.x, 320.0, "made it to the far bank")
	assert_lt(lowest, 60.0, "stayed on the deck (it only sags a little)")
	assert_gt(lowest, 2.0, "the deck did dip under the hiker")


func test_wobbly_stone_sinks_under_the_hiker() -> void:
	_ground(PackedVector2Array([Vector2(-600, 0), Vector2(0, 0)]))
	var stream: SteppingStones = (load("res://world/obstacles/stepping_stones.tscn") as PackedScene).instantiate() as SteppingStones
	stream.wobble = 6.0
	add_child_autofree(stream)
	var first: float = stream.gap + stream.stone_width * 0.5
	await _spawn(Vector2(first, -20))
	await wait_physics_frames(40)
	var stone: SteppingStone = null
	for child: Node in stream.get_children(true):
		if child is SteppingStone:
			stone = child as SteppingStone
			break
	assert_not_null(stone)
	assert_gt(stone.position.y, -SteppingStones.STONE_RISE + 2.0, "it sank under the hiker")


func test_rolling_boulder_trips_a_hiker_on_foot() -> void:
	_ground(PackedVector2Array([Vector2(-600, 0), Vector2(900, 0)]))
	await _spawn(Vector2(0, -4))
	watch_signals(hiker)
	var boulder: RollingBoulder = _place("res://world/obstacles/rolling_boulder.tscn", Vector2(220, 0)) as RollingBoulder
	boulder.push = 160.0
	await wait_physics_frames(200)
	assert_signal_emitted(hiker, "stumbled")


func test_wet_log_is_slippery() -> void:
	_ground(PackedVector2Array([Vector2(-600, 0), Vector2(900, 0)]))
	var log_node: FallenLog = (load("res://world/obstacles/fallen_log.tscn") as PackedScene).instantiate() as FallenLog
	log_node.wet = true
	log_node.position = Vector2(60, 0)
	add_child_autofree(log_node)
	await _spawn(Vector2(0, -4))
	Input.action_press(&"walk")
	var slipped: bool = false
	for i: int in 120:
		await wait_physics_frames(1)
		slipped = slipped or hiker.effective_surface() == TerrainStrip.Surface.ICE
	assert_true(slipped)


func test_exposed_ridge_strengthens_wind() -> void:
	_ground(PackedVector2Array([Vector2(-600, 0), Vector2(900, 0)]))
	var zone: WindZone = _place("res://world/obstacles/wind_zone.tscn", Vector2(-200, 0)) as WindZone
	await _spawn(Vector2(0, -4))
	await wait_physics_frames(4)
	assert_true(hiker.condition.is_exposed())
	var push: float = hiker.condition.exposed_wind(-10.0)
	assert_almost_eq(push, -10.0 * hiker.balance.exposed_gust_mult - zone.headwind, 0.01)


func test_hiker_slides_down_a_snow_slope() -> void:
	_ground(PackedVector2Array([Vector2(-400, 0), Vector2(0, 0), Vector2(500, 170), Vector2(1400, 170)]))
	_place("res://world/obstacles/snow_slide.tscn", Vector2(0, 0))
	await _spawn(Vector2(-80, -4))
	Input.action_press(&"walk")
	var slid: bool = false
	var fastest: float = 0.0
	for i: int in 240:
		await wait_physics_frames(1)
		slid = slid or hiker.state == Hiker.State.SLIDE
		fastest = maxf(fastest, hiker.velocity.x)
	assert_true(slid, "it started sliding")
	assert_gt(fastest, hiker.balance.walk_speed * 1.3, "sliding is faster than walking")
