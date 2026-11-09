class_name ShapeUtil
extends RefCounted
## Point lists for placeholder art and collision shapes built in code.


static func ellipse(center: Vector2, radii: Vector2, segments: int = 16) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in segments:
		var a: float = TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return pts


static func rounded_rect(rect: Rect2, radius: float, corner_segments: int = 3) -> PackedVector2Array:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts: PackedVector2Array = PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	for c: int in 4:
		var start: float = -PI * 0.5 + PI * 0.5 * float(c)
		for i: int in corner_segments + 1:
			var a: float = start + PI * 0.5 * float(i) / float(corner_segments)
			pts.append(corners[c] + Vector2(cos(a), sin(a)) * r)
	return pts


## A boulder outline sitting on y = 0: steep sides, rounded top.
static func dome(size: Vector2, segments: int = 12) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(Vector2(-size.x * 0.5, 0.0))
	for i: int in segments + 1:
		var a: float = PI + PI * float(i) / float(segments)
		# Squaring the sine pushes the bulk up, so the sides stay steep enough to block.
		var s: float = sin(a)
		pts.append(Vector2(cos(a) * size.x * 0.5, -absf(s) * sqrt(absf(s)) * size.y))
	pts.append(Vector2(size.x * 0.5, 0.0))
	return pts


## A thick arched band (tree root) from -half_width to +half_width rising to `height`.
static func arch(half_width: float, height: float, thickness: float, segments: int = 10) -> PackedVector2Array:
	var top: PackedVector2Array = PackedVector2Array()
	var bottom: PackedVector2Array = PackedVector2Array()
	for i: int in segments + 1:
		var t: float = float(i) / float(segments)
		var x: float = lerpf(-half_width, half_width, t)
		var y: float = -sin(t * PI) * height
		top.append(Vector2(x, y - thickness * 0.5))
		bottom.append(Vector2(x, y + thickness * 0.5))
	bottom.reverse()
	top.append_array(bottom)
	return top


## Adds a filled polygon child (internal, so it's never saved into the scene).
static func add_poly(parent: Node, points: PackedVector2Array, color: Color, z: int = 0) -> Polygon2D:
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = points
	poly.color = color
	poly.antialiased = true
	poly.z_index = z
	parent.add_child(poly, false, Node.INTERNAL_MODE_BACK)
	return poly


static func add_rect_shape(parent: Node, rect: Rect2) -> CollisionShape2D:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	parent.add_child(shape, false, Node.INTERNAL_MODE_BACK)
	return shape


## Removes everything a previous build added (for live editing in the editor).
static func clear_internal(parent: Node) -> void:
	for child: Node in parent.get_children(true):
		if parent.get_children(false).has(child):
			continue
		parent.remove_child(child)
		child.queue_free()
