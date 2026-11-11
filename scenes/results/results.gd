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

## Pause between the stamp landing and the season finale (lets the badges show first).
const FINALE_DELAY: float = 2.2
## The review request waits for the stars and TP to land.
const REVIEW_DELAY: float = 2.8

var _result: Dictionary
## "Watch an ad: +N TP" (built in code; shown only when an ad is ready).
var _ad_button: Button
var _ad_tp: int = 0
var _leaving: bool = false
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
	if bool(_result.get("finished", false)):
		Ads.note_hike_finished()
	_add_ad_button()
	# A review request belongs to a happy moment, after the stars land (never over the finale).
	if SeasonFinale.finished_season(_result, _trail) == null:
		get_tree().create_timer(REVIEW_DELAY).timeout.connect(func() -> void:
			if is_inside_tree() and not _leaving and not Ads.is_showing():
				ReviewPrompt.maybe_ask(self, _result))


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
	if int(_result.get("find_tp", 0)) > 0:
		lines.append(tr("RESULTS_TP_FINDS") % int(_result.get("find_tp", 0)))
	if int(_result.get("challenge_tp", 0)) > 0:
		lines.append(tr("RESULTS_TP_CHALLENGES") % [TrailChallenges.count(int(_result.get("new_challenges", 0))), int(_result.challenge_tp)])
	if bool(_result.get("medal", false)):
		lines.append(tr("RESULTS_MEDAL"))
	var daily: Dictionary = _result.get("daily", {})
	if not daily.is_empty():
		lines.append(tr("RESULTS_DAILY_DONE") % [int(daily.bonus), int(daily.streak)] if daily.done else tr("RESULTS_DAILY_MISSED"))
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
	tween.tween_callback(_show_new_badges)
	# The last trail of a season: after a moment, the season's ending.
	var season: SeasonData = SeasonFinale.finished_season(_result, _trail)
	if season != null:
		tween.tween_interval(FINALE_DELAY)
		tween.tween_callback(func() -> void: SeasonFinale.open(self, season))


## Newly earned badges slide down from the top as small pills.
func _show_new_badges() -> void:
	BadgePills.show(card.get_parent().get_parent(), _result.get("new_badges", []))


func _thump() -> void:
	var start: Vector2 = card.position
	var tween: Tween = create_tween()
	for offset: Vector2 in [Vector2(6, 4), Vector2(-5, -3), Vector2(3, 2), Vector2.ZERO]:
		tween.tween_property(card, "position", start + offset, 0.04)
	if bool(GameState.settings.get("vibration", true)):
		Input.vibrate_handheld(ContentDB.balance.stumble_vibrate_ms)


func _play(trail: TrailData) -> void:
	_leave(func() -> void:
		GameState.current_trail_id = trail.id
		SceneRouter.go_to(SceneRouter.TRAIL_RUNNER))


func _to_trails() -> void:
	_leave(SceneRouter.go_to.bind(SceneRouter.TRAIL_SELECT))


## Every way off this screen goes through here: the one place an interstitial may show.
func _leave(go: Callable) -> void:
	if _leaving or Ads.is_showing():
		return
	_leaving = true
	Ads.between_hikes(self, _trail.tutorial, go)


func _add_ad_button() -> void:
	_ad_tp = Ads.policy.reward_tp(int(_result.get("total", 0))) if Ads.policy != null else 0
	if _ad_tp <= 0 or _result.has("ad_bonus"):
		return
	_ad_button = Button.new()
	_ad_button.text = tr("RESULTS_AD_REWARD") % _ad_tp
	_ad_button.custom_minimum_size = Vector2(0, 64)
	_ad_button.add_theme_font_size_override("font_size", 22)
	_ad_button.visible = Ads.can_offer_reward()
	_ad_button.pressed.connect(func() -> void:
		_ad_button.disabled = true
		Ads.request_rewarded(self, _on_ad_reward, func() -> void:
			if _ad_button != null:
				_ad_button.disabled = false))
	# In the button row, not a row of its own: a busy results card is already tall.
	var buttons: Node = next_button.get_parent()
	buttons.add_child(_ad_button)
	buttons.move_child(_ad_button, 0)


func _process(_delta: float) -> void:
	# Ads load in the background: offer the reward as soon as one is ready.
	if _ad_button != null and not _ad_button.visible and Ads.can_offer_reward():
		_ad_button.visible = true
		UiMotion.intro([_ad_button])


func _on_ad_reward() -> void:
	GameState.add_bonus_tp(_ad_tp)
	_result = GameState.last_result
	tp_breakdown.text += "
" + tr("RESULTS_TP_AD") % _ad_tp
	_set_tp(int(_result.get("total", 0)) + _ad_tp)
	UiMotion.bump(tp_total)
	_ad_button.queue_free()
	_ad_button = null


func _finale() -> SeasonFinale:
	for child: Node in get_children():
		if child is SeasonFinale and not child.is_queued_for_deletion():
			return child as SeasonFinale
	return null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if Ads.is_showing():
			return
		if _finale() != null:
			_finale().queue_free()
		else:
			_to_trails()


func _notification(what: int) -> void:
	# Every node hears back; an open finale closes itself instead.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _finale() == null and not Ads.is_showing():
		_to_trails()
