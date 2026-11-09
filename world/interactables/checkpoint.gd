@tool
class_name TrailCheckpoint
extends HikerArea
## A trail marker post. Walking past it makes it the respawn point after a fall.
## Place its origin on the path: the hiker respawns standing right here.

const POST: Color = Color("#6B4F35")
const IDLE_FLAG: Color = Color("#C9C3B4")
const LIT_FLAG: Color = Color("#E85D3F")
## Respawn a little above the path so the hiker settles onto it.
const RESPAWN_LIFT: float = 6.0

var activated: bool = false
var _flag: Polygon2D


func build() -> void:
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-3, -70, 6, 70), 2.0), POST)
	# Painted trail blaze on a little flag.
	_flag = ShapeUtil.add_poly(self, PackedVector2Array([Vector2(3, -68), Vector2(30, -60), Vector2(3, -50)]), LIT_FLAG if activated else IDLE_FLAG)
	ShapeUtil.add_rect_shape(self, Rect2(-24, -120, 48, 124))


func _hiker_entered(hiker: Hiker) -> void:
	if activated:
		return
	activated = true
	if _flag != null:
		_flag.color = LIT_FLAG
		# A small pop so the player notices the save point.
		_flag.scale = Vector2(1.5, 1.5)
		create_tween().tween_property(_flag, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	hiker.touch_checkpoint(global_position + Vector2(0, -RESPAWN_LIFT))
