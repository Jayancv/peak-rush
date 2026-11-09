extends Control
## Title screen: a postcard-style title card over a slowly panning panorama,
## with the hiker resting on a hill. Play opens trail select.

## Gentle pan of the scenery behind the menu (px/s at full parallax depth). UI motion, not gameplay.
const PAN_SPEED: float = 22.0

@export var play_button: Button
@export var journal_button: Button
@export var backdrop: Node


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	journal_button.pressed.connect(func() -> void: SceneRouter.go_to(SceneRouter.JOURNAL))
	if not DisplayServer.is_touchscreen_available():
		play_button.grab_focus()
	_start_panning()


func _start_panning() -> void:
	if backdrop == null:
		return
	for child: Node in backdrop.get_children():
		var layer: Parallax2D = child as Parallax2D
		if layer != null:
			# Nearer layers move faster, which is what sells the depth.
			layer.autoscroll.x -= PAN_SPEED * layer.scroll_scale.x


func _on_play_pressed() -> void:
	SceneRouter.go_to(SceneRouter.TRAIL_SELECT)


func _notification(what: int) -> void:
	# Android back on the title screen leaves the app, as players expect.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
