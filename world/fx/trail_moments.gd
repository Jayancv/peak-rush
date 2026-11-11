class_name TrailMoments
extends Node2D
## Picks a few wildlife moments for this hike (Balance.moments_min..max, different kinds)
## and places them on open, gentle ground: away from trail pieces (anything from
## world/obstacles or world/interactables), from strip ends (gaps) and from the trailhead
## and summit. A new random pick every hike, so the same trail never plays quite the same.

## Ground steeper than this (rise/run) is skipped for animals standing on the path.
const MAX_SLOPE: float = 0.22
const SAMPLE_STEP: float = 150.0
## Trails are dense (20-40 pieces): much more than this and a short fell has no room left.
const CLEAR_OF_PIECES: float = 170.0
const CLEAR_OF_ENDS: float = 300.0
const MIN_SPACING: float = 1100.0

var moments: Array[WildlifeMoment] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## `seed_value` 0 = a random hike; tests pass a fixed one.
func setup(level: Node, hiker: Hiker, hud: Hud, balance: Balance, seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	var spots: Array[Vector2] = open_ground(level, hiker.global_position.x)
	var kinds: Array = WildlifeMoment.Kind.values()
	_shuffle(kinds)
	var count: int = mini(_rng.randi_range(balance.moments_min, balance.moments_max), kinds.size())
	var used: Array[float] = []
	for k: int in count:
		var at: Vector2 = _pick_spot(spots, used)
		if at == Vector2.INF:
			break
		used.append(at.x)
		var m: WildlifeMoment = WildlifeMoment.new()
		add_child(m)
		m.global_position = at
		m.setup(kinds[k], hiker, _rng.randi())
		if kinds[k] == WildlifeMoment.Kind.REINDEER:
			m.arrived.connect(hud.show_toast.bind("TOAST_REINDEER", 3.0))
			m.bumped.connect(hud.show_toast.bind("TOAST_REINDEER_BUMP"))
		moments.append(m)


## Points on the trail (world space) where an animal can stand without crowding a piece:
## between the trailhead and the summit cairn, clear of pieces and of real gaps (strips
## that just join end to end aren't gaps).
func open_ground(level: Node, start_x: float) -> Array[Vector2]:
	var pieces: Array[float] = []
	var strips: Array[TerrainStrip] = []
	var finish_x: float = INF
	for node: Node in level.find_children("*", "", true, false):
		if node is TerrainStrip:
			strips.append(node as TerrainStrip)
		elif node is TrailFinish:
			finish_x = minf(finish_x, (node as Node2D).global_position.x)
		if node is Node2D and _is_piece(node):
			pieces.append((node as Node2D).global_position.x)
	var starts: Array[float] = []
	var ends: Array[float] = []
	for strip: TerrainStrip in strips:
		if strip.points.size() >= 2:
			starts.append(strip.to_global(strip.points[0]).x)
			ends.append(strip.to_global(strip.points[strip.points.size() - 1]).x)
	var out: Array[Vector2] = []
	for strip: TerrainStrip in strips:
		if strip.points.size() < 2:
			continue
		var first: float = strip.points[0].x
		var last: float = strip.points[strip.points.size() - 1].x
		# Only keep clear of an end with nothing continuing from it.
		var from: float = first + (0.0 if _joined(strip.to_global(strip.points[0]).x, ends) else CLEAR_OF_ENDS)
		var to: float = last - (0.0 if _joined(strip.to_global(strip.points[strip.points.size() - 1]).x, starts) else CLEAR_OF_ENDS)
		var x: float = from
		while x <= to:
			var at: Vector2 = strip.to_global(Vector2(x, strip.edge_y_at(x)))
			var slope: float = absf(strip.edge_y_at(x + 40.0) - strip.edge_y_at(x - 40.0)) / 80.0
			if slope <= MAX_SLOPE and at.x > start_x + 700.0 and at.x < finish_x - 400.0 and _clear(at.x, pieces):
				out.append(at)
			x += SAMPLE_STEP
	return out


static func _joined(x: float, others: Array[float]) -> bool:
	for o: float in others:
		if absf(o - x) < 4.0:
			return true
	return false


## Any trail piece: obstacles (bridges, stones, logs, patches...) and interactables
## (benches, checkpoints, viewpoints, finds, springs, signs, the summit).
static func _is_piece(node: Node) -> bool:
	var script: Script = node.get_script() as Script
	if script == null:
		return false
	var path: String = script.resource_path
	# Tutorial triggers are invisible: an animal can stand there.
	if path.ends_with("tutorial_trigger.gd"):
		return false
	return path.begins_with("res://world/obstacles/") or path.begins_with("res://world/interactables/")


func _clear(x: float, pieces: Array[float]) -> bool:
	for p: float in pieces:
		if absf(p - x) < CLEAR_OF_PIECES:
			return false
	return true


func _pick_spot(spots: Array[Vector2], used: Array[float]) -> Vector2:
	var options: Array[Vector2] = []
	for s: Vector2 in spots:
		var free: bool = true
		for u: float in used:
			if absf(s.x - u) < MIN_SPACING:
				free = false
				break
		if free:
			options.append(s)
	if options.is_empty():
		return Vector2.INF
	return options[_rng.randi_range(0, options.size() - 1)]


func _shuffle(list: Array) -> void:
	for i: int in range(list.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: Variant = list[i]
		list[i] = list[j]
		list[j] = tmp
