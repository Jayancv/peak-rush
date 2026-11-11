class_name WildlifeMoment
extends Node2D
## One living moment on the trail, placed at runtime by TrailMoments:
## - FLOCK: small birds pecking on the path burst into the air as the hiker comes close.
## - EAGLE: an eagle sweeps across the sky with a cry once the hiker passes the spot.
## - REINDEER: a few reindeer wander onto the path ahead and graze; wait and they move
##   on, barge through and the hiker stumbles (and they bolt).

enum Kind { FLOCK, EAGLE, REINDEER }
enum Phase { WAITING, ACTIVE, LEAVING, DONE }

signal bumped
## Reindeer: they've wandered onto the path (time to wait).
signal arrived

const BIRD_COLOR: Color = Color("#6B5A4A")
const EAGLE_COLOR: Color = Color("#4A3728")
const EAGLE_HEAD: Color = Color("#EFE6D2")
## How close the hiker gets before the moment starts (px, ahead of the hiker).
const FLOCK_TRIGGER: float = 210.0
const REINDEER_TRIGGER: float = 640.0
const REINDEER_GRAZE: float = 4.5
const HERD_HALF_WIDTH: float = 70.0

var kind: Kind = Kind.FLOCK
var phase: Phase = Phase.WAITING

var _hiker: Hiker
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _animals: Array[Node2D] = []
## Per animal: [velocity, wing pivot or legs array, phase offset].
var _motion: Array = []
var _age: float = 0.0
var _phase_time: float = 0.0


func setup(moment_kind: Kind, hiker: Hiker, seed_value: int) -> void:
	kind = moment_kind
	_hiker = hiker
	_rng.seed = seed_value
	match kind:
		Kind.FLOCK:
			_build_flock()
		Kind.REINDEER:
			_build_herd()


func _process(delta: float) -> void:
	if _hiker == null or phase == Phase.DONE:
		return
	_age += delta
	_phase_time += delta
	var ahead: float = global_position.x - _hiker.global_position.x
	match kind:
		Kind.FLOCK:
			_flock(delta, ahead)
		Kind.EAGLE:
			_eagle(delta, ahead)
		Kind.REINDEER:
			_herd(delta, ahead)


func _set_phase(p: Phase) -> void:
	phase = p
	_phase_time = 0.0


# --- Flock ---

func _build_flock() -> void:
	for i: int in _rng.randi_range(5, 7):
		var bird: Node2D = Node2D.new()
		bird.position = Vector2(_rng.randf_range(-60, 60), -3)
		bird.scale = Vector2.ONE * _rng.randf_range(0.42, 0.55) * Vector2(-1.0 if _rng.randf() < 0.5 else 1.0, 1.0)
		add_child(bird)
		var wings: Node2D = SubjectArt.bird(bird, BIRD_COLOR, Color(0, 0, 0, 0))
		wings.scale.y = 0.15
		_animals.append(bird)
		_motion.append([Vector2.ZERO, wings, _rng.randf() * TAU])


func _flock(delta: float, ahead: float) -> void:
	if phase == Phase.WAITING:
		# Pecking: little bobs of the head end.
		for i: int in _animals.size():
			_animals[i].rotation = sin(_age * 5.0 + _motion[i][2]) * 0.12
		if ahead < FLOCK_TRIGGER and ahead > -80.0:
			_set_phase(Phase.ACTIVE)
			AudioManager.play_flutter()
			for i: int in _animals.size():
				var away: float = 1.0 if _rng.randf() < 0.7 else -1.0
				_motion[i][0] = Vector2(away * _rng.randf_range(90, 190), -_rng.randf_range(170, 260))
				_animals[i].scale.x = absf(_animals[i].scale.x) * away
		return
	for i: int in _animals.size():
		var v: Vector2 = _motion[i][0]
		_motion[i][0] = Vector2(v.x, v.y + 60.0 * delta)
		_animals[i].position += v * delta
		_animals[i].rotation = lerpf(_animals[i].rotation, -0.25 * signf(_animals[i].scale.x), 4.0 * delta)
		(_motion[i][1] as Node2D).scale.y = 0.35 + 0.65 * absf(sin(_age * 22.0 + _motion[i][2]))
	modulate.a = clampf(1.0 - (_phase_time - 1.6) / 1.0, 0.0, 1.0)
	if _phase_time > 2.7:
		_set_phase(Phase.DONE)
		queue_free()


# --- Eagle ---

func _eagle(delta: float, ahead: float) -> void:
	if phase == Phase.WAITING:
		if ahead < 0.0:
			_set_phase(Phase.ACTIVE)
			var bird: Node2D = Node2D.new()
			bird.scale = Vector2(-2.3, 2.3)
			add_child(bird)
			var wings: Node2D = SubjectArt.bird(bird, EAGLE_COLOR, EAGLE_HEAD)
			_animals.append(bird)
			_motion.append([Vector2.ZERO, wings, 0.0])
			# From ahead and high, across the sky towards the trailhead.
			bird.global_position = _hiker.global_position + Vector2(900, -420)
			AudioManager.play_cry()
		return
	var eagle: Node2D = _animals[0]
	var t: float = _phase_time / 5.5
	eagle.global_position.x -= 330.0 * delta
	eagle.global_position.y += sin(t * PI * 2.0) * 22.0 * delta
	# Mostly gliding, with a few slow wingbeats.
	(_motion[0][1] as Node2D).scale.y = 0.55 + 0.45 * maxf(sin(_phase_time * 4.0), 0.0) * (1.0 if fmod(_phase_time, 2.4) < 0.8 else 0.0)
	if _phase_time > 5.5:
		_set_phase(Phase.DONE)
		queue_free()


# --- Reindeer ---

func _build_herd() -> void:
	for i: int in _rng.randi_range(2, 3):
		var deer: Node2D = Node2D.new()
		deer.position = Vector2(i * 46.0 - 40.0 + _rng.randf_range(-6, 6), 0)
		deer.scale = Vector2(-0.8, 0.8) * _rng.randf_range(0.9, 1.05)
		add_child(deer)
		_animals.append(deer)
		_motion.append([Vector2.ZERO, SubjectArt.reindeer(deer), _rng.randf() * TAU])
	modulate.a = 0.0


func _herd(delta: float, ahead: float) -> void:
	match phase:
		Phase.WAITING:
			if ahead < REINDEER_TRIGGER:
				_set_phase(Phase.ACTIVE)
				arrived.emit()
		Phase.ACTIVE:
			# Wander in from the hillside, then graze (heads down, a slow sway).
			modulate.a = minf(_phase_time / 0.8, 1.0)
			for i: int in _animals.size():
				_animals[i].rotation = sin(_age * 1.3 + _motion[i][2]) * 0.03
				_swing_legs(i, 0.0)
			if _phase_time > REINDEER_GRAZE:
				_set_phase(Phase.LEAVING)
			elif absf(ahead) < HERD_HALF_WIDTH and _hiker.is_on_floor() and _hiker.stumble():
				bumped.emit()
				_set_phase(Phase.LEAVING)
		Phase.LEAVING:
			# Off up the hillside and away from the path.
			for i: int in _animals.size():
				_animals[i].scale.x = absf(_animals[i].scale.x)
				_animals[i].position += Vector2(70.0, -16.0) * delta
				_swing_legs(i, _phase_time)
			modulate.a = maxf(1.0 - _phase_time / 1.6, 0.0)
			if _phase_time > 1.6:
				_set_phase(Phase.DONE)
				queue_free()


func _swing_legs(i: int, walking_time: float) -> void:
	var legs: Array = _motion[i][1]
	for l: int in legs.size():
		var pair: float = 1.0 if l == 0 or l == 3 else -1.0
		(legs[l] as Node2D).rotation = sin(walking_time * 9.0) * 0.4 * pair if walking_time > 0.0 else 0.0


## Blocks the path while the herd is grazing (for the "wait for them" hint).
func is_blocking() -> bool:
	return kind == Kind.REINDEER and phase == Phase.ACTIVE
