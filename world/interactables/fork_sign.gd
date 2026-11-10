@tool
class_name ForkSign
extends Node2D
## A trail signpost at a fork: the upper board points up to the ridge route (jump up
## onto the boardwalk), the lower one straight on along the valley path.

const POST: Color = Color("#5C4332")
const BOARD: Color = Color("#E8D9B5")
const BOARD_EDGE: Color = Color("#8A6A45")
const INK: Color = Color("#2B2D42")

func _ready() -> void:
	ShapeUtil.clear_internal(self)
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-2.5, 4), Vector2(2.5, 4), Vector2(2, -64), Vector2(-2, -64)]), POST)
	_board(-58.0, "SIGN_RIDGE", true)
	_board(-36.0, "SIGN_VALLEY", false)


func _board(y: float, key: String, up: bool) -> void:
	# Each board hangs on its own pivot on the post, so the ridge board can tilt up.
	var pivot: Node2D = Node2D.new()
	pivot.position = Vector2(0, y)
	pivot.rotation = -0.35 if up else 0.0
	add_child(pivot, false, Node.INTERNAL_MODE_BACK)
	var tip: float = 54.0
	var pts: PackedVector2Array = PackedVector2Array([Vector2(-4, -8), Vector2(tip - 8, -8), Vector2(tip, 0), Vector2(tip - 8, 8), Vector2(-4, 8)])
	ShapeUtil.add_poly(pivot, pts, BOARD)
	var edge: Line2D = Line2D.new()
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	edge.points = closed
	edge.width = 1.2
	edge.default_color = BOARD_EDGE
	pivot.add_child(edge, false, Node.INTERNAL_MODE_BACK)
	var label: Label = Label.new()
	label.text = tr(key)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", INK)
	label.position = Vector2(-1, -8)
	label.size = Vector2(tip - 6, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pivot.add_child(label, false, Node.INTERNAL_MODE_BACK)
