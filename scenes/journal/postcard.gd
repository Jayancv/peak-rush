@tool
class_name Postcard
extends Control
## A postcard in the journal. Its picture is the ViewpointData.postcard texture
## (rendered from the game world by tools/postcards); without one it draws PostcardArt's
## scene for the viewpoint's motif. Either way it's styled as a printed postcard
## with the viewpoint and trail names, framed bronze/silver/gold by photo quality.
## An uncollected postcard shows as a blank card with a question mark.

const PAPER: Color = Color("#FFF6E5")
const TITLE_FONT: Font = preload("res://shared_art/title_font.tres")
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
	# A printed photo with a thin white border, a caption strip, and a stamp + postmark.
	var pic: Rect2 = Rect2(inner.position + Vector2(border, border), Vector2(inner.size.x - border * 2.0, inner.size.y * 0.7))
	var print_edge: float = maxf(size.x * 0.012, 2.0)
	draw_rect(pic.grow(print_edge), Color.WHITE, true)
	if art != null:
		_draw_photo(pic)
	else:
		_draw_placeholder_scene(pic)
	_draw_vignette(pic)
	var strip: Rect2 = Rect2(Vector2(pic.position.x, pic.end.y + print_edge * 2.0), Vector2(pic.size.x, inner.end.y - pic.end.y - print_edge * 2.0 - border * 0.5))
	var stamp_h: float = strip.size.y * 0.86
	var stamp: Rect2 = Rect2(Vector2(strip.end.x - stamp_h * 0.82, strip.get_center().y - stamp_h * 0.5), Vector2(stamp_h * 0.82, stamp_h))
	var title_size: int = maxi(int(size.y * 0.085), 10)
	var sub_size: int = maxi(int(size.y * 0.058), 8)
	var text_w: float = stamp.position.x - strip.position.x - border
	var text_top: float = strip.get_center().y - (title_size + sub_size * 1.3) * 0.5
	draw_string(TITLE_FONT, Vector2(strip.position.x + border * 0.4, text_top + title_size), title, HORIZONTAL_ALIGNMENT_LEFT, text_w, title_size, INK)
	draw_string(font, Vector2(strip.position.x + border * 0.4, text_top + title_size + sub_size * 1.3), subtitle, HORIZONTAL_ALIGNMENT_LEFT, text_w, sub_size, Color(INK, 0.6))
	_draw_stamp(stamp)


## The snapshot, centre-cropped to the print's shape, warmed a touch like a printed photo.
func _draw_photo(pic: Rect2) -> void:
	var tex: Vector2 = art.get_size()
	var want: float = pic.size.x / pic.size.y
	var src: Rect2 = Rect2(Vector2.ZERO, tex)
	if tex.x / tex.y > want:
		src.size.x = tex.y * want
		src.position.x = (tex.x - src.size.x) * 0.5
	else:
		src.size.y = tex.x / want
		src.position.y = (tex.y - src.size.y) * 0.45
	draw_texture_rect_region(art, pic, src, Color(1.0, 0.98, 0.93))


## Soft darkening towards the print's edges (old camera lenses did this).
func _draw_vignette(pic: Rect2) -> void:
	var d: float = minf(pic.size.x, pic.size.y) * 0.16
	var dark: Color = Color(0.1, 0.08, 0.05, 0.22)
	var clear: Color = Color(dark, 0.0)
	var o: Array[Vector2] = [pic.position, Vector2(pic.end.x, pic.position.y), pic.end, Vector2(pic.position.x, pic.end.y)]
	var i: Array[Vector2] = [pic.position + Vector2(d, d), Vector2(pic.end.x - d, pic.position.y + d), pic.end - Vector2(d, d), Vector2(pic.position.x + d, pic.end.y - d)]
	for k: int in 4:
		var n: int = (k + 1) % 4
		draw_polygon(PackedVector2Array([o[k], o[n], i[n], i[k]]), PackedColorArray([dark, dark, clear, clear]))


## A perforated stamp in the season colour with a postmark over its corner.
func _draw_stamp(r: Rect2) -> void:
	draw_rect(r, Color.WHITE, true)
	var hole: float = r.size.x * 0.06
	var steps: int = 7
	for k: int in steps + 1:
		var t: float = float(k) / steps
		for p: Vector2 in [Vector2(r.position.x + r.size.x * t, r.position.y), Vector2(r.position.x + r.size.x * t, r.end.y),
				Vector2(r.position.x, r.position.y + r.size.y * t), Vector2(r.end.x, r.position.y + r.size.y * t)]:
			draw_circle(p, hole, PAPER, true, -1.0, true)
	var face: Rect2 = r.grow(-r.size.x * 0.14)
	draw_rect(face, theme_color, true)
	draw_circle(face.position + face.size * Vector2(0.7, 0.3), face.size.x * 0.13, Color("#FFF1C9"), true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([face.position + face.size * Vector2(0.0, 1.0), face.position + face.size * Vector2(0.38, 0.42),
		face.position + face.size * Vector2(0.62, 0.72), face.position + face.size * Vector2(0.78, 0.55), face.end]), theme_color.darkened(0.3))
	var mark: Color = Color(INK, 0.45)
	var c: Vector2 = r.position + Vector2(0.0, r.size.y * 0.62)
	var rad: float = r.size.y * 0.36
	var w: float = maxf(r.size.x * 0.035, 1.0)
	draw_arc(c, rad, 0.0, TAU, 32, mark, w, true)
	draw_arc(c, rad * 0.72, 0.0, TAU, 28, mark, w * 0.7, true)
	for k: int in 3:
		var pts: PackedVector2Array = PackedVector2Array()
		var y: float = c.y - rad * 0.5 + k * rad * 0.5
		for j: int in 13:
			var x: float = c.x - rad * 3.2 + j * rad * 0.22
			pts.append(Vector2(x, y + sin(j * 1.2) * rad * 0.1))
		draw_polyline(pts, mark, w * 0.8, true)


func _draw_placeholder_scene(pic: Rect2) -> void:
	PostcardArt.draw(self, pic, motif, night, theme_color, art_seed)
