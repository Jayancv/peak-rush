class_name SynthSounds
extends RefCounted
## Placeholder sounds built from noise and sine waves, so the game has audio before
## real assets exist. Each is generated once on first use (AudioManager caches it).
## Loops cross-fade their tail into their head so they repeat without a click.

const SFX_RATE: int = 22050
## Long loops use a lower rate: quicker to build on a phone, and they're soft anyway.
const LOOP_RATE: int = 16000


static func make(key: StringName) -> AudioStreamWAV:
	match String(key):
		"shutter":
			return _shutter()
		"summit":
			return _summit()
		"menu_pad":
			return _menu_pad()
	var extra: AudioStreamWAV = SynthSfx.make(String(key))
	if extra != null:
		return extra
	if String(key).begins_with("step_"):
		return _footstep(int(String(key).trim_prefix("step_")))
	if String(key).begins_with("ambience_"):
		return _ambience(int(String(key).trim_prefix("ambience_")))
	push_error("SynthSounds: unknown sound %s" % key)
	return _wav(PackedFloat32Array([0.0]), SFX_RATE, false)


## Two short decaying noise clicks: the mirror going up, then the shutter closing.
static func _shutter() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = _rng(7)
	var n: int = int(SFX_RATE * 0.14)
	var second: int = int(SFX_RATE * 0.06)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var smooth: float = 0.0
	for i: int in n:
		var env: float = exp(-float(i) / SFX_RATE * 90.0)
		if i >= second:
			env += 0.8 * exp(-float(i - second) / SFX_RATE * 120.0)
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.45)
		out[i] = smooth * env * 0.8
	return _wav(out, SFX_RATE, false)


## A footstep per surface: soft thud on dirt, click on rock, squelch in mud,
## sharp tick on ice, crunch in snow (TerrainStrip.Surface order).
static func _footstep(surface: int) -> AudioStreamWAV:
	# length s, low-pass amount, decay rate, tone Hz, tone mix, wobble Hz, crunch
	var presets: Array = [
		[0.09, 0.16, 45.0, 0.0, 0.0, 0.0, false],
		[0.05, 0.6, 90.0, 1100.0, 0.3, 0.0, false],
		[0.15, 0.07, 22.0, 0.0, 0.0, 28.0, false],
		[0.04, 0.85, 140.0, 2400.0, 0.25, 0.0, false],
		[0.11, 0.45, 32.0, 0.0, 0.0, 0.0, true],
	]
	var p: Array = presets[clampi(surface, 0, presets.size() - 1)]
	var rng: RandomNumberGenerator = _rng(11 + surface)
	var n: int = int(SFX_RATE * float(p[0]))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var smooth: float = 0.0
	var gate: float = 1.0
	for i: int in n:
		var t: float = float(i) / SFX_RATE
		var env: float = exp(-t * float(p[2])) * minf(t * 400.0, 1.0)
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), float(p[1]))
		var s: float = smooth * (1.0 - float(p[4])) + sin(TAU * float(p[3]) * t) * float(p[4])
		if float(p[5]) > 0.0:
			s *= 0.6 + 0.4 * sin(TAU * float(p[5]) * t)
		if bool(p[6]) and i % 40 == 0:
			gate = 1.0 if rng.randf() > 0.35 else 0.25
		out[i] = s * env * gate * 1.6
	return _wav(out, SFX_RATE, false)


## A bright rising arpeggio (C E G C) for reaching the summit.
static func _summit() -> AudioStreamWAV:
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	var n: int = int(SFX_RATE * 1.9)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for k: int in notes.size():
		var start: int = int(SFX_RATE * 0.12 * k)
		for i: int in range(start, n):
			var t: float = float(i - start) / SFX_RATE
			var env: float = minf(t * 80.0, 1.0) * exp(-t * 2.6)
			var f: float = notes[k]
			out[i] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * env * 0.22
	return _wav(out, SFX_RATE, false)


static func _ambience(kind: int) -> AudioStreamWAV:
	match kind:
		1:
			return _forest()
		2:
			return _coast()
		3:
			return _fell_wind()
		4:
			return _rain()
	return _wav(PackedFloat32Array([0.0]), LOOP_RATE, false)


## Soft breeze with a few bird chirps.
static func _forest() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = _rng(21)
	var out: PackedFloat32Array = _breeze(6.0, 0.08, 0.02, rng)
	for c: int in 5:
		var at: int = int(rng.randf_range(0.2, 5.4) * LOOP_RATE)
		var base: float = rng.randf_range(2600.0, 3600.0)
		for rep: int in rng.randi_range(2, 3):
			var start: int = at + int(rep * 0.11 * LOOP_RATE)
			var chirp_len: int = int(0.07 * LOOP_RATE)
			for i: int in chirp_len:
				var t: float = float(i) / LOOP_RATE
				var idx: int = (start + i) % out.size()
				var f: float = base + 1400.0 * t / 0.07
				out[idx] += sin(TAU * f * t) * sin(PI * float(i) / chirp_len) * 0.12
	return _wav(_seamless(out, LOOP_RATE), LOOP_RATE, true)


## Waves: low rumbling noise swelling once per loop.
static func _coast() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = _rng(31)
	var seconds: float = 6.0
	var n: int = int(LOOP_RATE * seconds)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var smooth: float = 0.0
	for i: int in n:
		var phase: float = float(i) / n
		var swell: float = pow(0.5 + 0.5 * sin(TAU * phase - PI * 0.5), 2.0)
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.05 + 0.1 * swell)
		out[i] = smooth * (0.12 + 0.55 * swell)
	return _wav(_seamless(out, LOOP_RATE), LOOP_RATE, true)


## Open-fell wind: noise whose brightness and loudness rise and fall.
static func _fell_wind() -> AudioStreamWAV:
	return _wav(_seamless(_breeze(8.0, 0.18, 0.06, _rng(41)), LOOP_RATE), LOOP_RATE, true)


## Rain: bright hiss with scattered drops.
static func _rain() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = _rng(51)
	var n: int = int(LOOP_RATE * 5.0)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var low: float = 0.0
	for i: int in n:
		var white: float = rng.randf_range(-1.0, 1.0)
		low = lerpf(low, white, 0.2)
		out[i] = (white - low) * 0.22
		if rng.randf() < 0.0015:
			out[i] += rng.randf_range(0.3, 0.6)
	return _wav(_seamless(out, LOOP_RATE), LOOP_RATE, true)


## A calm four-chord pad for the menus.
static func _menu_pad() -> AudioStreamWAV:
	var chords: Array = [[261.63, 329.63, 392.0, 493.88], [220.0, 261.63, 329.63, 392.0], [174.61, 220.0, 261.63, 329.63], [196.0, 246.94, 293.66, 392.0]]
	var chord_len: float = 2.5
	var n: int = int(LOOP_RATE * chord_len * chords.size())
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for i: int in n:
		var t: float = float(i) / LOOP_RATE
		var c: int = int(t / chord_len)
		var local: float = fmod(t, chord_len)
		var env: float = minf(local / 0.6, 1.0) * minf((chord_len - local) / 0.6, 1.0)
		var s: float = 0.0
		for f: float in chords[c]:
			s += sin(TAU * f * t) + 0.5 * sin(TAU * f * 1.003 * t)
		out[i] = s * env * 0.05
	return _wav(out, LOOP_RATE, true)


## Filtered noise whose level and brightness drift slowly (wind).
static func _breeze(seconds: float, gain: float, brightness: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n: int = int(LOOP_RATE * seconds)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var smooth: float = 0.0
	for i: int in n:
		var phase: float = float(i) / n
		var drift: float = 0.6 + 0.4 * sin(TAU * phase * 2.0) * sin(TAU * phase * 3.0)
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), brightness * (0.6 + drift))
		out[i] = smooth * gain * 4.0 * drift
	return out


## Fades the last half-second into the first so the loop point is inaudible.
static func _seamless(samples: PackedFloat32Array, rate: int) -> PackedFloat32Array:
	var fade: int = mini(int(rate * 0.5), samples.size() / 4)
	var n: int = samples.size() - fade
	for i: int in fade:
		var w: float = float(i) / fade
		samples[i] = samples[i] * w + samples[n + i] * (1.0 - w)
	samples.resize(n)
	return samples


## Extra frames after the sound. The mixer reads a frame or two past the play
## position to interpolate (pitch != 1, loop wrap); without real data there it
## over-reads the buffer, which hardened Android allocators kill the app for.
const TAIL_PAD: int = 32


static func _wav(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var length: int = samples.size()
	var total: int = length + TAIL_PAD
	var data: PackedByteArray = PackedByteArray()
	data.resize(total * 2)
	for i: int in total:
		# Loops continue into a copy of their start (so the wrap is seamless too);
		# one-shots trail off into silence.
		var s: float = 0.0
		if i < length:
			s = samples[i]
		elif loop and length > 0:
			s = samples[(i - length) % length]
		data.encode_s16(i * 2, clampi(int(s * 32767.0), -32768, 32767))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		# The loop ends where the real sound ends; the padding is only ever read ahead.
		wav.loop_end = length
	return wav


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
