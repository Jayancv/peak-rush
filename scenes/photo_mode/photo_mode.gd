class_name PhotoMode
extends Control
## The photo overlay at a viewpoint. Tap (or Space) to shoot; the shot is graded by
## how close the moving subject is to the frame centre. A visit has a small roll of
## film and keeps its best shot. Back/Esc or the close button leaves.
## The trail runner opens it, moves the camera, and records what it reports.

signal shot_taken(viewpoint_id: StringName, quality: int)
signal closed

const RESULT_KEYS: Dictionary = {
	StarRating.PhotoQuality.NONE: "PHOTO_MISSED",
	StarRating.PhotoQuality.GOOD: "PHOTO_GOOD",
	StarRating.PhotoQuality.GREAT: "PHOTO_GREAT",
	StarRating.PhotoQuality.PERFECT: "PHOTO_PERFECT",
}
## Pause after a shot so one tap can't fire twice, and before closing on an empty roll.
const SHOT_COOLDOWN: float = 0.45
const EMPTY_ROLL_CLOSE_DELAY: float = 1.3

@export var viewfinder: Viewfinder
@export var flash: ColorRect
@export var result_panel: Control
@export var result_label: Label
@export var hint_label: Label
@export var close_button: Button

var viewpoint: Viewpoint
var scoring: PhotoScoring

var _balance: Balance
var _cooldown: float = 0.0
## Best quality already earned for this viewpoint (journal or earlier in this visit).
var _best_known: int = 0


func _ready() -> void:
	_balance = ContentDB.balance
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_button.pressed.connect(close)
	viewfinder.half_height = _balance.photo_frame_half
	viewfinder.ring_fraction = _balance.photo_perfect_radius


func open(at: Viewpoint) -> void:
	viewpoint = at
	scoring = PhotoScoring.new(_balance)
	viewfinder.shots_total = scoring.shots_left
	viewfinder.shots_left = scoring.shots_left
	result_panel.modulate.a = 0.0
	hint_label.visible = true
	flash.color.a = 0.0
	_cooldown = 0.0
	_best_known = int(GameState.record(GameState.current_trail_id).photos.get(String(at.viewpoint_id), 0))
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func frame_center() -> Vector2:
	return get_viewport_rect().size * 0.5


## Takes a photo with the subject at `subject_screen` (viewport coordinates).
## Returns the shot's quality, or -1 if no shot was taken (cooling down / no film).
func shoot_at(subject_screen: Vector2) -> int:
	if not visible or _cooldown > 0.0 or not scoring.has_film():
		return -1
	_cooldown = SHOT_COOLDOWN
	var q: int = scoring.shoot(subject_screen, frame_center())
	viewfinder.shots_left = scoring.shots_left
	hint_label.visible = false
	_flash()
	_show_result(q)
	_pop_postcard(q)
	AudioManager.play_shutter()
	shot_taken.emit(viewpoint.viewpoint_id, q)
	if not scoring.has_film():
		get_tree().create_timer(EMPTY_ROLL_CLOSE_DELAY).timeout.connect(close)
	return q


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	# A tap on the close button closes; it must not also fire the shutter.
	var on_close: bool = touch != null and close_button.get_global_rect().has_point(touch.position)
	var shutter: bool = (touch != null and touch.pressed and not on_close) or event.is_action_pressed("jump")
	if shutter:
		get_viewport().set_input_as_handled()
		shoot_at(viewpoint.subject_screen_position())
	elif event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _flash() -> void:
	flash.color.a = 0.9
	create_tween().tween_property(flash, "color:a", 0.0, 0.35).set_ease(Tween.EASE_OUT)


func _pop_postcard(q: int) -> void:
	var caption: String = PostcardPop.caption_for(q, _best_known)
	_best_known = maxi(_best_known, q)
	var trail: TrailData = ContentDB.get_trail(GameState.current_trail_id)
	if caption.is_empty() or trail == null:
		return
	for vp: ViewpointData in trail.viewpoints:
		if vp.id == viewpoint.viewpoint_id:
			PostcardPop.pop(self, trail, vp, q, caption)


func _show_result(q: int) -> void:
	result_label.text = tr(RESULT_KEYS[q])
	result_label.add_theme_color_override("font_color", Postcard.border_color(q) if q > 0 else Color("#FFF6E5"))
	result_panel.pivot_offset = result_panel.size * 0.5
	result_panel.scale = Vector2(0.6, 0.6)
	result_panel.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(result_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.9)
	tween.tween_property(result_panel, "modulate:a", 0.0, 0.3)
