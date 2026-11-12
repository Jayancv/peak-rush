extends GutTest
## Season 1 as a whole: five trails, Continue, night trail, tutorial, strings.

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func _complete(id: StringName) -> void:
	GameState.trails[String(id)] = {"stars": StarRating.STAR_SUMMIT, "best_time": 60.0, "photos": {}, "completions": 1}


func test_season_one_has_the_six_design_trails() -> void:
	var ids: Array[StringName] = []
	for t: TrailData in ContentDB.get_season(&"s01_nordic").ordered_trails():
		ids.append(t.id)
	assert_eq(ids, [&"t01_forest_lake", &"t02_archipelago_rocks", &"t03_lapland_fell", &"t04_fjord_ridge", &"t06_crane_mire", &"t05_aurora_summit"] as Array[StringName],
		"Crane Mire comes before the Aurora Summit finale")


func test_every_trail_has_two_to_four_viewpoints() -> void:
	for t: TrailData in ContentDB.get_season(&"s01_nordic").trails:
		assert_between(t.viewpoints.size(), 2, 4, "%s viewpoints" % t.id)


func test_continue_starts_at_trail_one_then_moves_on() -> void:
	assert_eq(GameState.next_trail_to_play().id, &"t01_forest_lake")
	_complete(&"t01_forest_lake")
	assert_eq(GameState.next_trail_to_play().id, &"t02_archipelago_rocks")


func test_continue_moves_to_the_next_season_then_is_empty() -> void:
	for t: TrailData in ContentDB.get_season(&"s01_nordic").trails:
		_complete(t.id)
	assert_eq(GameState.next_trail_to_play().id, &"t07_tea_terraces", "Season 1 done: on to Tea Country")
	for season: SeasonData in ContentDB.seasons():
		for t: TrailData in season.trails:
			_complete(t.id)
	assert_null(GameState.next_trail_to_play())


func test_continue_stays_in_the_season_being_played() -> void:
	_complete(&"t07_tea_terraces")
	assert_eq(GameState.next_trail_to_play().id, &"t08_ella_rock", "started Tea Country: keep going there")


func test_only_forest_lake_is_a_tutorial() -> void:
	for t: TrailData in ContentDB.get_season(&"s01_nordic").trails:
		assert_eq(t.tutorial, t.id == &"t01_forest_lake", String(t.id))


func test_aurora_summit_is_a_night_trail() -> void:
	var t: TrailData = ContentDB.get_trail(&"t05_aurora_summit")
	assert_true(t.night)
	assert_eq(t.star3_key, "RESULTS_STAR_AURORA")
	var day: Daylight = Daylight.new(ContentDB.balance, t.daylight_seconds, true)
	assert_true(day.tint().is_equal_approx(ContentDB.balance.tint_night), "dark from the start")


func test_weather_matches_design() -> void:
	# GAME_DESIGN §6: wind on Archipelago, fog on Lapland, rain on Fjord, mist on Crane Mire, snow on Aurora.
	assert_true(ContentDB.get_trail(&"t02_archipelago_rocks").weather.wind)
	assert_true(ContentDB.get_trail(&"t03_lapland_fell").weather.fog)
	assert_true(ContentDB.get_trail(&"t04_fjord_ridge").weather.rain)
	assert_true(ContentDB.get_trail(&"t05_aurora_summit").weather.snow)
	var mire: WeatherProfile = ContentDB.get_trail(&"t06_crane_mire").weather
	assert_true(mire.fog and mire.fog_density < ContentDB.get_trail(&"t03_lapland_fell").weather.fog_density, "light mist, thinner than Lapland's fog")


func test_tutorial_hints_have_strings() -> void:
	var level: Node = (load(ContentDB.get_trail(&"t01_forest_lake").scene_path) as PackedScene).instantiate()
	var found: int = 0
	for node: Node in level.find_children("*", "", true, false):
		var key: Variant = node.get("message_key")
		if key is String and not String(key).is_empty():
			found += 1
			assert_ne(tr(key), key, "missing string %s" % key)
	level.free()
	assert_gte(found, 4, "walk, rest, jump and photo hints at least")


func test_tea_country_has_its_five_trails_in_order() -> void:
	var ids: Array[StringName] = []
	for t: TrailData in ContentDB.get_season(&"s02_tea").ordered_trails():
		ids.append(t.id)
	assert_eq(ids, [&"t07_tea_terraces", &"t08_ella_rock", &"t09_nine_arches", &"t10_worlds_end", &"t11_pilgrims_peak"] as Array[StringName])


func test_tea_country_weather_and_the_sunrise_climb() -> void:
	assert_true(ContentDB.get_trail(&"t09_nine_arches").weather.rain, "monsoon rain on the viaduct trail")
	assert_true(ContentDB.get_trail(&"t10_worlds_end").weather.fog, "World's End lies in mist")
	var peak: TrailData = ContentDB.get_trail(&"t11_pilgrims_peak")
	assert_true(peak.night and peak.sunrise)
	assert_eq(peak.star3_key, "RESULTS_STAR_SUNRISE")
	var b: Balance = ContentDB.balance
	var day: Daylight = Daylight.new(b, 100.0, true, true)
	assert_true(day.tint().is_equal_approx(b.tint_night), "starts in the dark")
	day.advance(100.0)
	assert_true(day.tint().is_equal_approx(b.tint_sunrise), "the window ends at sunrise")
