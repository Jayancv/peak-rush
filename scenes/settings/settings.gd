extends Control
## Volumes, controls, vibration and reduce motion, plus the About popup. Every change goes straight into GameState
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
	_bind_toggle(left_handed_toggle, "left_handed")
	_bind_toggle(vibration_toggle, "vibration")
	var motion_toggle: Button = _add_toggle_row(vibration_toggle.get_parent(), "SETTINGS_REDUCE_MOTION", UiIcon.Kind.MOTION)
	_bind_toggle(motion_toggle, "reduce_motion")
	_add_steps_row(motion_toggle.get_parent())
	_add_about_button()
	# A sample sound while dragging the effects slider, so the level can be judged.
	sfx_slider.drag_ended.connect(func(_changed: bool) -> void: AudioManager.play_footstep(TerrainStrip.Surface.ROCK))
	UiMotion.intro($Center/Card/VBox.get_children(), 0.08)


func _bind_slider(slider: HSlider, key: String) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.set_value_no_signal(float(GameState.settings.get(key, 0.8)))
	slider.value_changed.connect(func(v: float) -> void: GameState.set_setting(key, v))


## Switches write straight to the setting; the label beside each one says what it is.
func _bind_toggle(toggle: Button, key: String) -> void:
	toggle.set_pressed_no_signal(bool(GameState.settings.get(key, false)))
	(toggle as ToggleSwitch).sync()
	toggle.toggled.connect(func(on: bool) -> void: GameState.set_setting(key, on))


## Another switch row, copied from `like` so it matches; returns its switch.
func _add_toggle_row(like: Node, label_key: String, icon: UiIcon.Kind) -> Button:
	var row: Node = like.duplicate()
	like.get_parent().add_child(row)
	like.get_parent().move_child(row, like.get_index() + 1)
	(row.get_node("Label") as Label).text = label_key
	(row.get_node("Badge/Icon") as UiIcon).kind = icon
	return row.get_node("Switch") as Button


## Real steps -> TP (M9). Only on phones with a step source; switching on asks the
## phone for access, and a refusal flips the switch back.
func _add_steps_row(like: Node) -> void:
	if not Steps.is_supported():
		return
	var toggle: ToggleSwitch = _add_toggle_row(like, "SETTINGS_STEPS", UiIcon.Kind.BOOTS) as ToggleSwitch
	toggle.get_parent().name = "StepsRow"
	toggle.set_pressed_no_signal(Steps.is_on())
	toggle.sync()
	toggle.toggled.connect(func(on: bool) -> void:
		if not on:
			Steps.turn_off()
			return
		Steps.turn_on(func(granted: bool) -> void:
			if not granted and is_instance_valid(toggle):
				toggle.set_pressed_no_signal(false)
				toggle.sync()))


## An "i" button at the top right, styled like the back button.
func _add_about_button() -> void:
	var top: Node = back_button.get_parent()
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var about: Button = back_button.duplicate() as Button
	about.name = "AboutButton"
	about.tooltip_text = "ABOUT_TITLE"
	(about.get_node("Icon") as UiIcon).kind = UiIcon.Kind.INFO
	(about.get_node("Icon") as UiIcon).stroke = 0.1
	top.add_child(about)
	about.pressed.connect(func() -> void: AboutCard.open(self))


func _about_open() -> AboutCard:
	for child: Node in get_children():
		if child is AboutCard and not child.is_queued_for_deletion():
			return child as AboutCard
	return null


func _go_back() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		var about: AboutCard = _about_open()
		if about != null:
			about.queue_free()
		else:
			_go_back()


func _notification(what: int) -> void:
	# Every node hears back; an open About card closes itself instead.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _about_open() == null:
		_go_back()
