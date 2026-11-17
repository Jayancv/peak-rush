class_name HutWall
extends Control
## The keepsakes on the hut walls: an old photo of Elsa pinned first (so a new player's
## hut already feels lived in), then the player's best postcards on the left wall; finds
## on shelves on the right (Elsa's traces first) beside a lantern; earned badges stitched
## on like patches above the stove. Every keepsake is a door: Elsa's photo opens the
## journey, postcards the journal, the shelf the journal's finds, patches the profile.

const CARD: Color = Color("#FFFDF7")
const PIN: Color = Color("#D9483B")
const SHELF: Color = Color("#A87650")
const SHELF_EDGE: Color = Color("#5C3A25")
const SEPIA_LIGHT: Color = Color("#E9D6B0")
const SEPIA_MID: Color = Color("#B89A6E")
const SEPIA_DARK: Color = Color("#6E5638")
const BRASS: Color = Color("#C9A24A")
const FLAME: Color = Color("#FFC861")
const FIND_SIZE: float = 62.0
const SHELF_GAP: float = 104.0
const PATCH_RADIUS: float = 15.0
const CARD_TOP: float = 128.0
const CARD_GAP: float = 24.0
## Tilts for the pinned cards (degrees), so they look hand-pinned.
const TILTS: Array[float] = [-4.0, 3.0, -2.0]

var room: HutRoom
var _cards: Array[Dictionary] = []
var _finds: Array[FindData] = []
var _badges: Array[BadgeData] = []
var _find_arts: Array[FindArt] = []
## Where each pinned card sits (untilted), Elsa's first; for taps.
var _card_rects: Array[Rect2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_layout)


## `cards` are the player's postcards (Elsa's photo is always added in front of them).
func fill(cards: Array[Dictionary], finds: Array[FindData], badges: Array[BadgeData]) -> void:
	_cards = cards
	_finds = finds
	_badges = badges
	for art: FindArt in _find_arts:
		art.queue_free()
	_find_arts.clear()
	for f: FindData in _finds:
		var art: FindArt = FindArt.new()
		art.kind = f.kind
		art.color = f.color
		art.found = true
		art.size = Vector2(FIND_SIZE, FIND_SIZE)
		add_child(art)
		_find_arts.append(art)
	_layout()


## Room for the lantern at the end of the top shelf.
func _per_shelf() -> int:
	return maxi(1, int((room.wall_width() - 30.0) / FIND_SIZE))


func _shelf_y(i: int) -> float:
	return 166.0 + SHELF_GAP * i


func _shelf_count() -> int:
	return clampi(ceili(float(_finds.size() + 1) / float(_per_shelf())), 1, 3)


## Slot n on the shelves; slot 0 is the lantern's.
func _slot_position(n: int) -> Vector2:
	var per: int = _per_shelf()
	var w: float = room.wall_width()
	var x0: float = size.x - w + HutRoom.FRAME_WIDTH
	var inner: float = w - HutRoom.FRAME_WIDTH
	var shelf: int = n / per
	var in_row: int = mini(per, _finds.size() + 1 - shelf * per)
	var start: float = x0 + (inner - in_row * FIND_SIZE) * 0.5
	return Vector2(start + (n % per) * FIND_SIZE, _shelf_y(shelf) - FIND_SIZE + 6.0)


func _layout() -> void:
	if room == null:
		return
	var light: float = room.room_light()
	for i: int in _find_arts.size():
		var art: FindArt = _find_arts[i]
		art.visible = (i + 1) / _per_shelf() < 3
		art.position = _slot_position(i + 1)
		art.modulate = Color(light, light, light)
	_card_rects.clear()
	var w: float = room.wall_width() - HutRoom.FRAME_WIDTH
	var cw: float = minf(w - 40.0, 176.0)
	if cw >= 60.0:
		var ch: float = cw * 0.68
		var bottom: float = room.seat_top() - 20.0
		for i: int in _cards.size() + 1:
			var y: float = CARD_TOP + i * (ch + CARD_GAP)
			if y + ch > bottom:
				break
			_card_rects.append(Rect2(Vector2((w - cw) * 0.5, y), Vector2(cw, ch)))
	queue_redraw()


func _draw() -> void:
	if room == null:
		return
	var light: float = room.room_light()
	var shade: Color = Color(light, light, light)
	for i: int in _card_rects.size():
		_draw_card(i, _card_rects[i], shade)
	_draw_shelves(shade)
	_draw_lantern(_slot_position(0) + Vector2(FIND_SIZE * 0.5, FIND_SIZE - 6.0), shade)
	_draw_patches(shade)


func _draw_card(i: int, rect: Rect2, shade: Color) -> void:
	draw_set_transform(rect.get_center(), deg_to_rad(TILTS[i % TILTS.size()]), Vector2.ONE)
	var r: Rect2 = Rect2(-rect.size * 0.5, rect.size)
	draw_rect(Rect2(r.position + Vector2(3, 5), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, (SEPIA_LIGHT.lightened(0.3) if i == 0 else CARD) * shade)
	var pic: Rect2 = r.grow(-6)
	pic.size.y -= 14 if i == 0 else 8
	if i == 0:
		_draw_elsa(pic, shade)
		draw_string(get_theme_default_font(), Vector2(r.position.x, r.end.y - 4), tr("HUT_ELSA_PHOTO"),
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, SEPIA_DARK * shade)
	else:
		var tex: Texture2D = _picture(_cards[i - 1])
		if tex != null:
			draw_texture_rect(tex, pic, false, shade)
		else:
			draw_rect(pic, Color("#8FC1D8") * shade)
			draw_rect(Rect2(pic.position + Vector2(0, pic.size.y * 0.6), Vector2(pic.size.x, pic.size.y * 0.4)), Color("#5E8C4A") * shade)
	draw_circle(Vector2(0, r.position.y + 6), 6.0, PIN * shade)
	draw_circle(Vector2(-2, r.position.y + 4), 2.0, Color(1, 1, 1, 0.6))
	draw_set_transform(Vector2.ZERO)


## An old sepia snapshot: fells, a cairn, and Elsa on top with her arms up.
func _draw_elsa(pic: Rect2, shade: Color) -> void:
	draw_rect(pic, SEPIA_LIGHT * shade)
	var p: Vector2 = pic.position
	var s: Vector2 = pic.size
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, s.y * 0.7), p + Vector2(s.x * 0.28, s.y * 0.3),
		p + Vector2(s.x * 0.5, s.y * 0.55), p + Vector2(s.x * 0.72, s.y * 0.22), p + Vector2(s.x, s.y * 0.62),
		p + s, p + Vector2(0, s.y)]), SEPIA_MID * shade)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, s.y * 0.88), p + Vector2(s.x * 0.45, s.y * 0.7),
		p + Vector2(s.x, s.y * 0.84), p + s, p + Vector2(0, s.y)]), SEPIA_DARK * shade)
	# Elsa on the knoll: legs, coat, head, arms raised.
	var f: Vector2 = p + Vector2(s.x * 0.45, s.y * 0.7)
	var u: float = s.y / 70.0
	draw_line(f, f + Vector2(-3, -9) * u, SEPIA_DARK.darkened(0.4) * shade, 2.0 * u)
	draw_line(f + Vector2(3, 0), f + Vector2(1, -9) * u, SEPIA_DARK.darkened(0.4) * shade, 2.0 * u)
	draw_rect(Rect2(f + Vector2(-4, -20) * u, Vector2(8, 12) * u), SEPIA_DARK.darkened(0.5) * shade)
	draw_circle(f + Vector2(0, -24) * u, 3.5 * u, SEPIA_DARK.darkened(0.5) * shade)
	draw_line(f + Vector2(-3, -18) * u, f + Vector2(-9, -28) * u, SEPIA_DARK.darkened(0.5) * shade, 1.8 * u)
	draw_line(f + Vector2(3, -18) * u, f + Vector2(9, -28) * u, SEPIA_DARK.darkened(0.5) * shade, 1.8 * u)
	# Age: a faded corner.
	draw_colored_polygon(PackedVector2Array([pic.position, pic.position + Vector2(s.x * 0.22, 0),
		pic.position + Vector2(0, s.y * 0.3)]), Color(1, 1, 1, 0.25))


func _picture(card: Dictionary) -> Texture2D:
	var vp: ViewpointData = card.viewpoint
	if vp.postcard != null:
		return vp.postcard
	return (card.trail as TrailData).postcard


func _draw_shelves(shade: Color) -> void:
	var r: Rect2 = _shelf_area()
	for i: int in _shelf_count():
		var y: float = _shelf_y(i)
		draw_rect(Rect2(r.position.x, y, r.size.x, 10), SHELF * shade)
		draw_rect(Rect2(r.position.x, y + 10, r.size.x, 3), SHELF_EDGE * shade)
		# Brackets under each end.
		for bx: float in [r.position.x + 10.0, r.end.x - 18.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(bx, y + 10), Vector2(bx + 8, y + 10), Vector2(bx, y + 28)]), SHELF_EDGE * shade)


func _shelf_area() -> Rect2:
	var w: float = room.wall_width()
	var x0: float = size.x - w + HutRoom.FRAME_WIDTH + 8.0
	var top: float = _shelf_y(0) - FIND_SIZE
	return Rect2(x0, top, size.x - 8.0 - x0, _shelf_y(_shelf_count() - 1) + 14.0 - top)


## A brass lantern: always on the shelf, so even an empty shelf looks kept.
func _draw_lantern(base: Vector2, shade: Color) -> void:
	var night: bool = room.phase == HutView.Phase.NIGHT or room.phase == HutView.Phase.DUSK
	if night:
		for k: int in 4:
			draw_circle(base + Vector2(0, -22), 18.0 + 12.0 * k, Color(FLAME, 0.09 / float(k + 1)))
	draw_rect(Rect2(base + Vector2(-13, -6), Vector2(26, 6)), BRASS.darkened(0.25) * shade)
	draw_rect(Rect2(base + Vector2(-10, -36), Vector2(20, 30)), Color(FLAME, 0.85) if night else Color("#F3E7C9") * shade)
	draw_rect(Rect2(base + Vector2(-10, -36), Vector2(20, 30)), BRASS * shade, false, 2.5)
	draw_line(base + Vector2(0, -36), base + Vector2(0, -6), BRASS * shade, 2.0)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-13, -36), base + Vector2(0, -46), base + Vector2(13, -36)]), BRASS.darkened(0.25) * shade)
	draw_arc(base + Vector2(0, -50), 5.0, PI, TAU, 10, BRASS * shade, 2.0)


func _patch_area() -> Rect2:
	var w: float = room.wall_width() - HutRoom.FRAME_WIDTH
	var y: float = room.stove_rect().position.y - 34.0
	return Rect2(Vector2(size.x - w, y - PATCH_RADIUS - 6.0), Vector2(w, PATCH_RADIUS * 2.0 + 12.0))


## Earned badges as round stitched patches in a row above the stove.
func _draw_patches(shade: Color) -> void:
	if _badges.is_empty():
		return
	var area: Rect2 = _patch_area()
	if area.position.y < _shelf_y(_shelf_count() - 1) + 30.0:
		return
	var step: float = PATCH_RADIUS * 2.0 + 8.0
	var shown: int = mini(_badges.size(), maxi(1, int((area.size.x - 16.0) / step)))
	var start: float = area.get_center().x - (shown - 1) * step * 0.5
	for i: int in shown:
		var c: Vector2 = Vector2(start + i * step, area.get_center().y)
		var col: Color = _badges[i].color
		draw_circle(c, PATCH_RADIUS + 2.0, col.darkened(0.35) * shade)
		draw_circle(c, PATCH_RADIUS, col * shade)
		draw_arc(c, PATCH_RADIUS - 3.5, 0.0, TAU, 24, Color(1, 1, 1, 0.55) * shade, 1.5, true)
		# A tiny peak: every badge in this game is about a mountain somewhere.
		draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 5), c + Vector2(0, -7), c + Vector2(8, 5)]), Color(1, 1, 1, 0.85) * shade)


## Which screen a tap at `at` opens ("" = not on a keepsake).
func target_at(at: Vector2) -> String:
	for i: int in _card_rects.size():
		if _card_rects[i].grow(6).has_point(at):
			return SceneRouter.JOURNEY if i == 0 else SceneRouter.JOURNAL
	if _shelf_area().has_point(at):
		return "finds"
	if not _badges.is_empty() and _patch_area().has_point(at):
		return SceneRouter.PROFILE
	return ""


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	var target: String = target_at(event.position)
	if target == "":
		return
	accept_event()
	if target == "finds":
		Journal.open_finds = true
		target = SceneRouter.JOURNAL
	SceneRouter.go_to(target)
