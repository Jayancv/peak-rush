class_name SeasonFinale
extends Control
## The end-of-season moment: shown on the results screen when a summit completes the
## last unfinished trail of a season. A postcard for the season, the season's totals
## and a thank-you. It can only happen once per season (first completion of the last trail).

const INK: Color = Color("#2B2D42")
const MUTED: Color = Color(0.168627, 0.176471, 0.258824, 0.7)


## The season this result just finished, or null.
static func finished_season(result: Dictionary, trail: TrailData) -> SeasonData:
	if not bool(result.get("first_completion", false)):
		return null
	var season: SeasonData = ContentDB.get_season(trail.season_id)
	if season == null:
		return null
	for t: TrailData in season.trails:
		if not GameState.is_completed(t.id):
			return null
	return season


static func open(parent: Control, season: SeasonData) -> SeasonFinale:
	var finale: SeasonFinale = SeasonFinale.new()
	parent.add_child(finale)
	finale._build(season)
	return finale


## Totals over the season's trails: stars, photos and finds.
static func totals(season: SeasonData) -> Dictionary:
	var out: Dictionary = {"stars": 0, "stars_max": 0, "photos": 0, "photos_max": 0, "finds": 0, "finds_max": 0}
	for t: TrailData in season.trails:
		var rec: Dictionary = GameState.record(t.id)
		out.stars += StarRating.count(int(rec.stars))
		out.stars_max += 3
		for vp: ViewpointData in t.viewpoints:
			out.photos += 1 if int(rec.photos.get(String(vp.id), 0)) > 0 else 0
		out.photos_max += t.viewpoints.size()
		out.finds += (rec.get("finds", []) as Array).size()
		out.finds_max += t.finds.size()
	return out


func _build(season: SeasonData) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.168627, 0.176471, 0.258824, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	center.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	panel.add_child(row)
	var card: Postcard = Postcard.new()
	card.custom_minimum_size = Vector2(300, 216)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.title = tr(season.title_key)
	card.subtitle = tr("FINALE_POSTCARD")
	card.theme_color = season.theme_color
	card.quality = 3
	card.art = season.banner
	card.art_seed = hash(season.id)
	# The season's last view (its finale trail), unless the season has a painted banner.
	var last: TrailData = season.ordered_trails().back() if not season.trails.is_empty() else null
	if last != null and not last.viewpoints.is_empty():
		card.motif = last.viewpoints.back().motif
		card.night = last.night
	card.rotation = deg_to_rad(-3.0)
	row.add_child(card)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(400, 0)
	row.add_child(box)
	box.add_child(_label(tr("FINALE_TITLE"), 40, INK))
	box.add_child(_label(tr("FINALE_SEASON") % tr(season.title_key), 26, season.theme_color.darkened(0.25)))
	var t: Dictionary = totals(season)
	box.add_child(_label(tr("FINALE_STATS") % [season.trails.size(), t.stars, t.stars_max, t.photos, t.photos_max, t.finds, t.finds_max], 22, INK))
	box.add_child(_label(tr("FINALE_THANKS"), 20, MUTED))
	var go: Button = Button.new()
	go.text = tr("FINALE_CONTINUE")
	go.theme_type_variation = &"PrimaryButton"
	go.custom_minimum_size = Vector2(220, 68)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(queue_free)
	box.add_child(go)
	AudioManager.play_summit()
	UiMotion.intro([panel, card])


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		queue_free()
