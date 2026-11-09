class_name SubjectArt
extends RefCounted
## Art for the photo subjects, built from flat shapes with a little shading. Every
## builder draws facing right into `body`; PhotoSubject mirrors and animates it.

const INK: Color = Color("#2B2D42")
const EYE_SHINE: Color = Color(1, 1, 1, 0.9)
const BEAK: Color = Color("#E8A33F")
const FUR: Color = Color("#7A5A43")
const FUR_DARK: Color = Color("#5C4332")
const FUR_LIGHT: Color = Color("#E3D5B8")
const HOOF: Color = Color("#2E2620")
const ANTLER: Color = Color("#E8DCC0")
const ANTLER_SHADE: Color = Color("#BFAF8E")
const HULL: Color = Color("#8C3B2A")
const HULL_STRIPE: Color = Color("#F2E6CF")
const SAIL: Color = Color("#FFF6E5")
const SAIL_SHADE: Color = Color("#E6D9C0")
const FLAG: Color = Color("#2F6690")


## A small songbird in flight. Returns the wing pivot, which PhotoSubject flaps.
static func bird(body: Node2D, color: Color, accent: Color) -> Node2D:
	var belly: Color = color.lightened(0.35)
	# Far wing sits behind the body, a shade darker.
	var wings: Node2D = Node2D.new()
	wings.position = Vector2(-1, -3)
	body.add_child(wings, false, Node.INTERNAL_MODE_BACK)
	var far: Polygon2D = ShapeUtil.add_poly(wings, _wing(0.85), color.darkened(0.35), -1)
	far.position = Vector2(3, -1)
	# Tail fan.
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-9, -1), Vector2(-21, -6), Vector2(-23, -2), Vector2(-21, 2), Vector2(-9, 2)]), color.darkened(0.15))
	# Body: a teardrop, with a paler belly.
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-11, -1), Vector2(-4, -6), Vector2(5, -7), Vector2(11, -5),
		Vector2(13, -1), Vector2(9, 3), Vector2(0, 5), Vector2(-8, 3)]), color)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-6, 2), Vector2(2, 0), Vector2(10, -1), Vector2(8, 3), Vector2(0, 5)]), belly)
	ShapeUtil.add_poly(body, ShapeUtil.ellipse(Vector2(12, -6), Vector2(5.5, 5), 12), color)
	if accent.a > 0.0:
		ShapeUtil.add_poly(body, ShapeUtil.ellipse(Vector2(12, -9), Vector2(4, 2.6), 10), accent)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(16, -7.5), Vector2(22, -5.5), Vector2(16, -4)]), BEAK)
	ShapeUtil.add_poly(body, ShapeUtil.ellipse(Vector2(14, -7), Vector2(1.4, 1.4), 8), INK)
	ShapeUtil.add_poly(body, ShapeUtil.ellipse(Vector2(14.4, -7.4), Vector2(0.5, 0.5), 6), EYE_SHINE)
	# Near wing in front of the body.
	ShapeUtil.add_poly(wings, _wing(1.0), color.lightened(0.08), 1)
	return wings


## A wing raised from the shoulder (y = 0), with scalloped feather tips.
static func _wing(scale: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-5, 0), Vector2(6, 0), Vector2(4, -8), Vector2(0, -15)])
	for i: int in 4:
		var t: float = float(i) / 3.0
		pts.append(Vector2(lerpf(-1.0, -9.0, t), lerpf(-21.0, -12.0, t)))
		pts.append(Vector2(lerpf(-3.5, -9.5, t), lerpf(-17.5, -8.0, t)))
	pts.append(Vector2(-8, -4))
	for i: int in pts.size():
		pts[i] *= scale
	return pts


## A reindeer walking right, hooves at y = 0. Returns the four leg pivots in the
## order front-near, front-far, back-near, back-far (diagonal pairs swing together).
static func reindeer(body: Node2D) -> Array[Node2D]:
	var legs: Array[Node2D] = []
	for spec: Vector2 in [Vector2(15, 1), Vector2(10, -1), Vector2(-13, 1), Vector2(-18, -1)]:
		var near: bool = spec.y > 0.0
		var leg: Node2D = Node2D.new()
		leg.position = Vector2(spec.x, -26)
		leg.z_index = 1 if near else -1
		body.add_child(leg, false, Node.INTERNAL_MODE_BACK)
		var col: Color = FUR_DARK if near else FUR_DARK.darkened(0.25)
		ShapeUtil.add_poly(leg, PackedVector2Array([Vector2(-3.2, -4), Vector2(3.2, -4), Vector2(2.2, 10), Vector2(1.5, 22),
			Vector2(-1.5, 22), Vector2(-2.4, 10)]), col)
		ShapeUtil.add_poly(leg, PackedVector2Array([Vector2(-2.2, 22), Vector2(2.4, 22), Vector2(3, 26), Vector2(-2.4, 26)]), HOOF)
		legs.append(leg)
	# Tail tuft, body, a darker belly and a paler back line.
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-25, -41), Vector2(-32, -38), Vector2(-27, -34)]), FUR_LIGHT)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-27, -36), Vector2(-24, -43), Vector2(-10, -45), Vector2(8, -46),
		Vector2(18, -44), Vector2(23, -36), Vector2(21, -27), Vector2(13, -22), Vector2(-4, -22), Vector2(-18, -23), Vector2(-26, -29)]), FUR)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-20, -27), Vector2(-4, -26), Vector2(14, -26), Vector2(13, -22),
		Vector2(-4, -22), Vector2(-18, -23)]), FUR_DARK)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-22, -42), Vector2(-8, -44.5), Vector2(10, -45), Vector2(-8, -42.5)]), FUR.lightened(0.15))
	# Neck, the pale ruff under it, then the head.
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(11, -44), Vector2(21, -60), Vector2(29, -62), Vector2(28, -50), Vector2(22, -35)]), FUR)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(19, -37), Vector2(25, -51), Vector2(30, -52), Vector2(29, -42), Vector2(24, -31)]), FUR_LIGHT)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(23, -62), Vector2(29, -66), Vector2(37, -63), Vector2(44, -57),
		Vector2(43, -53), Vector2(35, -53), Vector2(27, -55)]), FUR)
	ShapeUtil.add_poly(body, ShapeUtil.ellipse(Vector2(42, -55), Vector2(3, 2.4), 10), FUR_DARK.darkened(0.3))
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(27, -63), Vector2(20, -67), Vector2(25, -60)]), FUR_DARK)
	ShapeUtil.add_poly(body, ShapeUtil.ellipse(Vector2(34, -60), Vector2(1.5, 1.5), 8), INK)
	ShapeUtil.add_poly(body, ShapeUtil.ellipse(Vector2(34.4, -60.4), Vector2(0.5, 0.5), 6), EYE_SHINE)
	# Antlers: the far one behind in a darker shade, each a curved beam with tines.
	_antler(body, Vector2(25, -64), ANTLER_SHADE, -1)
	_antler(body, Vector2(29, -65), ANTLER, 0)
	return legs


static func _antler(body: Node2D, base: Vector2, col: Color, z: int) -> void:
	for pts: PackedVector2Array in [
		PackedVector2Array([base, base + Vector2(-2, -8), base + Vector2(-5, -16), base + Vector2(-3, -24), base + Vector2(2, -29)]),
		PackedVector2Array([base + Vector2(-3, -12), base + Vector2(3, -16)]),
		PackedVector2Array([base + Vector2(-4, -20), base + Vector2(-10, -25)]),
		PackedVector2Array([base + Vector2(-1, -3), base + Vector2(6, -6)]),
	]:
		var line: Line2D = Line2D.new()
		line.points = pts
		line.width = 2.2
		line.default_color = col
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.antialiased = true
		line.z_index = z
		body.add_child(line, false, Node.INTERNAL_MODE_BACK)


## A small sailing boat, waterline at y = 0.
static func boat(body: Node2D) -> void:
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-1, -2), Vector2(-1, -56), Vector2(25, -8), Vector2(12, -4)]), SAIL)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-1, -30), Vector2(-1, -56), Vector2(10, -36)]), SAIL_SHADE)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-5, -4), Vector2(-5, -44), Vector2(-27, -6)]), SAIL)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-3, 0), Vector2(-1, 0), Vector2(-1, -60), Vector2(-3, -60)]), INK)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-1, -60), Vector2(9, -57), Vector2(-1, -54)]), FLAG)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-32, -2), Vector2(32, -2), Vector2(24, 11), Vector2(-25, 11)]), HULL)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-31, -2), Vector2(31, -2), Vector2(30, 1), Vector2(-30, 1)]), HULL_STRIPE)
	ShapeUtil.add_poly(body, PackedVector2Array([Vector2(-25, 11), Vector2(24, 11), Vector2(26, 8), Vector2(-27, 8)]), HULL.darkened(0.3))
