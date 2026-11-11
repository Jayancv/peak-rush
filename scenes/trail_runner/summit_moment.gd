class_name SummitMoment
extends Node2D
## The payoff at the cairn: the hiker plants a flag that rises and waves, the camera
## pulls back to show the trail climbed, and a big "Summit!" title comes up with the
## trail name and time. Lasts Balance.summit_seconds; a tap skips it once it's had a
## moment. Emits `done` once, then the trail runner moves on to the results.

signal done

const POLE: Color = Color("#5C4332")
const FLAG: Color = Color("#E85D3F")
const FLAG_EDGE: Color = Color("#B8432C")
const POLE_HEIGHT: float = 58.0
const FLAG_SIZE: Vector2 = Vector2(30, 20)
## Taps before this are ignored (the finishing walk-in tap mustn't skip it).
const MIN_SECONDS: float = 0.8

var _flag: Polygon2D
var _pole: Node2D
var _age: float = 0.0
var _finished: bool = false
var _balance: Balance


func play(hiker: Hiker, camera: HikerCamera, hud: Hud, trail: TrailData, seconds_taken: float, balance: Balance) -> void:
	_balance = balance
	global_position = hiker.global_position + Vector2(24, 2)
	_build_flag()
	if not UiMotion.reduced():
		# Back and up, zoomed out: the climb laid out below.
		camera.frame(hiker.global_position + Vector2(-balance.summit_pull_px, -balance.summit_rise_px), balance.summit_zoom)
	hud.show_summit(tr(trail.name_key), TimeFormat.mmss(seconds_taken))
	get_tree().create_timer(balance.summit_seconds, false).timeout.connect(_finish)


func _build_flag() -> void:
	_pole = Node2D.new()
	add_child(_pole)
	var pole: Polygon2D = Polygon2D.new()
	pole.polygon = PackedVector2Array([Vector2(-1.6, 0), Vector2(1.6, 0), Vector2(1.2, -POLE_HEIGHT), Vector2(-1.2, -POLE_HEIGHT)])
	pole.color = POLE
	_pole.add_child(pole)
	_flag = Polygon2D.new()
	_flag.color = FLAG
	_flag.position = Vector2(1.2, -POLE_HEIGHT)
	_pole.add_child(_flag)
	var knob: Polygon2D = Polygon2D.new()
	knob.polygon = ShapeUtil.ellipse(Vector2(0, -POLE_HEIGHT - 2), Vector2(2.6, 2.6), 10)
	knob.color = FLAG_EDGE
	_pole.add_child(knob)
	# Planted: the pole grows up out of the ground with a little overshoot.
	_pole.scale = Vector2(1.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_interval(0.25)
	tween.tween_property(_pole, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_wave(0.0)


func _process(delta: float) -> void:
	_age += delta
	_wave(_age)


## A flag rippling in the wind: the free edge moves more than the edge on the pole.
func _wave(t: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 8
	for i: int in steps + 1:
		var u: float = float(i) / steps
		pts.append(Vector2(u * FLAG_SIZE.x, sin(t * 7.0 - u * 4.0) * 3.0 * u))
	for i: int in range(steps, -1, -1):
		var u: float = float(i) / steps
		# The bottom edge tapers in a little: a pennant, not a sheet.
		pts.append(Vector2(u * FLAG_SIZE.x, FLAG_SIZE.y * (1.0 - 0.35 * u) + sin(t * 7.0 - u * 4.0 + 0.6) * 3.0 * u))
	_flag.polygon = pts


func _input(event: InputEvent) -> void:
	if _age < MIN_SECONDS:
		return
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) \
		or event.is_action_pressed(&"jump") or event.is_action_pressed(&"pause")
	if tapped:
		_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	done.emit()
