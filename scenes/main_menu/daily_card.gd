class_name DailyCard
extends Control
## The daily trail popup on the main menu: today's trail and twist, the reward and
## the streak, with Start (or "done for today").

const INK: Color = Color("#2B2D42")
const MUTED: Color = Color(0.168627, 0.176471, 0.258824, 0.65)
const ACCENT: Color = Color("#B8432C")


static func open(parent: Control) -> DailyCard:
	var card: DailyCard = DailyCard.new()
	parent.add_child(card)
	card._build()
	return card


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.168627, 0.176471, 0.258824, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed or e is InputEventScreenTouch and e.pressed:
			queue_free())
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var d: Dictionary = GameState.daily_today()
	box.add_child(_label(tr("DAILY_TITLE"), 40, INK))
	if d.is_empty():
		queue_free()
		return
	var trail: TrailData = ContentDB.get_trail(d.trail_id)
	box.add_child(_label(tr(trail.name_key), 30, ACCENT))
	box.add_child(_label(tr(DailyChallenge.TWIST_KEYS[int(d.twist)]), 24, INK))
	var streak: int = GameState.profile.daily_streak
	var next_streak: int = DailyChallenge.next_streak(GameState.profile.daily_last, d.date, streak)
	if d.done:
		box.add_child(_label(tr("DAILY_DONE"), 22, MUTED))
	else:
		box.add_child(_label(tr("DAILY_REWARD") % DailyChallenge.reward(next_streak, ContentDB.balance), 22, MUTED))
	box.add_child(_label(tr("DAILY_STREAK") % streak, 22, MUTED))
	_add_weekly(box)
	_add_event(box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var close: Button = Button.new()
	close.text = tr("DAILY_CLOSE")
	close.custom_minimum_size = Vector2(180, 68)
	close.pressed.connect(queue_free)
	row.add_child(close)
	if not d.done:
		var start: Button = Button.new()
		start.text = tr("DAILY_START")
		start.theme_type_variation = &"PrimaryButton"
		start.custom_minimum_size = Vector2(200, 68)
		start.pressed.connect(func() -> void:
			GameState.current_trail_id = d.trail_id
			GameState.daily_active = true
			SceneRouter.go_to(SceneRouter.TRAIL_RUNNER))
		row.add_child(start)
	UiMotion.intro([panel])


## This week's goals with progress (WeeklyGoals; read-only here, results pays them).
func _add_weekly(box: VBoxContainer) -> void:
	var b: Balance = ContentDB.balance
	var week: int = WeeklyGoals.week_of(GameState.today())
	var state: Dictionary = WeeklyGoals.current(GameState.profile.weekly, week)
	var line: HSeparator = HSeparator.new()
	box.add_child(line)
	box.add_child(_label(tr("WEEKLY_TITLE") % (b.weekly_goal_tp), 26, INK))
	for goal: int in WeeklyGoals.goals_for(week, b):
		var target: int = WeeklyGoals.target(goal, b)
		var have: int = int(state.progress.get(str(goal), 0))
		var done: bool = (state.done as Array).has(goal)
		var text: String = (tr(WeeklyGoals.KEYS[goal]) % target) + "   " + (tr("WEEKLY_DONE") if done else "%d/%d" % [have, target])
		box.add_child(_label(text, 21, ACCENT if done else MUTED))
	if bool(state.bonus):
		box.add_child(_label(tr("WEEKLY_ALL_DONE"), 20, ACCENT))
	else:
		box.add_child(_label(tr("WEEKLY_BONUS") % b.weekly_all_bonus_tp, 18, MUTED))


## Today's seasonal event: collectibles so far and days left.
func _add_event(box: VBoxContainer) -> void:
	var date: String = GameState.today()
	var ev: EventData = SeasonalEvents.active(ContentDB.events(), date)
	if ev == null:
		return
	var key: String = SeasonalEvents.key_for(ev, date)
	var count: int = int(GameState.profile.events.get(key, 0))
	box.add_child(HSeparator.new())
	var state: String = tr("EVENT_DONE") if GameState.profile.events_done.has(key) else tr("EVENT_ENDS") % SeasonalEvents.days_left(ev, date)
	box.add_child(_label(tr("EVENT_CARD") % [tr(ev.token_key), count, ev.goal, tr(ev.name_key), state], 20, ACCENT))


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		queue_free()
