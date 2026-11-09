@tool
class_name Postcard
extends Control
## A postcard in the journal. Real postcard art is a Texture2D on the ViewpointData;
## until it exists this draws a placeholder: a little landscape in the season colour
## with the viewpoint and trail names, framed bronze/silver/gold by photo quality.
## An uncollected postcard shows as a blank card with a question mark.

const PAPER: Color = Color("#FFF6E5")
const INK: Color = Color("#2B2D42")
const SKY: Color = Color("#A8D8EA")
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


## Sky, a sun and two hill silhouettes in the season's colour.
func _draw_placeholder_scene(pic: Rect2) -> void:
	draw_rect(pic, SKY, true)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = art_seed
	draw_circle(pic.position + Vector2(pic.size.x * rng.randf_range(0.2, 0.8), pic.size.y * 0.3), pic.size.y * 0.12, Color("#FFF1C9"), true, -1.0, true)
	for layer: int in 2:
		var col: Color = theme_color.lightened(0.25) if layer == 0 else theme_color
		var pts: PackedVector2Array = PackedVector2Array()
		var base: float = pic.end.y
		var steps: int = 8
		for i: int in steps + 1:
			var x: float = pic.position.x + pic.size.x * float(i) / float(steps)
			var h: float = rng.randf_range(0.25, 0.55) if layer == 0 else rng.randf_range(0.1, 0.32)
			pts.append(Vector2(x, base - pic.size.y * h))
		pts.append(Vector2(pic.end.x, base))
		pts.append(Vector2(pic.position.x, base))
		draw_colored_polygon(pts, col)
