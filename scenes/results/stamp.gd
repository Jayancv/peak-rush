@tool
class_name PassportStamp
extends Control
## The passport stamp a finished trail earns: a double ring with the trail's name
## and the date, drawn in code like an ink stamp.

@export var title: String = "TRAIL":
	set(v):
		title = v
		queue_redraw()
@export var subtitle: String = "":
	set(v):
		subtitle = v
		queue_redraw()
@export var ink: Color = Color("#B8432C"):
	set(v):
		ink = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 4.0
	var font: Font = get_theme_default_font()
	draw_arc(c, r, 0.0, TAU, 64, ink, 5.0, true)
	draw_arc(c, r - 10.0, 0.0, TAU, 64, ink, 2.0, true)
	# Little stars around the inner ring, like a real passport stamp.
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0 + PI / 8.0
		draw_circle(c + Vector2(cos(a), sin(a)) * (r - 20.0), 2.5, ink, true, -1.0, true)
	var w: float = r * 1.5
	var title_size: int = int(r * 0.26)
	var lines: PackedStringArray = _title_lines(font, w, title_size)
	# Shrink until the widest line fits inside the ring.
	var widest: float = 0.0
	for line: String in lines:
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x)
	if widest > w:
		title_size = maxi(int(title_size * w / widest), 8)
	var line_h: float = title_size * 1.1
	var top: float = c.y + title_size * 0.15 - line_h * (lines.size() - 1) * 0.5
	for i: int in lines.size():
		draw_string(font, Vector2(c.x - w * 0.5, top + line_h * i), lines[i], HORIZONTAL_ALIGNMENT_CENTER, w, title_size, ink)
	if not subtitle.is_empty():
		var below: float = top + line_h * (lines.size() - 1) + r * 0.32
		draw_string(font, Vector2(c.x - w * 0.5, below), subtitle, HORIZONTAL_ALIGNMENT_CENTER, w, int(r * 0.18), ink)


## One line if the title fits; otherwise split into two at the most even space.
func _title_lines(font: Font, w: float, font_size: int) -> PackedStringArray:
	var words: PackedStringArray = title.split(" ", false)
	if words.size() < 2 or font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= w:
		return PackedStringArray([title])
	var best: PackedStringArray = PackedStringArray([title])
	var best_diff: float = INF
	for cut: int in range(1, words.size()):
		var a: String = " ".join(words.slice(0, cut))
		var b: String = " ".join(words.slice(cut))
		var diff: float = absf(font.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x - font.get_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		if diff < best_diff:
			best_diff = diff
			best = PackedStringArray([a, b])
	return best
