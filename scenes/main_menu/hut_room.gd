class_name HutRoom
extends Control
## The title screen seen from inside a mountain hut: log walls either side, a lintel and
## a sill framing the window (the menu's landscape is the view), a stove with a live fire,
## Elsa's notebook on the sill and a stool where the player's hiker sits (the main menu
## places the Hiker on seat_point()). The keepsakes on the walls are HutWall's job.
## At night the room is lamp-lit, the stove glows and the sky gets stars and a moon.
## Tapping the notebook opens the journey; tapping the hiker opens the profile.

const LOG: Color = Color("#8A5A3B")
const LOG_LIGHT: Color = Color("#A06C48")
const LOG_DARK: Color = Color("#5C3A25")
const FRAME: Color = Color("#4A2E1E")
const SILL: Color = Color("#B07B52")
const IRON: Color = Color("#2F2B2E")
const FIRE: Color = Color("#FF9A3C")
const EMBER: Color = Color("#FFD36B")
const COVER: Color = Color("#3F6B4A")
const PAGE: Color = Color("#F4E8CF")
const STAR: Color = Color("#FFF8E1")
const TAG: Color = Color("#E85D3F")
const TAG_TEXT: Color = Color("#FFF6E5")

## The window keeps at least this much width for the menu; the walls take the rest.
const WINDOW_MIN: float = 1000.0
const WALL_MIN: float = 64.0
const WALL_MAX: float = 340.0
const LOG_HEIGHT: float = 46.0
const LINTEL: float = 20.0
const SILL_HEIGHT: float = 30.0
const FRAME_WIDTH: float = 12.0

var phase: HutView.Phase = HutView.Phase.DAY
## Glows while a notebook page waits to be read.
var notebook_fresh: bool = false
var show_notebook: bool = true

## Tools (store shots, previews) pin the clock and the month; -1 / 0 = the real ones.
static var hour_override: float = -1.0
static var month_override: int = 0

var _time: float = 0.0
var _stars: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_scatter_stars)
	_scatter_stars()


func set_phase(p: HutView.Phase) -> void:
	phase = p
	queue_redraw()


func wall_width() -> float:
	return clampf((size.x - WINDOW_MIN) * 0.5, WALL_MIN, WALL_MAX)


## Where the view outside shows through (between the walls, under the lintel, above the sill).
func window_rect() -> Rect2:
	var w: float = wall_width()
	return Rect2(w, LINTEL, size.x - w * 2.0, size.y - LINTEL - SILL_HEIGHT)


func stove_rect() -> Rect2:
	var w: float = wall_width()
	var sw: float = minf(w * 0.62, 130.0)
	var sh: float = minf(sw * 1.05, 128.0)
	return Rect2(Vector2(size.x - w * 0.5 - sw * 0.5, size.y - SILL_HEIGHT - sh), Vector2(sw, sh))


## The notebook lies on the sill in the window's left corner.
func notebook_rect() -> Rect2:
	var bw: float = 96.0
	return Rect2(Vector2(wall_width() + 14.0, size.y - SILL_HEIGHT - bw * 0.32 + 4.0), Vector2(bw, bw * 0.32))


## Where the hiker sits: on a stool at the foot of the left wall (feet on the floor).
func seat_point() -> Vector2:
	return Vector2((wall_width() - FRAME_WIDTH) * 0.5 + 6.0, size.y - SILL_HEIGHT + 2.0)


## Top of the seated hiker (the wall's postcards stop above it).
func seat_top() -> float:
	return seat_point().y - 96.0


func hiker_rect() -> Rect2:
	return Rect2(seat_point() + Vector2(-46, -96), Vector2(92, 96))


## How lit the room is: full by day, lamp-dark at night.
func room_light() -> float:
	match phase:
		HutView.Phase.NIGHT:
			return 0.74
		HutView.Phase.DUSK, HutView.Phase.DAWN:
			return 0.84
	return 1.0


func _process(delta: float) -> void:
	_time += delta
	# Only the fire, the twinkle and the glowing notebook move; redraw at a gentle rate.
	if Engine.get_process_frames() % 3 == 0:
		queue_redraw()


func _scatter_stars() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1974
	_stars.clear()
	var win: Rect2 = window_rect()
	for i: int in 46:
		_stars.append(Vector3(rng.randf_range(win.position.x + 10, win.end.x - 10), rng.randf_range(30, 150), rng.randf_range(0, TAU)))


func _draw() -> void:
	var light: float = room_light()
	if phase == HutView.Phase.NIGHT:
		_draw_night_sky()
	var w: float = wall_width()
	_draw_wall(Rect2(0, 0, w, size.y), light, true)
	_draw_wall(Rect2(size.x - w, 0, w, size.y), light, false)
	var shade: Color = Color(light, light, light)
	# Window frame: a dark border inside the walls, lintel on top, deep sill at the bottom.
	draw_rect(Rect2(w - FRAME_WIDTH, 0, FRAME_WIDTH, size.y), FRAME * shade)
	draw_rect(Rect2(size.x - w, 0, FRAME_WIDTH, size.y), FRAME * shade)
	draw_rect(Rect2(0, 0, size.x, LINTEL), LOG_DARK * shade)
	draw_rect(Rect2(0, LINTEL - 4, size.x, 4), FRAME * shade)
	var sill: Rect2 = Rect2(0, size.y - SILL_HEIGHT, size.x, SILL_HEIGHT)
	draw_rect(sill, SILL * shade)
	draw_rect(Rect2(sill.position, Vector2(size.x, 5)), SILL.lightened(0.18) * shade)
	_draw_stove(light)
	_draw_stool(light)
	if show_notebook:
		_draw_notebook(light)


func _draw_night_sky() -> void:
	for s: Vector3 in _stars:
		var a: float = 0.45 + 0.4 * sin(_time * 1.3 + s.z)
		draw_circle(Vector2(s.x, s.y), 1.6, Color(STAR, a))
	var win: Rect2 = window_rect()
	var moon: Vector2 = Vector2(win.end.x - win.size.x * 0.18, 96)
	draw_circle(moon, 46.0, Color(STAR, 0.08))
	draw_circle(moon, 30.0, Color(STAR, 0.95))
	draw_circle(moon + Vector2(11, -6), 26.0, Color("#3A4270"))


## Stacked logs; the round log ends show at the window edge, like a real cabin corner.
func _draw_wall(rect: Rect2, light: float, left: bool) -> void:
	var shade: Color = Color(light, light, light)
	draw_rect(rect, LOG * shade)
	var y: float = 0.0
	var i: int = 0
	while y < rect.size.y:
		var band: Rect2 = Rect2(rect.position.x, y, rect.size.x, LOG_HEIGHT)
		draw_rect(Rect2(band.position + Vector2(0, 6), Vector2(band.size.x, 12)), LOG_LIGHT * shade)
		draw_rect(Rect2(band.position + Vector2(0, LOG_HEIGHT - 4), Vector2(band.size.x, 4)), LOG_DARK * shade)
		# A knot here and there so the logs aren't wallpaper.
		if i % 3 == 1:
			var kx: float = rect.position.x + rect.size.x * (0.3 if left else 0.62) + float(i % 2) * 30.0
			draw_circle(Vector2(kx, y + LOG_HEIGHT * 0.55), 4.0, LOG_DARK * shade)
		var edge_x: float = rect.end.x if left else rect.position.x
		var end_c: Vector2 = Vector2(edge_x, y + LOG_HEIGHT * 0.5)
		draw_circle(end_c, LOG_HEIGHT * 0.5 - 1.0, LOG_LIGHT.lightened(0.1) * shade)
		draw_arc(end_c, LOG_HEIGHT * 0.3, 0.0, TAU, 20, LOG_DARK * shade, 2.0, true)
		draw_circle(end_c, 3.0, LOG_DARK * shade)
		y += LOG_HEIGHT
		i += 1


func _draw_stove(light: float) -> void:
	var r: Rect2 = stove_rect()
	var shade: Color = Color(light, light, light)
	var flicker: float = 0.75 + 0.25 * sin(_time * 7.0) * sin(_time * 3.1 + 1.0)
	# Warm light on the wall around the stove; strongest when the room is dark.
	var glow: float = (1.15 - light) * flicker
	for k: int in 8:
		draw_circle(r.get_center(), r.size.x * (0.6 + 0.22 * k), Color(FIRE, 0.03 * glow))
	# Pipe up the wall, behind the shelves HutWall draws.
	var pipe_w: float = r.size.x * 0.2
	draw_rect(Rect2(r.get_center().x - pipe_w * 0.5, 0, pipe_w, r.position.y), IRON.lightened(0.12) * shade)
	draw_rect(Rect2(r.position + Vector2(-6, 0), Vector2(r.size.x + 12, 10)), IRON.lightened(0.2) * shade)
	draw_rect(Rect2(r.position + Vector2(0, 10), r.size - Vector2(0, 18)), IRON * shade)
	draw_rect(Rect2(Vector2(r.position.x + 6, r.end.y - 8), Vector2(8, 8)), IRON * shade)
	draw_rect(Rect2(Vector2(r.end.x - 14, r.end.y - 8), Vector2(8, 8)), IRON * shade)
	# The door window: the fire never goes out in this hut.
	var door: Rect2 = Rect2(r.position + Vector2(r.size.x * 0.2, r.size.y * 0.32), Vector2(r.size.x * 0.6, r.size.y * 0.4))
	draw_rect(door, Color("#1A1416"))
	var fire_c: Vector2 = Vector2(door.get_center().x, door.end.y - 4)
	for k: int in 3:
		var fx: float = (float(k) - 1.0) * door.size.x * 0.26
		var fh: float = door.size.y * (0.55 + 0.3 * sin(_time * (5.0 + k) + k * 2.0) * 0.5 + 0.15)
		draw_colored_polygon(PackedVector2Array([
			fire_c + Vector2(fx - door.size.x * 0.16, 0),
			fire_c + Vector2(fx, -fh),
			fire_c + Vector2(fx + door.size.x * 0.16, 0)]), FIRE.lerp(EMBER, float(k % 2) * 0.6))
	draw_rect(door, IRON.lightened(0.3) * shade, false, 3.0)


## A three-legged stool under the seated hiker.
func _draw_stool(light: float) -> void:
	var shade: Color = Color(light, light, light)
	var s: Vector2 = seat_point() + Vector2(-14, -30)
	draw_rect(Rect2(s + Vector2(-22, 0), Vector2(44, 8)), SILL.darkened(0.15) * shade)
	draw_line(s + Vector2(-16, 8), s + Vector2(-22, 30), LOG_DARK * shade, 5.0)
	draw_line(s + Vector2(16, 8), s + Vector2(22, 30), LOG_DARK * shade, 5.0)
	draw_line(s + Vector2(0, 8), s + Vector2(0, 30), LOG_DARK.darkened(0.2) * shade, 4.0)


## Elsa's green notebook lying on the sill; it glows and wears a tag while a page is new.
func _draw_notebook(light: float) -> void:
	var shade: Color = Color(light, light, light)
	var b: Rect2 = notebook_rect()
	if notebook_fresh:
		var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
		for k: int in 3:
			draw_circle(b.get_center(), b.size.x * (0.55 + 0.18 * k), Color(EMBER, (0.12 + 0.1 * pulse) / float(k + 1)))
	draw_rect(Rect2(b.position + Vector2(4, 4), b.size - Vector2(4, 4)), PAGE * shade)
	draw_rect(Rect2(b.position, b.size - Vector2(0, 6)), COVER * shade)
	draw_rect(Rect2(b.position, Vector2(b.size.x * 0.1, b.size.y - 6)), COVER.darkened(0.3) * shade)
	draw_rect(Rect2(b.position + Vector2(b.size.x * 0.82, 0), Vector2(5, b.size.y + 6)), Color("#C0492F") * shade)
	if notebook_fresh:
		var font: Font = get_theme_default_font()
		var text: String = tr("HUT_NEW_PAGE")
		var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		# A label on the cover (above the book would crowd the menu buttons).
		var tag: Rect2 = Rect2(Vector2(b.position.x + (b.size.x * 0.82 - tw) * 0.5 - 4.0, b.position.y + 3.0), Vector2(tw + 8.0, 20.0))
		draw_rect(tag, TAG)
		draw_string(font, Vector2(tag.position.x + 4.0, tag.end.y - 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TAG_TEXT)


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	if show_notebook and notebook_rect().grow(24).has_point(event.position):
		accept_event()
		SceneRouter.go_to(SceneRouter.JOURNEY)
	elif hiker_rect().has_point(event.position):
		accept_event()
		SceneRouter.go_to(SceneRouter.PROFILE)
