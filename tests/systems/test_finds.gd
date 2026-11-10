extends GutTest
## Finds: recording, TP for new ones, badge facts, and the pieces on real physics.

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	Input.action_release(&"walk")
	GameState.from_dict(_saved)


func _finish_with(finds: Array[StringName]) -> Dictionary:
	var trail: TrailData = ContentDB.first_trail()
	var r: TrailResult = TrailResult.new(trail.id)
	r.finished = true
	r.time_seconds = 100.0
	r.finds = finds
	return GameState.record_result(r)


func test_new_finds_are_saved_and_pay_tp_once() -> void:
	var trail: TrailData = ContentDB.first_trail()
	assert_gt(trail.finds.size(), 1, "the first trail has finds to test with")
	var first: StringName = trail.finds[0].id
	var out: Dictionary = _finish_with([first] as Array[StringName])
	assert_eq(int(out.new_finds), 1)
	assert_eq(int(out.find_tp), ContentDB.balance.tp_per_new_find)
	assert_true((GameState.record(trail.id).finds as Array).has(String(first)))
	var again: Dictionary = _finish_with([first] as Array[StringName])
	assert_eq(int(again.new_finds), 0, "a find only pays the first time")


func test_badge_facts_split_animals_from_other_finds() -> void:
	var trail: TrailData = ContentDB.first_trail()
	var ids: Array[StringName] = []
	var animals: int = 0
	for f: FindData in trail.finds:
		ids.append(f.id)
		animals += 1 if f.kind == FindData.Kind.ANIMAL else 0
	_finish_with(ids)
	var facts: Dictionary = GameState.profile_facts()
	assert_eq(int(facts.animals), animals)
	assert_eq(int(facts.finds), ids.size() - animals)


func _world_with_find(kind: FindData.Kind) -> Array:
	var strip: TerrainStrip = TerrainStrip.new()
	strip.points = PackedVector2Array([Vector2(-600, 0), Vector2(1200, 0)])
	strip.decorate = false
	add_child_autofree(strip)
	var find: Find = (load("res://world/interactables/find.tscn") as PackedScene).instantiate() as Find
	find.find_id = &"test_find"
	find.kind = kind
	find.position = Vector2(140, 0)
	add_child_autofree(find)
	var hiker: Hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	hiker.teleport(Vector2(0, -4))
	await wait_physics_frames(8)
	return [find, hiker]


func test_walking_into_a_flower_collects_it() -> void:
	var parts: Array = await _world_with_find(FindData.Kind.FLOWER)
	watch_signals(parts[0])
	Input.action_press(&"walk")
	await wait_physics_frames(90)
	assert_signal_emitted_with_parameters(parts[0], "collected", [&"test_find"])


func test_animal_flees_if_you_keep_walking() -> void:
	var parts: Array = await _world_with_find(FindData.Kind.ANIMAL)
	watch_signals(parts[0])
	Input.action_press(&"walk")
	await wait_physics_frames(150)
	assert_signal_not_emitted(parts[0], "collected")


func test_animal_is_spotted_by_standing_still() -> void:
	var parts: Array = await _world_with_find(FindData.Kind.ANIMAL)
	watch_signals(parts[0])
	Input.action_press(&"walk")
	# Walk just inside its range (70 px), then stop and wait quietly.
	await wait_physics_frames(46)
	Input.action_release(&"walk")
	await wait_physics_frames(130)
	assert_signal_emitted(parts[0], "collected")
