extends Control
## Pick a trail: one tab per season, a scrolling row of trail cards per tab.
## Everything is built from ContentDB, so a new season shows up here without code changes.

const CARD_SCENE: PackedScene = preload("res://scenes/trail_select/trail_card.tscn")

@export var tabs: HBoxContainer
@export var cards: HBoxContainer
@export var scroll: ScrollContainer
@export var back_button: Button
@export var tp_label: Label
@export var stars_label: Label
@export var gear_button: Button

var _season: SeasonData


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	gear_button.pressed.connect(_open_gear)
	AudioManager.enter_menu()
	tp_label.text = tr("HUD_TP") % GameState.tp
	stars_label.text = str(GameState.total_stars())
	var current: TrailData = ContentDB.get_trail(GameState.current_trail_id)
	var start: SeasonData = ContentDB.get_season(current.season_id) if current != null else null
	if start == null and not ContentDB.seasons().is_empty():
		start = ContentDB.seasons()[0]
	_build_tabs()
	if start != null:
		show_season(start)


func show_season(season: SeasonData) -> void:
	_season = season
	for tab: Node in tabs.get_children():
		var button: Button = tab as Button
		if button == null or not button.has_meta("season_id"):
			continue
		var active: bool = button.get_meta("season_id") == season.id
		button.theme_type_variation = &"PrimaryButton" if active else &""
	for old: Node in cards.get_children():
		old.queue_free()
	var focus_card: TrailCard = null
	var list: Array[TrailData] = season.ordered_trails()
	for i: int in list.size():
		var trail: TrailData = list[i]
		var card: TrailCard = CARD_SCENE.instantiate() as TrailCard
		cards.add_child(card)
		var previous: TrailData = ContentDB.previous_trail(trail.id)
		var hint: String = tr("SELECT_LOCKED") % tr(previous.name_key) if previous != null else ""
		var unlocked: bool = GameState.is_unlocked(trail)
		card.setup(i + 1, trail, GameState.record(trail.id), unlocked, season.theme_color, hint)
		ScrollTap.connect_tap(card, _start.bind(trail))
		# Scroll to the first open trail not finished yet (where the player left off).
		if focus_card == null and unlocked and not GameState.is_completed(trail.id):
			focus_card = card
	UiMotion.intro(cards.get_children(), 0.08)
	if focus_card != null:
		_scroll_to.call_deferred(focus_card)


## Number of trail cards shown (for tests).
func card_count() -> int:
	return cards.get_child_count()


func _build_tabs() -> void:
	for season: SeasonData in ContentDB.seasons():
		var tab: Button = Button.new()
		tab.text = tr(season.title_key)
		tab.custom_minimum_size = Vector2(0, 68)
		tab.add_theme_font_size_override("font_size", 26)
		tab.set_meta("season_id", season.id)
		tab.pressed.connect(show_season.bind(season))
		tabs.add_child(tab)
	_add_stroll_switch()


## "Stroll" at the end of the tabs row: hikes without the daylight clock (the daily is never a stroll).
func _add_stroll_switch() -> void:
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	var label: Label = Label.new()
	label.text = tr("SELECT_STROLL")
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#FFF6E5"))
	label.add_theme_color_override("font_outline_color", Color("#2B2D42"))
	label.add_theme_constant_override("outline_size", 6)
	tabs.add_child(label)
	var toggle: ToggleSwitch = ToggleSwitch.new()
	toggle.name = "StrollSwitch"
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs.add_child(toggle)
	toggle.set_pressed_no_signal(bool(GameState.settings.get("stroll_mode", false)))
	toggle.sync()
	toggle.toggled.connect(func(on: bool) -> void: GameState.set_setting("stroll_mode", on))
	_add_switch("SELECT_GHOST", "show_ghost", true, "GhostSwitch")


func _add_switch(label_key: String, setting: String, default: bool, node_name: String) -> void:
	var label: Label = Label.new()
	label.text = tr(label_key)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#FFF6E5"))
	label.add_theme_color_override("font_outline_color", Color("#2B2D42"))
	label.add_theme_constant_override("outline_size", 6)
	tabs.add_child(label)
	var toggle: ToggleSwitch = ToggleSwitch.new()
	toggle.name = node_name
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tabs.add_child(toggle)
	toggle.set_pressed_no_signal(bool(GameState.settings.get(setting, default)))
	toggle.sync()
	toggle.toggled.connect(func(on: bool) -> void: GameState.set_setting(setting, on))


func _scroll_to(card: Control) -> void:
	scroll.ensure_control_visible(card)


func _start(trail: TrailData) -> void:
	GameState.current_trail_id = trail.id
	SceneRouter.go_to(SceneRouter.TRAIL_RUNNER)


## Gear is picked before a hike, so the gear screen comes back here.
func _open_gear() -> void:
	GearScreen.return_to = SceneRouter.TRAIL_SELECT
	SceneRouter.go_to(SceneRouter.GEAR)


func _go_back() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
