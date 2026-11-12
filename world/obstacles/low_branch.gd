@tool
class_name LowBranch
extends HikerArea
## A branch hanging low over the path. Duck under it; walking into it upright makes the
## hiker stumble, and jumping into it knocks them back down.
## The origin is on the path; the branch hangs `clearance` above it.

@export var width: float = 90.0:
	set(v):
		width = v
		rebuild()
## Height of the branch's underside above the path (a ducking hiker fits, a standing one doesn't).
@export var clearance: float = 46.0:
	set(v):
		clearance = v
		rebuild()
@export var leaf_color: Color = Color("#4C7A45"):
	set(v):
		leaf_color = v
		rebuild()

const BARK: Color = Color("#5A4030")

var _inside: Hiker = null
var _hit: bool = false
var _shake: float = 0.0


func build() -> void:
	var y: float = -clearance
	# Trunk to the right of the path, behind it; the branch reaches back across.
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(width * 0.5, 4), Vector2(width * 0.5 + 16, 4), Vector2(width * 0.5 + 12, y - 70), Vector2(width * 0.5 + 2, y - 70)]), BARK.darkened(0.15), -1)
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-width * 0.5, y - 6), Vector2(width * 0.5 + 8, y - 18), Vector2(width * 0.5 + 8, y - 2), Vector2(-width * 0.5, y + 3)]), BARK, 1)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(width * 7.0 + clearance)
	for i: int in 8:
		var x: float = lerpf(-width * 0.55, width * 0.5, float(i) / 7.0)
		var c: Vector2 = Vector2(x, y - 8 + rng.randf_range(-8, 8))
		var leaf: Color = leaf_color.lightened(0.1) if i % 2 == 0 else leaf_color.darkened(0.08)
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(c, Vector2(rng.randf_range(16, 24), rng.randf_range(10, 15)), 12), leaf, 2)
	# Head height only: feet and a crouched hiker pass underneath.
	ShapeUtil.add_rect_shape(self, Rect2(-width * 0.5, y - 20.0, width, 20.0))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		rotation = sin(_shake * 40.0) * 0.04 * _shake
	if _inside != null and not _hit and not _inside.actions.crouching:
		_hit = true
		_shake = 0.6
		if not _inside.stumble() and _inside.velocity.y < 0.0:
			# Jumped into it: bumped back down.
			_inside.velocity.y = 60.0


func _hiker_entered(hiker: Hiker) -> void:
	_inside = hiker
	_hit = false


func _hiker_exited(hiker: Hiker) -> void:
	if _inside == hiker:
		_inside = null
