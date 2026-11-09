class_name HikerVisual
extends Node2D
## The hiker's look: a procedural walk cycle, poses per state, squash/stretch and
## breathing. Pure presentation; Hiker calls update_pose() every frame and
## squash() on jump/land. The origin is at the feet so scaling keeps them planted.
## Also does the feel: a footstep sound and dust puff each step (by surface), puffs
## on landing, and the summit celebration.

@export var front_leg: Node2D
@export var back_leg: Node2D
@export var arm: Node2D
## Light cone shown at dusk.
@export var headlamp: Node2D
## Green sparkles while recovering: a trickle when resting, a stream at a bench.
@export var regen_particles: CPUParticles2D
## Two one-shot puff emitters used alternately (one per foot), so a new step's puff
## doesn't cut the previous one short.
@export var dust: Array[CPUParticles2D] = []
@export var confetti: CPUParticles2D

## Sitting on a bench: hips drop onto the seat, legs stick out, pole rests on the knee.
const SIT_DROP: float = 6.0
const SIT_FRONT_LEG: float = -1.35
const SIT_BACK_LEG: float = -1.15
const SIT_ARM: float = 0.35
## Sparkle counts. Changing `amount` restarts the emitter, so it only changes with the mode.
const REST_SPARKLES: int = 6
const BENCH_SPARKLES: int = 14
const BENCH_SPARKLE_SPEED: float = 1.5
const REST_SPARKLE_COLOR: Color = Color(0.7, 1.0, 0.65, 0.85)
const BENCH_SPARKLE_COLOR: Color = Color(0.45, 1.0, 0.4, 1.0)

## Dust colour per TerrainStrip.Surface.
const DUST_COLORS: Array[Color] = [Color("#C9B28F"), Color("#B5B3AA"), Color("#6E5440"), Color("#E6F5FA"), Color("#FFFFFF")]
const CELEBRATE_SECONDS: float = 1.6
const CELEBRATE_HOP_PX: float = 9.0
const CELEBRATE_HOP_HZ: float = 2.4

var _balance: Balance
var _last_step: int = 0
var _next_dust: int = 0
var _was_on_floor: bool = true
var _celebrate_left: float = 0.0
var _squash: Vector2 = Vector2.ONE
var _phase: float = 0.0
var _time: float = 0.0


func setup(balance: Balance) -> void:
	_balance = balance


func set_headlamp(on: bool) -> void:
	if headlamp != null:
		headlamp.visible = on


func set_regen(mode: HikerCondition.Regen) -> void:
	if regen_particles == null:
		return
	regen_particles.emitting = mode != HikerCondition.Regen.NONE
	var bench: bool = mode == HikerCondition.Regen.BENCH
	var amount: int = BENCH_SPARKLES if bench else REST_SPARKLES
	if regen_particles.amount != amount:
		regen_particles.amount = amount
	regen_particles.speed_scale = BENCH_SPARKLE_SPEED if bench else 1.0
	regen_particles.color = BENCH_SPARKLE_COLOR if bench else REST_SPARKLE_COLOR


## Arms up, little hops and confetti at the summit.
func celebrate() -> void:
	_celebrate_left = CELEBRATE_SECONDS
	if confetti != null:
		confetti.restart()
	AudioManager.play_summit()


func squash(amount: Vector2) -> void:
	_squash = amount


func update_pose(delta: float, hiker: Hiker) -> void:
	if _balance == null:
		return
	_time += delta
	var blend: float = 1.0 - exp(-_balance.pose_blend_rate * delta)
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-_balance.squash_recover_rate * delta))

	# Targets in radians. Limbs hang down, so a negative angle swings them forward.
	var front: float = 0.0
	var back: float = 0.0
	var arm_angle: float = -0.15
	var lean: float = 0.0
	var bob: float = 0.0
	var breath: float = 0.0
	match hiker.state:
		Hiker.State.WALK:
			var speed_ratio: float = clampf(absf(hiker.velocity.x) / _balance.walk_speed, 0.0, 1.3)
			_phase += delta * TAU * _balance.walk_bob_hz * 0.5 * speed_ratio
			var step: int = floori(_phase / PI)
			if step != _last_step and hiker.is_on_floor():
				_footstep(hiker.effective_surface())
			_last_step = step
			var swing: float = sin(_phase)
			front = -swing * _balance.walk_leg_swing
			back = swing * _balance.walk_leg_swing
			arm_angle = swing * _balance.walk_arm_swing - 0.1
			bob = -absf(cos(_phase)) * _balance.walk_bob_px
			# Lean into climbs, sit back on descents.
			lean = clampf(hiker.signed_grade, -0.6, 0.8) * _balance.slope_lean
		Hiker.State.JUMP:
			front = -0.8
			back = 0.45
			arm_angle = -1.0
		Hiker.State.FALL:
			front = -0.35
			back = 0.25
			arm_angle = -0.6
		Hiker.State.STUMBLE:
			front = 0.3
			back = -0.2
			arm_angle = -1.2
			lean = _balance.stumble_lean
		Hiker.State.EXHAUSTED:
			arm_angle = 0.2
			lean = _balance.exhausted_lean
			breath = sin(_time * TAU * _balance.rest_breath_hz * 2.5) * _balance.rest_breath_amount * 1.6
		Hiker.State.REST when hiker.condition.is_on_bench():
			front = SIT_FRONT_LEG
			back = SIT_BACK_LEG
			arm_angle = SIT_ARM
			bob = SIT_DROP
			breath = sin(_time * TAU * _balance.rest_breath_hz) * _balance.rest_breath_amount
		Hiker.State.REST, Hiker.State.IDLE, Hiker.State.PHOTO:
			breath = sin(_time * TAU * _balance.rest_breath_hz) * _balance.rest_breath_amount

	if _celebrate_left > 0.0:
		_celebrate_left -= delta
		arm_angle = -2.8
		front = 0.0
		back = 0.0
		bob = -absf(sin(_time * TAU * CELEBRATE_HOP_HZ)) * CELEBRATE_HOP_PX
	var on_floor: bool = hiker.is_on_floor()
	if on_floor and not _was_on_floor:
		_footstep(hiker.effective_surface())
		_footstep(hiker.effective_surface(), false)
	_was_on_floor = on_floor

	if hiker.state != Hiker.State.WALK:
		# Let the stride settle back to standing instead of freezing mid-step.
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, blend)
	front_leg.rotation = lerp_angle(front_leg.rotation, front, blend)
	back_leg.rotation = lerp_angle(back_leg.rotation, back, blend)
	arm.rotation = lerp_angle(arm.rotation, arm_angle, blend)
	rotation = lerp_angle(rotation, lean, blend)
	scale = Vector2(_squash.x, _squash.y * (1.0 + breath))
	# Ease the height too, so sitting down and standing up don't snap.
	position.y = bob if hiker.state == Hiker.State.WALK else lerpf(position.y, bob, blend)


func _footstep(surface: TerrainStrip.Surface, with_sound: bool = true) -> void:
	if with_sound:
		AudioManager.play_footstep(surface)
	if dust.is_empty():
		return
	var puff: CPUParticles2D = dust[_next_dust]
	_next_dust = (_next_dust + 1) % dust.size()
	puff.color = DUST_COLORS[clampi(surface, 0, DUST_COLORS.size() - 1)]
	puff.restart()
