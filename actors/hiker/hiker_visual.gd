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
const SLIDE_CROUCH: float = 7.0
## Ducking squashes the body towards the feet by this much; hurrying adds this lean.
const CROUCH_SQUASH: float = 0.32
const HURRY_LEAN: float = 0.14
const SLIDE_SPRAY_SECONDS: float = 0.07
const CELEBRATE_SECONDS: float = 1.6
const CELEBRATE_HOP_PX: float = 9.0
const CELEBRATE_HOP_HZ: float = 2.4

## A real footstep landed (not the silent second puff of a landing).
signal stepped(surface: TerrainStrip.Surface)

var _balance: Balance
var _mug: Node2D
var _was_sliding: bool = false
## 0 standing .. 1 ducked (eased, so ducking doesn't snap).
var _crouch: float = 0.0
var _spray_left: float = 0.0
var _mug_angle: float = 0.0
var _mug_spin: float = 0.0
var _prev_vx: float = 0.0
var _last_step: int = 0
var _next_dust: int = 0
var _was_on_floor: bool = true
var _celebrate_left: float = 0.0
var _squash: Vector2 = Vector2.ONE
var _phase: float = 0.0
var _time: float = 0.0


## Outfit pieces per CosmeticData.Slot: [node path, shade]. Shade < 0 darkens the
## slot colour, > 0 lightens it (sleeves sit in shadow, the pom catches light...).
const LOOK_PARTS: Dictionary = {
	CosmeticData.Slot.HAT: [["Beanie", 0.0], ["Pom", 0.3]],
	CosmeticData.Slot.JACKET: [["Torso", 0.0], ["Arm/Sleeve", -0.16]],
	CosmeticData.Slot.PACK: [["Backpack", 0.0], ["Pocket", -0.14], ["Strap", -0.2]],
	CosmeticData.Slot.PANTS: [["FrontLeg/Leg", 0.0], ["BackLeg/Leg", -0.25]],
	CosmeticData.Slot.SKIN: [["Head", 0.0], ["Arm/Hand", 0.0]],
}


func _ready() -> void:
	apply_look(GameState.look_colors())
	_build_mug()


## A steel camping mug clipped to the bottom of the pack; it swings on a spring.
func _build_mug() -> void:
	var pack: Node = get_node_or_null("Backpack")
	if pack == null:
		return
	_mug = Node2D.new()
	_mug.name = "Mug"
	_mug.position = Vector2(-20, -33)
	add_child(_mug)
	move_child(_mug, pack.get_index() + 1)
	var cord: Line2D = Line2D.new()
	cord.points = PackedVector2Array([Vector2.ZERO, Vector2(0, 3.5)])
	cord.width = 1.0
	cord.default_color = Color("#2B2D42")
	_mug.add_child(cord)
	var cup: Polygon2D = Polygon2D.new()
	cup.polygon = PackedVector2Array([Vector2(-3, 3.5), Vector2(3, 3.5), Vector2(2.6, 9.5), Vector2(-2.6, 9.5)])
	cup.vertex_colors = PackedColorArray([Color("#C9D0D8"), Color("#8E99A6"), Color("#6E7887"), Color("#B2BAC4")])
	cup.antialiased = true
	_mug.add_child(cup)
	var handle: Line2D = Line2D.new()
	handle.points = PackedVector2Array([Vector2(3, 4.5), Vector2(4.6, 5.5), Vector2(4.6, 7.5), Vector2(2.8, 8.4)])
	handle.width = 1.0
	handle.default_color = Color("#8E99A6")
	_mug.add_child(handle)


## Spring-damper swing: the mug lags behind the hiker's acceleration and jolts on landings.
func _update_mug(delta: float, hiker: Hiker, walking: bool) -> void:
	if _mug == null or delta <= 0.0:
		return
	var accel: float = (hiker.velocity.x - _prev_vx) / delta
	_prev_vx = hiker.velocity.x
	var target: float = clampf(accel * _balance.mug_swing_per_accel, -1.0, 1.0)
	if walking:
		target += sin(_phase * 2.0) * 0.18
	_mug_spin += (-_balance.mug_stiffness * (_mug_angle - target) - _balance.mug_damping * _mug_spin) * delta
	_mug_angle = clampf(_mug_angle + _mug_spin * delta, -1.3, 1.3)
	# Counter the body's lean so the mug keeps hanging downwards.
	_mug.rotation = _mug_angle - rotation


## Paints the outfit: CosmeticData.Slot -> Color (slots left out keep their colour).
func apply_look(colors: Dictionary) -> void:
	for slot: Variant in colors:
		var base: Color = colors[slot]
		for part: Array in LOOK_PARTS.get(int(slot), []):
			var poly: Polygon2D = get_node_or_null(NodePath(part[0])) as Polygon2D
			if poly == null:
				continue
			var shade: float = float(part[1])
			poly.color = base.lightened(shade) if shade > 0.0 else base.darkened(-shade)


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
	var on_floor_now: bool = hiker.is_on_floor()
	if _was_sliding and hiker.state != Hiker.State.SLIDE:
		# A powder burst where the slide ends.
		for i: int in 3:
			_footstep(TerrainStrip.Surface.SNOW, false)
	_was_sliding = hiker.state == Hiker.State.SLIDE
	match hiker.state:
		Hiker.State.WALK:
			var speed_ratio: float = clampf(absf(hiker.velocity.x) / _balance.walk_speed, 0.0, 1.7)
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
			# Lean into climbs, sit back on descents; hurrying leans further forward.
			lean = clampf(hiker.signed_grade, -0.6, 0.8) * _balance.slope_lean + (HURRY_LEAN if hiker.actions.hurrying else 0.0)
			if hiker.actions.crouching:
				front *= 0.5
				back *= 0.5
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
		Hiker.State.SLIDE:
			# Crouched, arms out for balance, snow spraying from the boots.
			front = -0.7
			back = 0.55
			arm_angle = -1.4
			lean = -0.18
			bob = SLIDE_CROUCH
			_spray_left -= delta
			if _spray_left <= 0.0 and on_floor_now:
				_spray_left = SLIDE_SPRAY_SECONDS
				_footstep(TerrainStrip.Surface.SNOW, false)
		Hiker.State.CLIMB:
			# Hand over hand: arms reach up in turn, knees come up under the body.
			_phase += delta * TAU * 1.6 * clampf(-hiker.velocity.y / maxf(_balance.climb_speed, 1.0), 0.0, 1.0)
			arm_angle = -2.5 + sin(_phase) * 0.35
			front = -0.9 + sin(_phase) * 0.5
			back = -0.2 - sin(_phase) * 0.5
			lean = -0.06
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
		_mug_spin += 6.0
	_was_on_floor = on_floor
	_update_mug(delta, hiker, hiker.state == Hiker.State.WALK)

	if hiker.state != Hiker.State.WALK:
		# Let the stride settle back to standing instead of freezing mid-step.
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, blend)
	front_leg.rotation = lerp_angle(front_leg.rotation, front, blend)
	back_leg.rotation = lerp_angle(back_leg.rotation, back, blend)
	arm.rotation = lerp_angle(arm.rotation, arm_angle, blend)
	# Mirrored when walking back down the trail; lean follows the way it faces.
	rotation = lerp_angle(rotation, lean * hiker.facing, blend)
	_crouch = lerpf(_crouch, 1.0 if hiker.actions.crouching else 0.0, blend)
	scale = Vector2(_squash.x * hiker.facing, _squash.y * (1.0 + breath) * (1.0 - CROUCH_SQUASH * _crouch))
	# Ease the height too, so sitting down and standing up don't snap.
	position.y = bob if hiker.state == Hiker.State.WALK else lerpf(position.y, bob, blend)


func _footstep(surface: TerrainStrip.Surface, with_sound: bool = true) -> void:
	if with_sound:
		AudioManager.play_footstep(surface)
		stepped.emit(surface)
	if dust.is_empty():
		return
	var puff: CPUParticles2D = dust[_next_dust]
	_next_dust = (_next_dust + 1) % dust.size()
	puff.color = DUST_COLORS[clampi(surface, 0, DUST_COLORS.size() - 1)]
	puff.restart()
