extends GutTest
## First-time hints: shown when the hiker meets the thing, only once ever, one at a time.

var _saved: Dictionary
var _hud: Hud
var _hiker: Hiker


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	Input.action_release(&"walk")
	GameState.from_dict(_saved)


func _world(find_kind: int = -1) -> FirstHints:
	var level: Node2D = Node2D.new()
	add_child_autofree(level)
	var strip: TerrainStrip = TerrainStrip.new()
	strip.points = PackedVector2Array([Vector2(-600, 0), Vector2(1600, 0)])
	strip.decorate = false
	level.add_child(strip)
	if find_kind >= 0:
		var find: Find = (load("res://world/interactables/find.tscn") as PackedScene).instantiate() as Find
		find.find_id = &"test_find"
		find.kind = find_kind
		find.position = Vector2(600, 0)
		level.add_child(find)
	_hud = add_child_autofree((load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()) as Hud
	_hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	_hiker.teleport(Vector2(0, -4))
	var hints: FirstHints = add_child_autofree(FirstHints.new()) as FirstHints
	hints.setup(_hiker, _hud, level, ContentDB.balance)
	return hints


func _toast() -> String:
	return (_hud.toast_label as Label).text


func test_finds_hint_shows_when_close_and_only_once_ever() -> void:
	await _world(FindData.Kind.FLOWER)
	await wait_process_frames(5)
	assert_ne(_toast(), tr(FirstHints.FINDS), "not yet: the flower is far away")
	_hiker.teleport(Vector2(400, -4))
	await wait_process_frames(5)
	assert_eq(_toast(), tr(FirstHints.FINDS))
	assert_true(GameState.profile.has_seen_hint(FirstHints.FINDS), "remembered in the profile (saved)")


func test_seen_hint_never_shows_again() -> void:
	GameState.profile.mark_hint_seen(FirstHints.ANIMAL)
	await _world(FindData.Kind.ANIMAL)
	_hiker.teleport(Vector2(450, -4))
	await wait_process_frames(10)
	assert_ne(_toast(), tr(FirstHints.ANIMAL))


func test_hints_wait_their_turn() -> void:
	var hints: FirstHints = await _world()
	hints.request(FirstHints.WATER)
	hints.request(FirstHints.BACK)
	await wait_process_frames(3)
	assert_eq(_toast(), tr(FirstHints.WATER))
	assert_false(GameState.profile.has_seen_hint(FirstHints.BACK), "the second waits")
	await wait_seconds(ContentDB.balance.hint_seconds + 1.0)
	assert_eq(_toast(), tr(FirstHints.BACK))


func test_low_water_asks_for_the_water_hint() -> void:
	await _world()
	_hiker.water_changed.emit(0.3, 1.0)
	await wait_process_frames(3)
	assert_eq(_toast(), tr(FirstHints.WATER))


func test_seen_hints_survive_a_save() -> void:
	GameState.profile.mark_hint_seen(FirstHints.FORK)
	var back: PlayerProfile = PlayerProfile.new()
	back.from_dict(GameState.profile.to_dict())
	assert_true(back.has_seen_hint(FirstHints.FORK))
