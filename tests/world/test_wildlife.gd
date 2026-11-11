extends GutTest
## Wildlife moments: placed on open ground away from pieces; flock takes off; reindeer
## block the path for a while, and barging in makes the hiker stumble.

var _hiker: Hiker


func _flat_world() -> Node2D:
	var level: Node2D = Node2D.new()
	add_child_autofree(level)
	var strip: TerrainStrip = TerrainStrip.new()
	strip.points = PackedVector2Array([Vector2(-600, 0), Vector2(6000, 0)])
	strip.decorate = false
	level.add_child(strip)
	_hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate()) as Hiker
	_hiker.teleport(Vector2(0, -4))
	return level


func after_each() -> void:
	Input.action_release(&"walk")


func test_spots_avoid_pieces_and_every_trail_gets_moments() -> void:
	for season: SeasonData in ContentDB.seasons():
		for trail: TrailData in season.trails:
			var level: Node = add_child_autofree((load(trail.scene_path) as PackedScene).instantiate())
			var start: Marker2D = level.get_node("Trailhead") as Marker2D
			var director: TrailMoments = TrailMoments.new()
			add_child_autofree(director)
			var spots: Array[Vector2] = director.open_ground(level, start.global_position.x)
			assert_gt(spots.size(), 3, "%s has open ground for wildlife" % trail.id)
			for node: Node in level.find_children("*", "Node2D", true, false):
				if TrailMoments._is_piece(node):
					for s: Vector2 in spots:
						assert_true(absf(s.x - (node as Node2D).global_position.x) >= TrailMoments.CLEAR_OF_PIECES,
							"%s: spot at %d is on top of %s" % [trail.id, int(s.x), node.name])


func test_director_places_different_kinds() -> void:
	var level: Node2D = _flat_world()
	var hud: Hud = add_child_autofree((load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()) as Hud
	var director: TrailMoments = TrailMoments.new()
	level.add_child(director)
	director.setup(level, _hiker, hud, ContentDB.balance, 1234)
	assert_between(director.moments.size(), ContentDB.balance.moments_min, ContentDB.balance.moments_max)
	var kinds: Dictionary = {}
	for m: WildlifeMoment in director.moments:
		kinds[m.kind] = true
	assert_eq(kinds.size(), director.moments.size(), "no kind twice in one hike")


func _moment(kind: WildlifeMoment.Kind, x: float) -> WildlifeMoment:
	var m: WildlifeMoment = WildlifeMoment.new()
	add_child_autofree(m)
	m.global_position = Vector2(x, 0)
	m.setup(kind, _hiker, 7)
	return m


func test_flock_takes_off_when_the_hiker_comes_close() -> void:
	_flat_world()
	var m: WildlifeMoment = _moment(WildlifeMoment.Kind.FLOCK, 600)
	await wait_process_frames(3)
	assert_eq(m.phase, WildlifeMoment.Phase.WAITING)
	_hiker.teleport(Vector2(450, -4))
	await wait_process_frames(3)
	assert_eq(m.phase, WildlifeMoment.Phase.ACTIVE)


func test_reindeer_wait_or_get_bumped() -> void:
	_flat_world()
	var m: WildlifeMoment = _moment(WildlifeMoment.Kind.REINDEER, 500)
	watch_signals(m)
	await wait_physics_frames(8)
	assert_true(m.is_blocking(), "they're on the path once the hiker is near")
	assert_signal_emitted(m, "arrived")
	# Barge straight in from just short of them.
	_hiker.teleport(Vector2(380, -4))
	Input.action_press(&"walk")
	await wait_seconds(2.0)
	assert_signal_emitted(m, "bumped", "walking straight in startles them")
	assert_false(m.is_blocking(), "and they bolt")
