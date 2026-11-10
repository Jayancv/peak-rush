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
## Elevation map of the trail (TrailMap); the trail runner fills it.
@export var map: TrailMap

var _tween: Tween
var _closing: bool = false


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
	if not visible or _closing:
		return
	# Fade and shrink away instead of vanishing; it counts as closed straight away.
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_tween()
	_tween = create_tween().set_parallel()
	_tween.tween_property(card, "scale", Vector2(0.94, 0.94), 0.14).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.14)
	_tween.chain().tween_callback(func() -> void:
		visible = false
		_closing = false
	)


func is_open() -> bool:
	return visible and not _closing


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _show() -> void:
	vibration_toggle.set_pressed_no_signal(bool(GameState.settings.get("vibration", true)))
	_update_vibration_text()
	_kill_tween()
	_closing = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	# The dim fades in with the card rather than snapping on.
	modulate.a = 0.0
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.92, 0.92)
	_tween = create_tween().set_parallel()
	_tween.tween_property(card, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.16)


func _unhandled_input(event: InputEvent) -> void:
	# Esc closes the pause card (the trail runner is paused and can't hear it).
	if is_open() and event.is_action_pressed("pause"):
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
