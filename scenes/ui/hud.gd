class_name Hud
extends Control
## The in-trail HUD. It only displays: the trail runner feeds it values and it emits
## pause_pressed when the pause button is tapped.

signal pause_pressed
signal photo_pressed

const TOAST_SECONDS: float = 2.2

@export var stamina_bar: StaminaBar
@export var sun_arc: SunArc
@export var photo_label: Label
@export var pause_button: Button
@export var toast: Control
@export var toast_label: Label
## Green "×2" next to the bar while resting at a bench.
@export var boost_badge: Control
## "Take photo" button shown while standing at a viewpoint.
@export var photo_prompt: Button

var _toast_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	photo_prompt.pressed.connect(func() -> void: photo_pressed.emit())
	# Right-aligned text leaves room for the camera icon on the left.
	photo_prompt.add_theme_constant_override("h_separation", 0)
	photo_prompt.add_theme_stylebox_override("normal", _with_left_room(photo_prompt.get_theme_stylebox("normal")))
	photo_prompt.add_theme_stylebox_override("hover", _with_left_room(photo_prompt.get_theme_stylebox("hover")))
	photo_prompt.add_theme_stylebox_override("pressed", _with_left_room(photo_prompt.get_theme_stylebox("pressed")))
	toast.modulate.a = 0.0
	# Faded rather than hidden so the top bar never shifts sideways.
	boost_badge.modulate.a = 0.0


func set_stamina(value: float, max_value: float, recovering: bool) -> void:
	stamina_bar.set_stamina(value, max_value, recovering)


static func _with_left_room(box: StyleBox) -> StyleBox:
	var copy: StyleBox = box.duplicate()
	copy.content_margin_left = 84.0
	return copy


func show_photo_prompt(on: bool) -> void:
	if on and not photo_prompt.visible:
		photo_prompt.pivot_offset = photo_prompt.size * 0.5
		photo_prompt.scale = Vector2(0.6, 0.6)
		create_tween().tween_property(photo_prompt, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	photo_prompt.visible = on


## Photo mode owns the screen: hide the top bar and the prompt (toasts still show).
func set_photo_mode(on: bool) -> void:
	(pause_button.get_parent() as Control).visible = not on
	if on:
		photo_prompt.visible = false


func set_regen(mode: HikerCondition.Regen) -> void:
	stamina_bar.boost = mode
	var bench: bool = mode == HikerCondition.Regen.BENCH
	if bench and not is_boosted():
		boost_badge.pivot_offset = boost_badge.size * 0.5
		boost_badge.scale = Vector2(0.4, 0.4)
		create_tween().tween_property(boost_badge, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	boost_badge.modulate.a = 1.0 if bench else 0.0


func is_boosted() -> bool:
	return boost_badge.modulate.a > 0.5


func set_low_fraction(low: float) -> void:
	stamina_bar.low_fraction = low


func set_daylight(sun_progress: float, phase: Daylight.Phase, night: bool = false) -> void:
	sun_arc.night = night
	sun_arc.set_daylight(sun_progress, phase)


func set_photos(taken: int, total: int) -> void:
	photo_label.text = "%d/%d" % [taken, total]


## Short message under the top bar ("Checkpoint", "Dusk falls"...). `key` is a translation key.
func show_toast(key: String, seconds: float = TOAST_SECONDS) -> void:
	toast_label.text = tr(key)
	if _toast_tween != null:
		_toast_tween.kill()
	toast.modulate.a = 0.0
	toast.pivot_offset = toast.size * 0.5
	toast.scale = Vector2(0.9, 0.9)
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast, "modulate:a", 1.0, 0.15)
	_toast_tween.parallel().tween_property(toast, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.4)
