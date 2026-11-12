@tool
class_name EventToken
extends HikerArea
## A seasonal collectible on the path (golden leaf, lantern, blossom, wild berry). Walking
## through it collects it: it pops up and fades, and `collected` tells the HikeTracker.

signal collected

@export var kind: EventData.Token = EventData.Token.LEAF:
	set(v):
		kind = v
		rebuild()
@export var color: Color = Color("#E0A030"):
	set(v):
		color = v
		rebuild()

var _taken: bool = false
var _t: float = 0.0


func build() -> void:
	var c: Vector2 = Vector2(0, -34)
	match kind:
		EventData.Token.LEAF:
			ShapeUtil.add_poly(self, PackedVector2Array([c + Vector2(0, -14), c + Vector2(9, -4), c + Vector2(6, 8), c + Vector2(0, 12), c + Vector2(-6, 8), c + Vector2(-9, -4)]), color)
			ShapeUtil.add_poly(self, PackedVector2Array([c + Vector2(-0.8, -10), c + Vector2(0.8, -10), c + Vector2(0.8, 16), c + Vector2(-0.8, 16)]), color.darkened(0.35))
		EventData.Token.LANTERN:
			ShapeUtil.add_poly(self, ShapeUtil.ellipse(c, Vector2(16, 16), 14), Color(color, 0.28))
			ShapeUtil.add_poly(self, ShapeUtil.ellipse(c, Vector2(8, 10), 12), color)
			ShapeUtil.add_poly(self, PackedVector2Array([c + Vector2(-5, -10), c + Vector2(5, -10), c + Vector2(4, -13), c + Vector2(-4, -13)]), color.darkened(0.5))
		EventData.Token.BLOSSOM:
			for i: int in 5:
				var a: float = TAU * i / 5.0 - PI * 0.5
				ShapeUtil.add_poly(self, ShapeUtil.ellipse(c + Vector2(cos(a), sin(a)) * 7.0, Vector2(5.5, 5.5), 10), color)
			ShapeUtil.add_poly(self, ShapeUtil.ellipse(c, Vector2(3.5, 3.5), 8), Color("#F5D35A"))
		EventData.Token.BERRY:
			ShapeUtil.add_poly(self, PackedVector2Array([c + Vector2(-8, -4), c + Vector2(8, -4), c + Vector2(0, 11)]), color)
			ShapeUtil.add_poly(self, PackedVector2Array([c + Vector2(-7, -5), c + Vector2(0, -11), c + Vector2(7, -5)]), Color("#4C8A3C"))
	ShapeUtil.add_rect_shape(self, Rect2(-16.0, -60.0, 32.0, 60.0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if not _taken:
		position.y += sin(_t * 2.6) * 0.15
		rotation = sin(_t * 1.7) * 0.12


func _hiker_entered(_hiker: Hiker) -> void:
	if _taken:
		return
	_taken = true
	collected.emit()
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 40.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
