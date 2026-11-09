class_name ContentValidator
extends RefCounted
## Checks content before it ships: unique ids, files that exist, levels that have a
## Trailhead and a Finish, and viewpoints in the level that match the trail's data.
## Instantiates each level once, so it's meant for tests and tools, not gameplay.


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
	for node: Node in _all_nodes(level):
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
	level.free()
	return errors


static func _all_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = [root]
	var i: int = 0
	while i < out.size():
		for child: Node in out[i].get_children():
			out.append(child)
		i += 1
	return out
