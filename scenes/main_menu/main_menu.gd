extends Control
## Title screen, seen from inside a mountain hut (HutRoom): the title card in the window,
## a slowly panning panorama outside lit by the real clock, seasonal weather, and the
## player's keepsakes on the walls (HutWall). "Continue" opens the next unfinished trail
## directly; "All trails" opens trail select. The banner names the newest season.

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
var _hut: HutRoom
static var _startup_logged: bool = false


func _ready() -> void:
	AudioManager.enter_menu()
	play_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.TRAIL_SELECT))
	journal_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.JOURNAL))
	settings_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.SETTINGS))
	gear_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.GEAR))
	profile_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.PROFILE))
	continue_button.pressed.connect(_on_continue)
	_setup_hut()
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
		if is_instance_valid(_hut):
			_hut.notebook_fresh = fresh
	update.call()
	# Claiming steps on this screen can open a new page.
	GameState.progress_changed.connect(update)
	UiMotion.intro([button], 0.35)


## The hut around the window: built in code and slotted under the UI.
func _setup_hut() -> void:
	var b: Balance = ContentDB.balance
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var hour: float = float(now.hour) + float(now.minute) / 60.0
	if HutRoom.hour_override >= 0.0:
		hour = HutRoom.hour_override
	if HutRoom.month_override > 0:
		now.month = HutRoom.month_override
	var ui_index: int = $SafeArea.get_index()
	# The view outside takes the light of the real hour (multiplied over the landscape).
	var outside: ColorRect = ColorRect.new()
	outside.name = "OutsideLight"
	outside.color = HutView.tint(hour, b)
	var mul: CanvasItemMaterial = CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	outside.material = mul
	outside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outside)
	move_child(outside, ui_index)
	var weather: CPUParticles2D = HutWeather.create(HutView.weather(int(now.month)), get_viewport_rect().size)
	if weather != null:
		add_child(weather)
		move_child(weather, ui_index + 1)
	_hut = HutRoom.new()
	_hut.name = "Hut"
	_hut.phase = HutView.phase(hour, b)
	_hut.show_notebook = not ContentDB.journeys().is_empty()
	_hut.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hut)
	move_child(_hut, $SafeArea.get_index())
	var wall: HutWall = HutWall.new()
	wall.name = "Keepsakes"
	wall.room = _hut
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hut.add_child(wall)
	var trails: Array[TrailData] = []
	for s: SeasonData in ContentDB.seasons():
		trails.append_array(s.trails)
	var badges: Array[BadgeData] = []
	for badge: BadgeData in ContentDB.badge_list():
		if GameState.profile.badges.has(String(badge.id)):
			badges.append(badge)
	# Elsa's photo takes the first pin.
	wall.fill(HutView.wall_postcards(GameState.trails, trails, b.hut_wall_postcards - 1),
		HutView.shelf_finds(GameState.trails, trails, b.hut_shelf_slots), badges)
	var scenery: Backdrop = backdrop as Backdrop
	if scenery != null:
		if _hut.phase == HutView.Phase.NIGHT:
			scenery.sun_anchor.visible = false
		else:
			scenery.set_daylight(HutView.sun_progress(hour, b), HutView.tint(hour, b))
			# The light rect already tints the sky; keep only the sun's place and the warm glow.
			scenery.sky.modulate = Color.WHITE
	_seat_hiker()


## The player's hiker sits on the stool by the wall, in their own outfit, breathing slowly.
## Physics is off (no floor in here); the sitting pose is set by hand.
func _seat_hiker() -> void:
	var hiker: Hiker = get_node_or_null("Hiker") as Hiker
	if hiker == null:
		return
	hiker.process_mode = Node.PROCESS_MODE_DISABLED
	# In front of the walls, still under the buttons.
	move_child(hiker, _hut.get_index() + 1)
	var light: float = _hut.room_light()
	hiker.modulate = Color(light, light, light)
	var pose: HikerVisual = hiker.visual
	pose.front_leg.rotation = HikerVisual.SIT_FRONT_LEG
	pose.back_leg.rotation = HikerVisual.SIT_BACK_LEG
	pose.arm.rotation = HikerVisual.SIT_ARM
	pose.position.y = HikerVisual.SIT_DROP
	var place: Callable = func() -> void:
		if is_instance_valid(_hut):
			hiker.position = _hut.seat_point()
	# The hut is full-screen: `resized` fires once layout gives it a size (and on rotation).
	_hut.resized.connect(place)
	place.call()
	if not UiMotion.reduced():
		var breath: Tween = create_tween().set_loops()
		breath.tween_property(pose, "scale:y", 1.03, 1.3).set_trans(Tween.TRANS_SINE)
		breath.tween_property(pose, "scale:y", 1.0, 1.3).set_trans(Tween.TRANS_SINE)


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
