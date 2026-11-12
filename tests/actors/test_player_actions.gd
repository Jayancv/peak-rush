extends GutTest
## The extra moves: hold to jump higher, double-tap to hurry, duck under branches, climb ladders.

var hiker: Hiker


func before_each() -> void:
	var ground: TerrainStrip = TerrainStrip.new()
	ground.points = PackedVector2Array([Vector2(-3000, 0), Vector2(600, 0), Vector2(604, -140), Vector2(3000, -140)])
	add_child_autofree(ground)
	hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(6)


func after_each() -> void:
	for a: StringName in [&"walk", &"jump", &"duck", &"walk_back"]:
		Input.action_release(a)


## Highest point of a jump with jump held for `hold_seconds` (0 = released on the next tick).
func _jump_height(hold_seconds: float) -> float:
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(10)
	var start: float = hiker.global_position.y
	var top: float = start
	var held_for: float = 0.0
	Input.action_press(&"jump")
	var pressed: bool = true
	while held_for < 1.4:
		await get_tree().physics_frame
		held_for += 1.0 / Engine.physics_ticks_per_second
		if pressed and held_for >= hold_seconds:
			Input.action_release(&"jump")
			pressed = false
		top = minf(top, hiker.global_position.y)
	return start - top


func test_holding_jump_goes_higher_than_a_tap() -> void:
	var b: Balance = hiker.balance
	var scale: float = b.jump_hold_gravity_scale
	b.jump_hold_gravity_scale = 1.0
	var old_jump: float = await _jump_height(0.0)
	b.jump_hold_gravity_scale = scale
	var tap: float = await _jump_height(0.0)
	var finger_tap: float = await _jump_height(0.09)
	var held: float = await _jump_height(0.6)
	assert_almost_eq(tap, old_jump, 1.0, "a tap is exactly the jump the trails were built for")
	assert_almost_eq(finger_tap, old_jump, 1.0, "so is a ~0.1 s finger tap")
	assert_gt(held - tap, 30.0, "holding jumps clearly higher (tap %.0f px, held %.0f px)" % [tap, held])
	gut.p("jump heights: tap %.1f px, held %.1f px" % [tap, held])


func test_double_tap_walk_hurries_and_tires_faster() -> void:
	Input.action_press(&"walk")
	await wait_physics_frames(2)
	Input.action_release(&"walk")
	await wait_physics_frames(3)
	Input.action_press(&"walk")
	await wait_physics_frames(60)
	assert_true(hiker.actions.hurrying)
	assert_almost_eq(hiker.velocity.x, hiker.balance.walk_speed * hiker.balance.hurry_speed_mult, 6.0)
	assert_eq(hiker.condition.effort_mult, hiker.balance.hurry_drain_mult)
	Input.action_release(&"walk")
	await wait_physics_frames(30)
	Input.action_press(&"walk")
	await wait_physics_frames(30)
	assert_false(hiker.actions.hurrying, "a single press is a normal walk")


func test_ducking_crouch_walks_slower() -> void:
	Input.action_press(&"duck")
	Input.action_press(&"walk")
	await wait_physics_frames(60)
	assert_true(hiker.actions.crouching)
	assert_almost_eq(hiker.velocity.x, hiker.balance.walk_speed * hiker.balance.crouch_speed_mult, 6.0)


func test_low_branch_trips_a_standing_hiker_only() -> void:
	var branch: LowBranch = (load("res://world/obstacles/low_branch.tscn") as PackedScene).instantiate()
	branch.position = Vector2(120, 0)
	add_child_autofree(branch)
	watch_signals(hiker)
	Input.action_press(&"duck")
	Input.action_press(&"walk")
	await wait_seconds(2.4)
	assert_signal_not_emitted(hiker, "stumbled", "ducked under it")
	Input.action_release(&"walk")
	Input.action_release(&"duck")
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(10)
	Input.action_press(&"walk")
	await wait_seconds(1.6)
	assert_signal_emitted(hiker, "stumbled", "walked into it upright")


func test_ladder_climbs_a_wall_too_tall_to_jump() -> void:
	var ladder: Ladder = (load("res://world/obstacles/ladder.tscn") as PackedScene).instantiate()
	ladder.height = 140.0
	ladder.position = Vector2(590, 0)
	add_child_autofree(ladder)
	hiker.teleport(Vector2(450, -4))
	await wait_physics_frames(6)
	var climbed: bool = false
	Input.action_press(&"walk")
	for i: int in 400:
		await wait_physics_frames(1)
		climbed = climbed or hiker.state == Hiker.State.CLIMB
		if hiker.global_position.x > 650.0 and hiker.is_on_floor():
			break
	assert_true(climbed, "it used the ladder")
	assert_gt(hiker.global_position.x, 620.0, "and walked on along the top")
	assert_almost_eq(hiker.global_position.y, -140.0, 6.0, "standing on the ledge")


func test_free_standing_ladder_leads_onto_a_lookout_deck() -> void:
	var ladder: Ladder = (load("res://world/obstacles/ladder.tscn") as PackedScene).instantiate()
	ladder.height = 140.0
	ladder.position = Vector2(200, 0)
	add_child_autofree(ladder)
	var deck: Boardwalk = (load("res://world/obstacles/boardwalk.tscn") as PackedScene).instantiate()
	deck.points = PackedVector2Array([Vector2(186, -140), Vector2(390, -140)])
	add_child_autofree(deck)
	var climbed: bool = false
	var on_deck: bool = false
	Input.action_press(&"walk")
	for i: int in 400:
		await wait_physics_frames(1)
		climbed = climbed or hiker.state == Hiker.State.CLIMB
		if hiker.is_on_floor() and absf(hiker.global_position.y + 140.0) < 6.0:
			on_deck = true
			break
	assert_true(climbed, "walked into the ladder and climbed")
	assert_true(on_deck, "and stepped off onto the deck")
