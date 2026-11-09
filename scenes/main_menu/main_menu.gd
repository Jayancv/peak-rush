extends Control
## Placeholder title screen: one Play button into the (empty) trail runner.

@export var play_button: Button


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	SceneRouter.go_to(SceneRouter.TRAIL_RUNNER)


func _notification(what: int) -> void:
	# Android back on the title screen leaves the app, as players expect.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
