@tool
class_name Find
extends HikerArea
## Something to discover, matched to a FindData in the trail's TrailData.finds by
## `find_id`. Plants and lost items are picked up on contact. Animals have to be
## spotted: stand still near one for a moment; keep walking and it runs off.
## A faint twinkle now and then hints where finds hide.

const GROUP: StringName = &"find"
const STEM: Color = Color("#5E8C4A")
const CREAM: Color = Color("#F2EAD8")
const BRASS: Color = Color("#C9A24A")
const INK: Color = Color("#2B2D42")
const TWINKLE_SECONDS: float = 2.6

signal collected(find_id: StringName)

@export var find_id: StringName
@export var kind: FindData.Kind = FindData.Kind.FLOWER:
	set(v):
		kind = v
		rebuild()
@export var color: Color = Color("#D96C8E"):
	set(v):
		color = v
		rebuild()

var _art: Node2D
var _hiker: Hiker
var _taken: bool = false
var _present: bool = true
var _still: float = 0.0
var _walking_near: float = 0.0
var _twinkle_left: float = 1.0
var _twinkle: Polygon2D


func _ready() -> void:
	super()
	add_to_group(GROUP)


## Animals that didn't turn up this hike are hidden and can't be collected.
func set_present(present: bool) -> void:
	_present = present
	visible = present


func build() -> void:
	_art = Node2D.new()
	add_child(_art, false, Node.INTERNAL_MODE_BACK)
	match kind:
		FindData.Kind.FLOWER:
			_flower()
		FindData.Kind.MUSHROOM:
			_mushroom()
		FindData.Kind.ITEM:
			_compass()
		FindData.Kind.ANIMAL:
			_animal()
	_twinkle = ShapeUtil.add_poly(self, PackedVector2Array([Vector2(0, -5), Vector2(1.2, -1.2), Vector2(5, 0), Vector2(1.2, 1.2),
		Vector2(0, 5), Vector2(-1.2, 1.2), Vector2(-5, 0), Vector2(-1.2, -1.2)]), Color(1, 1, 0.9, 0.0), 1)
	_twinkle.position = Vector2(6, -26)
	var reach: float = 70.0 if kind == FindData.Kind.ANIMAL else 18.0
	ShapeUtil.add_rect_shape(self, Rect2(-reach, -50, reach * 2.0, 54))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _taken or not _present:
		return
	_twinkle_left -= delta
	if _twinkle_left <= 0.0:
		_twinkle_left = TWINKLE_SECONDS
		var t: Tween = _twinkle.create_tween()
		t.tween_property(_twinkle, "color:a", 0.9, 0.2)
		t.parallel().tween_property(_twinkle, "rotation", PI * 0.5, 0.5)
		t.tween_property(_twinkle, "color:a", 0.0, 0.3)
	if kind != FindData.Kind.ANIMAL or _hiker == null:
		return
	var balance: Balance = _hiker.balance
	var still: bool = _hiker.is_on_floor() and (_hiker.state == Hiker.State.IDLE or _hiker.state == Hiker.State.REST)
	if still:
		_still += delta
		if _still >= balance.animal_spot_seconds:
			_take()
	else:
		_still = 0.0
		_walking_near += delta
		# Ears up and a look at the hiker: a warning before it bolts.
		_art.scale.y = 1.12
		if _walking_near >= balance.animal_patience_seconds:
			_flee()


func _hiker_entered(hiker: Hiker) -> void:
	if _taken or not _present:
		return
	if kind == FindData.Kind.ANIMAL:
		_hiker = hiker
	else:
		_take()


func _hiker_exited(hiker: Hiker) -> void:
	if hiker == _hiker:
		_hiker = null
		_still = 0.0
		_walking_near = 0.0
		_art.scale.y = 1.0


func _take() -> void:
	_taken = true
	_hiker = null
	collected.emit(find_id)
	var pop: Tween = create_tween()
	pop.tween_property(_art, "scale", Vector2(1.4, 1.4), 0.12)
	pop.tween_property(_art, "modulate:a", 0.0, 0.35)
	pop.parallel().tween_property(_art, "position:y", -18.0, 0.35)
	pop.tween_callback(func() -> void: visible = false)


func _flee() -> void:
	_taken = true
	_hiker = null
	_art.scale = Vector2(-1.0, 1.0)
	var run: Tween = create_tween()
	run.tween_property(_art, "position:x", 260.0, 0.9).set_ease(Tween.EASE_IN)
	run.parallel().tween_property(_art, "modulate:a", 0.0, 0.9)
	run.tween_callback(func() -> void: visible = false)


# --- Art (drawn at the origin, standing on y = 0) ---

func _flower() -> void:
	for k: int in 3:
		var x: float = float(k - 1) * 6.0
		var h: float = 14.0 + float(k % 2) * 6.0
		ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(x - 0.8, 0), Vector2(x + 0.8, 0), Vector2(x + 0.6, -h), Vector2(x - 0.6, -h)]), STEM)
		for p: int in 5:
			var a: float = TAU * float(p) / 5.0
			ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(x, -h) + Vector2(cos(a), sin(a)) * 3.0, Vector2(2.6, 2.6), 8), color.lightened(0.1 * float(p % 2)))
		ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(x, -h), Vector2(1.6, 1.6), 8), Color("#F2C14E"))
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(-6, -3), Vector2(5, 2), 10), STEM)
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(6, -2), Vector2(5, 2), 10), STEM.darkened(0.1))


func _mushroom() -> void:
	for m: Vector2 in [Vector2(-5, 0.8), Vector2(5, 1.0)]:
		var sc: float = m.y
		ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(m.x - 2.5 * sc, 0), Vector2(m.x + 2.5 * sc, 0), Vector2(m.x + 2 * sc, -10 * sc), Vector2(m.x - 2 * sc, -10 * sc)]), CREAM)
		var cap: PackedVector2Array = PackedVector2Array()
		for i: int in 13:
			var a: float = PI + PI * float(i) / 12.0
			cap.append(Vector2(m.x, -9 * sc) + Vector2(cos(a) * 9 * sc, sin(a) * 7 * sc))
		var cap_poly: Polygon2D = ShapeUtil.add_poly(_art, cap, color)
		cap_poly.vertex_colors = _shade(cap, color)
		for d: Vector2 in [Vector2(-3, -13), Vector2(2, -15), Vector2(5, -11)]:
			ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(m.x, 0) + d * sc, Vector2(1.3, 1.1) * sc, 6), CREAM)


func _compass() -> void:
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(0, -6), Vector2(8, 6), 18), color.darkened(0.3))
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(0, -7), Vector2(7, 5.2), 18), BRASS)
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(0, -7.4), Vector2(5.4, 4), 16), CREAM)
	ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(0, -11), Vector2(1.2, -7.4), Vector2(-1.2, -7.4)]), Color("#E85D3F"))
	ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(0, -3.8), Vector2(1.2, -7.4), Vector2(-1.2, -7.4)]), INK)
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(-3, -9), Vector2(1.2, 0.8), 6), Color(1, 1, 1, 0.6))


## A small fox-like animal sitting and facing left (towards the arriving hiker).
func _animal() -> void:
	var fur: Color = color
	var tail: PackedVector2Array = PackedVector2Array([Vector2(8, -6), Vector2(20, -10), Vector2(24, -4), Vector2(18, 0), Vector2(8, -1)])
	ShapeUtil.add_poly(_art, tail, fur.darkened(0.1))
	ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(21, -7), Vector2(25, -5), Vector2(21, -2)]), CREAM)
	var body: PackedVector2Array = ShapeUtil.ellipse(Vector2(2, -9), Vector2(10, 9), 16)
	var body_poly: Polygon2D = ShapeUtil.add_poly(_art, body, fur)
	body_poly.vertex_colors = _shade(body, fur)
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(-2, -6), Vector2(4.5, 5), 12), CREAM)
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(-6, -19), Vector2(6, 5), 14), fur)
	ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(-12, -18), Vector2(-16, -16.5), Vector2(-11, -15)]), fur.darkened(0.15))
	for ex: float in [-9.0, -3.0]:
		ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(ex - 2.5, -22), Vector2(ex + 2.5, -22), Vector2(ex, -30)]), fur.darkened(0.08))
		ShapeUtil.add_poly(_art, PackedVector2Array([Vector2(ex - 1.2, -22.5), Vector2(ex + 1.2, -22.5), Vector2(ex, -27)]), CREAM)
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(-8, -20), Vector2(1, 1), 6), INK)
	ShapeUtil.add_poly(_art, ShapeUtil.ellipse(Vector2(-16, -16.6), Vector2(1, 0.9), 6), INK)
	for fx: float in [-4.0, 3.0]:
		ShapeUtil.add_poly(_art, ShapeUtil.rounded_rect(Rect2(fx, -4, 3, 4), 1.2), fur.darkened(0.2))


static func _shade(pts: PackedVector2Array, base: Color) -> PackedColorArray:
	var lo: float = INF
	var hi: float = -INF
	for p: Vector2 in pts:
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
	var cols: PackedColorArray = PackedColorArray()
	for p: Vector2 in pts:
		cols.append(base.lightened(0.15).lerp(base.darkened(0.2), (p.y - lo) / maxf(hi - lo, 0.001)))
	return cols
