extends Control
## Volumes, controls and vibration. Every change goes straight into GameState
## (SaveService saves it, AudioManager and TouchControls listen), so there's no
## "Apply" button and nothing to lose by backing out.

@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var ambience_slider: HSlider
@export var left_handed_toggle: Button
@export var vibration_toggle: Button
@export var back_button: Button


func _ready() -> void:
	AudioManager.enter_menu()
	back_button.pressed.connect(_go_back)
	_bind_slider(music_slider, "music_volume")
	_bind_slider(sfx_slider, "sfx_volume")
	_bind_slider(ambience_slider, "ambience_volume")
	_bind_toggle(left_handed_toggle, "left_handed", "SETTING_LEFT_HANDED")
	_bind_toggle(vibration_toggle, "vibration", "SETTING_VIBRATION")
	# A sample sound while dragging the effects slider, so the level can be judged.
	sfx_slider.drag_ended.connect(func(_changed: bool) -> void: AudioManager.play_footstep(TerrainStrip.Surface.ROCK))
	UiMotion.intro($Center/Card/VBox.get_children(), 0.08)


func _bind_slider(slider: HSlider, key: String) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.set_value_no_signal(float(GameState.settings.get(key, 0.8)))
	slider.value_changed.connect(func(v: float) -> void: GameState.set_setting(key, v))


## Toggles show "<label>: On/Off" from the keys `<prefix>_ON` / `<prefix>_OFF`.
func _bind_toggle(button: Button, key: String, prefix: String) -> void:
	button.toggle_mode = true
	button.set_pressed_no_signal(bool(GameState.settings.get(key, false)))
	button.text = tr(prefix + ("_ON" if button.button_pressed else "_OFF"))
	button.toggled.connect(func(on: bool) -> void:
		GameState.set_setting(key, on)
		button.text = tr(prefix + ("_ON" if on else "_OFF"))
	)


func _go_back() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
