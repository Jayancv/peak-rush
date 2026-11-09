class_name WeatherEffects
extends RefCounted
## Runs a trail's weather over time: when gusts happen and how hard the wind pushes.
## Seeded, so a test (or a replay) sees the same gusts at the same moments.
## "Resting braces you": the hiker only applies wind_push() while walking or airborne.

signal gust_started

var profile: WeatherProfile

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _time: float = 0.0
var _next_gust_at: float = INF
var _gust_started_at: float = -INF


func _init(weather: WeatherProfile, seed_value: int = 1) -> void:
	profile = weather if weather != null else WeatherProfile.new()
	_rng.seed = seed_value
	if profile.wind:
		_next_gust_at = _rng.randf_range(profile.gust_interval.x, profile.gust_interval.y)


func advance(delta: float) -> void:
	_time += delta
	if _time >= _next_gust_at:
		_gust_started_at = _next_gust_at
		_next_gust_at += profile.gust_seconds + _rng.randf_range(profile.gust_interval.x, profile.gust_interval.y)
		gust_started.emit()


func is_gusting() -> bool:
	return _time - _gust_started_at < profile.gust_seconds


## 0..1 over a gust: swells in and dies away (half a sine).
func gust_strength() -> float:
	if not is_gusting():
		return 0.0
	return sin(PI * (_time - _gust_started_at) / profile.gust_seconds)


## Horizontal push on the hiker in px/s (negative = back down the trail).
func wind_push() -> float:
	if not profile.wind:
		return 0.0
	return -(profile.wind_base + profile.gust_strength * gust_strength())


func drain_multiplier() -> float:
	return profile.drain_multiplier


func fog_alpha() -> float:
	return profile.fog_density if profile.fog else 0.0
