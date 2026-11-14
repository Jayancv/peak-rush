class_name NotebookArt
extends Control
## Elsa's green notebook. `open` (0..1): closed cover -> the cover swings left (squashed,
## a cheap page-turn) to show two pages: a pencil sketch of fells on the left, and the
## right page left blank for the Labels the Prologue lays on top.

const COVER: Color = Color("#4E6B50")
const COVER_EDGE: Color = Color("#34493A")
const PAGE: Color = Color("#F6ECD6")
const PAGE_SHADE: Color = Color("#E4D6B8")
const PENCIL: Color = Color("#6E6458")
const INK: Color = Color("#2B2D42")
const CREAM: Color = Color("#FFF6E5")

var open: float = 0.0:
	set(v):
		open = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The right-hand page, where the Prologue places the entry's text.
func right_page() -> Rect2:
	return Rect2(Vector2(size.x * 0.5 + 34, 34), Vector2(size.x * 0.5 - 68, size.y - 68))


## The closed book is the right half of the spread (the Prologue slides it to the centre);
## opening shrinks the cover towards the spine while the pages fade in underneath.
func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var half: float = w * 0.5
	if open > 0.0:
		var a: float = clampf(open * 1.6, 0.0, 1.0)
		draw_rect(Rect2(-8, -8, w + 16, h + 16), Color(COVER_EDGE, a))
		draw_rect(Rect2(0, 0, w, h), Color(PAGE, a))
		draw_rect(Rect2(half - 10, 0, 20, h), Color(PAGE_SHADE, a))
		for i: int in 12:
			var y: float = 60.0 + i * (h - 100.0) / 12.0
			draw_line(Vector2(half + 30, y), Vector2(w - 30, y), Color(PAGE_SHADE, 0.7 * a), 1.5)
		_draw_sketch(Rect2(30, 30, half - 60, h - 60), a)
	if open < 1.0:
		var rect: Rect2 = Rect2(Vector2(half, 0), Vector2(half * (1.0 - open), h))
		draw_rect(rect.grow(6), COVER_EDGE)
		draw_rect(rect, COVER)
		if open <= 0.0:
			_draw_cover_label(rect)


func _draw_cover_label(rect: Rect2) -> void:
	var label: Rect2 = Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.3), Vector2(rect.size.x * 0.64, rect.size.y * 0.24))
	draw_rect(label, CREAM)
	draw_rect(label, COVER_EDGE, false, 2.0)
	var font: Font = get_theme_default_font()
	var lines: PackedStringArray = tr("PROLOGUE_NOTEBOOK").split("\n")
	for i: int in lines.size():
		var fs: int = 28
		var tw: float = font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(label.get_center().x - tw * 0.5, label.position.y + 44 + i * 36), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	# An elastic band holding it shut.
	draw_rect(Rect2(rect.position.x + rect.size.x * 0.88, rect.position.y, 10, rect.size.y), Color("#2E2A28"))


## Pencil fells and a little hiker, the way she drew them in the margins.
func _draw_sketch(r: Rect2, a: float) -> void:
	var base: float = r.position.y + r.size.y * 0.7
	var peaks: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.18, 0.42), Vector2(0.32, 0.2), Vector2(0.5, 0.62),
		Vector2(0.66, 0.3), Vector2(0.8, 0.48), Vector2(1.0, 0.1)]
	var line: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in peaks:
		line.append(Vector2(r.position.x + r.size.x * p.x, base - r.size.y * 0.5 * p.y))
	draw_polyline(line, Color(PENCIL, a), 2.5, true)
	# Hatching under the ridge, a lake, and the trail winding up.
	for i: int in 14:
		var x: float = r.position.x + r.size.x * (0.05 + i * 0.065)
		draw_line(Vector2(x, base + 4), Vector2(x - 14, base + 22), Color(PENCIL, 0.5 * a), 1.5)
	draw_arc(Vector2(r.position.x + r.size.x * 0.3, base + 50), 60.0, PI * 1.05, PI * 1.95, 16, Color(PENCIL, 0.7 * a), 2.0)
	var trail: PackedVector2Array = PackedVector2Array([Vector2(r.position.x + r.size.x * 0.75, r.end.y - 10),
		Vector2(r.position.x + r.size.x * 0.6, base + 40), Vector2(r.position.x + r.size.x * 0.7, base + 10),
		Vector2(r.position.x + r.size.x * 0.5, base - r.size.y * 0.31)])
	for i: int in range(1, trail.size()):
		draw_dashed_line(trail[i - 1], trail[i], Color(PENCIL, a), 2.0, 7.0)
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(r.position.x + 8, r.end.y - 6), tr("PROLOGUE_SKETCH"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(PENCIL, a))
