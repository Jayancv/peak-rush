class_name WaterGauge
extends Control
## The water bottle on the HUD: a short rounded bar that empties as the hiker walks,
## refills at springs, and pulses red when nearly empty.

const TRACK: Color = Color(0.168627, 0.176471, 0.258824, 0.18)
const FULL: Color = Color("#3E9BD1")
const LOW: Color = Color("#E85D3F")
const PULSE_HZ: float = 2.5

var fraction: float = 1.0:
	set(v):
		fraction = clampf(v, 0.0, 1.0)
		queue_redraw()
var low_fraction: float = 0.2

var _shown: float = 1.0
var _time: float = 0.0
var _box: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	custom_minimum_size = Vector2(70, 18)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	_shown = lerpf(_shown, fraction, 1.0 - exp(-8.0 * delta))
	if absf(_shown - fraction) > 0.001 or fraction <= low_fraction:
		queue_redraw()


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2(0, (size.y - 14.0) * 0.5), Vector2(size.x, 14.0))
	_box.set_corner_radius_all(7)
	_box.bg_color = TRACK
	draw_style_box(_box, r)
	if _shown <= 0.005:
		return
	var low: bool = _shown <= low_fraction
	var col: Color = LOW if low else FULL
	if low:
		col.a = 0.6 + 0.4 * sin(_time * TAU * PULSE_HZ)
	_box.bg_color = col
	draw_style_box(_box, Rect2(r.position, Vector2(maxf(r.size.x * _shown, 14.0), r.size.y)))
