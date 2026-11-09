extends Node2D
## Runs one trail: instances the level, spawns the hiker at its Trailhead and
## wires up the camera. M3 swaps the exported trail scene for a TrailData lookup.
## Until the pause menu exists (M2), back/pause returns to the main menu.

@export var trail_scene: PackedScene
@export var hiker_scene: PackedScene
@export var world: Node2D
@export var camera: HikerCamera
@export var back_button: Button

var hiker: Hiker


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	_load_trail()


func _load_trail() -> void:
	var trail: Node2D = trail_scene.instantiate() as Node2D
	world.add_child(trail)
	var trailhead: Marker2D = trail.get_node_or_null("Trailhead") as Marker2D
	if trailhead == null:
		push_error("TrailRunner: trail has no Trailhead marker")
		return
	hiker = hiker_scene.instantiate() as Hiker
	world.add_child(hiker)
	hiker.teleport(trailhead.global_position)
	camera.target = hiker
	camera.set_bounds(TerrainStrip.bounds_under(trail))
	camera.snap_to_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _go_back() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)
