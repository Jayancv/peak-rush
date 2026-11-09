@tool
class_name ShadedBadge
extends Control
## A rounded backing for an icon, with light shading so it reads as a raised badge:
## a soft drop shadow, a body that's lighter at the top than the bottom, a highlight
## along the top edge and a slightly darker rim. Put the icon (UiIcon/TextureRect)
## inside it as a child; the badge draws behind its children.

@export var base_color: Color = Color("#F6D9CC"):
	set(v):
		base_color = v
		queue_redraw()
## 0.5 = circle; smaller = rounded square (fraction of the badge size).
@export_range(0.0, 0.5) var corner: float = 0.5:
	set(v):
		corner = v
		queue_redraw()
@export var shadow_size: float = 6.0:
	set(v):
		shadow_size = v
		queue_redraw()
## Width of a light frame around the badge (0 = none).
@export var frame_width: float = 0.0:
	set(v):
		frame_width = v
		queue_redraw()
@export var frame_color: Color = Color("#FFFFFF"):
	set(v):
		frame_color = v
		queue_redraw()
## Soft coloured glow spreading behind the badge (alpha 0 = none).
@export var glow_color: Color = Color(1, 0.8, 0.55, 0.0):
	set(v):
		glow_color = v
		queue_redraw()

const SHADOW: Color = Color(0.168627, 0.176471, 0.258824, 0.22)
const STEPS: int = 6


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var r: float = minf(size.x, size.y) * corner
	if glow_color.a > 0.0:
		# Rings of fading colour; cheap and smooth enough at this size.
		for i: int in STEPS:
			var t: float = float(STEPS - i) / float(STEPS)
			var grow: float = minf(size.x, size.y) * 0.45 * t
			_box(rect.grow(grow), r + grow, Color(glow_color, glow_color.a * (1.0 - t) * 0.5), 0.0)
	_box(rect, r, Color.TRANSPARENT, shadow_size)
	if frame_width > 0.0:
		_box(rect, r, frame_color, 0.0)
	var body: Rect2 = rect.grow(-frame_width)
	var br: float = maxf(r - frame_width, 0.0)
	_box(body, br, base_color.darkened(0.12), 0.0)
	# Lighter upper part over a darker base gives top-down light.
	_box(Rect2(body.position, Vector2(body.size.x, body.size.y - 3.0)), br, base_color.lightened(0.06), 0.0)
	_box(Rect2(body.position + Vector2(body.size.x * 0.18, 2.0), Vector2(body.size.x * 0.64, body.size.y * 0.22)), body.size.y * 0.11, Color(1, 1, 1, 0.28), 0.0)


func _box(rect: Rect2, radius: float, col: Color, shadow: float) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = col
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	if shadow > 0.0:
		box.shadow_color = SHADOW
		box.shadow_size = int(shadow)
		box.shadow_offset = Vector2(0, shadow * 0.5)
	draw_style_box(box, rect)
