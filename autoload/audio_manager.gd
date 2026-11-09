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
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in POOL_SIZE:
		_players.append(_make_player(SFX_BUS))
	_ambience = _make_player(AMBIENCE_BUS)
	_music = _make_player(MUSIC_BUS)
	apply_volumes()
	GameState.settings_changed.connect(apply_volumes)


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


func play_ambience(kind: Ambience) -> void:
	if kind == _ambience_kind and _ambience.playing:
		return
	_ambience_kind = kind
	if kind == Ambience.NONE:
		_fade_out(_ambience)
		return
	_fade_in(_ambience, _sound(StringName("ambience_%d" % kind)), -10.0)


func play_menu_music() -> void:
	if _music.playing:
		return
	_fade_in(_music, _sound(&"menu_pad"), -12.0)


## Menus: soft music, no trail ambience.
func enter_menu() -> void:
	play_ambience(Ambience.NONE)
	play_menu_music()


func stop_music() -> void:
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
		_cache[key] = SynthSounds.make(key)
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
