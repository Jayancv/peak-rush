class_name SwatchButton
extends Button
## A round colour swatch for the outfit picker: a ring when it's being worn, a lock
## and the stars needed when it isn't unlocked yet.

const SIZE: float = 60.0
const RING: Color = Color("#2B2D42")
const LOCK_TINT: Color = Color(0.168627, 0.176471, 0.258824, 0.55)
const SNOW: Color = Color("#FFF6E5")

var item: CosmeticData
var selected: bool = false:
	set(v):
		selected = v
		queue_redraw()
var locked: bool = false:
	set(v):
		locked = v
		queue_redraw()


func _init() -> void:
	flat = true
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 6.0
	draw_circle(c + Vector2(0, 2), r + 1.0, Color(0, 0, 0, 0.16), true, -1.0, true)
	draw_circle(c, r, item.color if item != null else Color.WHITE, true, -1.0, true)
	# A soft highlight so swatches read as little glossy buttons.
	draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.32, Color(1, 1, 1, 0.22), true, -1.0, true)
	if selected:
		draw_arc(c, r + 4.0, 0.0, TAU, 40, RING, 3.0, true)
	if locked:
		draw_circle(c, r, LOCK_TINT, true, -1.0, true)
		var body: Rect2 = Rect2(c + Vector2(-r * 0.3, -r * 0.05), Vector2(r * 0.6, r * 0.45))
		draw_rect(body, SNOW, true)
		draw_arc(c + Vector2(0, -r * 0.08), r * 0.2, PI, TAU, 10, SNOW, maxf(r * 0.1, 2.0), true)
