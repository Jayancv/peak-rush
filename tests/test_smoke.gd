extends GutTest
## M0 smoke tests: the project boots, autoloads exist, and the core scenes load.

const AUTOLOADS: Array[String] = ["GameState", "ContentDB", "SaveService", "AudioManager", "SceneRouter"]
const INPUT_ACTIONS: Array[String] = ["walk", "jump", "pause"]


func test_gut_runs() -> void:
	assert_true(true, "GUT is wired up")


func test_autoloads_are_present() -> void:
	for autoload_name: String in AUTOLOADS:
		assert_not_null(get_tree().root.get_node_or_null(autoload_name), "%s autoload missing" % autoload_name)


func test_input_actions_exist() -> void:
	for action: String in INPUT_ACTIONS:
		assert_true(InputMap.has_action(action), "input action '%s' missing" % action)


func test_main_menu_instantiates() -> void:
	var scene: PackedScene = load(SceneRouter.MAIN_MENU) as PackedScene
	assert_not_null(scene, "main menu scene failed to load")
	var menu: Node = add_child_autofree(scene.instantiate())
	assert_not_null(menu.get("play_button"), "main menu play_button export not wired")


func test_trail_runner_instantiates() -> void:
	var scene: PackedScene = load(SceneRouter.TRAIL_RUNNER) as PackedScene
	assert_not_null(scene, "trail runner scene failed to load")
	var runner: Node = add_child_autofree(scene.instantiate())
	var hiker: Hiker = runner.get("hiker") as Hiker
	assert_not_null(hiker, "trail runner did not spawn a hiker")
	assert_not_null(runner.find_child("Trailhead", true, false), "test trail has no Trailhead marker")


func test_translations_resolve() -> void:
	assert_eq(tr("MENU_PLAY"), "Play", "strings.csv not imported or not registered")
