class_name HikeTracker
extends Node
## Keeps track of the extras on one hike so the trail runner doesn't have to: finds
## collected (and which animals turned up today), springs, the water gauge, and the
## one-time hints (exposed ridge, sliding, thirst).

var finds: Array[StringName] = []

var _hiker: Hiker
var _hud: Hud
var _trail: TrailData
var _balance: Balance
var _hints_shown: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(hiker: Hiker, hud: Hud, trail: TrailData, level: Node, balance: Balance) -> void:
	_hiker = hiker
	_hud = hud
	_trail = trail
	_balance = balance
	_rng.randomize()
	hiker.water_changed.connect(func(v: float, m: float) -> void: hud.set_water(v, m, balance.water_low_fraction))
	hiker.thirst_changed.connect(func(thirsty: bool) -> void:
		if thirsty:
			hint_once("TOAST_THIRSTY"))
	hiker.state_changed.connect(func(_old: Hiker.State, new_state: Hiker.State) -> void:
		if new_state == Hiker.State.SLIDE:
			hint_once("TOAST_SLIDE"))
	hiker.back_blocked.connect(hint_once.bind("TOAST_BACK_LIMIT"))
	hud.set_water(1.0, 1.0, balance.water_low_fraction)
	for node: Node in get_tree().get_nodes_in_group(WindZone.GROUP):
		if level.is_ancestor_of(node):
			(node as WindZone).hiker_entered_zone.connect(hint_once.bind("TOAST_EXPOSED"))
	for node: Node in get_tree().get_nodes_in_group(Spring.GROUP):
		if level.is_ancestor_of(node):
			(node as Spring).hiker_arrived.connect(hint_once.bind("TOAST_SPRING"))
	for node: Node in get_tree().get_nodes_in_group(Find.GROUP):
		var find: Find = node as Find
		if find == null or not level.is_ancestor_of(find):
			continue
		var data: FindData = trail.get_find(find.find_id)
		if data != null and data.kind == FindData.Kind.ANIMAL:
			# Animals only turn up on some hikes.
			find.set_present(_rng.randf() < data.appear_chance)
		find.collected.connect(_on_find)
	_update_hud()


## Shows a hint the first time something happens on this hike.
func hint_once(key: String) -> void:
	if not _hints_shown.has(key):
		_hints_shown[key] = true
		_hud.show_toast(key)


func _on_find(id: StringName) -> void:
	if finds.has(id):
		return
	finds.append(id)
	var data: FindData = _trail.get_find(id)
	var name_text: String = tr(data.name_key) if data != null else String(id)
	var known: bool = GameState.record(_trail.id).get("finds", []).has(String(id))
	var key: String = "TOAST_SPOTTED" if data != null and data.kind == FindData.Kind.ANIMAL else "TOAST_FOUND"
	_hud.show_toast_text(tr(key) % name_text + ("" if known else "  " + tr("TOAST_NEW_FIND")))
	_update_hud()


func _update_hud() -> void:
	_hud.set_finds(finds.size(), _trail.finds.size())
