extends GutTest


func test_buses_exist() -> void:
	for bus: StringName in [AudioManager.MUSIC_BUS, AudioManager.SFX_BUS, AudioManager.AMBIENCE_BUS]:
		assert_true(AudioManager.has_bus(bus), "missing bus %s" % bus)


func test_every_surface_has_a_footstep() -> void:
	for surface: int in TerrainStrip.Surface.values():
		var wav: AudioStreamWAV = SynthSounds.make(StringName("step_%d" % surface))
		assert_gt(wav.data.size(), 100, "footstep for surface %d is empty" % surface)
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED)


func test_ambiences_loop() -> void:
	for kind: int in [AudioManager.Ambience.FOREST, AudioManager.Ambience.COAST, AudioManager.Ambience.FELL, AudioManager.Ambience.RAIN]:
		var wav: AudioStreamWAV = SynthSounds.make(StringName("ambience_%d" % kind))
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD)
		assert_gt(wav.loop_end, SynthSounds.LOOP_RATE, "loop should be longer than a second")


func test_every_sound_has_read_ahead_padding() -> void:
	# Regression: the mixer reads past the play position; unpadded buffers crashed on Android.
	for key: StringName in [&"shutter", &"summit", &"menu_pad", &"step_0", &"step_4", &"ambience_1", &"ambience_3",
			&"chime", &"gulp", &"creak", &"thud", &"splash", &"pebble"]:
		var wav: AudioStreamWAV = SynthSounds.make(key)
		var frames: int = wav.data.size() / 2
		if wav.loop_mode == AudioStreamWAV.LOOP_FORWARD:
			assert_gte(frames - wav.loop_end, SynthSounds.TAIL_PAD, "%s loop has no padding" % key)
		else:
			# Last frames of a one-shot must be silence.
			assert_eq(wav.data.decode_s16(wav.data.size() - 2), 0, "%s doesn't end in silence" % key)


func test_sfx_volume_setting_moves_the_bus() -> void:
	var before: float = float(GameState.settings.get("sfx_volume", 0.8))
	GameState.set_setting("sfx_volume", 0.25)
	var db: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(AudioManager.SFX_BUS))
	assert_almost_eq(db, linear_to_db(0.25), 0.01)
	GameState.set_setting("sfx_volume", before)


func test_zero_volume_mutes() -> void:
	var before: float = float(GameState.settings.get("music_volume", 0.8))
	GameState.set_setting("music_volume", 0.0)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(AudioManager.MUSIC_BUS)))
	GameState.set_setting("music_volume", before)


func test_ambience_follows_weather_when_not_set() -> void:
	assert_eq(AudioManager.ambience_for(load("res://content/weather/rain.tres")), AudioManager.Ambience.RAIN)
	assert_eq(AudioManager.ambience_for(load("res://content/weather/windy.tres")), AudioManager.Ambience.COAST)
	assert_eq(AudioManager.ambience_for(null), AudioManager.Ambience.FOREST)


func test_playing_sounds_does_not_error() -> void:
	AudioManager.play_footstep(TerrainStrip.Surface.SNOW)
	AudioManager.play_shutter()
	AudioManager.play_summit()
	AudioManager.play_ambience(AudioManager.Ambience.FOREST)
	AudioManager.enter_menu()
	assert_true(true)
