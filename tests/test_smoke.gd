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


func test_trail_select_lists_trails() -> void:
	var scene: PackedScene = load(SceneRouter.TRAIL_SELECT) as PackedScene
	var select: Node = add_child_autofree(scene.instantiate())
	assert_gt(int(select.call("card_count")), 0)


func test_results_screen_instantiates_without_a_result() -> void:
	var saved: Dictionary = GameState.last_result
	GameState.last_result = {}
	var scene: PackedScene = load(SceneRouter.RESULTS) as PackedScene
	assert_not_null(add_child_autofree(scene.instantiate()))
	GameState.last_result = saved


func test_journal_shows_every_postcard_slot() -> void:
	var journal: Node = add_child_autofree((load(SceneRouter.JOURNAL) as PackedScene).instantiate())
	var expected: int = 0
	for t: TrailData in ContentDB.seasons()[0].trails:
		expected += t.viewpoints.size()
	assert_eq(int(journal.call("postcard_count")), expected)


func test_settings_toggles_write_to_game_state() -> void:
	var before: bool = bool(GameState.settings.get("left_handed", false))
	var settings: Node = add_child_autofree((load(SceneRouter.SETTINGS) as PackedScene).instantiate())
	var toggle: Button = settings.get("left_handed_toggle") as Button
	toggle.toggled.emit(not before)
	assert_eq(bool(GameState.settings.left_handed), not before)
	assert_eq((toggle as ToggleSwitch).shown_on(), not before)
	GameState.set_setting("left_handed", before)


func test_lapland_fell_runs_with_fog() -> void:
	GameState.current_trail_id = &"t03_lapland_fell"
	var runner: Node = add_child_autofree((load(SceneRouter.TRAIL_RUNNER) as PackedScene).instantiate())
	assert_eq((runner.get("trail") as TrailData).id, &"t03_lapland_fell")
	assert_true((runner.get("weather_fx") as WeatherFx).fog_veil.visible)
	GameState.current_trail_id = &""


func test_gear_screen_lists_every_item() -> void:
	var gear: Node = add_child_autofree((load(SceneRouter.GEAR) as PackedScene).instantiate())
	assert_eq(int(gear.call("card_count")), ContentDB.gear_list().size())


func test_main_menu_offers_continue() -> void:
	var saved: Dictionary = GameState.to_dict()
	GameState.reset()
	var menu: Node = add_child_autofree((load(SceneRouter.MAIN_MENU) as PackedScene).instantiate())
	var button: Button = menu.get("continue_button") as Button
	assert_true(button.visible)
	assert_string_contains(button.text, tr("TRAIL_T01_NAME"))
	GameState.from_dict(saved)


func test_translations_resolve() -> void:
	assert_eq(tr("MENU_PLAY"), "Play", "strings.csv not imported or not registered")
