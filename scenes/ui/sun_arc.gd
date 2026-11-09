@tool
class_name SunArc
extends Control
## A dotted half-circle with the sun riding along it as daylight passes. The sun
## warms to orange in golden hour; at dusk it's replaced by the moon.

const DOTS: Color = Color(0.168627, 0.176471, 0.258824, 0.35)
const SUN: Color = Color("#F2B33D")
const SUN_GOLDEN: Color = Color("#E8823F")
const MOON: Color = Color("#6C74A6")
## Matches the HUD pill behind it, which cuts the moon into a crescent.
const MOON_SHADOW: Color = Color("#FFF6E5")
const DOT_COUNT: int = 11

@export_range(0.0, 1.0) var progress: float = 0.0:
	set(v):
		progress = clampf(v, 0.0, 1.0)
		queue_redraw()
## Night trails show the moon the whole way.
@export var night: bool = false:
	set(v):
		night = v
		queue_redraw()
@export var phase: Daylight.Phase = Daylight.Phase.MORNING:
	set(v):
		phase = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_daylight(sun_progress: float, day_phase: Daylight.Phase) -> void:
	# Only redraw when the sun visibly moves, not every frame.
	if absf(sun_progress - progress) > 0.002 or day_phase != phase:
		progress = sun_progress
		phase = day_phase


func _draw() -> void:
	var radius: float = minf(size.x * 0.5, size.y) - 8.0
	var center: Vector2 = Vector2(size.x * 0.5, size.y - 4.0)
	for i: int in DOT_COUNT:
		var a: float = PI + PI * float(i) / float(DOT_COUNT - 1)
		draw_circle(center + Vector2(cos(a), sin(a)) * radius, 2.0, DOTS, true, -1.0, true)
	var pos: Vector2 = center + Vector2(cos(PI + PI * progress), sin(PI + PI * progress)) * radius
	if phase == Daylight.Phase.DUSK or night:
		draw_circle(pos, 8.0, MOON, true, -1.0, true)
		draw_circle(pos + Vector2(3.5, -2.5), 6.5, MOON_SHADOW, true, -1.0, true)
	else:
		var col: Color = SUN_GOLDEN if phase == Daylight.Phase.GOLDEN else SUN
		draw_circle(pos, 12.0, Color(col, 0.3), true, -1.0, true)
		draw_circle(pos, 8.0, col, true, -1.0, true)
