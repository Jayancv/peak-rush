class_name Splash
extends Control
## The first screen: the hiker icon and the game's name on a sunrise sky (identical to
## the engine's boot image, so the hand-over is invisible), then the icon glides aside,
## the name grows into place beside it and the subtitle eases in, before fading into
## the main menu. A tap skips straight to the menu.
## Timings are UI feel, not gameplay tuning, so they live here.

const ICON: Texture2D = preload("res://shared_art/icons/icon_512.png")
const TITLE_FONT: Font = preload("res://shared_art/title_font.tres")
const SKY_TOP: Color = Color("#3D8ED0")
const SKY_MID: Color = Color("#8EC6E6")
const SKY_LOW: Color = Color("#F3C38E")
const GLOW: Color = Color(1.0, 0.88, 0.66, 0.6)
const CREAM: Color = Color("#FFF6E5")
const INK: Color = Color("#2B2D42")
const ICON_SIZE: float = 300.0
const GAP: float = 48.0
const TITLE_SIZE: int = 104
const SUBTITLE_SIZE: int = 32
## Seconds from start until the menu begins to fade in.
const HOLD_SECONDS: float = 2.2
const MOVE_SECONDS: float = 0.75
## The name sits under the icon at this size in the boot image, then grows into place.
const START_TITLE_SCALE: float = 0.6
const START_GAP: float = 18.0

## Off when the boot image is rendered from this scene (tools/make_boot_splash.gd).
static var autoplay: bool = true

var _icon: TextureRect
var _glow: TextureRect
var _title: Label
var _subtitle: Label
var _leaving: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	if not autoplay:
		return
	AudioManager.enter_menu()
	_animate()
	get_tree().create_timer(HOLD_SECONDS).timeout.connect(_leave)


func _build() -> void:
	var view: Vector2 = get_viewport_rect().size
	var sky: TextureRect = TextureRect.new()
	sky.texture = _gradient([SKY_TOP, SKY_MID, SKY_LOW], PackedFloat32Array([0.0, 0.55, 1.0]), false)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(sky)
	_glow = TextureRect.new()
	_glow.texture = SoftGlow.texture()
	_glow.self_modulate = GLOW
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.size = Vector2.ONE * ICON_SIZE * 3.0
	# Added light, so the warm glow brightens the blue sky instead of greying it.
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	add_child(_glow)
	var shadow: Panel = Panel.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(INK, 0.0)
	box.shadow_color = Color(INK, 0.28)
	box.shadow_size = 26
	box.shadow_offset = Vector2(0, 10)
	box.set_corner_radius_all(roundi(ICON_SIZE * 0.22))
	shadow.add_theme_stylebox_override("panel", box)
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.show_behind_parent = true
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon = TextureRect.new()
	_icon.texture = ICON
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.size = Vector2.ONE * ICON_SIZE
	_icon.pivot_offset = _icon.size * 0.5
	_icon.add_child(shadow)
	add_child(_icon)
	_title = _label(tr("MENU_TITLE"), TITLE_SIZE, CREAM, TITLE_FONT)
	_title.add_theme_color_override("font_shadow_color", Color(INK, 0.35))
	_title.add_theme_constant_override("shadow_offset_y", 5)
	_subtitle = _label(tr("MENU_SUBTITLE"), SUBTITLE_SIZE, Color(CREAM, 0.95), null)
	_subtitle.add_theme_color_override("font_shadow_color", Color(INK, 0.3))
	_subtitle.add_theme_constant_override("shadow_offset_y", 2)
	# End: icon and title side by side, subtitle under the title.
	var centre: Vector2 = view * 0.5 - Vector2(0, 10)
	var text_w: float = maxf(_title.size.x, _subtitle.size.x)
	var left: float = centre.x - (ICON_SIZE + GAP + text_w) * 0.5
	var text_x: float = left + ICON_SIZE + GAP
	var block_h: float = _title.size.y + _subtitle.size.y - 18.0
	var title_end: Vector2 = Vector2(text_x, centre.y - block_h * 0.5)
	_icon.set_meta("end", Vector2(left, centre.y - ICON_SIZE * 0.5))
	_title.set_meta("end", title_end)
	_subtitle.position = Vector2(text_x + 6.0, title_end.y + _title.size.y - 18.0)
	_subtitle.modulate.a = 0.0
	# Start (this is the boot image): icon in the middle with the name under it, smaller.
	var title_h: float = _title.size.y * START_TITLE_SCALE
	var stack_h: float = ICON_SIZE + START_GAP + title_h
	_icon.position = Vector2(centre.x - ICON_SIZE * 0.5, centre.y - stack_h * 0.5)
	_title.scale = Vector2.ONE * START_TITLE_SCALE
	_title.position = Vector2(centre.x - _title.size.x * START_TITLE_SCALE * 0.5, _icon.position.y + ICON_SIZE + START_GAP)
	_place_glow()


func _animate() -> void:
	# Icon glides aside while the name grows and travels to its place beside it.
	var move: Tween = create_tween().set_parallel()
	move.tween_property(_icon, "position", _icon.get_meta("end") as Vector2, MOVE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.2)
	move.tween_method(func(_v: float) -> void: _place_glow(), 0.0, 1.0, MOVE_SECONDS).set_delay(0.2)
	move.tween_property(_title, "position", _title.get_meta("end") as Vector2, MOVE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.32)
	move.tween_property(_title, "scale", Vector2.ONE, MOVE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.32)
	_reveal(_subtitle, 40.0, 0.75)
	# A gentle settle on the icon as everything lands.
	var pop: Tween = create_tween()
	pop.tween_interval(0.2 + MOVE_SECONDS)
	pop.tween_property(_icon, "scale", Vector2.ONE * 1.04, 0.16).set_ease(Tween.EASE_OUT)
	pop.tween_property(_icon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reveal(label: Label, slide: float, delay: float) -> void:
	var end_x: float = label.position.x
	label.position.x += slide
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(label, "position:x", end_x, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.45)


func _place_glow() -> void:
	_glow.position = _icon.position + _icon.size * 0.5 - _glow.size * 0.5


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _gui_input(event: InputEvent) -> void:
	# Any tap skips the intro.
	if autoplay and (event is InputEventScreenTouch or event is InputEventMouseButton) and event.is_pressed():
		_leave()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _label(text: String, size: int, color: Color, font: Font) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if font != null:
		label.add_theme_font_override("font", font)
	add_child(label)
	label.size = label.get_minimum_size()
	return label


static func _gradient(colors: Array[Color], offsets: PackedFloat32Array, radial: bool) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray(colors)
	gradient.offsets = offsets
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = gradient
	# Tall enough that the sky gradient has no visible steps on a phone.
	tex.width = 8 if not radial else 256
	tex.height = 1024 if not radial else 256
	if radial:
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
	else:
		tex.fill_from = Vector2(0, 0)
		tex.fill_to = Vector2(0, 1)
	return tex
