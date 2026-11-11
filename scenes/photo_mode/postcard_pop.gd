class_name PostcardPop
extends Control
## The journal reward, right when it's earned: after a new (or better) shot, the postcard
## slides up in the corner of the viewfinder with "New postcard!" for a moment.

const CARD_SIZE: Vector2 = Vector2(240, 173)
const HOLD_SECONDS: float = 1.6
const MARGIN: float = 28.0


## "" when the shot doesn't beat the journal (no pop then).
static func caption_for(quality: int, saved_quality: int) -> String:
	if quality <= StarRating.PhotoQuality.NONE or quality <= saved_quality:
		return ""
	return "PHOTO_NEW_POSTCARD" if saved_quality <= StarRating.PhotoQuality.NONE else "PHOTO_BETTER_POSTCARD"


static func pop(parent: Control, trail: TrailData, vp: ViewpointData, quality: int, caption_key: String) -> PostcardPop:
	var p: PostcardPop = PostcardPop.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	p._build(trail, vp, quality, caption_key)
	return p


func _build(trail: TrailData, vp: ViewpointData, quality: int, caption_key: String) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var label: Label = Label.new()
	label.text = tr(caption_key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#FFF6E5"))
	label.add_theme_color_override("font_outline_color", Color("#2B2D42"))
	label.add_theme_constant_override("outline_size", 8)
	box.add_child(label)
	var card: Postcard = Postcard.new()
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.title = tr(vp.name_key)
	card.subtitle = tr(trail.name_key)
	card.quality = quality
	card.motif = vp.motif
	card.night = trail.night
	card.art = vp.postcard
	card.art_seed = hash(vp.id)
	var season: SeasonData = ContentDB.get_season(trail.season_id)
	if season != null:
		card.theme_color = season.theme_color
	card.rotation = deg_to_rad(-3.0)
	box.add_child(card)
	var view: Vector2 = get_parent_area_size()
	var size_now: Vector2 = box.get_combined_minimum_size()
	var rest: Vector2 = Vector2(view.x - size_now.x - MARGIN, view.y - size_now.y - MARGIN * 3.0)
	position = rest + Vector2(0, size_now.y + MARGIN * 4.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", rest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_SECONDS)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
