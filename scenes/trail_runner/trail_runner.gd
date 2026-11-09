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

## How far below the lowest ground the hiker can drop before it counts as a fall,
## a safety net in case a gap has no KillZone.
const FALL_MARGIN: float = 200.0

## Pause between touching the cairn and the results screen, to let the moment land.
const SUMMIT_PAUSE: float = 1.2

var trail: TrailData
var hiker: Hiker
var daylight: Daylight
var finished: bool = false

var _balance: Balance
var _backdrop: Backdrop
var _respawn_point: Vector2
var _fall_limit_y: float = INF
var _respawning: bool = false
var _bench_explained: bool = false


func _ready() -> void:
	_balance = ContentDB.balance
	trail = ContentDB.get_trail(GameState.current_trail_id)
	if trail == null:
		# Started directly (F6 in the editor, tests): fall back to the first trail.
		trail = ContentDB.first_trail()
		GameState.current_trail_id = trail.id
	daylight = Daylight.new(_balance, trail.daylight_seconds)
	daylight.phase_changed.connect(_on_phase_changed)
	hud.pause_pressed.connect(pause)
	hud.set_low_fraction(_balance.low_stamina_fraction)
	pause_menu.resume_pressed.connect(resume)
	pause_menu.restart_pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.TRAIL_RUNNER))
	pause_menu.quit_pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.TRAIL_SELECT))
	_load_trail()
	_apply_daylight()


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
	hiker = hiker_scene.instantiate() as Hiker
	world.add_child(hiker)
	hiker.teleport(trailhead.global_position)
	hiker.condition.weather_drain_mult = trail.weather_drain()
	_respawn_point = trailhead.global_position
	hiker.stamina_changed.connect(_on_stamina_changed)
	hiker.exhausted.connect(func() -> void: hud.show_toast("TOAST_EXHAUSTED"))
	hiker.stumbled.connect(func() -> void: _vibrate(_balance.stumble_vibrate_ms))
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
	# Viewpoints arrive in M4; the counter already shows how many a trail has.
	hud.set_photos(0, get_tree().get_nodes_in_group(&"viewpoint").size())


func _process(delta: float) -> void:
	if finished or hiker == null:
		return
	daylight.advance(delta)
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if not finished:
			pause()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Android back: opens the pause card, or closes it if it's already open.
			if finished:
				return
			if get_tree().paused:
				resume()
			else:
				pause()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			# A phone call or the home button shouldn't let the sun keep setting.
			pause()


func _apply_daylight() -> void:
	var tint: Color = daylight.tint()
	world_tint.color = tint
	if _backdrop != null:
		_backdrop.set_daylight(daylight.sun_progress(), tint)
	hud.set_daylight(daylight.sun_progress(), daylight.phase())


func _on_phase_changed(phase: Daylight.Phase) -> void:
	if phase == Daylight.Phase.DUSK:
		hiker.set_dusk(true)
		hud.show_toast("TOAST_DUSK")


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
	SceneRouter.cover(func() -> void:
		hiker.respawn(_respawn_point)
		camera.snap_to_target()
		_respawning = false
	)


func _on_reached_finish() -> void:
	finished = true
	touch_controls.release_all()
	var result: TrailResult = TrailResult.new(trail.id)
	result.finished = true
	result.time_seconds = daylight.elapsed
	result.before_dusk = not daylight.is_dusk()
	result.viewpoint_total = trail.viewpoints.size()
	# Photos are taken in M4; until then the result simply has none.
	GameState.record_result(result)
	await get_tree().create_timer(SUMMIT_PAUSE).timeout
	SceneRouter.go_to(SceneRouter.RESULTS)


func _vibrate(ms: int) -> void:
	if bool(GameState.settings.get("vibration", true)):
		Input.vibrate_handheld(ms)

