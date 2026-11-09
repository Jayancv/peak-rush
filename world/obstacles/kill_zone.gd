@tool
class_name KillZone
extends HikerArea
## Put this below a gap or ledge. Falling into it sends the hiker back to the last
## checkpoint (the trail runner handles the respawn and stamina cost).

@export var size: Vector2 = Vector2(300, 120):
	set(v):
		size = v
		rebuild()
		queue_redraw()


func build() -> void:
	ShapeUtil.add_rect_shape(self, Rect2(-size * 0.5, size))


func _draw() -> void:
	# Only visible while editing, so designers can see where the danger is.
	if Engine.is_editor_hint():
		draw_rect(Rect2(-size * 0.5, size), Color(0.9, 0.2, 0.2, 0.25))


func _hiker_entered(hiker: Hiker) -> void:
	hiker.fall_out()
