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
@export var continue_button: Button
@export var gear_button: Button
@export var banner: PanelContainer
@export var banner_label: Label
@export var backdrop: Node

var _next: TrailData


func _ready() -> void:
	AudioManager.enter_menu()
	play_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.TRAIL_SELECT))
	journal_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.JOURNAL))
	settings_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.SETTINGS))
	gear_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.GEAR))
	continue_button.pressed.connect(_on_continue)
	_setup_banner()
	_setup_continue()
	if not DisplayServer.is_touchscreen_available():
		(continue_button if continue_button.visible else play_button).grab_focus()
	_start_panning()


func _setup_banner() -> void:
	var seasons: Array[SeasonData] = ContentDB.seasons()
	if seasons.is_empty():
		banner.visible = false
		return
	var newest: SeasonData = seasons[seasons.size() - 1]
	banner_label.text = tr("MENU_SEASON") % seasons.size() + "  ·  " + tr(newest.title_key)
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
	if backdrop == null:
		return
	for child: Node in backdrop.get_children():
		var layer: Parallax2D = child as Parallax2D
		if layer != null:
			# Nearer layers move faster, which is what sells the depth.
			layer.autoscroll.x -= PAN_SPEED * layer.scroll_scale.x


func _notification(what: int) -> void:
	# Android back on the title screen leaves the app, as players expect.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
