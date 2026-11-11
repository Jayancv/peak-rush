extends Node
## Takes the Google Play store screenshots: plays into the best moments of the real game
## (with made-up mid-season progress held only in memory) and saves 1920x1080 PNGs.
##
##   godot --path . --resolution 1920x1080 tools/store_shots/store_shots.tscn
## Needs a real window (not --headless). Output: export/store/ (build output, not committed).
## The player's own save is never written: autosave is off and nothing here calls save_game().

const OUT_DIR: String = "res://export/store/"
const SIZE: Vector2i = Vector2i(1920, 1080)
const FEATURE_SIZE: Vector2i = Vector2i(1024, 500)
const STEP: float = 1.0 / 60.0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree: SceneTree = get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	SaveService.autosave = false
	get_window().size = SIZE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_fake_progress()
	# No test-ad cards or consent form in store shots.
	Ads.use_provider(AdProvider.new())
	await _menu_shot(SceneRouter.MAIN_MENU, "08_main_menu")
	await _trail_shot(&"t01_forest_lake", 0.42, "01_forest")
	await _trail_shot(&"t04_fjord_ridge", 0.3, "03_fjord")
	await _trail_shot(&"t05_aurora_summit", 0.5, "04_aurora")
	await _photo_shot(&"t02_archipelago_rocks", "02_photo")
	await _menu_shot(SceneRouter.JOURNAL, "07_journal")
	await _menu_shot(SceneRouter.TRAIL_SELECT, "09_trails")
	# Before the summit: its badge toast outlives the results screen.
	await _feature_graphic()
	get_window().size = SIZE
	await _summit_shots(&"t03_lapland_fell", "05_summit", "06_results")
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://shared_art/icons/icon_512.png"),
		ProjectSettings.globalize_path(OUT_DIR + "icon_512.png"))
	print("STORE SHOTS done -> ", ProjectSettings.globalize_path(OUT_DIR))
	get_tree().quit()


## Four trails done with good photos and most finds; the last one open.
func _fake_progress() -> void:
	GameState.settings["ad_consent"] = "personalized"
	GameState.tp = 1240
	GameState.profile.hiker_name = "Aino"
	GameState.profile.hints_seen.assign(["HINT_FINDS", "HINT_ANIMAL", "HINT_FORK", "HINT_BACK", "HINT_WATER", "HINT_FLOW"])
	GameState.trails = {}
	var trails: Array[TrailData] = ContentDB.seasons()[0].ordered_trails()
	for i: int in trails.size() - 1:
		var t: TrailData = trails[i]
		var rec: Dictionary = TrailRecord.empty()
		rec.stars = StarRating.ALL_STARS if i != 2 else StarRating.STAR_SUMMIT
		rec.best_time = t.par_time * 0.9
		rec.completions = 2
		for vp: ViewpointData in t.viewpoints:
			rec.photos[String(vp.id)] = StarRating.PhotoQuality.PERFECT if i % 2 == 0 else StarRating.PhotoQuality.GREAT
		for f: int in maxi(t.finds.size() - 1, 0):
			rec.finds.append(String(t.finds[f].id))
		rec.challenges = TrailChallenges.ALL if i == 0 else 0
		GameState.trails[String(t.id)] = rec
	GameState.profile.hikes = 9
	GameState.refresh_badges()


## 1024x500 store banner: the menu's title card over its backdrop, without the buttons.
func _feature_graphic() -> void:
	get_window().size = FEATURE_SIZE
	SceneRouter.go_to(SceneRouter.MAIN_MENU)
	await _wait(2.0)
	var menu: Node = get_tree().current_scene
	for path: String in ["SafeArea/VBox/Banner", "SafeArea/VBox/ContinueButton", "SafeArea/VBox/Row",
			"SafeArea/Corner", "SafeArea/CornerLeft"]:
		var n: CanvasItem = menu.get_node_or_null(path)
		if n != null:
			n.modulate.a = 0.0
	await _wait(0.5)
	await RenderingServer.frame_post_draw
	_write(get_viewport().get_texture().get_image(), "feature_graphic", FEATURE_SIZE)


func _menu_shot(path: String, file: String) -> void:
	SceneRouter.go_to(path)
	await _wait(2.0)
	await _save(file)


func _open_trail(id: StringName) -> Node:
	GameState.current_trail_id = id
	GameState.daily_active = false
	get_tree().change_scene_to_file(SceneRouter.TRAIL_RUNNER)
	await get_tree().process_frame
	await get_tree().process_frame
	return get_tree().current_scene


## Walks the hiker in from a little before `at` (fraction of the trail) for a natural pose.
func _trail_shot(id: StringName, at: float, file: String) -> void:
	var r: Node = await _open_trail(id)
	var hiker: Hiker = r.get("hiker")
	var finish: Node2D = _find(r, "TrailFinish")
	var x: float = lerpf(hiker.global_position.x, finish.global_position.x, at)
	hiker.teleport(_ground(x) + Vector2(0, -40))
	Input.action_press(&"walk")
	await _wait(2.5)
	await _save(file)
	Input.action_release(&"walk")


func _photo_shot(id: StringName, file: String) -> void:
	var r: Node = await _open_trail(id)
	var hiker: Hiker = r.get("hiker")
	var vp: Viewpoint = _find(r, "Viewpoint")
	hiker.teleport(_ground(vp.global_position.x) + Vector2(0, -40))
	await _wait(1.0)
	r.call("start_photo")
	var photo: Node = r.get("photo_mode")
	# Keep the frame where the subject came closest to the centre of the viewfinder.
	var best: float = INF
	var best_img: Image = null
	var waited: float = 0.0
	while waited < 12.0:
		await RenderingServer.frame_post_draw
		waited += STEP
		var d: float = vp.subject_screen_position().distance_to(photo.call("frame_center"))
		if d < best:
			best = d
			best_img = get_viewport().get_texture().get_image()
	print("  photo subject closest to centre: %.0f px" % best)
	_write(best_img, file)
	photo.call("close")


func _summit_shots(id: StringName, summit_file: String, results_file: String) -> void:
	var r: Node = await _open_trail(id)
	var hiker: Hiker = r.get("hiker")
	var finish: Node2D = _find(r, "TrailFinish")
	hiker.teleport(_ground(finish.global_position.x - 260.0) + Vector2(0, -40))
	var done: Array[bool] = [false]
	hiker.reached_finish.connect(func() -> void: done[0] = true)
	# A believable finish: under par, every viewpoint photographed.
	var trail: TrailData = ContentDB.get_trail(id)
	r.get("daylight").set("elapsed", trail.par_time * 0.88)
	var photos: Dictionary = r.get("photos")
	for vp: ViewpointData in trail.viewpoints:
		photos[String(vp.id)] = StarRating.PhotoQuality.PERFECT
	Input.action_press(&"walk")
	var t: float = 0.0
	while not done[0] and t < 10.0:
		await get_tree().physics_frame
		t += STEP
	Input.action_release(&"walk")
	await _wait(1.6)
	await _save(summit_file)
	while get_tree().current_scene == null or not get_tree().current_scene.scene_file_path.ends_with("results.tscn"):
		await get_tree().process_frame
	await _wait(3.5)
	await _save(results_file)


## Ground point under `x` (the hiker collides with layer 1).
func _ground(x: float) -> Vector2:
	var space: PhysicsDirectSpaceState2D = get_tree().current_scene.get_world_2d().direct_space_state
	var q: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2(x, -20000), Vector2(x, 20000), 1)
	var hit: Dictionary = space.intersect_ray(q)
	return hit.position if not hit.is_empty() else Vector2(x, 0)


func _find(node: Node, cls: String) -> Node:
	for child: Node in node.get_children():
		var s: Script = child.get_script()
		if s != null and s.get_global_name() == cls:
			return child
		var deeper: Node = _find(child, cls)
		if deeper != null:
			return deeper
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(file: String) -> void:
	await RenderingServer.frame_post_draw
	_write(get_viewport().get_texture().get_image(), file)


func _write(img: Image, file: String, want: Vector2i = SIZE) -> void:
	img.convert(Image.FORMAT_RGB8)
	if img.get_size() != want:
		push_warning("%s is %s, not %s (window clamped by the screen?)" % [file, img.get_size(), want])
	img.save_png(ProjectSettings.globalize_path(OUT_DIR + file + ".png"))
	print("shot ", file, " ", img.get_size())
