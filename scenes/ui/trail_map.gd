class_name TrailMap
extends Control
## A small elevation map of the whole trail for the pause card: the ground profile,
## where the hiker is, checkpoints (filled once reached), springs, the fork,
## viewpoints, the summit, and the finds already collected (unfound ones stay hidden).

enum Mark { CHECKPOINT, SPRING, FORK, VIEWPOINT, FINISH, FIND }

const BG: Color = Color(0.168627, 0.176471, 0.258824, 0.06)
const LAND: Color = Color("#7FA6A0")
const LAND_LINE: Color = Color("#3B5B4A")
const DONE: Color = Color("#5E9C6E")
const TODO: Color = Color(0.168627, 0.176471, 0.258824, 0.35)
const SPRING_COL: Color = Color("#3E9BD1")
const FORK_COL: Color = Color("#8A6A45")
const CAMERA_COL: Color = Color("#2B2D42")
const FINISH_COL: Color = Color("#E85D3F")
const HIKER_COL: Color = Color("#E85D3F")
const PAD: Vector2 = Vector2(14, 12)
const SAMPLE_STEP: float = 60.0

## Ground profile in world space, sampled left to right.
var _profile: PackedVector2Array = PackedVector2Array()
## [Vector2 world position, Mark, StringName id] per marker.
var _marks: Array = []
var _bounds: Rect2 = Rect2()
var _hiker: Vector2 = Vector2.ZERO
var _reached_x: float = -INF
var _found: Array = []


func _ready() -> void:
	custom_minimum_size = Vector2(0, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Reads the level once: strips for the profile, pieces for the markers.
func scan(level: Node) -> void:
	_profile.clear()
	_marks.clear()
	var strips: Array[TerrainStrip] = []
	var nodes: Array[Node] = [level]
	var i: int = 0
	while i < nodes.size():
		var node: Node = nodes[i]
		i += 1
		nodes.append_array(node.get_children())
		if node is TerrainStrip:
			strips.append(node as TerrainStrip)
		elif node is TrailCheckpoint:
			_marks.append([(node as Node2D).global_position, Mark.CHECKPOINT, &""])
		elif node is Spring:
			_marks.append([(node as Node2D).global_position, Mark.SPRING, &""])
		elif node is ForkSign:
			_marks.append([(node as Node2D).global_position, Mark.FORK, &""])
		elif node is Viewpoint:
			_marks.append([(node as Node2D).global_position, Mark.VIEWPOINT, &""])
		elif node is TrailFinish:
			_marks.append([(node as Node2D).global_position, Mark.FINISH, &""])
		elif node is Find:
			_marks.append([(node as Node2D).global_position, Mark.FIND, (node as Find).find_id])
	strips.sort_custom(func(a: TerrainStrip, b: TerrainStrip) -> bool: return a.global_position.x + a.points[0].x < b.global_position.x + b.points[0].x)
	for strip: TerrainStrip in strips:
		if strip.points.size() < 2:
			continue
		var x: float = strip.points[0].x
		var end: float = strip.points[strip.points.size() - 1].x
		while x <= end:
			_profile.append(strip.to_global(Vector2(x, strip.edge_y_at(x))))
			x += SAMPLE_STEP
	_bounds = Rect2()
	if not _profile.is_empty():
		_bounds = Rect2(_profile[0], Vector2.ZERO)
		for p: Vector2 in _profile:
			_bounds = _bounds.expand(p)
	queue_redraw()


## Called when the pause card opens.
func show_progress(hiker_pos: Vector2, reached_x: float, found: Array) -> void:
	_hiker = hiker_pos
	_reached_x = reached_x
	_found = found
	queue_redraw()


func _to_map(p: Vector2) -> Vector2:
	var inner: Vector2 = size - PAD * 2.0
	var w: float = maxf(_bounds.size.x, 1.0)
	var h: float = maxf(_bounds.size.y, 1.0)
	# Squash the height a little: real trails are long and flat at this scale.
	return PAD + Vector2((p.x - _bounds.position.x) / w * inner.x, (p.y - _bounds.position.y) / h * inner.y * 0.8 + inner.y * 0.1)


func _draw() -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = BG
	box.set_corner_radius_all(14)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	if _profile.size() < 2:
		return
	var line: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in _profile:
		line.append(_to_map(p))
	var fill: PackedVector2Array = line.duplicate()
	fill.append(Vector2(line[line.size() - 1].x, size.y - PAD.y * 0.5))
	fill.append(Vector2(line[0].x, size.y - PAD.y * 0.5))
	draw_colored_polygon(fill, Color(LAND, 0.45))
	# Walked part darker than the part still ahead.
	var walked: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in line:
		if _to_map(Vector2(_hiker.x, 0)).x >= p.x:
			walked.append(p)
	draw_polyline(line, Color(LAND_LINE, 0.45), 2.0, true)
	if walked.size() > 1:
		draw_polyline(walked, LAND_LINE, 3.0, true)
	for m: Array in _marks:
		var at: Vector2 = _to_map(m[0])
		match m[1]:
			Mark.CHECKPOINT:
				var col: Color = DONE if (m[0] as Vector2).x <= _reached_x + 1.0 else TODO
				draw_line(at, at + Vector2(0, -12), col, 1.6, true)
				draw_colored_polygon(PackedVector2Array([at + Vector2(0, -12), at + Vector2(8, -9), at + Vector2(0, -6)]), col)
			Mark.SPRING:
				draw_circle(at + Vector2(0, -6), 3.6, SPRING_COL, true, -1.0, true)
			Mark.FORK:
				draw_line(at, at + Vector2(-4, -9), FORK_COL, 1.6, true)
				draw_line(at, at + Vector2(4, -9), FORK_COL, 1.6, true)
			Mark.VIEWPOINT:
				draw_rect(Rect2(at + Vector2(-4, -11), Vector2(8, 6)), CAMERA_COL, true)
			Mark.FINISH:
				draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(6, 0), at + Vector2(0, -12)]), FINISH_COL)
			Mark.FIND:
				if _found.has(String(m[2])) or _found.has(m[2]):
					draw_colored_polygon(ShapeUtil.ellipse(at + Vector2(0, -7), Vector2(2.6, 4.2), 10), DONE)
	# Kept inside the map even mid-jump or mid-fall.
	var me: Vector2 = _to_map(_hiker).clamp(PAD, size - PAD)
	draw_circle(me, 6.5, Color.WHITE, true, -1.0, true)
	draw_circle(me, 4.5, HIKER_COL, true, -1.0, true)
