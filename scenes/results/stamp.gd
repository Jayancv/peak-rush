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
	# Shrink long trail names until they fit inside the ring.
	var title_size: int = int(r * 0.26)
	var natural: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	if natural > w:
		title_size = maxi(int(title_size * w / natural), 8)
	draw_string(font, Vector2(c.x - w * 0.5, c.y + title_size * 0.15), title, HORIZONTAL_ALIGNMENT_CENTER, w, title_size, ink)
	if not subtitle.is_empty():
		draw_string(font, Vector2(c.x - w * 0.5, c.y + title_size * 0.15 + r * 0.32), subtitle, HORIZONTAL_ALIGNMENT_CENTER, w, int(r * 0.18), ink)
