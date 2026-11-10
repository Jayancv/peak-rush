@tool
class_name RollingBoulder
extends Node2D
## A boulder resting up a slope. When the hiker walks into the trigger zone (from
## `trigger_from` to the boulder), it breaks loose and rolls down the real terrain.
## If it hits the hiker while they're on their feet they stumble; jumping over it is
## the way past. It fades out after a while and re-arms at its start.

@export var radius: float = 15.0:
	set(v):
		radius = v
		_rebuild()
## Left edge of the trigger zone, relative to the boulder (negative = before it).
@export var trigger_from: float = -420.0:
	set(v):
		trigger_from = v
		_rebuild()
## Starting push down the slope (px/s, towards the trailhead).
@export var push: float = 60.0
## Top rolling speed (px/s); linear damping holds it near this.
@export var max_speed: float = 230.0
@export var lifetime: float = 7.0

## Boulders hit the ground (layer 1) only; the hiker is sensed with an Area2D.
const BOULDER_LAYER: int = 1 << 6
const ROCK: Color = Color("#8C8B84")
const ROCK_DARK: Color = Color("#5E5D57")
const ROCK_LIGHT: Color = Color("#B9B6AC")

var _body: RigidBody2D
var _trigger: Area2D
var _dust: CPUParticles2D
var _armed: bool = true
var _rolling_for: float = 0.0
var _ready_done: bool = false


func _ready() -> void:
	_ready_done = true
	_rebuild()


func _rebuild() -> void:
	if not _ready_done:
		return
	ShapeUtil.clear_internal(self)
	_body = RigidBody2D.new()
	_body.collision_layer = BOULDER_LAYER
	_body.collision_mask = 1
	_body.mass = 40.0
	_body.freeze = true
	_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.friction = 1.0
	mat.rough = true
	mat.bounce = 0.15
	_body.physics_material_override = mat
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	_body.add_child(shape)
	_body.add_child(_boulder_art())
	add_child(_body, false, Node.INTERNAL_MODE_BACK)
	_body.position = Vector2(0, -radius)
	if Engine.is_editor_hint():
		return
	_trigger = Area2D.new()
	_trigger.collision_layer = 0
	_trigger.collision_mask = HikerArea.HIKER_LAYER
	_trigger.monitorable = false
	add_child(_trigger, false, Node.INTERNAL_MODE_BACK)
	ShapeUtil.add_rect_shape(_trigger, Rect2(trigger_from, -260.0, -trigger_from, 320.0))
	_trigger.body_entered.connect(_on_trigger)
	var hit: Area2D = Area2D.new()
	hit.collision_layer = 0
	hit.collision_mask = HikerArea.HIKER_LAYER
	hit.monitorable = false
	_body.add_child(hit)
	ShapeUtil.add_rect_shape(hit, Rect2(-radius * 0.8, -radius * 0.8, radius * 1.6, radius * 1.6))
	hit.body_entered.connect(_on_hit)
	_dust = CPUParticles2D.new()
	_dust.emitting = false
	_dust.amount = 10
	_dust.lifetime = 0.6
	_dust.direction = Vector2(0.3, -1)
	_dust.spread = 40.0
	_dust.initial_velocity_min = 20.0
	_dust.initial_velocity_max = 50.0
	_dust.gravity = Vector2(0, 60)
	_dust.scale_amount_min = 2.0
	_dust.scale_amount_max = 4.0
	_dust.color = Color(0.79, 0.7, 0.56, 0.6)
	add_child(_dust, false, Node.INTERNAL_MODE_BACK)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _body == null or _armed:
		return
	_rolling_for += delta
	# Hold a believable top speed on long slopes.
	_body.linear_damp = 2.5 if _body.linear_velocity.length() > max_speed else 0.0
	_dust.position = _body.position + Vector2(0, radius)
	_dust.emitting = _body.linear_velocity.length() > 40.0
	if _rolling_for > lifetime:
		_rearm()


func _on_trigger(body: Node2D) -> void:
	if _armed and body is Hiker:
		_armed = false
		# Physics callbacks can't change bodies mid-step, so release it right after.
		_release.call_deferred()


func _release() -> void:
	_rolling_for = 0.0
	_body.freeze = false
	_body.linear_velocity = Vector2(-push, 0)
	_body.angular_velocity = -push / radius
	AudioManager.play_thud()


func _on_hit(body: Node2D) -> void:
	var hiker: Hiker = body as Hiker
	if hiker != null and not _armed:
		hiker.stumble()


func _rearm() -> void:
	var fade: Tween = create_tween()
	fade.tween_property(_body, "modulate:a", 0.0, 0.4)
	fade.tween_callback(func() -> void:
		_body.freeze = true
		_body.linear_velocity = Vector2.ZERO
		_body.angular_velocity = 0.0
		_body.position = Vector2(0, -radius)
		_body.rotation = 0.0
		_body.reset_physics_interpolation()
		_dust.emitting = false
		_armed = true)
	fade.tween_property(_body, "modulate:a", 1.0, 0.4)


## A lumpy round rock with a darker underside, a highlight and a crack, so its
## rolling is easy to see.
func _boulder_art() -> Node2D:
	var art: Node2D = Node2D.new()
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	for i: int in 18:
		var a: float = TAU * float(i) / 18.0
		var r: float = radius * (1.0 + 0.08 * sin(a * 3.0) + 0.05 * cos(a * 5.0))
		pts.append(Vector2(cos(a), sin(a)) * r)
		cols.append(ROCK_LIGHT.lerp(ROCK_DARK, 0.5 + 0.5 * sin(a)))
	var body_poly: Polygon2D = ShapeUtil.add_poly(art, pts, ROCK)
	body_poly.vertex_colors = cols
	ShapeUtil.add_poly(art, ShapeUtil.ellipse(Vector2(-radius * 0.35, -radius * 0.4), Vector2(radius * 0.3, radius * 0.18), 10), Color(1, 1, 1, 0.3))
	var crack: Line2D = Line2D.new()
	crack.points = PackedVector2Array([Vector2(radius * 0.1, -radius * 0.7), Vector2(radius * 0.25, -radius * 0.1), Vector2(-radius * 0.05, radius * 0.35)])
	crack.width = 1.4
	crack.default_color = ROCK_DARK
	art.add_child(crack)
	return art
