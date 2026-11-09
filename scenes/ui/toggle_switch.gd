@tool
class_name ToggleSwitch
extends Button
## An on/off switch: a pill track with a sliding knob. It's still a toggle Button, so
## code uses button_pressed / toggled as usual; the row's label sits next to it.

const ON_COLOR: Color = Color("#5E9C6E")
const OFF_COLOR: Color = Color(0.168627, 0.176471, 0.258824, 0.2)
const KNOB: Color = Color("#FFFFFF")
const SHADOW: Color = Color(0.168627, 0.176471, 0.258824, 0.28)
const SLIDE_SECONDS: float = 0.2
## Track height and the knob's inset from the track edge (px).
const TRACK_HEIGHT: float = 48.0
const KNOB_INSET: float = 5.0

## 0 = off .. 1 = on, as currently drawn (it slides between the two).
var _t: float = 0.0
var _target_on: bool = false
var _tween: Tween
var _track: StyleBoxFlat = StyleBoxFlat.new()


func _init() -> void:
	toggle_mode = true
	flat = true
	text = ""
	custom_minimum_size = Vector2(92, 56)
	_track.set_corner_radius_all(int(TRACK_HEIGHT * 0.5))
	_track.anti_aliasing = true


func _ready() -> void:
	sync()
	toggled.connect(_on_toggled)


## Call after set_pressed_no_signal() so the knob jumps to the new state without sliding.
func sync() -> void:
	_target_on = button_pressed
	_t = 1.0 if _target_on else 0.0
	queue_redraw()


## Whether the switch shows "on" (follows the toggled signal).
func shown_on() -> bool:
	return _target_on


func _on_toggled(on: bool) -> void:
	_target_on = on
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_t, _t, 1.0 if on else 0.0, SLIDE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_t(v: float) -> void:
	_t = v
	queue_redraw()


func _draw() -> void:
	var h: float = minf(size.y, TRACK_HEIGHT)
	var w: float = minf(size.x, h * 1.85)
	var track: Rect2 = Rect2((size - Vector2(w, h)) * 0.5, Vector2(w, h))
	_track.bg_color = OFF_COLOR.lerp(ON_COLOR, _t)
	draw_style_box(_track, track)
	var r: float = h * 0.5 - KNOB_INSET
	var cx: float = lerpf(track.position.x + h * 0.5, track.end.x - h * 0.5, _t)
	var centre: Vector2 = Vector2(cx, track.get_center().y)
	draw_circle(centre + Vector2(0, 2), r + 1.0, SHADOW, true, -1.0, true)
	draw_circle(centre, r, KNOB, true, -1.0, true)
	if _t > 0.01:
		# A small tick fades in on the knob when it's on.
		var tick: PackedVector2Array = PackedVector2Array([centre + Vector2(-r * 0.42, 0), centre + Vector2(-r * 0.1, r * 0.32), centre + Vector2(r * 0.45, -r * 0.34)])
		draw_polyline(tick, Color(ON_COLOR, _t), maxf(r * 0.2, 2.0), true)
