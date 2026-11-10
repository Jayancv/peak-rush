class_name FindArt
extends Control
## A small drawing of a find for the journal (flower, mushroom, lost item or animal).
## Not found yet: a faded silhouette with a question mark.

const STEM: Color = Color("#5E8C4A")
const CREAM: Color = Color("#F2EAD8")
const BRASS: Color = Color("#C9A24A")
const INK: Color = Color("#2B2D42")
const UNKNOWN: Color = Color(0.168627, 0.176471, 0.258824, 0.16)

var kind: FindData.Kind = FindData.Kind.FLOWER
var color: Color = Color.WHITE
var found: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s: float = minf(size.x, size.y) / 100.0
	var c: Vector2 = size * 0.5 + Vector2(0, 8) * s
	var main: Color = color if found else UNKNOWN
	var leaf: Color = STEM if found else UNKNOWN
	var light: Color = CREAM if found else UNKNOWN
	match kind:
		FindData.Kind.FLOWER:
			for k: int in 3:
				var x: float = (float(k) - 1.0) * 22.0
				var h: float = 44.0 + float(k % 2) * 14.0
				draw_line(c + Vector2(x, 34) * s, c + Vector2(x, 34 - h) * s, leaf, 3.0 * s, true)
				for p: int in 5:
					var a: float = TAU * float(p) / 5.0
					draw_circle(c + (Vector2(x, 34 - h) + Vector2(cos(a), sin(a)) * 9.0) * s, 8.0 * s, main, true, -1.0, true)
				draw_circle(c + Vector2(x, 34 - h) * s, 5.0 * s, Color("#F2C14E") if found else UNKNOWN, true, -1.0, true)
		FindData.Kind.MUSHROOM:
			draw_rect(Rect2(c + Vector2(-8, -6) * s, Vector2(16, 40) * s), light, true)
			var cap: PackedVector2Array = PackedVector2Array()
			for i: int in 17:
				var a: float = PI + PI * float(i) / 16.0
				cap.append(c + Vector2(cos(a) * 36.0, -4.0 + sin(a) * 28.0) * s)
			draw_colored_polygon(cap, main)
			if found:
				for d: Vector2 in [Vector2(-16, -18), Vector2(6, -24), Vector2(18, -10)]:
					draw_circle(c + d * s, 4.5 * s, CREAM, true, -1.0, true)
		FindData.Kind.ITEM:
			draw_circle(c, 34.0 * s, main.darkened(0.2) if found else UNKNOWN, true, -1.0, true)
			draw_circle(c, 29.0 * s, BRASS if found else UNKNOWN, true, -1.0, true)
			draw_circle(c, 23.0 * s, light, true, -1.0, true)
			if found:
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -20) * s, c + Vector2(5, 0) * s, c + Vector2(-5, 0) * s]), Color("#E85D3F"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, 20) * s, c + Vector2(5, 0) * s, c + Vector2(-5, 0) * s]), INK)
		FindData.Kind.ANIMAL:
			# A fox-like head: ears, face, snout.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-30, -6) * s, c + Vector2(-24, -42) * s, c + Vector2(-6, -16) * s]), main)
			draw_colored_polygon(PackedVector2Array([c + Vector2(30, -6) * s, c + Vector2(24, -42) * s, c + Vector2(6, -16) * s]), main)
			draw_colored_polygon(ShapeUtil.ellipse(c + Vector2(0, 2) * s, Vector2(32, 26) * s, 24), main)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 8) * s, c + Vector2(20, 8) * s, c + Vector2(0, 32) * s]), light)
			if found:
				draw_circle(c + Vector2(0, 30) * s, 4.0 * s, INK, true, -1.0, true)
				draw_circle(c + Vector2(-11, -2) * s, 3.5 * s, INK, true, -1.0, true)
				draw_circle(c + Vector2(11, -2) * s, 3.5 * s, INK, true, -1.0, true)
	if not found:
		var font: Font = get_theme_default_font()
		var fs: int = int(40.0 * s)
		draw_string(font, Vector2(c.x - fs * 0.28, c.y + fs * 0.1), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK, 0.5))
