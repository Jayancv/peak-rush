extends Control
## The travel journal: per season, a passport page of trail stamps and a gallery of
## postcards earned at viewpoints (bordered bronze/silver/gold by best photo).
## Tap a collected postcard to see it large. Built from ContentDB + GameState.

const STAMP_SIZE: Vector2 = Vector2(150, 150)
const CARD_SIZE: Vector2 = Vector2(210, 150)
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


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	enlarged.visible = false
	enlarged.gui_input.connect(_on_enlarged_input)
	for season: SeasonData in ContentDB.seasons():
		var tab: Button = Button.new()
		tab.text = tr(season.title_key)
		tab.custom_minimum_size = Vector2(0, 64)
		tab.add_theme_font_size_override("font_size", 24)
		tab.set_meta("season_id", season.id)
		tab.pressed.connect(show_season.bind(season))
		tabs.add_child(tab)
	if not ContentDB.seasons().is_empty():
		show_season(ContentDB.seasons()[0])


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
	count_label.text = tr("JOURNAL_COLLECTED") % [collected, total]


## How many postcards are shown (for tests).
func postcard_count() -> int:
	return postcards.get_child_count()


func _make_stamp(trail: TrailData) -> PassportStamp:
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
	button.pressed.connect(_enlarge.bind(trail, vp, q, season, i))
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
