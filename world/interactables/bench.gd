@tool
class_name TrailBench
extends HikerArea
## Resting here refills stamina twice as fast as resting anywhere else.

@export var width: float = 96.0:
	set(v):
		width = v
		rebuild()

const WOOD: Color = Color("#8C6A4A")
const WOOD_DARK: Color = Color("#6B4F35")
const HINT_BG: Color = Color(1, 0.964706, 0.898039, 0.92)
const HINT_TEXT: Color = Color("#2E7D4F")
## The hint bubble floats this high above the path and bobs this much.
const HINT_HEIGHT: float = 104.0
const HINT_BOB: float = 6.0
## While the hiker sits here the hint steps back; the HUD takes over.
const HINT_OCCUPIED_ALPHA: float = 0.2

var _hint: PanelContainer


func build() -> void:
	var half: float = width * 0.5
	for x: float in [-half + 8.0, half - 14.0]:
		ShapeUtil.add_poly(self, PackedVector2Array([Vector2(x, -26), Vector2(x + 6, -26), Vector2(x + 6, 0), Vector2(x, 0)]), WOOD_DARK)
		ShapeUtil.add_poly(self, PackedVector2Array([Vector2(x, -52), Vector2(x + 6, -52), Vector2(x + 6, -26), Vector2(x, -26)]), WOOD_DARK)
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-half, -30, width, 8), 3.0), WOOD)
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-half + 2, -52, width - 4, 7), 3.0), WOOD)
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-half + 2, -42, width - 4, 6), 3.0), WOOD)
	_build_hint()
	# Generous area: anywhere in front of the bench counts as sitting at it.
	ShapeUtil.add_rect_shape(self, Rect2(-half - 20.0, -70.0, width + 40.0, 74.0))


func _build_hint() -> void:
	_hint = PanelContainer.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = HINT_BG
	box.set_corner_radius_all(18)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 6.0
	_hint.add_theme_stylebox_override("panel", box)
	var label: Label = Label.new()
	label.text = "BENCH_HINT"
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", HINT_TEXT)
	_hint.add_child(label)
	add_child(_hint, false, Node.INTERNAL_MODE_BACK)
	# Centre over the bench once the bubble knows its size.
	_hint.resized.connect(func() -> void: _hint.position.x = -_hint.size.x * 0.5)
	_hint.position = Vector2(-60.0, -HINT_HEIGHT)
	if not Engine.is_editor_hint():
		var bob: Tween = create_tween().set_loops()
		bob.tween_property(_hint, "position:y", -HINT_HEIGHT - HINT_BOB, 0.9).set_trans(Tween.TRANS_SINE)
		bob.tween_property(_hint, "position:y", -HINT_HEIGHT, 0.9).set_trans(Tween.TRANS_SINE)


func _hiker_entered(hiker: Hiker) -> void:
	hiker.condition.enter_bench()
	if _hint != null:
		create_tween().tween_property(_hint, "modulate:a", HINT_OCCUPIED_ALPHA, 0.3)


func _hiker_exited(hiker: Hiker) -> void:
	hiker.condition.exit_bench()
	if _hint != null:
		create_tween().tween_property(_hint, "modulate:a", 1.0, 0.3)
