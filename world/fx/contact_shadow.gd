@tool
class_name ContactShadow
extends Node2D
## A soft shadow on the ground under something, so it stands on the trail instead of
## floating over it. With `follow_ground` it finds the ground under its parent every tick
## (the hiker, a rolling boulder), lies along the slope and shrinks and fades with height;
## otherwise it just sits where it's placed (rocks, logs).

const ALPHA: float = 0.42
## Cast this far down before giving up (higher than this, there's no shadow at all).
const MAX_DROP: float = 170.0

@export var size: Vector2 = Vector2(48, 10):
	set(v):
		size = v
		queue_redraw()
@export var follow_ground: bool = false
## How far the parent's origin sits above its lowest point (a boulder's radius).
@export var lift: float = 0.0

static var _texture: GradientTexture2D
var _query: PhysicsRayQueryParameters2D


func _ready() -> void:
	show_behind_parent = true
	set_physics_process(follow_ground and not Engine.is_editor_hint())
	if follow_ground:
		# Placed by the first physics tick; nothing until it knows where the ground is.
		visible = false


## A fixed shadow at the foot of `parent` (local origin at ground level).
static func add_to(parent: Node, width: float, height: float = 0.0) -> ContactShadow:
	var s: ContactShadow = ContactShadow.new()
	s.size = Vector2(width, height if height > 0.0 else maxf(width * 0.2, 6.0))
	parent.add_child(s, false, Node.INTERNAL_MODE_FRONT)
	return s


func _physics_process(_delta: float) -> void:
	var body: Node2D = get_parent() as Node2D
	if body == null or not body.is_visible_in_tree():
		visible = false
		return
	if _query == null:
		_query = PhysicsRayQueryParameters2D.new()
		_query.collision_mask = 1
		var col: CollisionObject2D = body as CollisionObject2D
		if col != null:
			_query.exclude = [col.get_rid()]
	var from: Vector2 = body.global_position + Vector2(0, -6)
	_query.from = from
	_query.to = from + Vector2(0, MAX_DROP)
	var hit: Dictionary = body.get_world_2d().direct_space_state.intersect_ray(_query)
	if hit.is_empty():
		visible = false
		return
	var drop: float = maxf((hit.position as Vector2).y - body.global_position.y - lift, 0.0)
	var k: float = clampf(1.0 - drop / MAX_DROP, 0.0, 1.0)
	visible = k > 0.05
	global_position = hit.position
	# Global, so a spinning parent (a rolling boulder) doesn't spin its shadow.
	global_rotation = (hit.normal as Vector2).angle() + PI * 0.5
	scale = Vector2.ONE * lerpf(0.55, 1.0, k)
	modulate.a = k


func _draw() -> void:
	if _texture == null:
		var g: Gradient = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray([Color(0, 0, 0, ALPHA), Color(0, 0, 0, ALPHA * 0.6), Color(0, 0, 0, 0)])
		_texture = GradientTexture2D.new()
		_texture.gradient = g
		_texture.width = 64
		_texture.height = 64
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
	draw_texture_rect(_texture, Rect2(-size * 0.5, size), false)
