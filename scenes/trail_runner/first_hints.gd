class_name FirstHints
extends Node
## Hints that explain a mechanic the first time the player meets it — ever, not per
## hike (seen hints are saved in the profile): walking back after the first checkpoint,
## picking up finds, standing still for animals, forks, drinking water, hurrying, high
## jumps, ladders and ducking.
## One hint at a time; the next waits until the previous one has had its moment.

const FINDS: String = "HINT_FINDS"
const ANIMAL: String = "HINT_ANIMAL"
const FORK: String = "HINT_FORK"
const BACK: String = "HINT_BACK"
const WATER: String = "HINT_WATER"
const FLOW: String = "HINT_FLOW"
const HURRY: String = "HINT_HURRY"
const HIGH_JUMP: String = "HINT_HIGH_JUMP"
const CLIMB: String = "HINT_CLIMB"
const DUCK: String = "HINT_DUCK"
## Level nodes in this group (e.g. a Marker2D under a high lookout) explain Hold-to-jump-higher.
const HIGH_LEDGE_GROUP: StringName = &"high_ledge"

var _hiker: Hiker
var _hud: Hud
var _balance: Balance
## [position, hint key] of things that explain themselves when the hiker gets close.
var _spots: Array = []
var _queue: Array[String] = []
var _busy_left: float = 0.0
var _walk_seconds: float = 0.0


func setup(hiker: Hiker, hud: Hud, level: Node, balance: Balance) -> void:
	_hiker = hiker
	_hud = hud
	_balance = balance
	for node: Node in get_tree().get_nodes_in_group(Find.GROUP):
		var find: Find = node as Find
		if find != null and level.is_ancestor_of(find):
			_spots.append([find, ANIMAL if find.kind == FindData.Kind.ANIMAL else FINDS])
	for node: Node in level.find_children("*", "ForkSign", true, false):
		_spots.append([node, FORK])
	for node: Node in level.find_children("*", "Ladder", true, false):
		_spots.append([node, CLIMB])
	for node: Node in level.find_children("*", "LowBranch", true, false):
		_spots.append([node, DUCK])
	for node: Node in get_tree().get_nodes_in_group(HIGH_LEDGE_GROUP):
		if level.is_ancestor_of(node):
			_spots.append([node, HIGH_JUMP])
	hiker.checkpoint_reached.connect(func(_at: Vector2) -> void:
		# After the "Checkpoint reached" toast, not over it.
		get_tree().create_timer(balance.hint_back_delay, false).timeout.connect(request.bind(BACK)))
	hiker.condition.flow.level_changed.connect(func(level: int) -> void:
		if level > 0:
			request(FLOW))
	hiker.water_changed.connect(func(value: float, max_value: float) -> void:
		if max_value > 0.0 and value / max_value < balance.hint_water_fraction:
			request(WATER))


## Queues `key` unless the player has seen it before (or it's already waiting).
func request(key: String) -> void:
	if GameState.profile.has_seen_hint(key) or _queue.has(key):
		return
	_queue.append(key)


func _process(delta: float) -> void:
	if _hiker == null:
		return
	var at: Vector2 = _hiker.global_position
	for i: int in range(_spots.size() - 1, -1, -1):
		var thing: Node2D = _spots[i][0] as Node2D
		if not is_instance_valid(thing) or not thing.is_visible_in_tree():
			continue
		var ahead: float = thing.global_position.x - at.x
		if ahead > -40.0 and ahead < _balance.hint_near_px and absf(thing.global_position.y - at.y) < _balance.hint_near_px:
			request(_spots[i][1])
			_spots.remove_at(i)
	if _hiker.state == Hiker.State.WALK:
		_walk_seconds += delta
		if _walk_seconds >= _balance.hint_hurry_after_seconds:
			request(HURRY)
	_busy_left = maxf(_busy_left - delta, 0.0)
	if _busy_left <= 0.0 and not _queue.is_empty():
		var key: String = _queue.pop_front()
		GameState.profile.mark_hint_seen(key)
		_hud.show_toast(key, _balance.hint_seconds)
		_busy_left = _balance.hint_seconds + 0.8
