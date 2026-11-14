extends Control
## The long journey: the map on the left, Elsa's notebook page on the right. Pages open
## as the walker passes landmarks (Journey); tap a dot or use the arrows to read them.

const CREAM: Color = Color("#FFF6E5")
const INK: Color = Color("#2B2D42")
const MUTED: Color = Color("#6B6A73")
const ACCENT: Color = Color("#C0492F")
const TITLE_FONT: Font = preload("res://shared_art/title_font.tres")

@export var safe_area: MarginContainer

var _journey: JourneyData
var _map: JourneyMap
var _km_label: Label
var _info: Label
var _page_no: Label
var _page_title: Label
var _page_text: Label
var _page_scroll: ScrollContainer
var _prev: Button
var _next: Button
var _index: int = 0


func _ready() -> void:
	AudioManager.enter_menu()
	_journey = GameState.journey()
	_build()
	if _journey == null:
		_page_title.text = tr("JOURNEY_DONE_ALL")
		return
	_refresh()
	_show_page(_first_page())
	GameState.progress_changed.emit()


## Opens on the newest unread page, else the last one reached.
func _first_page() -> int:
	var last: int = 0
	for i: int in _journey.landmarks.size():
		var lm: LandmarkData = _journey.landmarks[i]
		if not Journey.is_reached(GameState.profile, _journey, lm):
			break
		last = i
		if not GameState.profile.journey_seen.has(Journey.page_key(_journey, lm)):
			return i
	return last


func _reached_count() -> int:
	var n: int = 0
	for lm: LandmarkData in _journey.landmarks:
		n += 1 if Journey.is_reached(GameState.profile, _journey, lm) else 0
	return n


func _refresh() -> void:
	var profile: PlayerProfile = GameState.profile
	var km: float = Journey.km(profile, _journey)
	var reached: Array[StringName] = []
	var unread: Array[StringName] = []
	for lm: LandmarkData in _journey.landmarks:
		if Journey.is_reached(profile, _journey, lm):
			reached.append(lm.id)
			if not profile.journey_seen.has(Journey.page_key(_journey, lm)):
				unread.append(lm.id)
	_map.show_journey(_journey, km, reached, unread)
	_km_label.text = tr("JOURNEY_KM") % [floori(km), roundi(_journey.length_km)]
	var next_lm: LandmarkData = Journey.next_landmark(profile, _journey)
	_info.text = tr("JOURNEY_NEXT") % [tr(next_lm.name_key), ceili(next_lm.km - km)] if next_lm != null else tr("JOURNEY_AT_END")


func _show_page(index: int) -> void:
	var count: int = _journey.landmarks.size()
	# One page past the last reached can be peeked at: it says how far there is to go.
	_index = clampi(index, 0, mini(_reached_count(), count - 1))
	var lm: LandmarkData = _journey.landmarks[_index]
	_page_no.text = tr("JOURNEY_PAGE") % [_index + 1, count]
	if Journey.is_reached(GameState.profile, _journey, lm):
		_page_title.text = tr(lm.page_title_key)
		_page_text.text = tr(lm.page_text_key)
		_page_text.add_theme_color_override("font_color", INK)
		Journey.mark_read(GameState.profile, _journey, lm)
	else:
		var left: int = ceili(lm.km - Journey.km(GameState.profile, _journey))
		_page_title.text = tr(lm.name_key)
		_page_text.text = tr("JOURNEY_LOCKED") % [left, tr(lm.name_key)]
		_page_text.add_theme_color_override("font_color", MUTED)
	_page_scroll.scroll_vertical = 0
	_prev.disabled = _index <= 0
	_next.disabled = _index >= mini(_reached_count(), count - 1)
	_map.select(lm.id)
	_refresh()


func _on_landmark_tapped(lm: LandmarkData) -> void:
	var i: int = _journey.landmarks.find(lm)
	if i <= _reached_count():
		_show_page(i)


# --- Layout (built in code; the scene only holds the backdrop and safe area) ---

func _build() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_area.add_child(vbox)
	vbox.add_child(_header())
	var intro: Label = _label(tr(_journey.intro_key) if _journey != null else "", 20, CREAM)
	intro.add_theme_color_override("font_outline_color", INK)
	intro.add_theme_constant_override("outline_size", 6)
	vbox.add_child(intro)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(body)
	body.add_child(_map_card())
	body.add_child(_page_card())
	UiMotion.intro(body.get_children(), 0.08)


func _header() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back: Button = _icon_button(false)
	back.pressed.connect(_go_back)
	row.add_child(back)
	var title: Label = _label(tr(_journey.name_key) if _journey != null else tr("MENU_JOURNEY"), 52, CREAM)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_color_override("font_shadow_color", Color(INK, 0.5))
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var pill: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(CREAM, 0.92)
	box.set_corner_radius_all(30)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	pill.add_theme_stylebox_override("panel", box)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_km_label = _label("", 26, INK)
	pill.add_child(_km_label)
	row.add_child(pill)
	return row


func _map_card() -> PanelContainer:
	var card: PanelContainer = _card()
	card.size_flags_stretch_ratio = 1.5
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	_map = JourneyMap.new()
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.landmark_tapped.connect(_on_landmark_tapped)
	box.add_child(_map)
	_info = _label("", 22, INK)
	box.add_child(_info)
	box.add_child(_label(tr("JOURNEY_HOW") % roundi(ContentDB.balance.journey_km_per_hike), 18, MUTED))
	return card


func _page_card() -> PanelContainer:
	var card: PanelContainer = _card()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	_page_no = _label("", 18, MUTED)
	box.add_child(_page_no)
	_page_title = _label("", 30, ACCENT)
	_page_title.add_theme_font_override("font", TITLE_FONT)
	_page_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_page_title)
	_page_scroll = ScrollContainer.new()
	_page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_page_scroll)
	_page_text = _label("", 23, INK)
	_page_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_text.add_theme_constant_override("line_spacing", 4)
	_page_scroll.add_child(_page_text)
	var footer: HBoxContainer = HBoxContainer.new()
	_prev = _icon_button(false)
	_prev.pressed.connect(func() -> void: _show_page(_index - 1))
	footer.add_child(_prev)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_next = _icon_button(true)
	_next.pressed.connect(func() -> void: _show_page(_index + 1))
	footer.add_child(_next)
	box.add_child(footer)
	return card


func _card() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


## A round button with the back arrow (mirrored for "next").
func _icon_button(mirrored: bool) -> Button:
	var button: Button = Button.new()
	button.theme_type_variation = &"IconButton"
	button.custom_minimum_size = Vector2(72, 72)
	var icon: UiIcon = UiIcon.new()
	icon.kind = UiIcon.Kind.BACK
	icon.stroke = 0.16
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 16
	icon.offset_top = 14
	icon.offset_right = -16
	icon.offset_bottom = -18
	if mirrored:
		icon.scale = Vector2(-1, 1)
		icon.resized.connect(func() -> void: icon.pivot_offset = icon.size * 0.5)
	button.add_child(icon)
	return button


func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _go_back() -> void:
	GameState.progress_changed.emit()
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
