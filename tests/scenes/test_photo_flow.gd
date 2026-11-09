extends GutTest
## The trail runner end to end at a viewpoint: prompt, photo mode, shot, back to hiking.

var runner: Node
var hiker: Hiker


func before_each() -> void:
	GameState.current_trail_id = &"t01_forest_lake"
	runner = add_child_autofree((load(SceneRouter.TRAIL_RUNNER) as PackedScene).instantiate())
	hiker = runner.get("hiker") as Hiker
	await wait_physics_frames(4)


func _go_to_viewpoint(id: StringName) -> Viewpoint:
	for node: Node in get_tree().get_nodes_in_group(Viewpoint.GROUP):
		var vp: Viewpoint = node as Viewpoint
		if vp.viewpoint_id == id and runner.is_ancestor_of(vp):
			hiker.teleport(vp.global_position + Vector2(-10, -20))
			return vp
	return null


func test_viewpoint_shows_prompt_and_photo_counts() -> void:
	var vp: Viewpoint = _go_to_viewpoint(&"lake_mirror")
	assert_not_null(vp)
	await wait_physics_frames(20)
	var hud: Hud = runner.get("hud") as Hud
	assert_true(hud.photo_prompt.visible, "standing at a viewpoint offers the camera")
	runner.call("start_photo")
	var photo: PhotoMode = runner.get("photo_mode") as PhotoMode
	assert_true(photo.is_open())
	assert_eq(hiker.state, Hiker.State.PHOTO, "the hiker stands still for the photo")
	photo.shoot_at(photo.frame_center())
	assert_eq(int(runner.get("photos")["lake_mirror"]), StarRating.PhotoQuality.PERFECT)
	assert_eq(hud.photo_label.text, "1/2")
	photo.close()
	assert_ne(hiker.state, Hiker.State.PHOTO)
	assert_true((runner.get("touch_controls") as TouchControls).visible, "controls come back after photo mode")


func test_cannot_open_photo_mode_away_from_a_viewpoint() -> void:
	runner.call("start_photo")
	assert_false((runner.get("photo_mode") as PhotoMode).is_open())
