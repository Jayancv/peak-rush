extends GutTest

var controls: TouchControls


func before_each() -> void:
	var scene: PackedScene = load("res://scenes/ui/touch_controls.tscn") as PackedScene
	controls = add_child_autofree(scene.instantiate()) as TouchControls


func after_each() -> void:
	Input.action_release(&"walk")
	Input.action_release(&"jump")


func _touch(index: int, x_fraction: float, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	var size: Vector2 = controls.get_viewport_rect().size
	event.position = Vector2(size.x * x_fraction, size.y * 0.5)
	controls._unhandled_input(event)


func test_holding_left_half_walks() -> void:
	_touch(0, 0.2, true)
	assert_true(Input.is_action_pressed(&"walk"))
	_touch(0, 0.2, false)
	assert_false(Input.is_action_pressed(&"walk"))


func test_tapping_right_half_jumps() -> void:
	_touch(0, 0.8, true)
	assert_true(Input.is_action_pressed(&"jump"))
	assert_false(Input.is_action_pressed(&"walk"))
	_touch(0, 0.8, false)
	assert_false(Input.is_action_pressed(&"jump"))


func test_walk_and_jump_at_the_same_time() -> void:
	_touch(0, 0.2, true)
	_touch(1, 0.8, true)
	assert_true(Input.is_action_pressed(&"walk"))
	assert_true(Input.is_action_pressed(&"jump"))
	_touch(1, 0.8, false)
	assert_true(Input.is_action_pressed(&"walk"), "lifting the jump finger keeps walking")


func test_finger_keeps_its_role_after_sliding_across() -> void:
	_touch(0, 0.2, true)
	# Released over the jump half: it must still release walk.
	_touch(0, 0.9, false)
	assert_false(Input.is_action_pressed(&"walk"))
	assert_false(Input.is_action_pressed(&"jump"))


func test_two_walk_fingers_release_only_when_both_lift() -> void:
	_touch(0, 0.1, true)
	_touch(1, 0.3, true)
	_touch(0, 0.1, false)
	assert_true(Input.is_action_pressed(&"walk"))
	_touch(1, 0.3, false)
	assert_false(Input.is_action_pressed(&"walk"))


func test_left_handed_swaps_halves() -> void:
	controls.left_handed = true
	_touch(0, 0.8, true)
	assert_true(Input.is_action_pressed(&"walk"))
	_touch(1, 0.2, true)
	assert_true(Input.is_action_pressed(&"jump"))


func test_touch_on_blocker_is_ignored() -> void:
	var button: Button = Button.new()
	button.add_to_group(TouchControls.BLOCKER_GROUP)
	button.position = Vector2.ZERO
	button.size = controls.get_viewport_rect().size * Vector2(0.5, 1.0)
	add_child_autofree(button)
	_touch(0, 0.2, true)
	assert_false(Input.is_action_pressed(&"walk"))


func test_hint_brightens_while_held() -> void:
	_touch(0, 0.2, true)
	assert_almost_eq(controls.left_hint.modulate.a, TouchControls.HINT_ACTIVE_ALPHA, 0.001)
	assert_almost_eq(controls.right_hint.modulate.a, TouchControls.HINT_IDLE_ALPHA, 0.001)
