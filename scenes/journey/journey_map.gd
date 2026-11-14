class_name JourneyMap
extends Control
## The journey's map, drawn like a sketch in the notebook: paper, lakes, little fells,
## the trail (solid where walked, dashed ahead), landmarks and the walker. Turned on its
## side so the trail runs left to right (north is on the left; the compass says so).
## Tapping a reached landmark emits `landmark_tapped`.

signal landmark_tapped(landmark: LandmarkData)

const PAPER: Color = Color("#F4E8CF")
const PAPER_EDGE: Color = Color("#E2D2AE")
const INK: Color = Color("#2B2D42")
const PENCIL: Color = Color("#8C7B5E")
const WATER: Color = Color("#9CC3D5")
const FELL: Color = Color("#B9AE96")
const SNOW: Color = Color("#FFFDF7")
const WALKED: Color = Color("#E85D3F")
const DOT_RADIUS: float = 11.0
const TAP_RADIUS: float = 44.0
const MARGIN: Vector2 = Vector2(28, 26)

var journey: JourneyData
var walked_km: float = 0.0
## Landmark ids reached (filled dots, labels, tappable).
var reached: Array[StringName] = []
var selected: StringName = &""
## Landmarks whose page is new (a small glow around the dot).
var unread: Array[StringName] = []

var _fells: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_scatter_fells)


func show_journey(j: JourneyData, km: float, reached_ids: Array[StringName], unread_ids: Array[StringName]) -> void:
	journey = j
	walked_km = km
	reached = reached_ids
	unread = unread_ids
	_scatter_fells()
	queue_redraw()


func select(id: StringName) -> void:
	selected = id
	queue_redraw()


## Map space (0..1) -> local pixels inside the paper margin.
func to_local_px(p: Vector2) -> Vector2:
	return MARGIN + p * (size - MARGIN * 2.0)


func _scatter_fells() -> void:
	# Fixed seed: the same sketch every time the screen opens.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 74
	_fells.clear()
	for i: int in 34:
		var p: Vector2 = Vector2(rng.randf_range(0.03, 0.97), rng.randf_range(0.05, 0.95))
		if _near_trail(p, 0.07) or _in_lake(p):
			continue
		_fells.append(Vector3(p.x, p.y, rng.randf_range(0.7, 1.3)))
	queue_redraw()


func _near_trail(p: Vector2, dist: float) -> bool:
	if journey == null:
		return false
	for i: int in range(1, journey.landmarks.size()):
		var a: Vector2 = journey.landmarks[i - 1].map_pos
		var b: Vector2 = journey.landmarks[i].map_pos
		if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < dist:
			return true
	return false


func _in_lake(p: Vector2) -> bool:
	if journey == null:
		return false
	for lake: Vector4 in journey.lakes:
		var d: Vector2 = (p - Vector2(lake.x, lake.y)) / Vector2(lake.z + 0.04, lake.w + 0.04)
		if d.length() < 1.0:
			return true
	return false


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, PAPER)
	draw_rect(rect.grow(-6), PAPER_EDGE, false, 2.0)
	if journey == null:
		return
	var scale_px: float = minf(size.x, size.y) / 420.0
	for lake: Vector4 in journey.lakes:
		var c: Vector2 = to_local_px(Vector2(lake.x, lake.y))
		var r: Vector2 = Vector2(lake.z, lake.w) * (size - MARGIN * 2.0)
		draw_colored_polygon(ShapeUtil.ellipse(c, r, 20), WATER)
	for f: Vector3 in _fells:
		_draw_fell(to_local_px(Vector2(f.x, f.y)), 16.0 * f.z * scale_px)
	_draw_trail()
	_draw_compass(Vector2(size.x - 54, size.y - 56))


func _draw_fell(at: Vector2, h: float) -> void:
	draw_colored_polygon(PackedVector2Array([at + Vector2(-h, 0), at + Vector2(0, -h * 1.1), at + Vector2(h, 0)]), FELL)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-h * 0.32, -h * 0.75), at + Vector2(0, -h * 1.1), at + Vector2(h * 0.32, -h * 0.75)]), SNOW)


func _draw_trail() -> void:
	var lms: Array[LandmarkData] = journey.landmarks
	var walker: Vector2 = to_local_px(Journey.map_position(journey, walked_km))
	for i: int in range(1, lms.size()):
		var a: Vector2 = to_local_px(lms[i - 1].map_pos)
		var b: Vector2 = to_local_px(lms[i].map_pos)
		if walked_km >= lms[i].km:
			draw_line(a, b, WALKED, 5.0, true)
		elif walked_km > lms[i - 1].km:
			draw_line(a, walker, WALKED, 5.0, true)
			draw_dashed_line(walker, b, PENCIL, 3.0, 10.0)
		else:
			draw_dashed_line(a, b, PENCIL, 3.0, 10.0)
	var font: Font = get_theme_default_font()
	for i: int in lms.size():
		var lm: LandmarkData = lms[i]
		var at: Vector2 = to_local_px(lm.map_pos)
		var is_reached: bool = reached.has(lm.id)
		if unread.has(lm.id):
			draw_circle(at, DOT_RADIUS + 9.0, Color(WALKED, 0.25))
		if lm.id == selected:
			draw_arc(at, DOT_RADIUS + 6.0, 0.0, TAU, 28, INK, 3.0, true)
		draw_circle(at, DOT_RADIUS, WALKED if is_reached else PAPER)
		draw_arc(at, DOT_RADIUS, 0.0, TAU, 24, INK if is_reached else PENCIL, 2.5, true)
		if is_reached or i == reached.size():
			# Labels alternate above and below so neighbours don't collide.
			var text: String = tr(lm.name_key)
			var fs: int = 20
			var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var y: float = at.y - 20.0 if i % 2 == 0 else at.y + 34.0
			var x: float = clampf(at.x - w * 0.5, 8.0, size.x - w - 8.0)
			draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK if is_reached else PENCIL)
	_draw_walker(walker)


## The walker: a little red pin with a white head, like a map marker.
func _draw_walker(at: Vector2) -> void:
	var tip: Vector2 = at + Vector2(0, -6)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-11, -20), tip + Vector2(11, -20)]), INK)
	draw_circle(tip + Vector2(0, -24), 13.0, INK)
	draw_circle(tip + Vector2(0, -24), 10.0, WALKED)
	draw_circle(tip + Vector2(0, -24), 4.0, SNOW)


func _draw_compass(at: Vector2) -> void:
	draw_circle(at, 26.0, Color(PAPER_EDGE, 0.8))
	# North points left: the map is turned so the trail runs across the screen.
	draw_colored_polygon(PackedVector2Array([at + Vector2(-22, 0), at + Vector2(0, -7), at + Vector2(0, 7)]), WALKED)
	draw_colored_polygon(PackedVector2Array([at + Vector2(22, 0), at + Vector2(0, -7), at + Vector2(0, 7)]), PENCIL)
	var font: Font = get_theme_default_font()
	draw_string(font, at + Vector2(-44, 8), tr("JOURNEY_MAP_NORTH"), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed or journey == null:
		return
	var best: LandmarkData = null
	var best_d: float = TAP_RADIUS
	for lm: LandmarkData in journey.landmarks:
		var d: float = to_local_px(lm.map_pos).distance_to(event.position)
		if d < best_d:
			best = lm
			best_d = d
	if best != null:
		accept_event()
		landmark_tapped.emit(best)
