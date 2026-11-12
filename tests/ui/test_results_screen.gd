extends GutTest
## The results screen: badge pills land on the screen itself (a wrong parent once sent them
## to the window and they never showed), and the weekly-goal line appears in the breakdown.

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	Ads.use_provider(AdProvider.new())


func after_each() -> void:
	GameState.from_dict(_saved)


func _open(result: Dictionary) -> Control:
	GameState.last_result = result
	return add_child_autofree((load(SceneRouter.RESULTS) as PackedScene).instantiate()) as Control


func test_new_badges_show_as_pills_on_the_screen() -> void:
	var badge: String = String(ContentDB.badge_list()[0].id)
	var screen: Control = _open({"trail_id": &"t01_forest_lake", "finished": true, "total": 50, "finish": 50, "new_badges": [badge]})
	screen.call("_show_new_badges")
	var pills: Array[Node] = screen.find_children("*", "VBoxContainer", false, false)
	assert_gt(pills.size(), 0, "the pill column is added to the results screen")


func test_weekly_goals_line_in_the_breakdown() -> void:
	var screen: Control = _open({"trail_id": &"t01_forest_lake", "finished": true, "total": 110, "finish": 50,
		"weekly": {"done": [WeeklyGoals.Goal.SUMMITS], "tp": 60, "bonus": false}})
	var breakdown: Label = screen.get("tp_breakdown")
	assert_string_contains(breakdown.text, tr("RESULTS_WEEKLY") % [1, 60])
