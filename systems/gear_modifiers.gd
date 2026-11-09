class_name GearModifiers
extends RefCounted
## The combined effect of the equipped gear. Scales multiply, so two items that
## touch the same thing stack (only two slots, so it never gets silly).

var slip_scale: float = 1.0
var uphill_drain_scale: float = 1.0
var weather_drain_scale: float = 1.0
var rest_regen_scale: float = 1.0
var dusk_penalty_scale: float = 1.0


static func from_gear(items: Array[GearData]) -> GearModifiers:
	var m: GearModifiers = GearModifiers.new()
	for g: GearData in items:
		if g == null:
			continue
		m.slip_scale *= g.slip_scale
		m.uphill_drain_scale *= g.uphill_drain_scale
		m.weather_drain_scale *= g.weather_drain_scale
		m.rest_regen_scale *= g.rest_regen_scale
		m.dusk_penalty_scale *= g.dusk_penalty_scale
	return m


## Weather multiplier after gear: only the part above 1.0 is scaled.
func weather_multiplier(weather_mult: float) -> float:
	return 1.0 + (weather_mult - 1.0) * weather_drain_scale


## Dusk speed multiplier after gear (0.7 base with half penalty -> 0.85).
func dusk_speed(dusk_speed_mult: float) -> float:
	return 1.0 - (1.0 - dusk_speed_mult) * dusk_penalty_scale
