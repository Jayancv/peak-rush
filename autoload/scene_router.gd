extends CanvasLayer
## Changes scenes behind a short fade. Every screen change goes through here so
## transitions look the same everywhere and double taps can't start two changes.

signal transition_finished(path: String)

const MAIN_MENU: String = "res://scenes/main_menu/main_menu.tscn"
const TRAIL_SELECT: String = "res://scenes/trail_select/trail_select.tscn"
const TRAIL_RUNNER: String = "res://scenes/trail_runner/trail_runner.tscn"
const RESULTS: String = "res://scenes/results/results.tscn"
const JOURNAL: String = "res://scenes/journal/journal.tscn"
const SETTINGS: String = "res://scenes/settings/settings.tscn"
const GEAR: String = "res://scenes/gear/gear_screen.tscn"
const PROFILE: String = "res://scenes/profile/profile.tscn"

## UI timing, not gameplay tuning, so it stays here instead of balance.tres.
const FADE_SECONDS: float = 0.25
const FADE_COLOR: Color = Color("#2B2D42")

var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	# Above every gameplay and HUD layer.
	layer = 100
	# Must keep running while the tree is paused (e.g. quitting from a pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color(FADE_COLOR, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	UiMotion.watch(get_tree())


func is_busy() -> bool:
	return _busy


## Starts a faded change to the scene at `path`. Returns false (and changes nothing)
## if a transition is already running or the scene doesn't exist.
func go_to(path: String) -> bool:
	if _busy:
		return false
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: scene not found: %s" % path)
		return false
	_transition(path)
	return true


## Fades to dark, runs `midpoint` while the screen is covered, then fades back.
## Used for in-scene jumps like respawning after a fall.
func cover(midpoint: Callable) -> bool:
	if _busy:
		return false
	_cover(midpoint)
	return true


func _cover(midpoint: Callable) -> void:
	# Touches stay unblocked here: swallowing a finger-lift mid-fade would leave walk held.
	_busy = true
	await _fade_to(1.0)
	midpoint.call()
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false


func _transition(path: String) -> void:
	_busy = true
	# Swallow taps during the fade so the old scene's buttons can't fire again.
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)
	get_tree().paused = false
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: failed to change to %s (error %d)" % [path, err])
	# The new scene is added at the end of this frame.
	await get_tree().process_frame
	await _fade_to(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	transition_finished.emit(path)


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	# Eased both ways so the fade glides instead of starting and stopping abruptly.
	tween.tween_property(_fade, "color:a", alpha, FADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
