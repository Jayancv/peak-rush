extends Control
## The travel journal: per season, a passport page of trail stamps and a gallery of
## postcards earned at viewpoints (bordered bronze/silver/gold by best photo).
## Tap a collected postcard to see it large. Built from ContentDB + GameState.

## Three stamps per row; the passport scrolls if a season ever has more than fit.
const STAMP_SIZE: Vector2 = Vector2(108, 108)
const CARD_SIZE: Vector2 = Vector2(190, 136)
const CARD_GAP: int = 18
## Uncompleted trails show as a faint stamp outline.
const FADED_INK: Color = Color(0.168627, 0.176471, 0.258824, 0.18)
const INK: Color = Color("#B8432C")

@export var tabs: HBoxContainer
@export var stamps: GridContainer
@export var postcards: GridContainer
@export var count_label: Label
@export var back_button: Button
@export var enlarged: Control
@export var enlarged_card: Postcard

var _season: SeasonData
var _finds_grid: GridContainer
var _finds_scroll: ScrollContainer
var _page_buttons: Array[Button] = []
var _showing_finds: bool = false
## [collected, total] for the season's postcards and finds; the counter shows the open page's.
var _postcard_count: Vector2i = Vector2i.ZERO
var _find_count: Vector2i = Vector2i.ZERO


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	AudioManager.enter_menu()
	enlarged.visible = false
	enlarged.gui_input.connect(_on_enlarged_input)
	# As many postcard columns as fit: phones range from 16:9 to 20:9 (and tablets 4:3).
	var scroll: Control = postcards.get_parent() as Control
	scroll.resized.connect(func() -> void: _fit_columns(scroll.size.x))
	for season: SeasonData in ContentDB.seasons():
		var tab: Button = Button.new()
		tab.text = tr(season.title_key)
		tab.custom_minimum_size = Vector2(0, 64)
		tab.add_theme_font_size_override("font_size", 24)
		tab.set_meta("season_id", season.id)
		tab.pressed.connect(show_season.bind(season))
		tabs.add_child(tab)
	_build_finds_page()
	if not ContentDB.seasons().is_empty():
		show_season(ContentDB.seasons()[0])


## Swaps the postcards heading for a Postcards / Finds switch and adds the finds grid.
func _build_finds_page() -> void:
	var heading: Label = $SafeArea/VBox/Pages/Postcards/VBox/Label as Label
	var page: VBoxContainer = heading.get_parent() as VBoxContainer
	var switch: HBoxContainer = HBoxContainer.new()
	switch.add_theme_constant_override("separation", 8)
	for i: int in 2:
		var b: Button = Button.new()
		b.text = tr("JOURNAL_POSTCARDS" if i == 0 else "JOURNAL_FINDS_TAB")
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_show_page.bind(i == 1))
		switch.add_child(b)
		_page_buttons.append(b)
	page.add_child(switch)
	page.move_child(switch, heading.get_index())
	heading.visible = false
	_finds_scroll = ScrollContainer.new()
	_finds_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# SHOW_NEVER, not DISABLED: a disabled axis makes the grid's width the scroll's
	# minimum width, so more columns widened the page, which made room for more columns...
	_finds_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	page.add_child(_finds_scroll)
	_finds_grid = GridContainer.new()
	_finds_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finds_grid.add_theme_constant_override("h_separation", CARD_GAP)
	_finds_grid.add_theme_constant_override("v_separation", CARD_GAP)
	_finds_scroll.add_child(_finds_grid)
	_finds_scroll.resized.connect(_fit_find_columns)
	_show_page(false)


func _show_page(finds: bool) -> void:
	_showing_finds = finds
	(postcards.get_parent() as Control).visible = not finds
	_finds_scroll.visible = finds
	for i: int in _page_buttons.size():
		_page_buttons[i].theme_type_variation = &"PrimaryButton" if (i == 1) == finds else &""
	_update_count()
	if finds:
		UiMotion.intro(_finds_grid.get_children(), 0.05)


func _update_count() -> void:
	var c: Vector2i = _find_count if _showing_finds else _postcard_count
	count_label.text = tr("JOURNAL_COLLECTED") % [c.x, c.y]


func show_season(season: SeasonData) -> void:
	_season = season
	for tab: Node in tabs.get_children():
		(tab as Button).theme_type_variation = &"PrimaryButton" if tab.get_meta("season_id") == season.id else &""
	for old: Node in stamps.get_children() + postcards.get_children():
		old.queue_free()
	var collected: int = 0
	var total: int = 0
	for trail: TrailData in season.ordered_trails():
		stamps.add_child(_make_stamp(trail))
		var record: Dictionary = GameState.record(trail.id)
		for i: int in trail.viewpoints.size():
			var vp: ViewpointData = trail.viewpoints[i]
			var q: int = int(record.photos.get(String(vp.id), StarRating.PhotoQuality.NONE))
			total += 1
			if q > StarRating.PhotoQuality.NONE:
				collected += 1
			postcards.add_child(_make_postcard(trail, vp, q, season, i))
	_postcard_count = Vector2i(collected, total)
	_find_count = Vector2i.ZERO
	for old: Node in _finds_grid.get_children():
		old.queue_free()
	for trail: TrailData in season.ordered_trails():
		var have: Array = GameState.record(trail.id).get("finds", [])
		for f: FindData in trail.finds:
			var found: bool = have.has(String(f.id))
			_find_count += Vector2i(1 if found else 0, 1)
			_finds_grid.add_child(FindCard.create(f, trail, found))
	_fit_find_columns()
	_update_count()
	UiMotion.intro(stamps.get_children() + postcards.get_children(), 0.08)


## Columns that fit beside the vertical scrollbar.
func _fit_find_columns() -> void:
	var width: float = _finds_scroll.size.x - _finds_scroll.get_v_scroll_bar().get_combined_minimum_size().x
	# The card's real width includes the CardPanel padding, so measure one.
	var card_w: float = FindCard.SIZE.x
	if _finds_grid.get_child_count() > 0:
		card_w = maxf(card_w, (_finds_grid.get_child(0) as Control).get_combined_minimum_size().x)
	_finds_grid.columns = maxi(int((width + CARD_GAP) / (card_w + CARD_GAP)), 1)


func _fit_columns(width: float) -> void:
	postcards.columns = maxi(1, int((width + CARD_GAP) / (CARD_SIZE.x + CARD_GAP)))


## How many postcards are shown (for tests).
func postcard_count() -> int:
	return postcards.get_child_count()


## The trail's stamp, with how many of its finds have been collected underneath.
func _make_stamp(trail: TrailData) -> Control:
	var cell: VBoxContainer = VBoxContainer.new()
	cell.add_theme_constant_override("separation", 2)
	cell.add_child(_stamp_art(trail))
	if not trail.finds.is_empty():
		var found: int = (GameState.record(trail.id).get("finds", []) as Array).size()
		var label: Label = Label.new()
		label.text = tr("JOURNAL_FINDS") % [found, trail.finds.size()]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("#5E8C4A") if found >= trail.finds.size() else Color(0.168627, 0.176471, 0.258824, 0.6))
		cell.add_child(label)
	return cell


func _stamp_art(trail: TrailData) -> PassportStamp:
	var stamp: PassportStamp = PassportStamp.new()
	stamp.custom_minimum_size = STAMP_SIZE
	var done: bool = GameState.is_completed(trail.id)
	stamp.title = tr(trail.name_key).to_upper() if done else "?"
	stamp.subtitle = TimeFormat.mmss(GameState.best_time(trail.id)) if done else ""
	stamp.ink = INK if done else FADED_INK
	# A slight tilt per stamp, so the page looks hand-stamped.
	stamp.rotation = deg_to_rad(float(hash(trail.id) % 13) - 6.0)
	return stamp


func _make_postcard(trail: TrailData, vp: ViewpointData, q: int, season: SeasonData, i: int) -> Button:
	var button: Button = Button.new()
	button.flat = true
	button.custom_minimum_size = CARD_SIZE
	button.disabled = q == StarRating.PhotoQuality.NONE
	var card: Postcard = _postcard_for(trail, vp, q, season, i)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(card)
	ScrollTap.connect_tap(button, _enlarge.bind(trail, vp, q, season, i))
	return button


func _postcard_for(trail: TrailData, vp: ViewpointData, q: int, season: SeasonData, i: int) -> Postcard:
	var card: Postcard = Postcard.new()
	_fill(card, trail, vp, q, season, i)
	return card


func _fill(card: Postcard, trail: TrailData, vp: ViewpointData, q: int, season: SeasonData, i: int) -> void:
	card.title = tr(vp.name_key)
	card.subtitle = tr(trail.name_key)
	card.quality = q
	card.theme_color = season.theme_color
	card.art = vp.postcard
	card.art_seed = hash(vp.id) + i


func _enlarge(trail: TrailData, vp: ViewpointData, q: int, season: SeasonData, i: int) -> void:
	_fill(enlarged_card, trail, vp, q, season, i)
	enlarged.visible = true
	enlarged_card.pivot_offset = enlarged_card.size * 0.5
	enlarged_card.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(enlarged_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _on_enlarged_input(event: InputEvent) -> void:
	var press: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if press:
		enlarged.visible = false
		accept_event()


func _go_back() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if enlarged.visible:
			enlarged.visible = false
		else:
			_go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if enlarged.visible:
			enlarged.visible = false
		else:
			_go_back()
