@tool
class_name UiIcon
extends Control
## Small vector icons drawn in code, so they look crisp at any size and don't depend
## on a font having arrow glyphs (many phone fonts don't).

## BOOTS..HEADLAMP follow GearData.Icon order (kind = BOOTS + icon).
## New kinds go at the end: scenes store the number.
enum Kind { MOUNTAIN, WALK, JUMP, BACK, PAUSE, CAMERA, STAR, STAR_EMPTY, LOCK, GEAR, BOOTS, POLES, SHELL, THERMOS, HEADLAMP,
	MUSIC, SOUND, NATURE, SWAP, VIBRATE, PERSON, CLOCK, DROP, LEAF, PAW, MOTION, INFO }

@export var kind: Kind = Kind.WALK:
	set(v):
		kind = v
		queue_redraw()
@export var color: Color = Color("#2B2D42"):
	set(v):
		color = v
		queue_redraw()
## Colour of holes and details cut into the icon (lens, keyhole, zip...). Set it to
## whatever is behind the icon when that isn't the usual cream.
@export var cutout: Color = Color("#FFF6E5"):
	set(v):
		cutout = v
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
			draw_circle(c + Vector2(0, s * 0.14), s * 0.06, cutout, true, -1.0, true)
		Kind.GEAR:
			# A cog: eight flat-topped teeth on a round body, with a hole in the middle.
			var teeth: int = 8
			var outer: float = s * 0.46
			var inner: float = s * 0.35
			var cog: PackedVector2Array = PackedVector2Array()
			for i: int in teeth:
				var a: float = TAU * float(i) / float(teeth)
				for step: Vector2 in [Vector2(-0.3, inner), Vector2(-0.19, outer), Vector2(0.19, outer), Vector2(0.3, inner)]:
					cog.append(c + Vector2.from_angle(a + step.x) * step.y)
				# Round the body between this tooth and the next.
				for k: int in range(1, 3):
					var b: float = a + 0.3 + (TAU / float(teeth) - 0.6) * float(k) / 3.0
					cog.append(c + Vector2.from_angle(b) * inner)
			draw_colored_polygon(cog, color)
			draw_circle(c, s * 0.15, cutout, true, -1.0, true)
		Kind.BOOTS:
			# A hiking boot: shaft, foot and a chunky sole.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.38), c + Vector2(-s * 0.02, -s * 0.38), c + Vector2(0, s * 0.02), c + Vector2(s * 0.38, s * 0.1), c + Vector2(s * 0.4, s * 0.26), c + Vector2(-s * 0.3, s * 0.26)]), color)
			draw_rect(Rect2(c + Vector2(-s * 0.34, s * 0.24), Vector2(s * 0.78, s * 0.1)), ACCENT, true)
		Kind.POLES:
			for dx: float in [-0.14, 0.14]:
				draw_line(c + Vector2(s * dx - s * 0.08, -s * 0.42), c + Vector2(s * dx + s * 0.08, s * 0.42), color, maxf(s * 0.07, 2.0), true)
				draw_rect(Rect2(c + Vector2(s * dx - s * 0.12, -s * 0.44), Vector2(s * 0.1, s * 0.16)), ACCENT, true)
		Kind.SHELL:
			# A rain jacket with a hood.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.12, -s * 0.36), c + Vector2(s * 0.12, -s * 0.36), c + Vector2(s * 0.42, -s * 0.1), c + Vector2(s * 0.32, s * 0.04), c + Vector2(s * 0.24, -s * 0.02), c + Vector2(s * 0.24, s * 0.4), c + Vector2(-s * 0.24, s * 0.4), c + Vector2(-s * 0.24, -s * 0.02), c + Vector2(-s * 0.32, s * 0.04), c + Vector2(-s * 0.42, -s * 0.1)]), color)
			draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.38), cutout, maxf(s * 0.04, 1.5), true)
		Kind.THERMOS:
			draw_rect(Rect2(c + Vector2(-s * 0.18, -s * 0.28), Vector2(s * 0.36, s * 0.7)), color, true)
			draw_rect(Rect2(c + Vector2(-s * 0.14, -s * 0.42), Vector2(s * 0.28, s * 0.14)), ACCENT, true)
			draw_rect(Rect2(c + Vector2(-s * 0.18, -s * 0.02), Vector2(s * 0.36, s * 0.08)), cutout, true)
		Kind.HEADLAMP:
			draw_arc(c + Vector2(0, s * 0.06), s * 0.3, PI, TAU, 16, color, maxf(s * 0.08, 2.0), true)
			draw_circle(c + Vector2(0, -s * 0.24), s * 0.13, color, true, -1.0, true)
			draw_circle(c + Vector2(0, -s * 0.24), s * 0.07, Color("#FFE9A8"), true, -1.0, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.08, -s * 0.3), c + Vector2(s * 0.46, -s * 0.44), c + Vector2(s * 0.46, -s * 0.04), c + Vector2(s * 0.08, -s * 0.18)]), Color("#FFE9A8", 0.7))
		Kind.MUSIC:
			# Two beamed notes.
			for dx: float in [-0.2, 0.22]:
				draw_set_transform(c + Vector2(s * dx, s * 0.26), -0.35, Vector2.ONE)
				draw_colored_polygon(ShapeUtil.ellipse(Vector2.ZERO, Vector2(s * 0.14, s * 0.1), 14), color)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_line(c + Vector2(s * (dx + 0.12), s * 0.22), c + Vector2(s * (dx + 0.12), -s * 0.3), color, w, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * 0.3), c + Vector2(s * 0.36, -s * 0.38), c + Vector2(s * 0.36, -s * 0.24), c + Vector2(-s * 0.1, -s * 0.16)]), color)
		Kind.SOUND:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.12), c + Vector2(-s * 0.22, -s * 0.12), c + Vector2(0, -s * 0.34), c + Vector2(0, s * 0.34), c + Vector2(-s * 0.22, s * 0.12), c + Vector2(-s * 0.4, s * 0.12)]), color)
			draw_arc(c + Vector2(s * 0.02, 0), s * 0.18, -0.9, 0.9, 10, color, w, true)
			draw_arc(c + Vector2(s * 0.02, 0), s * 0.34, -0.9, 0.9, 14, color, w, true)
		Kind.NATURE:
			# A leaf with its midrib.
			var leaf: PackedVector2Array = PackedVector2Array()
			for i: int in 17:
				var t: float = float(i) / 16.0
				leaf.append(c + Vector2(lerpf(-s * 0.46, s * 0.46, t), -sin(t * PI) * s * 0.3).rotated(-0.6))
			for i: int in range(15, 0, -1):
				var t: float = float(i) / 16.0
				leaf.append(c + Vector2(lerpf(-s * 0.46, s * 0.46, t), sin(t * PI) * s * 0.26).rotated(-0.6))
			draw_colored_polygon(leaf, color)
			draw_line(c + Vector2(-s * 0.5, 0).rotated(-0.6), c + Vector2(s * 0.34, 0).rotated(-0.6), cutout, maxf(w * 0.5, 1.5), true)
		Kind.SWAP:
			# Arrows pointing both ways: which side walks and which side jumps.
			for row: float in [-1.0, 1.0]:
				var y: float = row * s * 0.17
				var dir: float = -row
				draw_line(c + Vector2(-s * 0.32, y), c + Vector2(s * 0.32, y), color, w, true)
				var tip: Vector2 = c + Vector2(s * 0.38 * dir, y)
				draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-s * 0.18 * dir, -s * 0.13), tip + Vector2(-s * 0.18 * dir, s * 0.13)]), color)
		Kind.VIBRATE:
			var phone: Rect2 = Rect2(c + Vector2(-s * 0.16, -s * 0.34), Vector2(s * 0.32, s * 0.68))
			draw_rect(phone, color, false, w)
			draw_circle(c + Vector2(0, s * 0.24), s * 0.035, color, true, -1.0, true)
			for side: float in [-1.0, 1.0]:
				var x: float = c.x + side * s * 0.3
				draw_polyline(PackedVector2Array([Vector2(x, c.y - s * 0.22), Vector2(x + side * s * 0.07, c.y - s * 0.11), Vector2(x, c.y), Vector2(x + side * s * 0.07, c.y + s * 0.11), Vector2(x, c.y + s * 0.22)]), color, maxf(w * 0.8, 1.5), true)
		Kind.PERSON:
			draw_circle(c + Vector2(0, -s * 0.16), s * 0.19, color, true, -1.0, true)
			var shoulders: PackedVector2Array = PackedVector2Array()
			for i: int in 13:
				var a: float = PI + PI * float(i) / 12.0
				shoulders.append(c + Vector2(cos(a) * s * 0.36, s * 0.42 + sin(a) * s * 0.34))
			draw_colored_polygon(shoulders, color)
		Kind.CLOCK:
			draw_arc(c, s * 0.38, 0.0, TAU, 32, color, w, true)
			draw_line(c, c + Vector2(0, -s * 0.24), color, w, true)
			draw_line(c, c + Vector2(s * 0.17, s * 0.08), color, w, true)
		Kind.DROP:
			var drop: PackedVector2Array = PackedVector2Array([c + Vector2(0, -s * 0.44)])
			for i: int in 13:
				var a: float = -0.35 + (PI + 0.7) * float(i) / 12.0
				drop.append(c + Vector2(0, s * 0.12) + Vector2(cos(a), sin(a)) * s * 0.3)
			draw_colored_polygon(drop, color)
			draw_circle(c + Vector2(-s * 0.1, s * 0.08), s * 0.07, cutout, true, -1.0, true)
		Kind.LEAF:
			var leaf2: PackedVector2Array = PackedVector2Array()
			for i: int in 17:
				var t: float = float(i) / 16.0
				leaf2.append(c + Vector2(-sin(t * PI) * s * 0.3, lerpf(s * 0.42, -s * 0.42, t)).rotated(0.5))
			for i: int in range(15, 0, -1):
				var t: float = float(i) / 16.0
				leaf2.append(c + Vector2(sin(t * PI) * s * 0.3, lerpf(s * 0.42, -s * 0.42, t)).rotated(0.5))
			draw_colored_polygon(leaf2, color)
			draw_line(c + Vector2(0, s * 0.46).rotated(0.5), c + Vector2(0, -s * 0.3).rotated(0.5), cutout, maxf(w * 0.5, 1.5), true)
		Kind.PAW:
			draw_colored_polygon(ShapeUtil.ellipse(c + Vector2(0, s * 0.16), Vector2(s * 0.22, s * 0.18), 16), color)
			for p: Vector2 in [Vector2(-0.3, -0.08), Vector2(-0.12, -0.3), Vector2(0.12, -0.3), Vector2(0.3, -0.08)]:
				draw_colored_polygon(ShapeUtil.ellipse(c + p * s, Vector2(s * 0.09, s * 0.11), 12), color)
		Kind.MOTION:
			# A ball with speed lines: "moving things".
			draw_circle(c + Vector2(s * 0.18, 0), s * 0.2, color, true, -1.0, true)
			for row: float in [-0.2, 0.0, 0.2]:
				var len: float = 0.34 - absf(row) * 0.6
				draw_line(c + Vector2(-s * 0.44, s * row), c + Vector2(-s * (0.44 - len), s * row), color, maxf(w * 0.8, 1.5), true)
		Kind.INFO:
			draw_arc(c, s * 0.4, 0.0, TAU, 32, color, w, true)
			draw_circle(c + Vector2(0, -s * 0.19), s * 0.065, color, true, -1.0, true)
			draw_line(c + Vector2(0, -s * 0.04), c + Vector2(0, s * 0.24), color, w * 1.1, true)
		Kind.CAMERA:
			var body: Rect2 = Rect2(c + Vector2(-s * 0.42, -s * 0.24), Vector2(s * 0.84, s * 0.58))
			draw_rect(body, color, true)
			draw_rect(Rect2(c + Vector2(-s * 0.16, -s * 0.36), Vector2(s * 0.32, s * 0.14)), color, true)
			draw_circle(c + Vector2(0, s * 0.05), s * 0.17, cutout, true, -1.0, true)
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
