class_name Hud
extends Control
## The in-trail HUD. It only displays: the trail runner feeds it values and it emits
## pause_pressed when the pause button is tapped.

signal pause_pressed
signal photo_pressed

const TOAST_SECONDS: float = 2.2
const TITLE_FONT: Font = preload("res://shared_art/title_font.tres")
## Longer toasts (first-time hints) wrap at this width instead of running off a 4:3 screen.
const TOAST_MAX_WIDTH: float = 760.0

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
var _water: WaterGauge
var _finds_label: Label
var _flow_label: Label


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
	_build_extra_pills()


## The water gauge (after the energy bar) and the finds counter (after photos) are
## copies of the photo pill, so they match the HUD style exactly.
func _build_extra_pills() -> void:
	var photo_pill: Control = photo_label.get_parent().get_parent() as Control
	var top: Node = photo_pill.get_parent()
	var finds_pill: Control = photo_pill.duplicate() as Control
	top.add_child(finds_pill)
	top.move_child(finds_pill, photo_pill.get_index() + 1)
	_finds_label = finds_pill.get_node("Row/Count") as Label
	var leaf: UiIcon = finds_pill.get_node("Row/Icon") as UiIcon
	leaf.kind = UiIcon.Kind.LEAF
	leaf.color = Color("#5E8C4A")
	_finds_label.text = "0/0"
	var water_pill: Control = photo_pill.duplicate() as Control
	var stamina_pill: Node = stamina_bar.get_parent().get_parent()
	top.add_child(water_pill)
	top.move_child(water_pill, stamina_pill.get_index() + 1)
	var drop: UiIcon = water_pill.get_node("Row/Icon") as UiIcon
	drop.kind = UiIcon.Kind.DROP
	drop.color = WaterGauge.FULL
	var count: Node = water_pill.get_node("Row/Count")
	count.get_parent().remove_child(count)
	count.queue_free()
	_water = WaterGauge.new()
	_water.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	water_pill.get_node("Row").add_child(_water)
	var flow_pill: Control = photo_pill.duplicate() as Control
	top.add_child(flow_pill)
	top.move_child(flow_pill, water_pill.get_index() + 1)
	var chevrons: UiIcon = flow_pill.get_node("Row/Icon") as UiIcon
	chevrons.kind = UiIcon.Kind.WALK
	chevrons.color = UiIcon.ACCENT
	_flow_label = flow_pill.get_node("Row/Count") as Label
	flow_pill.visible = false


func set_water(value: float, max_value: float, low_fraction: float) -> void:
	_water.low_fraction = low_fraction
	_water.fraction = value / max_value if max_value > 0.0 else 0.0


func set_finds(found: int, total: int) -> void:
	var text: String = "%d/%d" % [found, total]
	if _finds_label.text != text and found > 0:
		UiMotion.bump(_finds_label.get_parent() as Control)
	_finds_label.text = text
	(_finds_label.get_parent().get_parent() as Control).visible = total > 0


## Flow level from steady hiking; hidden at 0, gold at the top level.
func set_flow(level: int, max_level: int) -> void:
	var pill: Control = _flow_label.get_parent().get_parent() as Control
	var grew: bool = level > int(_flow_label.get_meta(&"level", 0))
	_flow_label.set_meta(&"level", level)
	_flow_label.text = tr("HUD_FLOW") % level
	pill.visible = level > 0
	if level >= max_level:
		_flow_label.add_theme_color_override("font_color", Color("#C98A12"))
	else:
		_flow_label.remove_theme_color_override("font_color")
	if grew:
		UiMotion.bump(pill, 1.12)


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
	var text: String = "%d/%d" % [taken, total]
	# Bounce the counter when a new photo lands (not when it's first filled in).
	if photo_label.text != text and not photo_label.text.is_empty() and taken > 0:
		UiMotion.bump(photo_label.get_parent() as Control)
	photo_label.text = text


## The big "Summit!" title, the trail's name and the time, over the middle of the screen.
func show_summit(trail_name: String, time_text: String) -> void:
	var center: CenterContainer = CenterContainer.new()
	center.name = "Summit"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	var title: Label = _summit_label(tr("SUMMIT_TITLE"), 104)
	title.add_theme_font_override("font", TITLE_FONT)
	box.add_child(title)
	box.add_child(_summit_label(tr("SUMMIT_SUBTITLE") % [trail_name, time_text], 32))
	box.modulate.a = 0.0
	# The bars and counters step aside: the view is the reward now.
	var bars: Control = get_node_or_null("SafeArea") as Control
	if bars != null:
		create_tween().tween_property(bars, "modulate:a", 0.0, 0.4)
	var tween: Tween = create_tween()
	tween.tween_interval(0.35)
	# The size is only right after layout, so set the pivot when the motion starts.
	tween.tween_callback(func() -> void:
		box.pivot_offset = box.size * 0.5
		box.scale = Vector2.ONE if UiMotion.reduced() else Vector2(0.6, 0.6))
	tween.tween_property(box, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(box, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _summit_label(text: String, size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#FFF6E5"))
	label.add_theme_color_override("font_shadow_color", Color(0.168627, 0.176471, 0.258824, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 5)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", Color(0.168627, 0.176471, 0.258824, 0.35))
	return label


## Short message under the top bar ("Checkpoint", "Dusk falls"...). `key` is a translation key.
func show_toast(key: String, seconds: float = TOAST_SECONDS) -> void:
	show_toast_text(tr(key), seconds)


## Like show_toast, for text that's already translated and filled in.
func show_toast_text(text: String, seconds: float = TOAST_SECONDS) -> void:
	toast_label.text = text
	# Measure the one-line width; wrap only when it wouldn't fit.
	toast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	toast_label.custom_minimum_size.x = 0.0
	var font: Font = toast_label.get_theme_font("font")
	var one_line: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, toast_label.get_theme_font_size("font_size")).x
	if one_line > TOAST_MAX_WIDTH:
		toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		toast_label.custom_minimum_size.x = TOAST_MAX_WIDTH
	toast.reset_size()
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
