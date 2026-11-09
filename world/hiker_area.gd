@tool
class_name HikerArea
extends Area2D
## Base for trail pieces that react when the hiker walks in or out (roots, patches,
## benches, checkpoints...). Subclasses override build() for their look and shape,
## and _hiker_entered()/_hiker_exited() for the effect.

const HIKER_LAYER: int = 2

var _ready_done: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = HIKER_LAYER
	monitorable = false
	_ready_done = true
	rebuild()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)



## Clears and rebuilds generated children. Safe to call from export setters
## (which also fire while the scene is still loading, before _ready).
func rebuild() -> void:
	if not _ready_done:
		return
	ShapeUtil.clear_internal(self)
	build()


func build() -> void:
	pass


func _hiker_entered(_hiker: Hiker) -> void:
	pass


func _hiker_exited(_hiker: Hiker) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	var hiker: Hiker = body as Hiker
	if hiker != null:
		_hiker_entered(hiker)


func _on_body_exited(body: Node2D) -> void:
	var hiker: Hiker = body as Hiker
	if hiker != null:
		_hiker_exited(hiker)
