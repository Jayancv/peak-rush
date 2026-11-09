@tool
class_name SteppingStones
extends Node2D
## A shallow stream crossed by hopping stone to stone. The origin is the left bank at
## path height; put terrain strips ending/starting at x = 0 and x = total_width().
## Missing a stone drops the hiker in the water: wet feet (extra drain for a while)
## and a jump out over the stone or the bank.

@export var stone_count: int = 3:
	set(v):
		stone_count = maxi(v, 1)
		_rebuild()
@export var stone_width: float = 44.0:
	set(v):
		stone_width = v
		_rebuild()
## Water between stones. Must be under the jump distance (about 90 px at walk speed).
@export var gap: float = 72.0:
	set(v):
		gap = v
		_rebuild()
@export var depth: float = 58.0:
	set(v):
		depth = v
		_rebuild()

const WATER: Color = Color("#5FA8C8")
const WATER_LIGHT: Color = Color("#A8D8EA")
const STONE: Color = Color("#8C8B84")
const STONE_TOP: Color = Color("#C4C2BA")
const BED: Color = Color("#4A7359")
## Stone tops stand this far above the banks so they read as stepping stones.
const STONE_RISE: float = 10.0
## The water surface sits this far below the banks.
const WATER_DROP: float = 16.0

var _ready_done: bool = false


func _ready() -> void:
	_ready_done = true
	_rebuild()


func total_width() -> float:
	return gap + float(stone_count) * (stone_width + gap)


func _rebuild() -> void:
	if not _ready_done:
		return
	ShapeUtil.clear_internal(self)
	var w: float = total_width()
	# Stream bed: solid ground under the water so a miss means wet feet, not a fall.
	var bed: StaticBody2D = StaticBody2D.new()
	add_child(bed, false, Node.INTERNAL_MODE_BACK)
	ShapeUtil.add_poly(bed, PackedVector2Array([Vector2(0, depth), Vector2(w, depth), Vector2(w, depth + 400), Vector2(0, depth + 400)]), BED)
	ShapeUtil.add_rect_shape(bed, Rect2(0, depth, w, 60))
	for i: int in stone_count:
		var x: float = gap + float(i) * (stone_width + gap)
		var stone: StaticBody2D = StaticBody2D.new()
		add_child(stone, false, Node.INTERNAL_MODE_BACK)
		var body_rect: Rect2 = Rect2(x, -STONE_RISE, stone_width, depth + STONE_RISE)
		ShapeUtil.add_poly(stone, ShapeUtil.rounded_rect(body_rect, 12.0), STONE, 2)
		ShapeUtil.add_poly(stone, ShapeUtil.rounded_rect(Rect2(x + 5, -STONE_RISE + 2.0, stone_width - 10, 8), 4.0), STONE_TOP, 2)
		ShapeUtil.add_rect_shape(stone, body_rect)
	# Water draws over the hiker (z 1) so wading looks like wading.
	var water_rect: PackedVector2Array = PackedVector2Array([Vector2(0, WATER_DROP), Vector2(w, WATER_DROP), Vector2(w, depth), Vector2(0, depth)])
	var water_poly: Polygon2D = ShapeUtil.add_poly(self, water_rect, Color(WATER, 0.85), 1)
	water_poly.vertex_colors = PackedColorArray([Color(WATER, 0.8), Color(WATER, 0.8), Color(WATER.darkened(0.3), 0.95), Color(WATER.darkened(0.3), 0.95)])
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(0, WATER_DROP - 1), Vector2(w, WATER_DROP - 1), Vector2(w, WATER_DROP + 2), Vector2(0, WATER_DROP + 2)]), WATER_LIGHT, 1)
	var water: Area2D = Area2D.new()
	water.collision_layer = 0
	water.collision_mask = HikerArea.HIKER_LAYER
	water.monitorable = false
	add_child(water, false, Node.INTERNAL_MODE_BACK)
	ShapeUtil.add_rect_shape(water, Rect2(0, WATER_DROP + 6.0, w, depth - WATER_DROP))
	if not Engine.is_editor_hint():
		water.body_entered.connect(_on_water_entered)


func _on_water_entered(body: Node2D) -> void:
	var hiker: Hiker = body as Hiker
	if hiker != null:
		hiker.condition.soak_feet()
