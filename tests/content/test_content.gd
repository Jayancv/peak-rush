extends GutTest
## Broken content must never ship: this runs the validator over everything in the index.


func test_shipped_content_is_valid() -> void:
	var errors: Array[String] = ContentDB.validate()
	assert_eq(errors, [] as Array[String], "\n".join(errors))


func test_template_trail_is_valid() -> void:
	var template: TrailData = load("res://content/_templates/trail_template/trail.tres") as TrailData
	assert_eq(ContentValidator.validate_trail(template), [] as Array[String])


func test_every_season_has_strings_and_ordered_trails() -> void:
	for season: SeasonData in ContentDB.seasons():
		assert_ne(tr(season.title_key), season.title_key, "missing string for %s" % season.title_key)
		var orders: Array[int] = []
		for t: TrailData in season.ordered_trails():
			orders.append(t.unlock_order)
			assert_ne(tr(t.name_key), t.name_key, "missing string for %s" % t.name_key)
		var sorted: Array[int] = orders.duplicate()
		sorted.sort()
		assert_eq(orders, sorted)


func test_validator_catches_missing_scene() -> void:
	var t: TrailData = TrailData.new()
	t.id = &"broken"
	t.name_key = "X"
	t.scene_path = "res://nope/trail.tscn"
	var errors: Array[String] = ContentValidator.validate_trail(t)
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "scene not found")


func test_validator_catches_level_without_trailhead_or_finish() -> void:
	var t: TrailData = TrailData.new()
	t.id = &"no_finish"
	t.name_key = "X"
	# The hiker scene has neither a Trailhead nor a Finish: two problems.
	t.scene_path = "res://actors/hiker/hiker.tscn"
	var errors: Array[String] = ContentValidator.validate_trail(t)
	assert_eq(errors.size(), 2)


func test_validator_catches_viewpoint_mismatch() -> void:
	var t: TrailData = (load("res://content/_templates/trail_template/trail.tres") as TrailData).duplicate()
	var vp: ViewpointData = ViewpointData.new()
	vp.id = &"lake_mirror"
	t.viewpoints = [vp] as Array[ViewpointData]
	var errors: Array[String] = ContentValidator.validate_trail(t)
	# Both directions are caught: data without a level node, and a level node without data.
	assert_true(errors.any(func(e: String) -> bool: return e.contains("'lake_mirror' that isn't in the level")), "
".join(errors))
	assert_true(errors.any(func(e: String) -> bool: return e.contains("'template_view' that isn't in its data")), "
".join(errors))


func test_validator_catches_duplicate_ids_and_wrong_season() -> void:
	var t: TrailData = load("res://content/_templates/trail_template/trail.tres") as TrailData
	var s: SeasonData = SeasonData.new()
	s.id = &"sx"
	s.trails = [t, t] as Array[TrailData]
	var index: ContentIndex = ContentIndex.new()
	index.seasons = [s] as Array[SeasonData]
	var errors: Array[String] = ContentValidator.validate_index(index)
	assert_true(errors.any(func(e: String) -> bool: return e.contains("Duplicate trail id")))
	assert_true(errors.any(func(e: String) -> bool: return e.contains("says season")))


func test_lookups_follow_unlock_order() -> void:
	var first: TrailData = ContentDB.first_trail()
	assert_not_null(first)
	assert_null(ContentDB.previous_trail(first.id))
	var second: TrailData = ContentDB.next_trail(first.id)
	assert_not_null(second)
	assert_eq(ContentDB.previous_trail(second.id), first)


func _strip(from_x: float, to_x: float) -> TerrainStrip:
	var strip: TerrainStrip = TerrainStrip.new()
	strip.points = PackedVector2Array([Vector2(from_x, 0), Vector2(to_x, 0)])
	return strip


func test_validator_catches_a_gap_too_wide_to_jump() -> void:
	var level: Node2D = Node2D.new()
	level.add_child(_strip(0, 500))
	level.add_child(_strip(500 + ContentValidator.MAX_JUMP_GAP - 5.0, 1000))
	assert_eq(ContentValidator._check_gaps(level, "t").size(), 0, "a normal jump is fine")
	level.add_child(_strip(1120, 1600))
	var errors: Array[String] = ContentValidator._check_gaps(level, "t")
	assert_eq(errors.size(), 1, "a 120 px gap can't be jumped")
	assert_string_contains(errors[0], "x=1000")
	var stones: SteppingStones = (load("res://world/obstacles/stepping_stones.tscn") as PackedScene).instantiate()
	stones.stone_count = 1
	stones.gap = 38.0
	stones.position = Vector2(1000, 0)
	level.add_child(stones)
	assert_eq(ContentValidator._check_gaps(level, "t").size(), 0, "stepping stones make it crossable")
	level.free()
