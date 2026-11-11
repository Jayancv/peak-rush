@tool
class_name Postcard
extends Control
## A postcard in the journal. Real postcard art is a Texture2D on the ViewpointData;
## until it exists this draws a placeholder (PostcardArt: a scene per viewpoint motif)
## with the viewpoint and trail names, framed bronze/silver/gold by photo quality.
## An uncollected postcard shows as a blank card with a question mark.

const PAPER: Color = Color("#FFF6E5")
const INK: Color = Color("#2B2D42")
const BRONZE: Color = Color("#C88A52")
const SILVER: Color = Color("#AEB6C0")
const GOLD: Color = Color("#E6B94A")
const BLANK: Color = Color(0.168627, 0.176471, 0.258824, 0.18)

@export var title: String = "":
	set(v):
		title = v
		queue_redraw()
@export var subtitle: String = "":
	set(v):
		subtitle = v
		queue_redraw()
@export var theme_color: Color = Color("#5E8C7A"):
	set(v):
		theme_color = v
		queue_redraw()
## StarRating.PhotoQuality; NONE draws the blank "not collected" card.
@export_range(0, 3) var quality: int = 0:
	set(v):
		quality = v
		queue_redraw()
@export var art: Texture2D:
	set(v):
		art = v
		queue_redraw()
## ViewpointData.Motif: which little scene the placeholder draws (PostcardArt).
@export var motif: int = 0:
	set(v):
		motif = v
		queue_redraw()
## Night trails get a night sky.
@export var night: bool = false:
	set(v):
		night = v
		queue_redraw()
## Varies the placeholder landscape between postcards.
@export var art_seed: int = 0:
	set(v):
		art_seed = v
		queue_redraw()


static func border_color(q: int) -> Color:
	match q:
		StarRating.PhotoQuality.PERFECT:
			return GOLD
		StarRating.PhotoQuality.GREAT:
			return SILVER
		StarRating.PhotoQuality.GOOD:
			return BRONZE
	return BLANK


func is_collected() -> bool:
	return quality > StarRating.PhotoQuality.NONE


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	var border: float = maxf(size.x * 0.035, 4.0)
	draw_rect(r, border_color(quality) if is_collected() else Color(PAPER, 0.6), true)
	var inner: Rect2 = r.grow(-border)
	draw_rect(inner, PAPER, true)
	var font: Font = get_theme_default_font()
	if not is_collected():
		var q_size: int = int(size.y * 0.32)
		draw_string(font, Vector2(inner.position.x, inner.get_center().y + q_size * 0.35), "?", HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, q_size, BLANK)
		return
	var pic: Rect2 = Rect2(inner.position + Vector2(border, border), Vector2(inner.size.x - border * 2.0, inner.size.y * 0.66))
	if art != null:
		draw_texture_rect(art, pic, false)
	else:
		_draw_placeholder_scene(pic)
	var text_top: float = pic.end.y + inner.size.y * 0.04
	var title_size: int = maxi(int(size.y * 0.085), 10)
	draw_string(font, Vector2(inner.position.x, text_top + title_size), title, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, title_size, INK)
	var sub_size: int = maxi(int(size.y * 0.06), 8)
	draw_string(font, Vector2(inner.position.x, text_top + title_size + sub_size * 1.5), subtitle, HORIZONTAL_ALIGNMENT_CENTER, inner.size.x, sub_size, Color(INK, 0.6))


func _draw_placeholder_scene(pic: Rect2) -> void:
	PostcardArt.draw(self, pic, motif, night, theme_color, art_seed)
