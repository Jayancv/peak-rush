extends Node2D
## Runs one trail: looks up GameState.current_trail_id in ContentDB, instances the
## level, spawns the hiker at its Trailhead, runs the day clock with the trail's
## daylight and weather, and reacts to what the hiker reports (falls, checkpoints,
## summit). On the summit it records the result and moves on to the results screen.

@export var hiker_scene: PackedScene
@export var world: Node2D
@export var camera: HikerCamera
@export var world_tint: CanvasModulate
@export var hud: Hud
@export var touch_controls: TouchControls
@export var pause_menu: PauseMenu
@export var photo_mode: PhotoMode
@export var weather_fx: WeatherFx

## How far below the lowest ground the hiker can drop before it counts as a fall,
## a safety net in case a gap has no KillZone.
const FALL_MARGIN: float = 200.0

## Pause between touching the cairn and the results screen, to let the moment land.
const SUMMIT_PAUSE: float = 1.2

var trail: TrailData
var hiker: Hiker
var daylight: Daylight
var weather: WeatherEffects
var finished: bool = false
## Best photo this hike per viewpoint id (String -> StarRating.PhotoQuality).
var photos: Dictionary = {}

var _balance: Balance
var _backdrop: Backdrop
var _respawn_point: Vector2
var _fall_limit_y: float = INF
var _respawning: bool = false
var _bench_explained: bool = false
var _near_viewpoint: Viewpoint
var _gust_explained: bool = false


func _ready() -> void:
	_balance = ContentDB.balance
	trail = ContentDB.get_trail(GameState.current_trail_id)
	if trail == null:
		# Started directly (F6 in the editor, tests): fall back to the first trail.
		trail = ContentDB.first_trail()
		GameState.current_trail_id = trail.id
	daylight = Daylight.new(_balance, trail.daylight_seconds, trail.night)
	daylight.phase_changed.connect(_on_phase_changed)
	weather = WeatherEffects.new(trail.weather, hash(trail.id))
	weather.gust_started.connect(_on_gust_started)
	weather_fx.apply(trail.weather)
	AudioManager.stop_music()
	AudioManager.play_ambience(trail.ambience_kind())
	hud.pause_pressed.connect(pause)
	hud.set_low_fraction(_balance.low_stamina_fraction)
	pause_menu.resume_pressed.connect(resume)
	pause_menu.restart_pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.TRAIL_RUNNER))
	pause_menu.quit_pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.TRAIL_SELECT))
	hud.photo_pressed.connect(start_photo)
	photo_mode.shot_taken.connect(_on_shot_taken)
	photo_mode.closed.connect(_on_photo_closed)
	_load_trail()
	_apply_daylight()
	PerfProbe.attach_if_debug(self)


func _load_trail() -> void:
	var level: Node2D = (load(trail.scene_path) as PackedScene).instantiate() as Node2D
	world.add_child(level)
	var trailhead: Marker2D = level.get_node_or_null("Trailhead") as Marker2D
	if trailhead == null:
		push_error("TrailRunner: %s has no Trailhead marker" % trail.scene_path)
		return
	for node: Node in get_tree().get_nodes_in_group(Backdrop.GROUP):
		if level.is_ancestor_of(node):
			_backdrop = node as Backdrop
	weather_fx.add_world_fog(trail.weather, level, _backdrop, camera)
	hiker = hiker_scene.instantiate() as Hiker
	world.add_child(hiker)
	hiker.teleport(trailhead.global_position)
	hiker.condition.weather_drain_mult = trail.weather_drain()
	hiker.condition.set_gear(GameState.equipped_items())
	if trail.night:
		# Dark from the start: lamp on, but no slowdown until the window closes.
		hiker.visual.set_headlamp(true)
	_respawn_point = trailhead.global_position
	hiker.stamina_changed.connect(_on_stamina_changed)
	hiker.exhausted.connect(func() -> void: hud.show_toast("TOAST_EXHAUSTED"))
	hiker.stumbled.connect(_on_stumbled)
	hiker.fell.connect(_on_hiker_fell)
	hiker.checkpoint_reached.connect(_on_checkpoint_reached)
	hiker.reached_finish.connect(_on_reached_finish)
	hiker.regen_changed.connect(_on_regen_changed)
	var bounds: Rect2 = TerrainStrip.bounds_under(level)
	_fall_limit_y = bounds.end.y + FALL_MARGIN
	camera.target = hiker
	camera.set_bounds(bounds)
	camera.snap_to_target()
	var stamina: Stamina = hiker.condition.stamina
	hud.set_stamina(stamina.value, stamina.max_value, stamina.recovering)
	for node: Node in get_tree().get_nodes_in_group(Viewpoint.GROUP):
		var vp: Viewpoint = node as Viewpoint
		if vp != null and level.is_ancestor_of(vp):
			vp.hiker_entered.connect(_on_viewpoint_entered)
			vp.hiker_left.connect(_on_viewpoint_left)
	_update_photo_count()
	if trail.tutorial and not GameState.is_completed(trail.id):
		for node: Node in get_tree().get_nodes_in_group(TutorialTrigger.GROUP):
			if level.is_ancestor_of(node):
				(node as TutorialTrigger).triggered.connect(func(key: String, secs: float) -> void: hud.show_toast(key, secs))


func _process(delta: float) -> void:
	if finished or hiker == null:
		return
	daylight.advance(delta)
	weather.advance(delta)
	hiker.condition.wind_push = weather.wind_push()
	weather_fx.set_gusting(weather.is_gusting())
	_apply_daylight()
	if hiker.global_position.y > _fall_limit_y:
		_on_hiker_fell()


func pause() -> void:
	if finished or get_tree().paused:
		return
	touch_controls.release_all()
	get_tree().paused = true
	pause_menu.open_pause(tr(trail.name_key))


func resume() -> void:
	pause_menu.close()
	get_tree().paused = false


## Opens photo mode at the viewpoint the hiker is standing at.
func start_photo() -> void:
	if _near_viewpoint == null or photo_mode.is_open() or not hiker.enter_photo():
		return
	touch_controls.set_enabled(false)
	hud.set_photo_mode(true)
	camera.frame(_near_viewpoint.frame_center(), _balance.photo_zoom)
	photo_mode.open(_near_viewpoint)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if photo_mode.is_open():
			photo_mode.close()
		elif not finished:
			pause()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Android back: opens the pause card, or closes it if it's already open.
			if finished:
				return
			if photo_mode.is_open():
				photo_mode.close()
			elif get_tree().paused:
				resume()
			else:
				pause()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			# A phone call or the home button shouldn't let the sun keep setting.
			pause()


func _apply_daylight() -> void:
	var tint: Color = daylight.tint()
	world_tint.color = tint
	weather_fx.set_tint(tint)
	if _backdrop != null:
		_backdrop.set_daylight(daylight.sun_progress(), tint)
	hud.set_daylight(daylight.sun_progress(), daylight.phase(), trail.night)


func _on_phase_changed(phase: Daylight.Phase) -> void:
	if phase == Daylight.Phase.DUSK:
		hiker.set_dusk(true)
		hud.show_toast("TOAST_AURORA_FADES" if trail.night else "TOAST_DUSK")


func _on_stamina_changed(value: float, max_value: float) -> void:
	hud.set_stamina(value, max_value, hiker.condition.stamina.recovering)


func _on_regen_changed(mode: HikerCondition.Regen) -> void:
	hud.set_regen(mode)
	# Explain benches the first time one is used; after that the ×2 badge says it.
	if mode == HikerCondition.Regen.BENCH and not _bench_explained:
		_bench_explained = true
		hud.show_toast("TOAST_BENCH")


func _on_checkpoint_reached(respawn_position: Vector2) -> void:
	_respawn_point = respawn_position
	hud.show_toast("TOAST_CHECKPOINT")


func _on_hiker_fell() -> void:
	if _respawning:
		return
	_respawning = true
	_vibrate(_balance.fall_vibrate_ms)
	camera.shake(_balance.shake_fall_px)
	SceneRouter.cover(func() -> void:
		hiker.respawn(_respawn_point)
		camera.snap_to_target()
		_respawning = false
	)


func _on_reached_finish() -> void:
	finished = true
	touch_controls.release_all()
	hiker.visual.celebrate()
	var result: TrailResult = TrailResult.new(trail.id)
	result.finished = true
	result.time_seconds = daylight.elapsed
	result.before_dusk = not daylight.is_dusk()
	result.viewpoint_total = trail.viewpoints.size()
	for id: String in photos:
		if int(photos[id]) > StarRating.PhotoQuality.NONE:
			result.photos[id] = photos[id]
	GameState.record_result(result)
	await get_tree().create_timer(SUMMIT_PAUSE).timeout
	SceneRouter.go_to(SceneRouter.RESULTS)


func _on_stumbled() -> void:
	_vibrate(_balance.stumble_vibrate_ms)
	camera.shake(_balance.shake_stumble_px)


func _on_gust_started() -> void:
	# Explain wind once; afterwards the streaks and the push say it.
	if not _gust_explained:
		_gust_explained = true
		hud.show_toast("TOAST_GUST")


func _on_viewpoint_entered(vp: Viewpoint) -> void:
	_near_viewpoint = vp
	hud.show_photo_prompt(not finished)


func _on_viewpoint_left(vp: Viewpoint) -> void:
	if _near_viewpoint == vp:
		_near_viewpoint = null
		hud.show_photo_prompt(false)


func _on_shot_taken(viewpoint_id: StringName, quality: int) -> void:
	var key: String = String(viewpoint_id)
	photos[key] = maxi(int(photos.get(key, StarRating.PhotoQuality.NONE)), quality)
	_update_photo_count()


func _on_photo_closed() -> void:
	hiker.exit_photo()
	camera.release_frame()
	touch_controls.set_enabled(true)
	hud.set_photo_mode(false)
	hud.show_photo_prompt(_near_viewpoint != null and not finished)


func _update_photo_count() -> void:
	var taken: int = 0
	for id: String in photos:
		if int(photos[id]) > StarRating.PhotoQuality.NONE:
			taken += 1
	hud.set_photos(taken, trail.viewpoints.size())


func _vibrate(ms: int) -> void:
	if bool(GameState.settings.get("vibration", true)):
		Input.vibrate_handheld(ms)

