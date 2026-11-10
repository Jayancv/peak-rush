extends Node
## All game audio: sound effects (SFX bus), looping ambience per biome (Ambience bus)
## and menu music (Music bus). There are no audio assets yet, so placeholder sounds
## are synthesised by `SynthSounds` the first time they're needed; drop real
## AudioStreams into play_sfx()/play_ambience() later without touching callers.

enum Ambience { NONE, FOREST, COAST, FELL, RAIN }

const SFX_BUS: StringName = &"SFX"
const AMBIENCE_BUS: StringName = &"Ambience"
const MUSIC_BUS: StringName = &"Music"
const POOL_SIZE: int = 6
const LOOP_FADE_SECONDS: float = 1.2
## Footsteps are quiet and varied so a long walk doesn't become a metronome.
const FOOTSTEP_DB: float = -14.0
const FOOTSTEP_PITCH_JITTER: float = 0.08

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _ambience: AudioStreamPlayer
var _music: AudioStreamPlayer
var _ambience_kind: Ambience = Ambience.NONE
var _cache: Dictionary = {}
## Sounds are synthesised on a worker thread at boot so nothing is built mid-game
## (a 6 s ambience loop costs ~40 ms on a fast phone, several times that on a slow one).
const PREWARM: Array[StringName] = [&"menu_pad", &"step_0", &"step_1", &"step_2", &"step_3", &"step_4",
	&"shutter", &"summit", &"chime", &"gulp", &"creak", &"thud", &"splash", &"pebble",
	&"ambience_1", &"ambience_2", &"ambience_3", &"ambience_4"]
var _prewarm_task: int = -1
## Loops asked for before the worker finished them; they start as soon as they arrive.
var _waiting_music: bool = false
var _waiting_ambience: Ambience = Ambience.NONE
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in POOL_SIZE:
		_players.append(_make_player(SFX_BUS))
	_ambience = _make_player(AMBIENCE_BUS)
	_music = _make_player(MUSIC_BUS)
	apply_volumes()
	GameState.settings_changed.connect(apply_volumes)
	_prewarm_task = WorkerThreadPool.add_task(_prewarm, false, "Synthesise sounds")


func _exit_tree() -> void:
	if _prewarm_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_prewarm_task)
		_prewarm_task = -1


## Runs on a worker thread: builds every sound and hands each to the main thread.
func _prewarm() -> void:
	for key: StringName in PREWARM:
		var started: int = Time.get_ticks_usec()
		var stream: AudioStreamWAV = SynthSounds.make(key)
		_store.call_deferred(key, stream, (Time.get_ticks_usec() - started) / 1000.0)


func _store(key: StringName, stream: AudioStream, ms: float) -> void:
	if not _cache.has(key):
		_cache[key] = stream
	if OS.is_debug_build():
		print("PERF synth %s ms=%.1f (background)" % [key, ms])
	if _waiting_music and key == &"menu_pad":
		_waiting_music = false
		play_menu_music()
	if _waiting_ambience != Ambience.NONE and key == StringName("ambience_%d" % _waiting_ambience):
		var kind: Ambience = _waiting_ambience
		_waiting_ambience = Ambience.NONE
		_ambience_kind = Ambience.NONE
		play_ambience(kind)


func is_ready(key: StringName) -> bool:
	return _cache.has(key)


## Bus volumes from the settings (0..1 sliders).
func apply_volumes() -> void:
	_set_bus(MUSIC_BUS, float(GameState.settings.get("music_volume", 0.8)))
	_set_bus(SFX_BUS, float(GameState.settings.get("sfx_volume", 0.8)))
	_set_bus(AMBIENCE_BUS, float(GameState.settings.get("ambience_volume", 0.8)))


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	# Round-robin so overlapping sounds don't cut each other off.
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play_shutter() -> void:
	play_sfx(_sound(&"shutter"), -4.0)


func play_footstep(surface: TerrainStrip.Surface) -> void:
	var key: StringName = StringName("step_%d" % surface)
	play_sfx(_sound(key), FOOTSTEP_DB, 1.0 + _rng.randf_range(-FOOTSTEP_PITCH_JITTER, FOOTSTEP_PITCH_JITTER))


func play_summit() -> void:
	play_sfx(_sound(&"summit"), -6.0)


## Little sounds for the trail extras. Pitch jitter keeps repeats from sounding canned.
func play_find() -> void:
	play_sfx(_sound(&"chime"), -6.0)


func play_drink() -> void:
	play_sfx(_sound(&"gulp"), -8.0)


func play_creak() -> void:
	play_sfx(_sound(&"creak"), -12.0, 1.0 + _rng.randf_range(-0.1, 0.1))


func play_thud() -> void:
	play_sfx(_sound(&"thud"), -4.0)


func play_splash() -> void:
	play_sfx(_sound(&"splash"), -8.0, 1.0 + _rng.randf_range(-0.08, 0.08))


func play_pebble() -> void:
	play_sfx(_sound(&"pebble"), -16.0, 1.0 + _rng.randf_range(-0.15, 0.15))


func play_ambience(kind: Ambience) -> void:
	if kind == _ambience_kind and _ambience.playing:
		return
	_ambience_kind = kind
	_waiting_ambience = Ambience.NONE
	if kind == Ambience.NONE:
		_fade_out(_ambience)
		return
	var key: StringName = StringName("ambience_%d" % kind)
	if not _cache.has(key) and _prewarm_task >= 0:
		# Still being built in the background: start it when it arrives.
		_fade_out(_ambience)
		_waiting_ambience = kind
		return
	_fade_in(_ambience, _sound(key), -10.0)


func play_menu_music() -> void:
	if _music.playing:
		return
	if not _cache.has(&"menu_pad") and _prewarm_task >= 0:
		_waiting_music = true
		return
	_fade_in(_music, _sound(&"menu_pad"), -12.0)


## Menus: soft music, no trail ambience.
func enter_menu() -> void:
	play_ambience(Ambience.NONE)
	play_menu_music()


func stop_music() -> void:
	_waiting_music = false
	_fade_out(_music)


## Ambience that suits a weather profile when a trail doesn't name one.
static func ambience_for(weather: WeatherProfile) -> Ambience:
	if weather == null:
		return Ambience.FOREST
	if weather.rain:
		return Ambience.RAIN
	if weather.wind:
		return Ambience.COAST
	if weather.fog or weather.snow:
		return Ambience.FELL
	return Ambience.FOREST


func has_bus(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) >= 0


func _sound(key: StringName) -> AudioStream:
	if not _cache.has(key):
		# Only short effects get here before the worker has made them; they're cheap.
		var started: int = Time.get_ticks_usec()
		_cache[key] = SynthSounds.make(key)
		if OS.is_debug_build():
			print("PERF synth %s ms=%.1f (main thread)" % [key, (Time.get_ticks_usec() - started) / 1000.0])
	return _cache[key]


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _fade_in(player: AudioStreamPlayer, stream: AudioStream, volume_db: float) -> void:
	player.stream = stream
	player.volume_db = -40.0
	player.play()
	create_tween().tween_property(player, "volume_db", volume_db, LOOP_FADE_SECONDS)


func _fade_out(player: AudioStreamPlayer) -> void:
	if not player.playing:
		return
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", -40.0, LOOP_FADE_SECONDS)
	tween.tween_callback(player.stop)


func _set_bus(bus_name: StringName, linear: float) -> void:
	var i: int = AudioServer.get_bus_index(bus_name)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(i, linear <= 0.001)
