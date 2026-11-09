extends Node
## Plays sound effects (music, ambience and buses arrive in M5).
## Until real audio assets exist, a few placeholder sounds are synthesised here so
## the game already gives audible feedback (e.g. the camera shutter).

const MIX_RATE: int = 22050
const POOL_SIZE: int = 4

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _shutter: AudioStreamWAV


func _ready() -> void:
	for i: int in POOL_SIZE:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_shutter = _make_shutter()


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	# Round-robin so overlapping sounds don't cut each other off.
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db + linear_to_db(maxf(float(GameState.settings.get("sfx_volume", 0.8)), 0.001))
	p.play()


func play_shutter() -> void:
	play_sfx(_shutter, -4.0)


## Two short decaying noise clicks: the mirror going up, then the shutter closing.
static func _make_shutter() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var length: int = int(MIX_RATE * 0.14)
	var second_click: int = int(MIX_RATE * 0.06)
	var data: PackedByteArray = PackedByteArray()
	data.resize(length * 2)
	var smooth: float = 0.0
	for i: int in length:
		var t1: float = float(i) / MIX_RATE
		var t2: float = float(i - second_click) / MIX_RATE
		var env: float = exp(-t1 * 90.0)
		if i >= second_click:
			env += 0.8 * exp(-t2 * 120.0)
		# A little low-pass so it's a click, not hiss.
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.45)
		var sample: int = clampi(int(smooth * env * 26000.0), -32768, 32767)
		data.encode_s16(i * 2, sample)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
