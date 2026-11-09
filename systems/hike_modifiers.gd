class_name HikeModifiers
extends RefCounted
## Combines everything that changes how fast the hiker walks and how fast they tire:
## slope, surface underfoot, wet feet, dusk and exhaustion. Weather (M5) and gear (M6)
## plug in as extra multipliers. All effects multiply together.

var _balance: Balance
var _slope: Slope


func _init(balance: Balance) -> void:
	_balance = balance
	_slope = Slope.new(balance)


func slope() -> Slope:
	return _slope


## Multiplies walk_speed. Slope is included here so states need one number.
func speed_multiplier(grade: float, surface: TerrainStrip.Surface, is_dusk: bool, recovering: bool) -> float:
	var m: float = _slope.speed_factor(grade)
	m *= surface_speed(surface)
	if is_dusk:
		m *= _balance.dusk_speed_mult
	if recovering:
		m *= _balance.exhausted_speed_mult
	return m


## Multiplies the base walking drain.
func drain_multiplier(grade: float, surface: TerrainStrip.Surface, wet_feet: bool, weather_mult: float = 1.0) -> float:
	var m: float = _slope.drain_factor(grade) * weather_mult
	if surface == TerrainStrip.Surface.MUD:
		m *= _balance.mud_drain_mult
	if wet_feet:
		m *= 1.0 + _balance.wet_feet_drain_bonus
	return m


func surface_speed(surface: TerrainStrip.Surface) -> float:
	match surface:
		TerrainStrip.Surface.MUD:
			return _balance.mud_speed_mult
		TerrainStrip.Surface.ICE:
			return _balance.ice_speed_mult
		TerrainStrip.Surface.SNOW:
			return _balance.snow_speed_mult
	return 1.0


static func is_slippery(surface: TerrainStrip.Surface) -> bool:
	return surface == TerrainStrip.Surface.ICE
