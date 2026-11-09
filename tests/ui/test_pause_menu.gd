extends GutTest

var menu: PauseMenu


func before_each() -> void:
	menu = add_child_autofree((load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate()) as PauseMenu


func test_starts_hidden() -> void:
	assert_false(menu.is_open())


func test_pause_mode_shows_resume() -> void:
	menu.open_pause()
	assert_true(menu.is_open())
	assert_true(menu.resume_button.visible)
	assert_false(menu.info_label.visible)


func test_buttons_emit_signals() -> void:
	watch_signals(menu)
	menu.open_pause()
	menu.resume_button.pressed.emit()
	menu.restart_button.pressed.emit()
	menu.quit_button.pressed.emit()
	assert_signal_emitted(menu, "resume_pressed")
	assert_signal_emitted(menu, "restart_pressed")
	assert_signal_emitted(menu, "quit_pressed")


func test_vibration_toggle_updates_setting() -> void:
	var before: bool = bool(GameState.settings.get("vibration", true))
	menu.vibration_toggle.toggled.emit(not before)
	assert_eq(bool(GameState.settings["vibration"]), not before)
	GameState.set_setting("vibration", before)
