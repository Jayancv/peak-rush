class_name AboutCard
extends Control
## The About popup from Settings: version, credits, what the game does with data,
## open-source licences, and "Reset progress" (which asks twice).

const INK: Color = Color("#2B2D42")
const MUTED: Color = Color(0.168627, 0.176471, 0.258824, 0.65)
const DANGER: Color = Color("#C0392B")
## Public privacy policy page; set when it's hosted (M7.9). Empty = show the summary only.
const PRIVACY_URL: String = ""
## How long the "tap again to erase" state waits for the second tap.
const CONFIRM_SECONDS: float = 4.0

var _box: VBoxContainer
var _reset: Button
var _confirm_left: float = 0.0


static func open(parent: Control) -> AboutCard:
	var card: AboutCard = AboutCard.new()
	parent.add_child(card)
	card._build()
	return card


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.168627, 0.176471, 0.258824, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed or e is InputEventScreenTouch and e.pressed:
			queue_free())
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	panel.add_child(_box)
	_box.add_child(_label(tr("ABOUT_TITLE"), 38, INK))
	_box.add_child(_label(tr("ABOUT_VERSION") % version(), 22, MUTED))
	_box.add_child(_label(tr("ABOUT_CREDITS"), 22, INK))
	_box.add_child(_label(tr("ABOUT_PRIVACY"), 18, MUTED))
	var links: HBoxContainer = _row()
	if not PRIVACY_URL.is_empty():
		links.add_child(_button(tr("ABOUT_PRIVACY_LINK"), func() -> void: OS.shell_open(PRIVACY_URL)))
	links.add_child(_button(tr("ABOUT_LICENSES"), _show_licenses))
	Ads._ensure()
	if Ads.provider.needs_consent():
		links.add_child(_button(tr("ABOUT_AD_CHOICES"), func() -> void: Ads.open_consent(self)))
	var actions: HBoxContainer = _row()
	_reset = _button(tr("ABOUT_RESET"), _on_reset)
	actions.add_child(_reset)
	var close: Button = _button(tr("ABOUT_CLOSE"), queue_free)
	close.theme_type_variation = &"PrimaryButton"
	actions.add_child(close)
	UiMotion.intro([panel])


## The version players see (and quote in feedback).
static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "?"))


func _process(delta: float) -> void:
	if _confirm_left > 0.0:
		_confirm_left -= delta
		if _confirm_left <= 0.0:
			_set_confirming(false)


## First tap arms it; a second tap within a few seconds erases progress (settings stay).
func _on_reset() -> void:
	if _confirm_left <= 0.0:
		_set_confirming(true)
		return
	GameState.reset_progress()
	SaveService.save_game()
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _set_confirming(on: bool) -> void:
	_confirm_left = CONFIRM_SECONDS if on else 0.0
	_reset.text = tr("ABOUT_RESET_CONFIRM" if on else "ABOUT_RESET")
	if on:
		_reset.add_theme_color_override("font_color", DANGER)
		_reset.add_theme_color_override("font_hover_color", DANGER)
		UiMotion.bump(_reset, 1.06)
	else:
		_reset.remove_theme_color_override("font_color")
		_reset.remove_theme_color_override("font_hover_color")


## The engine's licence (the MIT licence asks for its notice to ship with the game).
func _show_licenses() -> void:
	for child: Node in _box.get_children():
		child.queue_free()
	_box.add_child(_label(tr("ABOUT_LICENSES"), 32, INK))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box.add_child(scroll)
	var text: Label = _label("Godot Engine\n\n" + Engine.get_license_text(), 14, MUTED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(540, 0)
	scroll.add_child(text)
	_row().add_child(_button(tr("ABOUT_CLOSE"), queue_free))


func _row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(row)
	return row


func _button(text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(540, 0)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		queue_free()
