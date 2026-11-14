class_name StepsButton
extends Button
## Main menu: today's real steps (M9), highlighted with "+N TP" while there's TP to claim.
## A tap claims it with a count-up and shows any badges the steps earned. It re-reads the
## phone when the app comes back to the front (steps walked meanwhile), and hides itself
## if the phone stops letting us read.

const COUNT_SECONDS: float = 0.8

## Where the badge pills appear (the menu screen).
var pills_parent: Control
var _pending: int = 0
var _claiming: bool = false


static func create(parent: Control, pills_on: Control) -> StepsButton:
	var b: StepsButton = StepsButton.new()
	b.name = "StepsButton"
	b.pills_parent = pills_on
	b.custom_minimum_size = Vector2(0, 80)
	b.add_theme_font_size_override("font_size", 26)
	parent.add_child(b)
	return b
## "+21 km on Kungsleden" after a claim, when the steps walked the journey on.
var _journey_note: String = ""


func _ready() -> void:
	pressed.connect(_claim)
	_show_count(0, 0)
	refresh()


func refresh() -> void:
	if _claiming:
		return
	Steps.refresh(func(pending: int) -> void:
		if not is_instance_valid(self):
			return
		visible = Steps.is_on()
		_pending = pending
		_show_count(Steps.today_steps(), pending))


func _show_count(steps: int, pending: int) -> void:
	text = tr("STEPS_PILL_PENDING") % [steps, pending] if pending > 0 else tr("STEPS_PILL") % steps
	disabled = pending <= 0
	theme_type_variation = &"PrimaryButton" if pending > 0 else &""


func _claim() -> void:
	if _pending <= 0 or _claiming:
		return
	var out: Dictionary = Steps.claim()
	var tp: int = int(out.tp)
	_pending = 0
	if tp <= 0:
		_show_count(Steps.today_steps(), 0)
		return
	AudioManager.play_find()
	disabled = true
	theme_type_variation = &""
	var ids: Array = (out.badges as Array).map(func(b: BadgeData) -> String: return String(b.id))
	_journey_note = ""
	var walked: Dictionary = out.get("journey", {})
	if not walked.is_empty():
		_journey_note = "  ·  " + tr("STEPS_JOURNEY") % [roundi(float(walked.added)), tr(walked.name_key)]
	if UiMotion.reduced():
		_set_claimed(tp)
		_after_claim(ids)
		return
	_claiming = true
	var tween: Tween = create_tween()
	tween.tween_method(_set_claimed, 0, tp, COUNT_SECONDS).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_claiming = false
		_after_claim(ids))


func _set_claimed(value: int) -> void:
	text = tr("STEPS_CLAIMED") % value + _journey_note


func _after_claim(badge_ids: Array) -> void:
	if pills_parent != null and is_instance_valid(pills_parent):
		BadgePills.show(pills_parent, badge_ids)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		refresh()
