extends GutTest
## SceneRouter guards. Real scene changes aren't exercised here because they
## would replace the GUT runner's scene; they're checked by playing the game.


func test_go_to_rejects_missing_scene() -> void:
	var started: bool = SceneRouter.go_to("res://does/not/exist.tscn")
	assert_false(started, "go_to should refuse a missing scene")
	assert_false(SceneRouter.is_busy(), "a refused go_to must not leave the router busy")
	assert_push_error("scene not found")


func test_known_scene_paths_exist() -> void:
	assert_true(ResourceLoader.exists(SceneRouter.MAIN_MENU))
	assert_true(ResourceLoader.exists(SceneRouter.TRAIL_RUNNER))
