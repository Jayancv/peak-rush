class_name ContentValidator
extends RefCounted
## Checks content before it ships: unique ids, files that exist, levels that have a
## Trailhead and a Finish, and viewpoints in the level that match the trail's data.
## Instantiates each level once, so it's meant for tests and tools, not gameplay.


## Widest open gap a hiker can jump at the slowest normal speed (85% on snow), with margin.
const MAX_JUMP_GAP: float = 75.0


static func validate_index(index: ContentIndex) -> Array[String]:
	var errors: Array[String] = []
	if index == null:
		return ["Content index is missing"]
	var season_ids: Dictionary = {}
	var trail_ids: Dictionary = {}
	for season: SeasonData in index.seasons:
		if season == null:
			errors.append("Content index has an empty season slot")
			continue
		if String(season.id).is_empty():
			errors.append("A season has no id")
		elif season_ids.has(season.id):
			errors.append("Duplicate season id '%s'" % season.id)
		season_ids[season.id] = true
		if season.trails.is_empty():
			errors.append("Season '%s' has no trails" % season.id)
		for trail: TrailData in season.trails:
			if trail == null:
				errors.append("Season '%s' has an empty trail slot" % season.id)
				continue
			if trail_ids.has(trail.id):
				errors.append("Duplicate trail id '%s'" % trail.id)
			trail_ids[trail.id] = true
			if trail.season_id != season.id:
				errors.append("Trail '%s' says season '%s' but is listed in '%s'" % [trail.id, trail.season_id, season.id])
			errors.append_array(validate_trail(trail))
	return errors


static func validate_trail(trail: TrailData) -> Array[String]:
	var errors: Array[String] = []
	var who: String = "Trail '%s'" % trail.id
	if String(trail.id).is_empty():
		errors.append("A trail has no id")
	if trail.name_key.is_empty():
		errors.append("%s has no name_key" % who)
	if trail.daylight_seconds <= 0.0:
		errors.append("%s needs daylight_seconds > 0" % who)
	if trail.par_time <= 0.0:
		errors.append("%s needs par_time > 0" % who)
	var vp_ids: Dictionary = {}
	for vp: ViewpointData in trail.viewpoints:
		if vp == null:
			errors.append("%s has an empty viewpoint slot" % who)
		elif vp_ids.has(vp.id):
			errors.append("%s lists viewpoint '%s' twice" % [who, vp.id])
		else:
			vp_ids[vp.id] = true
	var find_ids: Dictionary = {}
	for f: FindData in trail.finds:
		if f == null:
			errors.append("%s has an empty find slot" % who)
		elif find_ids.has(f.id):
			errors.append("%s lists find '%s' twice" % [who, f.id])
		else:
			find_ids[f.id] = true
	if trail.scene_path.is_empty() or not ResourceLoader.exists(trail.scene_path):
		errors.append("%s scene not found: '%s'" % [who, trail.scene_path])
		return errors
	var packed: PackedScene = load(trail.scene_path) as PackedScene
	if packed == null:
		errors.append("%s scene failed to load: %s" % [who, trail.scene_path])
		return errors
	var level: Node = packed.instantiate()
	if not level.get_node_or_null("Trailhead") is Marker2D:
		errors.append("%s level has no Trailhead (Marker2D) at its root" % who)
	var finishes: int = 0
	var scene_vps: Dictionary = {}
	var scene_finds: Dictionary = {}
	for node: Node in _all_nodes(level):
		if node is Find:
			scene_finds[(node as Find).find_id] = true
		if node is TrailFinish:
			finishes += 1
		var vp_id: Variant = node.get("viewpoint_id")
		if vp_id != null:
			scene_vps[StringName(vp_id)] = true
	if finishes == 0:
		errors.append("%s level has no Finish" % who)
	for id: StringName in scene_vps:
		if not vp_ids.has(id):
			errors.append("%s level has viewpoint '%s' that isn't in its data" % [who, id])
	for id: StringName in vp_ids:
		if not scene_vps.has(id):
			errors.append("%s data lists viewpoint '%s' that isn't in the level" % [who, id])
	for id: StringName in scene_finds:
		if not find_ids.has(id):
			errors.append("%s level has find '%s' that isn't in its data" % [who, id])
	for id: StringName in find_ids:
		if not scene_finds.has(id):
			errors.append("%s data lists find '%s' that isn't in the level" % [who, id])
	errors.append_array(_check_gaps(level, who))
	level.free()
	return errors


## Every open gap between ground strips must be jumpable at the slowest normal speed
## (snow); wider crossings need stepping stones, a bridge, a log or a boardwalk.
static func _check_gaps(level: Node, who: String) -> Array[String]:
	var errors: Array[String] = []
	var spans: Array[Vector2] = []
	var crossings: Array[Vector2] = []
	for node: Node in _all_nodes(level):
		var at: Vector2 = _level_position(node, level)
		if node is TerrainStrip and (node as TerrainStrip).points.size() >= 2:
			var pts: PackedVector2Array = (node as TerrainStrip).points
			spans.append(Vector2(at.x + pts[0].x, at.x + pts[pts.size() - 1].x))
		elif node is SteppingStones:
			crossings.append(Vector2(at.x, at.x + (node as SteppingStones).total_width()))
		elif node is RopeBridge:
			crossings.append(Vector2(at.x, at.x + (node as RopeBridge).span))
		elif node is FallenLog:
			crossings.append(Vector2(at.x, at.x + (node as FallenLog).length))
		elif node is Boardwalk and (node as Boardwalk).points.size() >= 2:
			var deck: PackedVector2Array = (node as Boardwalk).points
			crossings.append(Vector2(at.x + deck[0].x, at.x + deck[deck.size() - 1].x))
	spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var reach: float = -INF
	for span: Vector2 in spans:
		var gap: float = span.x - reach
		if reach > -INF and gap > MAX_JUMP_GAP and not _crossed(reach, span.x, crossings):
			errors.append("%s has a %d px gap at x=%d, wider than a jump (max %d): add stones, a bridge or a log" % [who, int(gap), int(reach), int(MAX_JUMP_GAP)])
		reach = maxf(reach, span.y)
	return errors


static func _crossed(from_x: float, to_x: float, crossings: Array[Vector2]) -> bool:
	for c: Vector2 in crossings:
		if c.x <= from_x + 20.0 and c.y >= to_x - 20.0:
			return true
	return false


## Position relative to the level root (the level isn't in the tree, so no global transforms).
static func _level_position(node: Node, level: Node) -> Vector2:
	var at: Vector2 = Vector2.ZERO
	var n: Node = node
	while n != null and n != level:
		if n is Node2D:
			at += (n as Node2D).position
		n = n.get_parent()
	return at


static func _all_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = [root]
	var i: int = 0
	while i < out.size():
		for child: Node in out[i].get_children():
			out.append(child)
		i += 1
	return out
