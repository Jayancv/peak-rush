class_name Hiker
extends CharacterBody2D
## The player character. Gameplay reads only the walk/jump input actions;
## TouchControls turns touches into those actions on phones.
## States live in states/ and pick velocities; HikerCondition tracks stamina and
## effects; HikerVisual draws it. Obstacles call the public API below, and the
## hiker reports back up with signals (the trail runner and HUD listen).

signal state_changed(old_state: State, new_state: State)
signal stamina_changed(value: float, max_value: float)
signal exhausted
signal stumbled
signal fell
signal reached_finish
signal checkpoint_reached(respawn_position: Vector2)
signal regen_changed(mode: HikerCondition.Regen)
signal jumped
signal landed

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

var condition: HikerCondition
## Everything that scales walk speed (slope, surface, dusk, tiredness), refreshed every tick.
var speed_multiplier: float = 1.0
var signed_grade: float = 0.0
var surface: TerrainStrip.Surface = TerrainStrip.Surface.DIRT
var state: State = State.IDLE
var state_time: float = 0.0
var finished: bool = false

var _states: Array[HikerState] = []
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _jump_was_down: bool = false
var _was_on_floor: bool = false
var _surface_check_left: float = 0.0
## Physics ticks since spawn; input is ignored on the first one.
var _ticks: int = 0


func _ready() -> void:
	if balance == null:
		balance = ContentDB.balance
	condition = HikerCondition.new(balance)
	condition.stamina.changed.connect(func(v: float, m: float) -> void: stamina_changed.emit(v, m))
	condition.stamina.exhausted.connect(_on_stamina_exhausted)
	condition.regen_changed.connect(_on_regen_changed)
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
	speed_multiplier = condition.speed_multiplier(signed_grade, surface)
	var next: int = _states[state].physics_update(delta)
	if next != STAY:
		change_state(next as State)
	move_and_slide()
	_update_floor_info(delta)
	var walking: bool = state == State.WALK and is_on_floor() and absf(velocity.x) > 1.0
	# No regen during the forced exhausted rest: running dry has to cost the slow walk afterwards.
	var resting: bool = state == State.IDLE or state == State.REST
	condition.tick(delta, walking, resting and is_on_floor(), signed_grade, surface)


func _process(delta: float) -> void:
	if visual != null:
		visual.update_pose(delta, self)


# --- Public API (called by obstacles, interactables and the trail runner) ---

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
	condition.stamina.spend(balance.stumble_cost)
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


## Fell into a gap. The trail runner decides where to put the hiker back.
func fall_out() -> void:
	if not finished:
		fell.emit()


func respawn(at: Vector2) -> void:
	teleport(at)
	condition.clear_location_effects()
	condition.stamina.spend(balance.fall_cost)
	if state != State.EXHAUSTED:
		change_state(State.IDLE)


func touch_checkpoint(respawn_position: Vector2) -> void:
	checkpoint_reached.emit(respawn_position)


func reach_finish() -> void:
	if finished:
		return
	finished = true
	reached_finish.emit()


func set_dusk(on: bool) -> void:
	condition.is_dusk = on
	if visual != null:
		visual.set_headlamp(on)


## Moves the hiker instantly (spawn, respawn) without smoothing in between.
func teleport(to: Vector2) -> void:
	global_position = to
	velocity = Vector2.ZERO
	reset_physics_interpolation()


func effective_surface() -> TerrainStrip.Surface:
	return condition.effective_surface(surface)


# --- Movement helpers for states ---

func wants_walk() -> bool:
	return input_enabled and not finished and Input.is_action_pressed("walk")


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
	return balance.walk_speed * speed_multiplier * FACING


func move_horizontal(target: float, accel: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, target, accel * delta)


func stop_horizontal(decel: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, decel * delta)


## Standing still: stops quickly on grip, slides on ice (and back down uphill ice).
func ground_stop(decel: float, delta: float) -> void:
	if is_on_floor() and HikeModifiers.is_slippery(effective_surface()):
		var slide: float = -balance.ice_slip_speed * FACING if signed_grade > 0.05 else 0.0
		move_horizontal(slide, balance.ice_decel, delta)
	else:
		stop_horizontal(decel, delta)


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

func _on_regen_changed(mode: HikerCondition.Regen) -> void:
	if visual != null:
		visual.set_regen(mode)
	regen_changed.emit(mode)


func _on_stamina_exhausted() -> void:
	exhausted.emit()
	exhaust()


func _is_on_foot() -> bool:
	return is_on_floor() and (state == State.IDLE or state == State.WALK or state == State.REST)


func _update_jump_input(delta: float) -> void:
	_ticks += 1
	if _ticks == 1:
		# A tap from the previous screen still reads as "just pressed" on the first
		# tick; don't let it make a freshly spawned hiker jump.
		_jump_was_down = Input.is_action_pressed("jump")
		return
	# Touch presses arrive via Input.action_press, which can land between physics
	# ticks; checking the held edge too means a quick tap is never lost.
	var allowed: bool = input_enabled and not finished
	var down: bool = allowed and Input.is_action_pressed("jump")
	if (allowed and Input.is_action_just_pressed("jump")) or (down and not _jump_was_down):
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
