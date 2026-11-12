extends Node
## Renders every viewpoint's postcard from the real game: walks into the viewpoint, opens
## photo mode with the hiker and all UI hidden, waits for the subject (bird, boat, herd)
## to cross the centre, and saves the viewfinder's frame as
## content/seasons/<season>/trails/<trail>/postcards/<viewpoint>.webp.
##
##   godot --path . --resolution 1920x1080 tools/postcards/make_postcards.tscn [-- <trail_id>]
## Needs a real window (not --headless). Then run --import and point each ViewpointData.postcard
## at its file (done once; re-running just refreshes the pictures).
## The player's save is never written (autosave off, progress only in memory).

const SIZE: Vector2i = Vector2i(900, 600)
const SETTLE_SECONDS: float = 1.2
const SEARCH_SECONDS: float = 14.0


func _ready() -> void:
	# Runs while the tree is paused, to undo it (see _process).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


## The runner pauses whenever the window loses focus (right on a phone, wrong for a tool that
## runs in the background): keep it running and its pause card out of the picture, every frame.
func _process(_delta: float) -> void:
	var r: Node = get_tree().current_scene
	if r == null or not "pause_menu" in r:
		return
	(r.get("pause_menu") as CanvasItem).visible = false
	if get_tree().paused:
		r.call("resume")


func _run() -> void:
	var tree: SceneTree = get_tree()
	get_parent().remove_child(self)
	tree.root.add_child(self)
	SaveService.autosave = false
	Ads.use_provider(AdProvider.new())
	GameState.profile.hints_seen.assign(["HINT_FINDS", "HINT_ANIMAL", "HINT_FORK", "HINT_BACK", "HINT_WATER", "HINT_FLOW"])
	var only: PackedStringArray = OS.get_cmdline_user_args()
	for season: SeasonData in ContentDB.seasons():
		for trail: TrailData in season.ordered_trails():
			if not only.is_empty() and not only.has(String(trail.id)):
				continue
			# Finished once, so tutorial hints stay away.
			GameState.trails[String(trail.id)] = {"stars": StarRating.STAR_SUMMIT, "best_time": 60.0, "photos": {}, "completions": 1}
			for vp: ViewpointData in trail.viewpoints:
				# Random wildlife can block the spot; a fresh load rerolls it.
				for attempt: int in 3:
					if await _shoot(trail, vp):
						break
	print("POSTCARDS done")
	tree.quit()


func _shoot(trail: TrailData, data: ViewpointData) -> bool:
	GameState.current_trail_id = trail.id
	GameState.daily_active = false
	get_tree().change_scene_to_file(SceneRouter.TRAIL_RUNNER)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: Node = get_tree().current_scene
	var hiker: Hiker = r.get("hiker")
	var vp: Viewpoint = _find_viewpoint(r, data.id)
	if vp == null:
		push_error("no Viewpoint node for %s" % data.id)
		return true
	var photo: PhotoMode = r.get("photo_mode")
	if trail.sunrise:
		# A dawn climb: show the light a hiker on par would see at this point of the trail.
		var finish: Node2D = _find_finish(r)
		if finish != null:
			var along: float = clampf(vp.global_position.x / finish.global_position.x, 0.0, 1.0)
			(r.get("daylight") as Daylight).elapsed = trail.par_time * along
	# Stand on the ground at the viewpoint and retry until photo mode opens (the hiker must
	# have landed and the viewpoint must have noticed it).
	var space: PhysicsDirectSpaceState2D = (r as Node2D).get_world_2d().direct_space_state if r is Node2D else hiker.get_world_2d().direct_space_state
	var x: float = vp.global_position.x
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, vp.global_position.y - 60), Vector2(x, vp.global_position.y + 400), 1))
	hiker.teleport((hit.position if not hit.is_empty() else vp.global_position) + Vector2(0, -24))
	var tries: float = 0.0
	while not photo.is_open() and tries < 5.0:
		# The runner pauses when the window loses focus (as it should on a phone); a tool
		# running in the background must not be stopped by that.
		r.call("resume")
		await _wait(0.25)
		tries += 0.25
		r.call("start_photo")
	if not photo.is_open():
		print("  retrying %s: photo mode didn't open" % data.id)
		return false
	photo.modulate.a = 0.0
	(r.get("hud") as Object).set("visible", false)
	(r.get("touch_controls") as Object).set("visible", false)
	hiker.visible = false
	var pieces: Node = (r.get("world") as Node).find_child("Pieces", true, false)
	if pieces != null:
		_hide_world_ui(pieces)
	await _wait(SETTLE_SECONDS)
	get_tree().paused = false
	var best: float = INF
	var best_img: Image = null
	var waited: float = 0.0
	while waited < SEARCH_SECONDS:
		if get_tree().paused:
			r.call("resume")
			best_img = null
			best = INF
		await RenderingServer.frame_post_draw
		waited += get_process_delta_time()
		var d: float = vp.subject_screen_position().distance_to(photo.frame_center())
		if d < best:
			best = d
			best_img = get_viewport().get_texture().get_image()
	var scale: float = float(best_img.get_width()) / get_viewport().get_visible_rect().size.x
	var half: Vector2 = Vector2(ContentDB.balance.photo_frame_half * Viewfinder.ASPECT, ContentDB.balance.photo_frame_half)
	var centre: Vector2 = photo.frame_center()
	var crop: Rect2i = Rect2i(Vector2i((centre - half) * scale), Vector2i(half * 2.0 * scale))
	var img: Image = best_img.get_region(crop)
	img.convert(Image.FORMAT_RGB8)
	img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var dir: String = trail.scene_path.get_base_dir() + "/postcards/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	img.save_webp(ProjectSettings.globalize_path(dir + String(data.id) + ".webp"), true, 0.9)
	print("postcard %s/%s subject %.0f px from centre" % [trail.id, data.id, best])
	return true


## In-world badges (a bench's "Rest ×2") don't belong on a postcard. Only the level's
## pieces: the backdrop's sky is a Control too.
func _hide_world_ui(node: Node) -> void:
	for child: Node in node.get_children(true):
		if child is Control:
			(child as Control).visible = false
		else:
			_hide_world_ui(child)


func _find_finish(node: Node) -> Node2D:
	for child: Node in node.get_children():
		if child is TrailFinish:
			return child
		var deeper: Node2D = _find_finish(child)
		if deeper != null:
			return deeper
	return null


func _find_viewpoint(node: Node, id: StringName) -> Viewpoint:
	for child: Node in node.get_children():
		if child is Viewpoint and (child as Viewpoint).viewpoint_id == id:
			return child
		var deeper: Viewpoint = _find_viewpoint(child, id)
		if deeper != null:
			return deeper
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
