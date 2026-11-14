class_name AtticArt
extends Control
## Grandma Elsa's attic for the opening: dusk light through a round window, roof beams,
## old skis, and the box with her hiking things. `lid_open` (0..1) swings the flaps open.

const WALL_TOP: Color = Color("#3B2B25")
const WALL_LOW: Color = Color("#251A1A")
const BEAM: Color = Color("#1E1414")
const FLOOR: Color = Color("#2F211C")
const BOARD: Color = Color("#251A16")
const SKY: Color = Color("#F6C27A")
const SKY_LOW: Color = Color("#E98F5A")
const LIGHT: Color = Color(1.0, 0.86, 0.6, 0.13)
const BOX: Color = Color("#B88A58")
const BOX_SIDE: Color = Color("#8E6640")
const BOX_INSIDE: Color = Color("#4A3322")
const INK: Color = Color("#2B2D42")

var lid_open: float = 0.0:
	set(v):
		lid_open = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The box's mouth in local pixels (the notebook rises out of it).
func box_top() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.74)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var floor_y: float = h * 0.8
	var bands: int = 12
	for i: int in bands:
		var t: float = float(i) / float(bands)
		draw_rect(Rect2(0, h * t, w, h / bands + 1.0), WALL_TOP.lerp(WALL_LOW, t))
	# Round window with the evening sky, and the shaft of light it throws on the floor.
	var win: Vector2 = Vector2(w * 0.68, h * 0.3)
	var r: float = h * 0.11
	draw_colored_polygon(PackedVector2Array([win + Vector2(-r * 0.7, 0), win + Vector2(r * 0.7, 0),
		Vector2(w * 0.62, floor_y + 30), Vector2(w * 0.3, floor_y + 30)]), LIGHT)
	draw_circle(win, r + 10.0, BEAM)
	draw_circle(win, r, SKY, true, -1.0, true)
	draw_colored_polygon(ShapeUtil.ellipse(win + Vector2(0, r * 0.45), Vector2(r * 0.95, r * 0.5), 20), SKY_LOW)
	draw_line(win + Vector2(-r, 0), win + Vector2(r, 0), BEAM, 6.0)
	draw_line(win + Vector2(0, -r), win + Vector2(0, r), BEAM, 6.0)
	# A-frame roof beams.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.2, 0), Vector2(0, h * 0.62)]), BEAM)
	draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w * 0.8, 0), Vector2(w, h * 0.62)]), BEAM)
	draw_rect(Rect2(0, h * 0.04, w, 14), BEAM)
	draw_rect(Rect2(w * 0.12, 0, 16, floor_y), Color(BEAM, 0.85))
	draw_rect(Rect2(w * 0.86, 0, 16, floor_y), Color(BEAM, 0.85))
	# Floor boards.
	draw_rect(Rect2(0, floor_y, w, h - floor_y), FLOOR)
	for i: int in 7:
		var y: float = floor_y + (h - floor_y) * float(i) / 7.0
		draw_line(Vector2(0, y), Vector2(w, y), BOARD, 2.0)
	# Old wooden skis leaning on the wall, and a stack of boxes in the corner.
	for k: int in 2:
		var x: float = w * 0.2 + k * 18.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, floor_y), Vector2(x + 10, floor_y), Vector2(x + 70, h * 0.2),
			Vector2(x + 62, h * 0.18)]), Color("#6B4A32").darkened(0.15 * k))
	draw_rect(Rect2(w * 0.78, floor_y - 120, 150, 120), BOX_SIDE.darkened(0.35))
	draw_rect(Rect2(w * 0.8, floor_y - 200, 110, 80), BOX_SIDE.darkened(0.45))
	_draw_box()


func _draw_box() -> void:
	var top: Vector2 = box_top()
	var bw: float = size.x * 0.2
	var bh: float = size.y * 0.16
	var left: float = top.x - bw * 0.5
	draw_rect(Rect2(left, top.y, bw, bh), BOX)
	draw_colored_polygon(PackedVector2Array([Vector2(left + bw, top.y), Vector2(left + bw + 30, top.y - 16),
		Vector2(left + bw + 30, top.y + bh - 16), Vector2(left + bw, top.y + bh)]), BOX_SIDE)
	draw_colored_polygon(PackedVector2Array([Vector2(left, top.y), Vector2(left + 30, top.y - 16),
		Vector2(left + bw + 30, top.y - 16), Vector2(left + bw, top.y)]), BOX_INSIDE)
	# Flaps: closed they lie flat over the mouth; open they swing out to the sides.
	var a: float = lid_open * 2.1
	var hinge_l: Vector2 = Vector2(left + 15, top.y - 8)
	var hinge_r: Vector2 = Vector2(left + bw + 15, top.y - 8)
	var flap: float = bw * 0.5
	var tip_l: Vector2 = hinge_l + Vector2(cos(-a), sin(-a)) * flap
	var tip_r: Vector2 = hinge_r + Vector2(-cos(-a), sin(-a)) * flap
	draw_colored_polygon(PackedVector2Array([hinge_l + Vector2(0, -8), hinge_l + Vector2(0, 8), tip_l + Vector2(0, 8), tip_l + Vector2(0, -8)]), BOX.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([hinge_r + Vector2(0, -8), hinge_r + Vector2(0, 8), tip_r + Vector2(0, 8), tip_r + Vector2(0, -8)]), BOX.lightened(0.04))
	# Her name in marker on the front.
	var font: Font = get_theme_default_font()
	var text: String = tr("PROLOGUE_BOX")
	var fs: int = 30
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(top.x - tw * 0.5, top.y + bh * 0.6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK, 0.75))
