@tool
class_name Viewfinder
extends Control
## The camera overlay: everything outside the frame is dimmed, with corner brackets,
## a centre ring (the Perfect zone) and the film left as dots under the frame.

const DIM: Color = Color(0.168627, 0.176471, 0.258824, 0.45)
const LINE: Color = Color(1, 0.964706, 0.898039, 0.95)
const FAINT: Color = Color(1, 0.964706, 0.898039, 0.25)
const ASPECT: float = 1.5

## Half the frame's height in viewport pixels (from Balance.photo_frame_half).
@export var half_height: float = 190.0:
	set(v):
		half_height = v
		queue_redraw()
## Radius of the centre ring as a fraction of half_height (the Perfect zone).
@export var ring_fraction: float = 0.14:
	set(v):
		ring_fraction = v
		queue_redraw()
@export var shots_total: int = 3:
	set(v):
		shots_total = v
		queue_redraw()
@export var shots_left: int = 3:
	set(v):
		shots_left = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func frame_rect() -> Rect2:
	var half: Vector2 = Vector2(half_height * ASPECT, half_height)
	return Rect2(size * 0.5 - half, half * 2.0)


func _draw() -> void:
	var f: Rect2 = frame_rect()
	# Dim the four bands around the frame.
	draw_rect(Rect2(0, 0, size.x, f.position.y), DIM)
	draw_rect(Rect2(0, f.end.y, size.x, size.y - f.end.y), DIM)
	draw_rect(Rect2(0, f.position.y, f.position.x, f.size.y), DIM)
	draw_rect(Rect2(f.end.x, f.position.y, size.x - f.end.x, f.size.y), DIM)
	# Rule-of-thirds guides.
	for i: int in [1, 2]:
		var x: float = f.position.x + f.size.x * i / 3.0
		var y: float = f.position.y + f.size.y * i / 3.0
		draw_line(Vector2(x, f.position.y), Vector2(x, f.end.y), FAINT, 1.0, true)
		draw_line(Vector2(f.position.x, y), Vector2(f.end.x, y), FAINT, 1.0, true)
	# Corner brackets.
	var arm: float = 34.0
	var w: float = 5.0
	for corner: Vector2 in [f.position, Vector2(f.end.x, f.position.y), f.end, Vector2(f.position.x, f.end.y)]:
		var sx: float = 1.0 if corner.x < f.get_center().x else -1.0
		var sy: float = 1.0 if corner.y < f.get_center().y else -1.0
		draw_polyline(PackedVector2Array([corner + Vector2(0, sy * arm), corner, corner + Vector2(sx * arm, 0)]), LINE, w, true)
	var c: Vector2 = f.get_center()
	draw_arc(c, half_height * ring_fraction, 0.0, TAU, 40, LINE, 3.0, true)
	draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), LINE, 2.0, true)
	draw_line(c + Vector2(0, -10), c + Vector2(0, 10), LINE, 2.0, true)
	# Film left.
	var dot_y: float = f.end.y + 26.0
	for i: int in shots_total:
		var x: float = c.x + (float(i) - float(shots_total - 1) * 0.5) * 28.0
		if i < shots_left:
			draw_circle(Vector2(x, dot_y), 8.0, LINE, true, -1.0, true)
		else:
			draw_arc(Vector2(x, dot_y), 8.0, 0.0, TAU, 20, LINE, 2.0, true)
