class_name HikeTracker
extends Node
## Keeps track of the extras on one hike so the trail runner doesn't have to: finds
## collected (and which animals turned up today), springs, the water gauge, and the
## one-time hints (benches, gusts, exposed ridge, sliding, thirst, tutorial triggers).

var finds: Array[StringName] = []

## Short description of each daily twist (DailyChallenge.Twist order).
const TWIST_KEYS: Array[String] = ["DAILY_TWIST_HEADWIND", "DAILY_TWIST_FOG", "DAILY_TWIST_SHORT_DAY", "DAILY_TWIST_FORAGER", "DAILY_TWIST_BEAT_PAR"]

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
	# Benches are explained the first time; after that the ×2 badge says it.
	hiker.regen_changed.connect(func(mode: HikerCondition.Regen) -> void:
		if mode == HikerCondition.Regen.BENCH:
			hint_once("TOAST_BENCH"))
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
	if trail.tutorial and not GameState.is_completed(trail.id):
		for node: Node in get_tree().get_nodes_in_group(TutorialTrigger.GROUP):
			if level.is_ancestor_of(node):
				(node as TutorialTrigger).triggered.connect(func(key: String, secs: float) -> void: hud.show_toast(key, secs))
	_update_hud()


## Wind is explained on the first gust; afterwards the streaks and the push say it.
func watch_weather(weather: WeatherEffects) -> void:
	weather.gust_started.connect(hint_once.bind("TOAST_GUST"))


## Today's twist if this hike is the daily trail (and it isn't done yet), else -1.
static func daily_twist(trail: TrailData) -> int:
	if not GameState.daily_active:
		return -1
	var d: Dictionary = GameState.daily_today()
	if d.is_empty() or d.trail_id != trail.id or d.done:
		GameState.daily_active = false
		return -1
	return int(d.twist)


## The trail's weather, with thick fog added on a foggy daily.
static func twisted_weather(base: WeatherProfile, twist: int, balance: Balance) -> WeatherProfile:
	if twist != DailyChallenge.Twist.FOG:
		return base
	var w: WeatherProfile = base.duplicate() as WeatherProfile if base != null else WeatherProfile.new()
	w.fog = true
	w.fog_density = maxf(w.fog_density, balance.daily_fog_density)
	return w


func announce_daily(twist: int) -> void:
	if twist >= 0:
		_hud.show_toast_text(tr("TOAST_DAILY") % tr(TWIST_KEYS[twist]), 3.5)


## Shows a hint the first time something happens on this hike.
func hint_once(key: String) -> void:
	if not _hints_shown.has(key):
		_hints_shown[key] = true
		_hud.show_toast(key)


func _on_find(id: StringName) -> void:
	if finds.has(id):
		return
	finds.append(id)
	AudioManager.play_find()
	var data: FindData = _trail.get_find(id)
	var name_text: String = tr(data.name_key) if data != null else String(id)
	var known: bool = GameState.record(_trail.id).get("finds", []).has(String(id))
	var key: String = "TOAST_SPOTTED" if data != null and data.kind == FindData.Kind.ANIMAL else "TOAST_FOUND"
	_hud.show_toast_text(tr(key) % name_text + ("" if known else "  " + tr("TOAST_NEW_FIND")))
	_update_hud()


func _update_hud() -> void:
	_hud.set_finds(finds.size(), _trail.finds.size())
