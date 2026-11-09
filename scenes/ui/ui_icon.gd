@tool
class_name UiIcon
extends Control
## Small vector icons drawn in code, so they look crisp at any size and don't depend
## on a font having arrow glyphs (many phone fonts don't).

enum Kind { MOUNTAIN, WALK, JUMP, BACK, PAUSE, CAMERA, STAR, STAR_EMPTY, LOCK, GEAR }

@export var kind: Kind = Kind.WALK:
	set(v):
		kind = v
		queue_redraw()
@export var color: Color = Color("#2B2D42"):
	set(v):
		color = v
		queue_redraw()
## Stroke width as a fraction of the icon's size.
@export_range(0.04, 0.3) var stroke: float = 0.12:
	set(v):
		stroke = v
		queue_redraw()

const ACCENT: Color = Color("#E85D3F")
const SNOW: Color = Color("#FFF6E5")
const FAR: Color = Color("#7FA6A0")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	var w: float = maxf(s * stroke, 1.5)
	match kind:
		Kind.WALK:
			_chevron(c + Vector2(-s * 0.16, 0), s * 0.26, Vector2.RIGHT, w)
			_chevron(c + Vector2(s * 0.16, 0), s * 0.26, Vector2.RIGHT, w)
		Kind.JUMP:
			_chevron(c + Vector2(0, -s * 0.16), s * 0.26, Vector2.UP, w)
			_chevron(c + Vector2(0, s * 0.16), s * 0.26, Vector2.UP, w)
		Kind.BACK:
			_chevron(c + Vector2(-s * 0.06, 0), s * 0.3, Vector2.LEFT, w)
		Kind.MOUNTAIN:
			_mountain_badge(c, s)
		Kind.PAUSE:
			var bar: Vector2 = Vector2(s * 0.16, s * 0.56)
			for side: float in [-1.0, 1.0]:
				var r: Rect2 = Rect2(c + Vector2(side * s * 0.15 - bar.x * 0.5, -bar.y * 0.5), bar)
				draw_rect(r, color, true)
		Kind.STAR:
			draw_colored_polygon(_star_points(c, s * 0.48), color)
		Kind.STAR_EMPTY:
			var pts: PackedVector2Array = _star_points(c, s * 0.44)
			pts.append(pts[0])
			draw_polyline(pts, color, maxf(s * 0.07, 1.5), true)
		Kind.LOCK:
			var body: Rect2 = Rect2(c + Vector2(-s * 0.32, -s * 0.06), Vector2(s * 0.64, s * 0.46))
			draw_rect(body, color, true)
			draw_arc(c + Vector2(0, -s * 0.08), s * 0.2, PI, TAU, 12, color, maxf(s * 0.1, 2.0), true)
			draw_circle(c + Vector2(0, s * 0.14), s * 0.06, SNOW, true, -1.0, true)
		Kind.GEAR:
			var teeth: PackedVector2Array = PackedVector2Array()
			for i: int in 16:
				var r: float = s * (0.44 if i % 2 == 0 else 0.32)
				var a: float = TAU * float(i) / 16.0
				teeth.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(teeth, color)
			draw_circle(c, s * 0.14, SNOW, true, -1.0, true)
		Kind.CAMERA:
			var body: Rect2 = Rect2(c + Vector2(-s * 0.42, -s * 0.24), Vector2(s * 0.84, s * 0.58))
			draw_rect(body, color, true)
			draw_rect(Rect2(c + Vector2(-s * 0.16, -s * 0.36), Vector2(s * 0.32, s * 0.14)), color, true)
			draw_circle(c + Vector2(0, s * 0.05), s * 0.17, SNOW, true, -1.0, true)
			draw_circle(c + Vector2(0, s * 0.05), s * 0.1, color, true, -1.0, true)


## Five-pointed star, point up.
func _star_points(c: Vector2, outer: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var r: float = outer if i % 2 == 0 else outer * 0.45
		var a: float = -PI * 0.5 + PI * float(i) / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## An open arrowhead pointing in `dir`.
func _chevron(tip_center: Vector2, half: float, dir: Vector2, w: float) -> void:
	var side: Vector2 = dir.orthogonal()
	var tip: Vector2 = tip_center + dir * half * 0.5
	var back: Vector2 = tip_center - dir * half * 0.5
	var pts: PackedVector2Array = PackedVector2Array([back + side * half, tip, back - side * half])
	draw_polyline(pts, color, w, true)
	# Round off the joints so thick strokes don't look cut.
	for p: Vector2 in pts:
		draw_circle(p, w * 0.5, color, true, -1.0, true)


## The game's logo: a sun behind two peaks with snow caps.
func _mountain_badge(c: Vector2, s: float) -> void:
	var base_y: float = c.y + s * 0.32
	draw_circle(c + Vector2(s * 0.22, -s * 0.12), s * 0.2, ACCENT, true, -1.0, true)
	var back_peak: PackedVector2Array = PackedVector2Array([
		Vector2(c.x - s * 0.05, base_y), Vector2(c.x + s * 0.28, c.y - s * 0.2), Vector2(c.x + s * 0.62, base_y)])
	draw_colored_polygon(back_peak, FAR)
	var front_peak: PackedVector2Array = PackedVector2Array([
		Vector2(c.x - s * 0.62, base_y), Vector2(c.x - s * 0.12, c.y - s * 0.36), Vector2(c.x + s * 0.38, base_y)])
	draw_colored_polygon(front_peak, color)
	# Snow cap follows the front peak's slopes.
	var peak: Vector2 = front_peak[1]
	var cap: PackedVector2Array = PackedVector2Array([
		peak,
		peak.lerp(front_peak[2], 0.3),
		peak.lerp(front_peak[2], 0.22) + Vector2(-s * 0.05, s * 0.02),
		peak.lerp(Vector2(peak.x, base_y), 0.24),
		peak.lerp(front_peak[0], 0.22) + Vector2(s * 0.04, s * 0.03),
		peak.lerp(front_peak[0], 0.3),
	])
	draw_colored_polygon(cap, SNOW)
