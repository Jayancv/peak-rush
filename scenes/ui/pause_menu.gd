class_name PauseMenu
extends Control
## The pause card: a dimmed screen with a card of buttons. Runs while the tree is paused. It only reports choices; the trail runner acts.

signal resume_pressed
signal restart_pressed
signal quit_pressed

@export var title_label: Label
@export var info_label: Label
@export var resume_button: Button
@export var restart_button: Button
@export var quit_button: Button
@export var vibration_toggle: Button
@export var card: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	quit_button.pressed.connect(func() -> void: quit_pressed.emit())
	vibration_toggle.toggled.connect(_on_vibration_toggled)


## `subtitle` (e.g. the trail's name) shows under the title when given.
func open_pause(subtitle: String = "") -> void:
	title_label.text = tr("PAUSE_TITLE")
	info_label.text = subtitle
	info_label.visible = not subtitle.is_empty()
	resume_button.visible = true
	_show()
	_focus(resume_button)


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _show() -> void:
	vibration_toggle.set_pressed_no_signal(bool(GameState.settings.get("vibration", true)))
	_update_vibration_text()
	visible = true
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.92, 0.92)
	card.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "modulate:a", 1.0, 0.15)


func _unhandled_input(event: InputEvent) -> void:
	# Esc closes the pause card (the trail runner is paused and can't hear it).
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		resume_pressed.emit()


func _on_vibration_toggled(on: bool) -> void:
	GameState.set_setting("vibration", on)
	_update_vibration_text()


func _update_vibration_text() -> void:
	vibration_toggle.text = tr("SETTING_VIBRATION_ON" if vibration_toggle.button_pressed else "SETTING_VIBRATION_OFF")


## Keyboard/controller focus helps on desktop; on a touch screen the ring just looks stuck.
func _focus(button: Button) -> void:
	if not DisplayServer.is_touchscreen_available():
		button.grab_focus()
