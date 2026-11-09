class_name TouchControls
extends Control
## Turns touches into input actions: hold one half of the screen to walk, tap the
## other half to jump. Gameplay never sees touches, only the walk/jump actions.
## Each finger keeps the role it started with, so sliding across the middle doesn't flip it.

## Buttons (pause, back...) join this group so touching them never walks or jumps.
const BLOCKER_GROUP: StringName = &"touch_blocker"
const HINT_IDLE_ALPHA: float = 0.35
const HINT_ACTIVE_ALPHA: float = 0.8

## Swaps the halves: walk on the right, jump on the left.
@export var left_handed: bool = false:
	set(value):
		left_handed = value
		_release_all()
		_update_hints()
@export var left_hint: Control
@export var left_hint_label: Label
@export var right_hint: Control
@export var right_hint_label: Label

## finger index -> action it controls
var _fingers: Dictionary[int, StringName] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_handed = bool(GameState.settings.get("left_handed", false))
	GameState.settings_changed.connect(_on_settings_changed)
	_update_hints()


func _exit_tree() -> void:
	_release_all()


func _notification(what: int) -> void:
	# A finger lifted while the app was in the background would otherwise leave walk stuck on.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_all()


func _unhandled_input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch == null:
		return
	if touch.pressed:
		if _is_over_blocker(touch.position):
			return
		var action: StringName = action_for_position(touch.position)
		_fingers[touch.index] = action
		Input.action_press(action)
	elif _fingers.has(touch.index):
		var action: StringName = _fingers[touch.index]
		_fingers.erase(touch.index)
		# Two fingers can hold walk; only let go when the last one lifts.
		if not _fingers.values().has(action):
			Input.action_release(action)
	else:
		return
	_update_hints()
	get_viewport().set_input_as_handled()


func action_for_position(pos: Vector2) -> StringName:
	var on_left: bool = pos.x < get_viewport_rect().size.x * 0.5
	return &"walk" if on_left != left_handed else &"jump"


func _is_over_blocker(pos: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group(BLOCKER_GROUP):
		var control: Control = node as Control
		if control != null and control.is_visible_in_tree() and control.get_global_rect().has_point(pos):
			return true
	return false


func _release_all() -> void:
	for action: StringName in _fingers.values():
		Input.action_release(action)
	_fingers.clear()
	_update_hints()


func _on_settings_changed() -> void:
	left_handed = bool(GameState.settings.get("left_handed", false))


func _update_hints() -> void:
	if left_hint_label == null or right_hint_label == null:
		return
	left_hint_label.text = "TOUCH_HINT_JUMP" if left_handed else "TOUCH_HINT_WALK"
	right_hint_label.text = "TOUCH_HINT_WALK" if left_handed else "TOUCH_HINT_JUMP"
	var walk_held: bool = _fingers.values().has(&"walk")
	var jump_held: bool = _fingers.values().has(&"jump")
	var left_held: bool = jump_held if left_handed else walk_held
	var right_held: bool = walk_held if left_handed else jump_held
	left_hint.modulate.a = HINT_ACTIVE_ALPHA if left_held else HINT_IDLE_ALPHA
	right_hint.modulate.a = HINT_ACTIVE_ALPHA if right_held else HINT_IDLE_ALPHA
