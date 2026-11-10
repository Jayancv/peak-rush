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
signal water_changed(value: float, max_value: float)
signal thirst_changed(thirsty: bool)
## Tried to walk back past the last checkpoint.
signal back_blocked
signal landed

enum State { IDLE, WALK, REST, JUMP, FALL, STUMBLE, EXHAUSTED, PHOTO, SLIDE }

const STAY: int = -1
## How close to the back limit the hiker stops (px).
const BACK_MARGIN: float = 6.0
## Reading slide collisions allocates, so the surface underfoot is sampled, not read every tick.
const SURFACE_CHECK_SECONDS: float = 0.1

@export var balance: Balance
@export var visual: HikerVisual
## Off for decorative hikers (e.g. resting on the main menu) so keys don't walk them away.
@export var input_enabled: bool = true

var condition: HikerCondition
## Speed carried from descents (systems/momentum.gd).
var momentum: Momentum
## Everything that scales walk speed (slope, surface, dusk, tiredness), refreshed every tick.
var speed_multiplier: float = 1.0
var signed_grade: float = 0.0
var surface: TerrainStrip.Surface = TerrainStrip.Surface.DIRT
var state: State = State.IDLE
var state_time: float = 0.0
var finished: bool = false
## +1 heading for the summit, -1 walking back down the trail.
var facing: float = 1.0
## Walking back stops here (the last checkpoint, or the trailhead).
var back_limit_x: float = -INF

var _states: Array[HikerState] = []
var _coyote_left: float = 0.0
var _input: HikerInput = HikerInput.new()
var _was_on_floor: bool = false
var _surface_check_left: float = 0.0
var _slide_zones: int = 0


func _ready() -> void:
	if balance == null:
		balance = ContentDB.balance
	condition = HikerCondition.new(balance)
	momentum = Momentum.new(balance)
	condition.stamina.changed.connect(func(v: float, m: float) -> void: stamina_changed.emit(v, m))
	condition.stamina.exhausted.connect(_on_stamina_exhausted)
	condition.regen_changed.connect(_on_regen_changed)
	condition.hydration.changed.connect(func(v: float, m: float) -> void: water_changed.emit(v, m))
	condition.hydration.thirst_changed.connect(func(t: bool) -> void: thirst_changed.emit(t))
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
		HikerSlideState.new(self),
	]
	_states[state].enter()
	if visual != null:
		visual.setup(balance)


func _physics_process(delta: float) -> void:
	state_time += delta
	_input.update(delta, input_enabled and not finished, balance.jump_buffer_seconds)
	_coyote_left = balance.coyote_seconds if is_on_floor() else maxf(_coyote_left - delta, 0.0)
	_update_facing()
	speed_multiplier = condition.speed_multiplier(signed_grade, surface)
	var next: int = _states[state].physics_update(delta)
	if next != STAY:
		change_state(next as State)
	move_and_slide()
	_update_floor_info(delta)
	momentum.update(delta, signed_grade, state == State.WALK and wants_walk(), is_on_floor(),
		condition.modifiers.surface_speed(effective_surface()))
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
	momentum.reset()
	_slide_zones = 0
	facing = 1.0
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


## SnowSlide zones call these; the hiker slides while inside one on a steep descent.
func enter_slide_zone() -> void:
	_slide_zones += 1


func exit_slide_zone() -> void:
	_slide_zones = maxi(_slide_zones - 1, 0)


func in_slide_zone() -> bool:
	return _slide_zones > 0


func can_slide() -> bool:
	# Slides only run towards the summit.
	return facing > 0.0 and in_slide_zone() and is_on_floor() and signed_grade <= -balance.slide_min_grade


func effective_surface() -> TerrainStrip.Surface:
	return condition.effective_surface(surface)


# --- Movement helpers for states ---

## Wants to move either way: on to the summit, or back towards the last checkpoint.
func wants_walk() -> bool:
	var allowed: bool = input_enabled and not finished
	return _input.wants_walk(allowed) or (_input.wants_back(allowed) and can_go_back())


func can_go_back() -> bool:
	# Leave room to brake, so the hiker comes to rest at the limit rather than past it.
	var braking: float = velocity.x * velocity.x / (2.0 * balance.walk_decel) if velocity.x < 0.0 else 0.0
	return global_position.x - braking > back_limit_x + BACK_MARGIN


func has_buffered_jump() -> bool:
	return _input.jump_buffer_left > 0.0


func walk_target_speed() -> float:
	return (balance.walk_speed * speed_multiplier + momentum.bonus) * facing + condition.wind_push


## Grace time left to jump after walking off an edge.
func coyote_left() -> float:
	return _coyote_left


func start_jump() -> void:
	velocity.y = -balance.jump_velocity
	_input.jump_buffer_left = 0.0
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


## Turning around sheds momentum.
func _update_facing() -> void:
	var new_facing: float = _input.choose_facing(input_enabled and not finished, facing, can_go_back())
	if _input.back_just_blocked:
		back_blocked.emit()
	if new_facing != facing:
		facing = new_facing
		momentum.reset()


func _update_floor_info(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	if on_floor:
		signed_grade = Slope.signed_grade(get_floor_normal(), facing)
		# The floor normal wobbles a hair even on level ground; call that flat.
		if absf(signed_grade) < Momentum.FLAT_GRADE:
			signed_grade = 0.0
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
