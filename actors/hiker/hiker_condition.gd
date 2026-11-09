class_name HikerCondition
extends RefCounted
## Everything about how the hiker is *doing*: stamina, wet feet, sitting at a bench,
## standing in a mud/ice patch, hiking at dusk. Turns that into the speed multiplier
## the movement code uses and drains or refills stamina each tick.

## How the hiker is recovering right now; drives the sit pose, sparkles and HUD boost.
enum Regen { NONE, REST, BENCH }

signal regen_changed(mode: Regen)

var stamina: Stamina
var regen: Regen = Regen.NONE
var modifiers: HikeModifiers
var is_dusk: bool = false
## Multiplier from weather; gear (M6) plugs in the same way.
var weather_drain_mult: float = 1.0
## Wind pushing back (px/s, negative = towards the trailhead). Only applied while
## walking or airborne: standing still braces the hiker against it.
var wind_push: float = 0.0
var wet_feet_left: float = 0.0

var _balance: Balance
var _bench_count: int = 0
## Patches can overlap, so keep a stack and use the most recent one.
var _patches: Array[TerrainStrip.Surface] = []


func _init(balance: Balance) -> void:
	_balance = balance
	stamina = Stamina.new(balance)
	modifiers = HikeModifiers.new(balance)


func effective_surface(ground: TerrainStrip.Surface) -> TerrainStrip.Surface:
	return _patches.back() if not _patches.is_empty() else ground


func speed_multiplier(grade: float, ground: TerrainStrip.Surface) -> float:
	return modifiers.speed_multiplier(grade, effective_surface(ground), is_dusk, stamina.recovering)


## Called every physics tick by the hiker with what it's currently doing.
func tick(delta: float, walking: bool, resting: bool, grade: float, ground: TerrainStrip.Surface) -> void:
	wet_feet_left = maxf(wet_feet_left - delta, 0.0)
	if walking:
		var drain: float = modifiers.drain_multiplier(grade, effective_surface(ground), has_wet_feet(), weather_drain_mult)
		stamina.walk(delta, drain)
	elif resting:
		stamina.rest(delta, is_on_bench(), modifiers.gear.rest_regen_scale)
	var mode: Regen = Regen.NONE
	if resting and stamina.value < stamina.max_value:
		mode = Regen.BENCH if is_on_bench() else Regen.REST
	if mode != regen:
		regen = mode
		regen_changed.emit(mode)


func set_gear(items: Array[GearData]) -> void:
	modifiers.gear = GearModifiers.from_gear(items)


func has_wet_feet() -> bool:
	return wet_feet_left > 0.0


func soak_feet() -> void:
	wet_feet_left = _balance.wet_feet_seconds


func is_on_bench() -> bool:
	return _bench_count > 0


func enter_bench() -> void:
	_bench_count += 1


func exit_bench() -> void:
	_bench_count = maxi(_bench_count - 1, 0)


func enter_patch(surface: TerrainStrip.Surface) -> void:
	_patches.append(surface)


func exit_patch(surface: TerrainStrip.Surface) -> void:
	var i: int = _patches.rfind(surface)
	if i >= 0:
		_patches.remove_at(i)


## Respawning clears whatever the hiker was standing in.
func clear_location_effects() -> void:
	_bench_count = 0
	_patches.clear()
