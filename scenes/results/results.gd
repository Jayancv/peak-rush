extends Control
## After the summit: stars pop in one by one, Trail Points count up, and the
## passport stamp thumps down. Reads GameState.last_result (set by the trail runner).

const STAR_ON: Color = Color("#F2B33D")
const STAR_OFF: Color = Color(0.168627, 0.176471, 0.258824, 0.25)
const STAR_DELAY: float = 0.35
const COUNT_SECONDS: float = 1.0

@export var trail_label: Label
@export var stars: Array[UiIcon] = []
@export var star_tags: Array[Label] = []
## Caption under the third star (dusk, or e.g. the aurora window on night trails).
@export var star3_caption: Label
@export var time_label: Label
@export var best_tag: Control
@export var par_label: Label
@export var tp_breakdown: Label
@export var tp_total: Label
@export var stamp: PassportStamp
@export var card: Control
@export var next_button: Button
@export var replay_button: Button
@export var trails_button: Button

var _result: Dictionary
var _trail: TrailData
var _next: TrailData


func _ready() -> void:
	_result = GameState.last_result
	AudioManager.enter_menu()
	_trail = ContentDB.get_trail(StringName(_result.get("trail_id", GameState.current_trail_id)))
	if _trail == null:
		_trail = ContentDB.first_trail()
	_next = ContentDB.next_trail(_trail.id)
	next_button.visible = _next != null and GameState.is_unlocked(_next)
	next_button.pressed.connect(_play.bind(_next))
	replay_button.pressed.connect(_play.bind(_trail))
	trails_button.pressed.connect(_to_trails)
	if next_button.visible and not DisplayServer.is_touchscreen_available():
		next_button.grab_focus()
	_fill()
	_animate()


func _fill() -> void:
	trail_label.text = tr(_trail.name_key)
	star3_caption.text = tr(_trail.star3_key)
	time_label.text = tr("RESULTS_TIME") % TimeFormat.mmss(float(_result.get("time", 0.0)))
	par_label.text = tr("RESULTS_PAR") % TimeFormat.mmss(_trail.par_time)
	best_tag.visible = bool(_result.get("new_best", false))
	var lines: PackedStringArray = PackedStringArray()
	lines.append(tr("RESULTS_TP_FINISH") % int(_result.get("finish", 0)))
	if int(_result.get("stars", 0)) > 0:
		lines.append(tr("RESULTS_TP_STARS") % int(_result.get("stars", 0)))
	if int(_result.get("photos", 0)) > 0:
		lines.append(tr("RESULTS_TP_PHOTOS") % int(_result.get("photos", 0)))
	tp_breakdown.text = "\n".join(lines)
	tp_total.text = tr("HUD_TP") % 0
	var date: Dictionary = Time.get_date_dict_from_system()
	stamp.title = tr(_trail.name_key).to_upper()
	stamp.subtitle = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	for i: int in stars.size():
		stars[i].kind = UiIcon.Kind.STAR_EMPTY
		stars[i].color = STAR_OFF
		star_tags[i].modulate.a = 0.0
	stamp.modulate.a = 0.0


func _animate() -> void:
	var mask: int = int(_result.get("stars_mask", 0))
	var new_mask: int = int(_result.get("new_stars_mask", 0))
	var bits: Array[int] = [StarRating.STAR_SUMMIT, StarRating.STAR_PHOTOS, StarRating.STAR_BEFORE_DUSK]
	var tween: Tween = create_tween()
	tween.tween_interval(0.35)
	for i: int in stars.size():
		if mask & bits[i] == 0:
			continue
		tween.tween_callback(_light_star.bind(i, new_mask & bits[i] != 0))
		tween.tween_interval(STAR_DELAY)
	tween.tween_method(_set_tp, 0, int(_result.get("total", 0)), COUNT_SECONDS).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_land_stamp)


func _light_star(i: int, is_new: bool) -> void:
	var star: UiIcon = stars[i]
	star.kind = UiIcon.Kind.STAR
	star.color = STAR_ON
	star.pivot_offset = star.size * 0.5
	star.scale = Vector2(1.8, 1.8)
	create_tween().tween_property(star, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	if is_new:
		create_tween().tween_property(star_tags[i], "modulate:a", 1.0, 0.25)


func _set_tp(value: int) -> void:
	tp_total.text = tr("HUD_TP") % value


func _land_stamp() -> void:
	# Comes down big and slightly transparent, then thumps onto the card.
	stamp.pivot_offset = stamp.size * 0.5
	stamp.scale = Vector2(2.4, 2.4)
	var tween: Tween = create_tween()
	tween.tween_property(stamp, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(stamp, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_thump)


func _thump() -> void:
	var start: Vector2 = card.position
	var tween: Tween = create_tween()
	for offset: Vector2 in [Vector2(6, 4), Vector2(-5, -3), Vector2(3, 2), Vector2.ZERO]:
		tween.tween_property(card, "position", start + offset, 0.04)
	if bool(GameState.settings.get("vibration", true)):
		Input.vibrate_handheld(ContentDB.balance.stumble_vibrate_ms)


func _play(trail: TrailData) -> void:
	GameState.current_trail_id = trail.id
	SceneRouter.go_to(SceneRouter.TRAIL_RUNNER)


func _to_trails() -> void:
	SceneRouter.go_to(SceneRouter.TRAIL_SELECT)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_to_trails()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_to_trails()
