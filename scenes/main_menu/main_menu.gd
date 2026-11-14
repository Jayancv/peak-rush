extends Control
## Title screen: a postcard-style title card over a slowly panning panorama, with
## the hiker resting on a hill. "Continue" opens the next unfinished trail directly;
## "All trails" opens trail select. The banner names the newest season.

## Gentle pan of the scenery behind the menu (px/s at full parallax depth). UI motion, not gameplay.
const PAN_SPEED: float = 22.0
const BANNER_RADIUS: int = 22

@export var play_button: Button
@export var journal_button: Button
@export var settings_button: Button
@export var profile_button: Button
@export var continue_button: Button
@export var gear_button: Button
@export var banner: PanelContainer
@export var banner_label: Label
@export var backdrop: Node

var _next: TrailData
static var _startup_logged: bool = false


func _ready() -> void:
	AudioManager.enter_menu()
	play_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.TRAIL_SELECT))
	journal_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.JOURNAL))
	settings_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.SETTINGS))
	gear_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.GEAR))
	profile_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.PROFILE))
	continue_button.pressed.connect(_on_continue)
	_setup_banner()
	_setup_continue()
	if not DisplayServer.is_touchscreen_available():
		(continue_button if continue_button.visible else play_button).grab_focus()
	_add_daily_button()
	_add_steps_button()
	_add_journey_button()
	# Ad consent waits until ads matter (see Ads); this only catches players past the grace period.
	_ask_consent.call_deferred()
	_start_panning()
	UiMotion.intro([$SafeArea/VBox/Card, banner, continue_button, play_button, journal_button, gear_button, settings_button, profile_button], 0.1)
	if OS.is_debug_build() and not _startup_logged:
		_startup_logged = true
		print("PERF startup_to_menu_ms=%d" % Time.get_ticks_msec())


## "Journey" in the button row (after All trails): marked while a notebook page is unread.
func _add_journey_button() -> void:
	if ContentDB.journeys().is_empty():
		return
	var button: Button = Button.new()
	button.name = "JourneyButton"
	button.custom_minimum_size = play_button.custom_minimum_size
	button.add_theme_font_size_override("font_size", play_button.get_theme_font_size("font_size"))
	button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.JOURNEY))
	play_button.get_parent().add_child(button)
	play_button.get_parent().move_child(button, play_button.get_index() + 1)
	var update: Callable = func() -> void:
		if not is_instance_valid(button):
			return
		var fresh: bool = Journey.unread(GameState.profile) > 0
		button.text = tr("MENU_JOURNEY_NEW") if fresh else tr("MENU_JOURNEY")
		button.theme_type_variation = &"PrimaryButton" if fresh else &""
	update.call()
	# Claiming steps on this screen can open a new page.
	GameState.progress_changed.connect(update)
	UiMotion.intro([button], 0.35)


## "Daily" next to the profile button: highlighted until today's daily is done.
func _add_daily_button() -> void:
	var d: Dictionary = GameState.daily_today()
	if d.is_empty():
		return
	var button: Button = Button.new()
	var streak: int = GameState.profile.daily_streak
	button.text = tr("DAILY_PILL") + ("  ·  %d" % streak if streak > 0 else "")
	button.custom_minimum_size = Vector2(0, 80)
	button.add_theme_font_size_override("font_size", 26)
	button.theme_type_variation = &"" if d.done else &"PrimaryButton"
	button.pressed.connect(func() -> void: DailyCard.open(self))
	profile_button.get_parent().add_child(button)
	UiMotion.intro([button], 0.5)


## Real steps (M9): only while the step counter is on (see StepsButton).
func _add_steps_button() -> void:
	if not Steps.is_on():
		return
	var button: StepsButton = StepsButton.create(profile_button.get_parent(), self)
	UiMotion.intro([button], 0.55)


## Deferred from _ready; skipped if the menu was left (and freed) in the same frame.
func _ask_consent() -> void:
	if is_inside_tree():
		Ads.ensure_consent(self)


func _setup_banner() -> void:
	var seasons: Array[SeasonData] = ContentDB.seasons()
	if seasons.is_empty():
		banner.visible = false
		return
	var newest: SeasonData = seasons[seasons.size() - 1]
	banner_label.text = tr("MENU_SEASON") % seasons.size() + "  ·  " + tr(newest.title_key)
	var ev: EventData = SeasonalEvents.active(ContentDB.events(), GameState.today())
	if ev != null:
		banner_label.text += "  ·  " + tr(ev.name_key)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = newest.theme_color
	box.set_corner_radius_all(BANNER_RADIUS)
	box.content_margin_left = 22.0
	box.content_margin_right = 22.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 6.0
	banner.add_theme_stylebox_override("panel", box)


func _setup_continue() -> void:
	_next = GameState.next_trail_to_play()
	if _next == null:
		# Everything open is done: no Continue, the banner says so.
		continue_button.visible = false
		banner_label.text += "  ·  " + tr("MENU_ALL_DONE")
		play_button.theme_type_variation = &"PrimaryButton"
		return
	var label_key: String = "MENU_PLAY" if GameState.trails.is_empty() else "MENU_CONTINUE"
	continue_button.text = tr(label_key) + "  ·  " + tr(_next.name_key)


func _on_continue() -> void:
	GameState.current_trail_id = _next.id
	SceneRouter.go_to(SceneRouter.TRAIL_RUNNER)


func _start_panning() -> void:
	if backdrop == null or UiMotion.reduced():
		return
	for child: Node in backdrop.get_children():
		var layer: Parallax2D = child as Parallax2D
		if layer != null:
			# Nearer layers move faster, which is what sells the depth.
			layer.autoscroll.x -= PAN_SPEED * layer.scroll_scale.x


func _notification(what: int) -> void:
	# Android back on the title screen leaves the app, as players expect.
	# Every node hears back; an open Daily card closes itself instead of the app quitting.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _popup_open():
		get_tree().quit()


func _popup_open() -> bool:
	for child: Node in get_children():
		if child is DailyCard and not child.is_queued_for_deletion():
			return true
	return false
