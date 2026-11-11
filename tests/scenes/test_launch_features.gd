extends GutTest
## M7.7: season finale, About (version, reset progress), reduce motion.

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func _finish(trail: TrailData) -> Dictionary:
	var r: TrailResult = TrailResult.new(trail.id)
	r.finished = true
	r.time_seconds = 100.0
	return GameState.record_result(r)


# --- Season finale ---

func test_finale_only_when_the_last_trail_of_the_season_is_first_completed() -> void:
	var season: SeasonData = ContentDB.seasons()[0]
	var trails: Array[TrailData] = season.ordered_trails()
	for i: int in trails.size() - 1:
		var out: Dictionary = _finish(trails[i])
		assert_null(SeasonFinale.finished_season(out, trails[i]), "not after trail %d" % (i + 1))
	var last: TrailData = trails[trails.size() - 1]
	var final_out: Dictionary = _finish(last)
	assert_eq(SeasonFinale.finished_season(final_out, last), season, "the fifth summit ends the season")
	var again: Dictionary = _finish(last)
	assert_null(SeasonFinale.finished_season(again, last), "replaying doesn't show it again")


func test_finale_totals_count_the_season() -> void:
	var season: SeasonData = ContentDB.seasons()[0]
	var t: Dictionary = SeasonFinale.totals(season)
	assert_eq(int(t.stars), 0)
	assert_eq(int(t.stars_max), season.trails.size() * 3)
	assert_gt(int(t.finds_max), 0)


func test_finale_card_builds_and_stats_text_has_two_lines() -> void:
	var host: Control = add_child_autofree(Control.new()) as Control
	var finale: SeasonFinale = SeasonFinale.open(host, ContentDB.seasons()[0])
	assert_not_null(finale)
	assert_eq(tr("FINALE_STATS").count("\n"), 1, "the CSV keeps the line break")
	assert_eq((tr("FINALE_STATS") % [5, 1, 15, 2, 10, 3, 20]).count("%"), 0, "all numbers filled in")


# --- About ---

func test_version_comes_from_project_settings() -> void:
	assert_eq(AboutCard.version(), str(ProjectSettings.get_setting("application/config/version")))


func test_reset_progress_keeps_settings() -> void:
	GameState.set_setting("music_volume", 0.3)
	_finish(ContentDB.first_trail())
	GameState.tp = 500
	GameState.profile.mark_hint_seen("HINT_FORK")
	GameState.reset_progress()
	assert_eq(GameState.tp, 0)
	assert_eq(GameState.trails, {})
	assert_false(GameState.profile.has_seen_hint("HINT_FORK"))
	assert_almost_eq(float(GameState.settings.music_volume), 0.3, 0.001, "volumes survive a reset")


func test_reset_needs_two_taps() -> void:
	_finish(ContentDB.first_trail())
	var host: Control = add_child_autofree(Control.new()) as Control
	var about: AboutCard = AboutCard.open(host)
	var reset: Button = about.get("_reset") as Button
	reset.pressed.emit()
	assert_false(GameState.trails.is_empty(), "the first tap only asks")
	assert_eq(reset.text, tr("ABOUT_RESET_CONFIRM"))


func test_settings_has_reduce_motion_and_about() -> void:
	var settings: Node = add_child_autofree((load(SceneRouter.SETTINGS) as PackedScene).instantiate())
	await wait_process_frames(2)
	var labels: Array[String] = []
	for l: Node in settings.find_children("*", "Label", true, false):
		labels.append((l as Label).text)
	assert_has(labels, "SETTINGS_REDUCE_MOTION")
	assert_not_null(settings.find_child("AboutButton", true, false))


# --- Reduce motion ---

func test_reduce_motion_skips_ui_motion_and_shake() -> void:
	GameState.set_setting("reduce_motion", true)
	var box: Control = add_child_autofree(Control.new()) as Control
	UiMotion.intro([box])
	assert_eq(box.modulate.a, 1.0, "no fade-in")
	UiMotion.bump(box)
	assert_eq(box.scale, Vector2.ONE, "no bounce")
	var cam: HikerCamera = HikerCamera.new()
	# Physics interpolation needs a physics-process camera (else the engine warns).
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child_autofree(cam)
	cam.shake(20.0)
	assert_false(cam.is_shaking())


func test_old_saves_get_reduce_motion_off() -> void:
	GameState.from_dict({"settings": {"music_volume": 0.5}})
	assert_false(bool(GameState.settings.reduce_motion))
