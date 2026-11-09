class_name HikerVisual
extends Node2D
## The hiker's look: a procedural walk cycle, poses per state, squash/stretch and
## breathing. Pure presentation; Hiker calls update_pose() every frame and
## squash() on jump/land. The origin is at the feet so scaling keeps them planted.

@export var front_leg: Node2D
@export var back_leg: Node2D
@export var arm: Node2D

var _balance: Balance
var _squash: Vector2 = Vector2.ONE
var _phase: float = 0.0
var _time: float = 0.0


func setup(balance: Balance) -> void:
	_balance = balance


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
		Hiker.State.REST, Hiker.State.IDLE, Hiker.State.PHOTO:
			breath = sin(_time * TAU * _balance.rest_breath_hz) * _balance.rest_breath_amount

	if hiker.state != Hiker.State.WALK:
		# Let the stride settle back to standing instead of freezing mid-step.
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, blend)
	front_leg.rotation = lerp_angle(front_leg.rotation, front, blend)
	back_leg.rotation = lerp_angle(back_leg.rotation, back, blend)
	arm.rotation = lerp_angle(arm.rotation, arm_angle, blend)
	rotation = lerp_angle(rotation, lean, blend)
	scale = Vector2(_squash.x, _squash.y * (1.0 + breath))
	position.y = bob
