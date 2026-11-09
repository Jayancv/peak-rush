class_name Hiker
extends CharacterBody2D
## The player character. Gameplay reads only the walk/jump input actions;
## TouchControls turns touches into those actions on phones.
## States live in states/ and pick velocities; this script owns movement and the look.

signal state_changed(old_state: State, new_state: State)
signal jumped
signal landed
signal stumbled

enum State { IDLE, WALK, REST, JUMP, FALL, STUMBLE, EXHAUSTED, PHOTO }

const STAY: int = -1
## Hikers always walk towards the summit (to the right).
const FACING: float = 1.0
## Reading slide collisions allocates, so the surface underfoot is sampled, not read every tick.
const SURFACE_CHECK_SECONDS: float = 0.1

@export var balance: Balance
@export var visual: HikerVisual
## Off for decorative hikers (e.g. resting on the main menu) so keys don't walk them away.
@export var input_enabled: bool = true

## Outside slowdowns (exhaustion, dusk, mud in M2) multiply walk speed here.
var speed_multiplier: float = 1.0
var signed_grade: float = 0.0
var surface: TerrainStrip.Surface = TerrainStrip.Surface.DIRT
var state: State = State.IDLE
var state_time: float = 0.0

var _slope: Slope
var _states: Array[HikerState] = []
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _jump_was_down: bool = false
var _was_on_floor: bool = false
var _surface_check_left: float = 0.0


func _ready() -> void:
	if balance == null:
		balance = ContentDB.balance
	_slope = Slope.new(balance)
	floor_max_angle = deg_to_rad(balance.max_floor_angle_deg)
	floor_snap_length = balance.floor_snap_px
	# Speed along a slope is decided by Slope, not by how steep the collision is.
	floor_constant_speed = true
	floor_stop_on_slope = true
	floor_block_on_wall = true
	# Order must match the State enum.
	_states = [
		HikerIdleState.new(self),
		HikerWalkState.new(self),
		HikerRestState.new(self),
		HikerJumpState.new(self),
		HikerFallState.new(self),
		HikerStumbleState.new(self),
		HikerExhaustedState.new(self),
		HikerPhotoState.new(self),
	]
	_states[state].enter()
	if visual != null:
		visual.setup(balance)


func _physics_process(delta: float) -> void:
	state_time += delta
	_update_jump_input(delta)
	_coyote_left = balance.coyote_seconds if is_on_floor() else maxf(_coyote_left - delta, 0.0)
	var next: int = _states[state].physics_update(delta)
	if next != STAY:
		change_state(next as State)
	move_and_slide()
	_update_floor_info(delta)


func _process(delta: float) -> void:
	if visual != null:
		visual.update_pose(delta, self)


# --- Public API (called by obstacles, systems and the HUD) ---

func change_state(new_state: State) -> void:
	var old_state: State = state
	_states[old_state].exit()
	state = new_state
	state_time = 0.0
	_states[new_state].enter()
	state_changed.emit(old_state, new_state)


## Trip on a root. Only possible with both feet on the ground.
func stumble() -> bool:
	if not _is_on_foot():
		return false
	change_state(State.STUMBLE)
	stumbled.emit()
	return true


func exhaust() -> void:
	if state != State.EXHAUSTED and state != State.PHOTO:
		change_state(State.EXHAUSTED)


func enter_photo() -> bool:
	if not _is_on_foot():
		return false
	change_state(State.PHOTO)
	return true


func exit_photo() -> void:
	if state == State.PHOTO:
		change_state(State.IDLE)


## Moves the hiker instantly (spawn, respawn) without smoothing in between.
func teleport(to: Vector2) -> void:
	global_position = to
	velocity = Vector2.ZERO
	reset_physics_interpolation()


# --- Movement helpers for states ---

func wants_walk() -> bool:
	return input_enabled and Input.is_action_pressed("walk")


func has_buffered_jump() -> bool:
	return _jump_buffer_left > 0.0


## Shared exits from the on-foot states: jumping, or walking off an edge.
func grounded_transition() -> int:
	if has_buffered_jump() and _coyote_left > 0.0:
		return State.JUMP
	if not is_on_floor() and _coyote_left <= 0.0:
		return State.FALL
	return STAY


func walk_target_speed() -> float:
	return balance.walk_speed * _slope.speed_factor(signed_grade) * speed_multiplier * FACING


func move_horizontal(target: float, accel: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, target, accel * delta)


func stop_horizontal(decel: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, decel * delta)


func air_control(delta: float) -> void:
	if wants_walk():
		move_horizontal(balance.walk_speed * speed_multiplier * FACING, balance.air_accel, delta)
	else:
		stop_horizontal(balance.air_decel, delta)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + balance.gravity * delta, balance.max_fall_speed)


func start_jump() -> void:
	velocity.y = -balance.jump_velocity
	_jump_buffer_left = 0.0
	_coyote_left = 0.0
	if visual != null:
		visual.squash(balance.jump_stretch)
	jumped.emit()


# --- Internals ---

func _is_on_foot() -> bool:
	return is_on_floor() and (state == State.IDLE or state == State.WALK or state == State.REST)


func _update_jump_input(delta: float) -> void:
	# Touch presses arrive via Input.action_press, which can land between physics
	# ticks; checking the held edge too means a quick tap is never lost.
	var down: bool = input_enabled and Input.is_action_pressed("jump")
	if (input_enabled and Input.is_action_just_pressed("jump")) or (down and not _jump_was_down):
		_jump_buffer_left = balance.jump_buffer_seconds
	else:
		_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	_jump_was_down = down


func _update_floor_info(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	if on_floor:
		signed_grade = Slope.signed_grade(get_floor_normal(), FACING)
		_surface_check_left -= delta
		if _surface_check_left <= 0.0 or not _was_on_floor:
			_surface_check_left = SURFACE_CHECK_SECONDS
			_read_surface()
	else:
		signed_grade = 0.0
	if on_floor and not _was_on_floor:
		if visual != null:
			visual.squash(balance.land_squash)
		landed.emit()
	_was_on_floor = on_floor


func _read_surface() -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_normal().y < -0.5:
			surface = TerrainStrip.surface_of(collision.get_collider())
			return
