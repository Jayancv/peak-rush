class_name SynthSfx
extends RefCounted
## More placeholder effects (split from SynthSounds to keep files small): a chime for
## finds, a gulp at springs, a rope-bridge creak, a boulder thud, a splash and a
## pebble click. Same rules: generated once, one-shots end in silence (padding).

const RATE: int = SynthSounds.SFX_RATE


static func make(key: String) -> AudioStreamWAV:
	match key:
		"chime":
			return _chime()
		"gulp":
			return _gulp()
		"creak":
			return _creak()
		"thud":
			return _thud()
		"splash":
			return _splash()
		"pebble":
			return _pebble()
	return null


## Two soft bell notes and a shimmer: something found.
static func _chime() -> AudioStreamWAV:
	var n: int = int(RATE * 1.0)
	var out: PackedFloat32Array = _empty(n)
	for k: int in 2:
		var f: float = [1318.5, 1975.5][k]
		var start: int = int(RATE * 0.09 * k)
		for i: int in range(start, n):
			var t: float = float(i - start) / RATE
			var env: float = minf(t * 300.0, 1.0) * exp(-t * 4.5)
			out[i] += (sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.76 * t)) * env * 0.22
	return SynthSounds._wav(out, RATE, false)


## Three rising bubbles: a drink from the spring.
static func _gulp() -> AudioStreamWAV:
	var n: int = int(RATE * 0.5)
	var out: PackedFloat32Array = _empty(n)
	for k: int in 3:
		var start: int = int(RATE * 0.14 * k)
		var phase: float = 0.0
		for i: int in range(start, mini(start + int(RATE * 0.11), n)):
			var t: float = float(i - start) / RATE
			phase += TAU * (170.0 + 1600.0 * t) / RATE
			out[i] += sin(phase) * sin(PI * t / 0.11) * 0.5
	return SynthSounds._wav(out, RATE, false)


## Rope and planks taking weight: a low, gritty, wavering creak.
static func _creak() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = SynthSounds._rng(31)
	var n: int = int(RATE * 0.38)
	var out: PackedFloat32Array = _empty(n)
	var phase: float = 0.0
	for i: int in n:
		var t: float = float(i) / RATE
		phase += TAU * (95.0 + 40.0 * sin(TAU * 3.0 * t)) / RATE
		var saw: float = fmod(phase / TAU, 1.0) * 2.0 - 1.0
		var grit: float = 0.55 + 0.45 * float(rng.randf() > 0.4)
		out[i] = saw * grit * sin(PI * t / 0.38) * 0.35
	return SynthSounds._wav(out, RATE, false)


## A heavy rock hitting the ground: low boom plus a short burst of grit.
static func _thud() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = SynthSounds._rng(37)
	var n: int = int(RATE * 0.45)
	var out: PackedFloat32Array = _empty(n)
	var smooth: float = 0.0
	for i: int in n:
		var t: float = float(i) / RATE
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.2)
		out[i] = (sin(TAU * (70.0 - 30.0 * t) * t) * exp(-t * 9.0) * 0.8 + smooth * exp(-t * 30.0) * 0.6) * minf(t * 300.0, 1.0)
	return SynthSounds._wav(out, RATE, false)


## Water breaking: a bright noise burst that settles into bubbly droplets.
static func _splash() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = SynthSounds._rng(41)
	var n: int = int(RATE * 0.55)
	var out: PackedFloat32Array = _empty(n)
	var prev: float = 0.0
	for i: int in n:
		var t: float = float(i) / RATE
		var noise: float = rng.randf_range(-1.0, 1.0)
		var bright: float = noise - prev
		prev = noise
		var drops: float = 1.0 if t < 0.12 or rng.randf() > 0.82 else 0.35
		out[i] = bright * exp(-t * 7.0) * minf(t * 500.0, 1.0) * drops * 0.4
	return SynthSounds._wav(out, RATE, false)


## Two tiny stone ticks: a kicked pebble.
static func _pebble() -> AudioStreamWAV:
	var n: int = int(RATE * 0.14)
	var out: PackedFloat32Array = _empty(n)
	for k: int in 2:
		var start: int = int(RATE * 0.06 * k)
		for i: int in range(start, n):
			var t: float = float(i - start) / RATE
			out[i] += sin(TAU * (1900.0 - 300.0 * k) * t) * exp(-t * 180.0) * (0.5 - 0.2 * k)
	return SynthSounds._wav(out, RATE, false)


static func _empty(n: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	return out
