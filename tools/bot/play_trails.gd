extends Node
## Regression bot: plays trails like a decent first-time player (holds walk, jumps at
## known obstacles from routes/<trail_id>.json or when blocked, rests when tired, takes
## one photo per viewpoint) and fails loudly when a trail breaks.
##
## Usage (from the project folder):
##   godot --headless --path . --fixed-fps 60 tools/bot/bot.tscn                 # every trail
##   godot --headless --path . --fixed-fps 60 tools/bot/bot.tscn -- t03_lapland_fell no_photos
## (A scene, not a `-s` script: `-s` scripts can't use classes that depend on autoloads.)
##
## A trail FAILS if the hiker doesn't finish, falls off the trail, gets stuck, or reaches
## dusk. Finishing over par is only a warning (photos and rests cost time). Exit code 1 on
## any failure, so CI can run it.

const ROUTES: String = "res://tools/bot/routes/"
const STEP: float = 1.0 / 60.0
## Give up on a trail after this long (in-game seconds), or after this long without progress.
const MAX_SECONDS: float = 600.0
const STUCK_SECONDS: float = 20.0
## Don't rest within this distance before a planned jump (a standing jump can fall short).
const NO_REST_BEFORE_JUMP: float = 140.0

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# Live beside the current scene so changing scenes doesn't free the bot.
	var tree: SceneTree = get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var photos: bool = not args.has("no_photos")
	SaveService.autosave = false
	var ids: Array[StringName] = []
	for a: String in args:
		if a.begins_with("t"):
			ids.append(StringName(a))
	if ids.is_empty():
		for season: SeasonData in ContentDB.seasons():
			for trail: TrailData in season.ordered_trails():
				ids.append(trail.id)
	for id: StringName in ids:
		await _play(id, photos)
	print("BOT %s: %d trail(s), %d failed" % ["FAILED" if _failures > 0 else "OK", ids.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _route(id: StringName) -> Array:
	var path: String = ROUTES + String(id) + ".json"
	if not FileAccess.file_exists(path):
		print("  (no route file for %s: jumping only when blocked)" % id)
		return []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (data as Dictionary).get("jumps", []) if data is Dictionary else []


func _tap_jump() -> void:
	Input.action_press(&"jump")
	await get_tree().physics_frame
	Input.action_release(&"jump")


func _play(id: StringName, photos: bool) -> void:
	var jumps: Array = _route(id)
	var trail: TrailData = ContentDB.get_trail(id)
	GameState.current_trail_id = id
	get_tree().change_scene_to_file("res://scenes/trail_runner/trail_runner.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var r: Node = get_tree().current_scene
	var hiker: Hiker = r.get("hiker") as Hiker
	var day: Object = r.get("daylight")
	var falls: Array[float] = []
	var done: Array[bool] = [false]
	hiker.fell.connect(func() -> void: falls.append(hiker.global_position.x))
	hiker.reached_finish.connect(func() -> void: done[0] = true)
	var shot: Dictionary = {}
	var next_jump: int = 0
	var resting: bool = false
	var blocked: float = 0.0
	var blocked_from_x: float = hiker.global_position.x
	var t: float = 0.0
	var best_x: float = hiker.global_position.x
	var since_progress: float = 0.0
	while t < MAX_SECONDS and not done[0] and since_progress < STUCK_SECONDS:
		await get_tree().physics_frame
		t += STEP
		var x: float = hiker.global_position.x
		if x > best_x + 1.0:
			best_x = x
			since_progress = 0.0
		elif not resting:
			since_progress += STEP
		var near: Viewpoint = r.get("_near_viewpoint") as Viewpoint
		if photos and near != null and not shot.has(near.viewpoint_id) and hiker.is_on_floor():
			Input.action_release(&"walk")
			t += await _photo(r, near)
			shot[near.viewpoint_id] = true
			continue
		var jump_ahead: bool = next_jump < jumps.size() and float(jumps[next_jump]) - x < NO_REST_BEFORE_JUMP and float(jumps[next_jump]) - x > -10.0
		var stamina: float = hiker.condition.stamina.value
		if not resting and stamina < 22.0 and hiker.is_on_floor() and not jump_ahead:
			resting = true
		if resting and stamina > 85.0:
			resting = false
		if resting:
			Input.action_release(&"walk")
			continue
		Input.action_press(&"walk")
		while next_jump < jumps.size() and x > float(jumps[next_jump]) + 30.0:
			next_jump += 1
		var want: bool = false
		if next_jump < jumps.size() and x >= float(jumps[next_jump]) and hiker.is_on_floor():
			want = true
			next_jump += 1
		# Blocked = pushing forward but not getting anywhere (speed can flicker against a rock,
		# so judge by distance covered, like a player would).
		if hiker.is_on_floor() and hiker.state == Hiker.State.WALK:
			blocked += STEP
			if x > blocked_from_x + 6.0:
				blocked = 0.0
				blocked_from_x = x
		else:
			blocked = 0.0
			blocked_from_x = x
		if blocked > 0.25:
			want = true
			blocked = 0.0
			blocked_from_x = x
		if want:
			await _tap_jump()
			t += STEP
	Input.action_release(&"walk")
	var elapsed: float = float(day.get("elapsed"))
	var dusk: bool = bool(day.call("is_dusk"))
	var problems: Array[String] = []
	if not done[0]:
		problems.append("did not finish (stuck at x=%.0f)" % hiker.global_position.x if since_progress >= STUCK_SECONDS else "did not finish")
	if not falls.is_empty():
		problems.append("fell at x=%s" % str(falls))
	if dusk:
		problems.append("reached dusk")
	var note: String = ""
	if trail != null and done[0] and elapsed > trail.par_time:
		note = "  (warning: over par %.0f s)" % trail.par_time
	if problems.is_empty():
		print("PASS %s time=%.1f s photos=%d%s" % [id, elapsed, shot.size(), note])
	else:
		_failures += 1
		print("FAIL %s time=%.1f s: %s" % [id, elapsed, ", ".join(problems)])


## Waits for the subject to cross the frame centre, shoots, and returns the time spent.
func _photo(r: Node, near: Viewpoint) -> float:
	await get_tree().physics_frame
	r.call("start_photo")
	var photo: Node = r.get("photo_mode")
	var waited: float = 0.0
	while bool(photo.call("is_open")) and waited < 20.0:
		await get_tree().physics_frame
		waited += STEP
		var at: Vector2 = near.subject_screen_position()
		if at.distance_to(photo.call("frame_center")) < 20.0:
			photo.call("shoot_at", at)
			break
	photo.call("close")
	return waited + STEP
