extends Control
## The player's profile: a live preview of their hiker with a name field, and three
## tabs: Look (outfit colours, nicer ones unlocked by stars), Stats and Badges.

@export var back_button: Button
@export var name_edit: LineEdit
@export var tabs: HBoxContainer
@export var content: VBoxContainer
@export var preview: Hiker

enum Tab { LOOK, STATS, BADGES }

const TAB_KEYS: Array[String] = ["PROFILE_TAB_LOOK", "PROFILE_TAB_STATS", "PROFILE_TAB_BADGES"]
const SLOT_KEYS: Array[String] = ["PROFILE_SLOT_HAT", "PROFILE_SLOT_JACKET", "PROFILE_SLOT_PACK", "PROFILE_SLOT_PANTS", "PROFILE_SLOT_SKIN"]
const INK: Color = Color("#2B2D42")
const MUTED: Color = Color(0.168627, 0.176471, 0.258824, 0.6)
const FIELD: Color = Color(1, 1, 1, 0.75)
const FIELD_LINE: Color = Color("#E0CFAF")

var _tab: Tab = Tab.LOOK
var _swatches: Array[SwatchButton] = []
var _hint: Label


func _ready() -> void:
	AudioManager.enter_menu()
	back_button.pressed.connect(_go_back)
	_style_name_field()
	name_edit.text = GameState.profile.hiker_name
	name_edit.text_submitted.connect(func(_t: String) -> void: name_edit.release_focus())
	name_edit.focus_exited.connect(_save_name)
	for i: int in TAB_KEYS.size():
		var tab: Button = Button.new()
		tab.text = tr(TAB_KEYS[i])
		tab.custom_minimum_size = Vector2(0, 60)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 24)
		tab.pressed.connect(show_tab.bind(i))
		tabs.add_child(tab)
	show_tab(Tab.LOOK)
	UiMotion.intro([$SafeArea/VBox/Body/LeftCard, $SafeArea/VBox/Body/RightCard], 0.08)


func show_tab(tab: Tab) -> void:
	_tab = tab
	for i: int in tabs.get_child_count():
		(tabs.get_child(i) as Button).theme_type_variation = &"PrimaryButton" if i == tab else &""
	for old: Node in content.get_children():
		content.remove_child(old)
		old.queue_free()
	_swatches.clear()
	match tab:
		Tab.LOOK:
			_build_look()
		Tab.STATS:
			_build_stats()
		Tab.BADGES:
			_build_badges()
	UiMotion.intro(content.get_children(), 0.02)


# --- Look ---

func _build_look() -> void:
	var stars: int = GameState.total_stars()
	for slot: int in CosmeticData.Slot.values():
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.add_child(_label(tr(SLOT_KEYS[slot]), 24, INK))
		var swatches: HFlowContainer = HFlowContainer.new()
		swatches.add_theme_constant_override("h_separation", 6)
		for item: CosmeticData in ContentDB.cosmetics(slot):
			var swatch: SwatchButton = SwatchButton.new()
			swatch.item = item
			swatch.locked = not PlayerProfile.is_unlocked(item, stars)
			ScrollTap.connect_tap(swatch, _on_swatch.bind(swatch))
			swatches.add_child(swatch)
			_swatches.append(swatch)
		row.add_child(swatches)
		content.add_child(row)
	_hint = _label("", 22, MUTED)
	content.add_child(_hint)
	_refresh_swatches()


func _on_swatch(swatch: SwatchButton) -> void:
	if swatch.locked:
		_hint.text = tr("PROFILE_LOCKED") % swatch.item.stars_required
		UiMotion.bump(_hint, 1.08)
		return
	_hint.text = ""
	GameState.wear(swatch.item)
	preview.visual.apply_look(GameState.look_colors())
	_refresh_swatches()


func _refresh_swatches() -> void:
	for swatch: SwatchButton in _swatches:
		swatch.selected = GameState.worn(swatch.item.slot) == swatch.item


# --- Stats ---

func _build_stats() -> void:
	var facts: Dictionary = GameState.profile_facts()
	var trail_total: int = 0
	var viewpoint_total: int = 0
	for season: SeasonData in ContentDB.seasons():
		for trail: TrailData in season.trails:
			trail_total += 1
			viewpoint_total += trail.viewpoints.size()
	var rows: Array = [
		[UiIcon.Kind.MOUNTAIN, "STAT_TRAILS", "%d / %d" % [facts.trails_finished, trail_total]],
		[UiIcon.Kind.STAR, "STAT_STARS", "%d / %d" % [facts.stars, trail_total * 3]],
		[UiIcon.Kind.CAMERA, "STAT_POSTCARDS", "%d / %d" % [facts.photos, viewpoint_total]],
		[UiIcon.Kind.CAMERA, "STAT_PERFECT", str(facts.perfect_photos)],
		[UiIcon.Kind.BOOTS, "STAT_HIKES", str(facts.hikes)],
		[UiIcon.Kind.CLOCK, "STAT_TIME", _duration(GameState.profile.hike_seconds)],
		[UiIcon.Kind.MOUNTAIN, "STAT_TP", str(GameState.tp)],
		[UiIcon.Kind.STAR_EMPTY, "STAT_BADGES", "%d / %d" % [GameState.profile.badges.size(), ContentDB.badge_list().size()]],
	]
	if GameState.steps.enabled or GameState.steps.lifetime_steps > 0:
		rows.append([UiIcon.Kind.BOOTS, "STAT_REAL_KM", "%.1f km" % GameState.steps.lifetime_km(ContentDB.balance)])
	for r: Array in rows:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(BadgeView.icon_badge(r[0], Color("#F6D9CC"), Color("#E85D3F"), 46.0))
		var name_label: Label = _label(tr(r[1]), 26, INK)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_label(r[2], 28, INK, true))
		content.add_child(row)


func _duration(seconds: float) -> String:
	var minutes: int = int(seconds / 60.0)
	if minutes < 60:
		return tr("TIME_MINUTES") % minutes
	return tr("TIME_HOURS_MINUTES") % [minutes / 60, minutes % 60]


# --- Badges ---

func _build_badges() -> void:
	var facts: Dictionary = GameState.profile_facts()
	var all: Array[BadgeData] = ContentDB.badge_list()
	content.add_child(_label(tr("PROFILE_BADGES_COUNT") % [GameState.profile.badges.size(), all.size()], 24, MUTED))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	for badge: BadgeData in all:
		var earned: bool = GameState.profile.badges.has(String(badge.id))
		var tile: HBoxContainer = HBoxContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_constant_override("separation", 12)
		tile.add_child(BadgeView.medal(badge, earned, 64.0))
		var text: VBoxContainer = VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(_label(tr(badge.name_key), 24, INK if earned else MUTED, true))
		var desc: String = tr(badge.description_key)
		if not earned:
			desc += "  ·  %d/%d" % [BadgeRules.progress(badge, facts), badge.amount]
		var desc_label: Label = _label(desc, 18, MUTED)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(desc_label)
		tile.add_child(text)
		grid.add_child(tile)
	content.add_child(grid)


# --- Helpers ---

func _label(text: String, font_size: int, color: Color, bold: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", color)
	return label


func _style_name_field() -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = FIELD
	box.border_color = FIELD_LINE
	box.border_width_bottom = 4
	box.set_corner_radius_all(18)
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	name_edit.add_theme_stylebox_override("normal", box)
	var focus: StyleBoxFlat = box.duplicate()
	focus.border_color = Color("#E85D3F")
	name_edit.add_theme_stylebox_override("focus", focus)
	name_edit.add_theme_color_override("font_color", INK)
	name_edit.add_theme_color_override("font_placeholder_color", MUTED)
	name_edit.add_theme_color_override("caret_color", INK)


func _save_name() -> void:
	if PlayerProfile.clean_name(name_edit.text) != GameState.profile.hiker_name:
		GameState.set_hiker_name(name_edit.text)


func _go_back() -> void:
	_save_name()
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
