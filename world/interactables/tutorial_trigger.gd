@tool
class_name TutorialTrigger
extends HikerArea
## An invisible hint zone: the first time the hiker walks in, it asks the trail
## runner to show `message_key`. Only shown on trails marked `tutorial`, until the
## player has finished that trail once.

signal triggered(message_key: String, seconds: float)

const GROUP: StringName = &"tutorial_trigger"

@export var message_key: String = ""
@export var seconds: float = 4.0
@export var size: Vector2 = Vector2(80, 200):
	set(v):
		size = v
		rebuild()
		queue_redraw()

var _done: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	super()


func build() -> void:
	ShapeUtil.add_rect_shape(self, Rect2(Vector2(-size.x * 0.5, -size.y), size))


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(-size.x * 0.5, -size.y), size), Color(0.3, 0.6, 1.0, 0.2))


func _hiker_entered(_hiker: Hiker) -> void:
	if not _done:
		_done = true
		triggered.emit(message_key, seconds)
