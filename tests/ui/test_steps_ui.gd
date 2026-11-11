extends GutTest
## Real steps on screen (M9) with a mock phone: the Settings switch (fits on a 720p
## screen, refusal flips it back), and the main menu's claim button.

var _saved: Dictionary
var _phone: MockStepProvider


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()
	_phone = MockStepProvider.new()
	Steps.use_provider(_phone)


func after_each() -> void:
	Steps.use_provider(StepProvider.new())
	GameState.from_dict(_saved)


func _open(path: String) -> Node:
	var screen: Node = add_child_autofree((load(path) as PackedScene).instantiate())
	await wait_process_frames(3)
	return screen


func test_settings_card_with_the_steps_row_fits_the_screen() -> void:
	var screen: Node = await _open("res://scenes/settings/settings.tscn")
	assert_not_null(screen.find_child("StepsRow", true, false), "shown when the phone has a step source")
	# The headless test window isn't 720 high, so check the size against the base viewport
	# (landscape phones keep 720 px of height with aspect "expand"), leaving a 16 px gutter.
	var card: Control = screen.get_node("Center/Card")
	assert_lt(card.size.y, 720.0 - 32.0, "settings card is %d px tall" % card.size.y)


func test_settings_hides_the_row_without_a_step_source() -> void:
	Steps.use_provider(StepProvider.new())
	var screen: Node = await _open("res://scenes/settings/settings.tscn")
	assert_null(screen.find_child("StepsRow", true, false))


func test_refused_access_flips_the_switch_back() -> void:
	_phone.grant = false
	var screen: Node = await _open("res://scenes/settings/settings.tscn")
	var toggle: Button = screen.find_child("StepsRow", true, false).get_node("Switch")
	toggle.button_pressed = true
	assert_false(toggle.button_pressed)
	assert_false(GameState.steps.enabled)
	_phone.grant = true
	toggle.button_pressed = true
	assert_true(GameState.steps.enabled)
	toggle.button_pressed = false
	assert_false(GameState.steps.enabled, "switching off disconnects")


func test_menu_has_no_steps_button_while_off() -> void:
	var menu: Node = await _open("res://scenes/main_menu/main_menu.tscn")
	assert_null(menu.find_child("StepsButton", true, false))


func test_menu_button_claims_the_steps() -> void:
	Steps.turn_on(func(_on: bool) -> void: pass)
	_phone.fixed = {GameState.today(): 2600}
	var menu: Node = await _open("res://scenes/main_menu/main_menu.tscn")
	var button: Button = menu.find_child("StepsButton", true, false)
	assert_not_null(button)
	assert_false(button.disabled, "there is TP to claim")
	assert_string_contains(button.text, "2600")
	var before: int = GameState.tp
	button.pressed.emit()
	assert_eq(GameState.tp, before + 5)
	assert_true(button.disabled, "nothing left to claim")


func test_menu_rereads_when_the_app_comes_back() -> void:
	Steps.turn_on(func(_on: bool) -> void: pass)
	var menu: Node = await _open("res://scenes/main_menu/main_menu.tscn")
	var button: Button = menu.find_child("StepsButton", true, false)
	assert_true(button.disabled)
	_phone.fixed = {GameState.today(): 1000}
	button.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_false(button.disabled, "steps walked while the app was away show up")


func test_revoked_access_hides_the_button() -> void:
	Steps.turn_on(func(_on: bool) -> void: pass)
	_phone.access_ok = false
	var menu: Node = await _open("res://scenes/main_menu/main_menu.tscn")
	var button: Button = menu.find_child("StepsButton", true, false)
	assert_true(button == null or not button.visible)
