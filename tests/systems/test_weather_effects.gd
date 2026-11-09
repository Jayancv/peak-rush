extends GutTest


func _windy() -> WeatherProfile:
	var p: WeatherProfile = WeatherProfile.new()
	p.wind = true
	p.wind_base = 5.0
	p.gust_strength = 80.0
	p.gust_interval = Vector2(2.0, 3.0)
	p.gust_seconds = 1.0
	return p


func _run_until_gust(w: WeatherEffects, limit: float = 10.0) -> float:
	var t: float = 0.0
	while t < limit and not w.is_gusting():
		w.advance(0.05)
		t += 0.05
	return t


func test_clear_weather_has_no_wind_or_fog() -> void:
	var w: WeatherEffects = WeatherEffects.new(WeatherProfile.new())
	w.advance(30.0)
	assert_eq(w.wind_push(), 0.0)
	assert_eq(w.fog_alpha(), 0.0)
	assert_false(w.is_gusting())


func test_null_profile_is_clear() -> void:
	assert_eq(WeatherEffects.new(null).drain_multiplier(), 1.0)


func test_steady_headwind_between_gusts() -> void:
	var w: WeatherEffects = WeatherEffects.new(_windy())
	w.advance(0.5)
	assert_false(w.is_gusting())
	assert_almost_eq(w.wind_push(), -5.0, 0.001)


func test_gust_arrives_within_the_interval_and_pushes_harder() -> void:
	var w: WeatherEffects = WeatherEffects.new(_windy())
	watch_signals(w)
	var t: float = _run_until_gust(w)
	assert_between(t, 2.0, 3.1)
	assert_signal_emitted(w, "gust_started")
	w.advance(0.5)
	assert_lt(w.wind_push(), -60.0, "mid-gust is close to full strength")
	assert_gt(w.wind_push(), -85.1, "never more than base + gust")


func test_gust_ends() -> void:
	var w: WeatherEffects = WeatherEffects.new(_windy())
	_run_until_gust(w)
	w.advance(1.05)
	assert_false(w.is_gusting())


func test_same_seed_same_gusts() -> void:
	var a: WeatherEffects = WeatherEffects.new(_windy(), 42)
	var b: WeatherEffects = WeatherEffects.new(_windy(), 42)
	assert_eq(_run_until_gust(a), _run_until_gust(b))


func test_fog_and_drain_come_from_profile() -> void:
	var p: WeatherProfile = WeatherProfile.new()
	p.fog = true
	p.fog_density = 0.6
	p.drain_multiplier = 1.3
	var w: WeatherEffects = WeatherEffects.new(p)
	assert_eq(w.fog_alpha(), 0.6)
	assert_eq(w.drain_multiplier(), 1.3)


func test_shipped_profiles_match_design() -> void:
	# GAME_DESIGN §5.8: rain ×1.3, snow ×1.2.
	assert_eq((load("res://content/weather/rain.tres") as WeatherProfile).drain_multiplier, 1.3)
	assert_eq((load("res://content/weather/snow.tres") as WeatherProfile).drain_multiplier, 1.2)
	assert_true((load("res://content/weather/windy.tres") as WeatherProfile).wind)
	assert_true((load("res://content/weather/fog.tres") as WeatherProfile).fog)
