@tool
class_name TrailFinish
extends HikerArea
## The summit cairn. Reaching it ends the hike.

const STONES: Array[Color] = [Color("#7E7C75"), Color("#8C8B84"), Color("#9C9A92"), Color("#ABA9A1"), Color("#B9B7AF")]
const POLE: Color = Color("#6B4F35")
const PENNANT: Color = Color("#E85D3F")


func build() -> void:
	# A stack of flat stones, each a bit smaller than the one below.
	var y: float = 0.0
	for i: int in STONES.size():
		var r: Vector2 = Vector2(30.0 - i * 5.0, 8.0 - i * 0.6)
		y -= r.y
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(i % 2 * 2.0 - 1.0, y), r, 16), STONES[i])
		y -= r.y * 0.85
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-1.5, y - 50), Vector2(1.5, y - 50), Vector2(1.5, y + 4), Vector2(-1.5, y + 4)]), POLE)
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(1.5, y - 50), Vector2(30, y - 42), Vector2(1.5, y - 34)]), PENNANT)
	ShapeUtil.add_rect_shape(self, Rect2(-40, -140, 80, 144))


func _hiker_entered(hiker: Hiker) -> void:
	hiker.reach_finish()
