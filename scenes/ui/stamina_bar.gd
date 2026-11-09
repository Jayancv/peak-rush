@tool
class_name StaminaBar
extends Control
## Rounded stamina bar: green when fresh, amber, then red and pulsing when low;
## slate grey while recovering from exhaustion. The fill eases towards the real
## value so drains and refills read smoothly.

const TRACK: Color = Color("#2B2D42")
const HIGH: Color = Color("#7CC47F")
const MID: Color = Color("#F2B33D")
const LOW: Color = Color("#E85D3F")
const RECOVERING: Color = Color("#8A8FA8")
const SHINE: Color = Color(1, 1, 1, 0.25)
const EASE_RATE: float = 10.0
const PULSE_HZ: float = 2.2
const INSET: float = 3.0
## A bright band sweeping along the fill while stamina refills; faster at a bench.
const SWEEP_COLOR: Color = Color(1, 1, 1, 0.45)
const SWEEP_SECONDS_REST: float = 1.4
const SWEEP_SECONDS_BENCH: float = 0.7

@export_range(0.0, 1.0) var fraction: float = 1.0:
	set(v):
		fraction = clampf(v, 0.0, 1.0)
		set_process(true)
@export var low_fraction: float = 0.25
@export var recovering: bool = false:
	set(v):
		recovering = v
		queue_redraw()

## 0 = not refilling, 1 = resting, 2 = at a bench (HikerCondition.Regen values).
var boost: int = 0:
	set(v):
		boost = v
		set_process(true)
		queue_redraw()

var _shown: float = 1.0
var _time: float = 0.0
var _track_box: StyleBoxFlat
var _fill_box: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track_box = _box(Color(TRACK, 0.55))
	_fill_box = _box(HIGH)
	_shown = fraction


func set_stamina(value: float, max_value: float, is_recovering: bool) -> void:
	fraction = value / maxf(max_value, 0.001)
	recovering = is_recovering


func _process(delta: float) -> void:
	_time += delta
	_shown = lerpf(_shown, fraction, 1.0 - exp(-EASE_RATE * delta))
	var settled: bool = absf(_shown - fraction) < 0.001
	if settled:
		_shown = fraction
	# Low stamina pulses, which needs redraws every frame; otherwise stop once settled.
	var pulsing: bool = fraction < low_fraction and not recovering
	modulate.a = 0.65 + 0.35 * (0.5 + 0.5 * cos(_time * TAU * PULSE_HZ)) if pulsing else 1.0
	queue_redraw()
	if settled and not pulsing and boost == 0:
		set_process(false)


func _draw() -> void:
	if _track_box == null:
		return
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	draw_style_box(_track_box, r)
	var inner: Rect2 = r.grow(-INSET)
	var w: float = inner.size.x * _shown
	if w < 1.0:
		return
	_fill_box.bg_color = _fill_color()
	var fill: Rect2 = Rect2(inner.position, Vector2(maxf(w, inner.size.y), inner.size.y))
	draw_style_box(_fill_box, fill)
	draw_rect(Rect2(fill.position + Vector2(inner.size.y * 0.4, 2.0), Vector2(maxf(fill.size.x - inner.size.y * 0.8, 0.0), 3.0)), SHINE)
	if boost > 0:
		var period: float = SWEEP_SECONDS_BENCH if boost == 2 else SWEEP_SECONDS_REST
		var t: float = fmod(_time, period) / period
		var band: float = inner.size.y * 1.2
		var x: float = fill.position.x + (fill.size.x + band) * t - band
		var x0: float = maxf(x, fill.position.x + 2.0)
		var x1: float = minf(x + band, fill.end.x - 2.0)
		if x1 > x0:
			draw_rect(Rect2(x0, fill.position.y + 2.0, x1 - x0, fill.size.y - 4.0), SWEEP_COLOR)


func _fill_color() -> Color:
	if recovering:
		return RECOVERING
	if _shown > 0.5:
		return MID.lerp(HIGH, (_shown - 0.5) * 2.0)
	return LOW.lerp(MID, clampf((_shown - low_fraction) / (0.5 - low_fraction), 0.0, 1.0))


func _box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(64)
	box.anti_aliasing = true
	return box
