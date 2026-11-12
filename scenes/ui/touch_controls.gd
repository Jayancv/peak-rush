class_name TouchControls
extends Control
## Turns touches into input actions: hold one half of the screen to walk (double-tap and
## hold to hurry), tap the other half to jump (hold for a higher jump), hold the small Back
## pad (above the walk hint) to walk back towards the last checkpoint, and the Duck pad
## (above the jump hint) to crouch under low branches. Gameplay never sees touches, only the actions.
## Each finger keeps the role it started with, so sliding across the middle doesn't flip it.

## Buttons (pause, back...) join this group so touching them never walks or jumps.
const BLOCKER_GROUP: StringName = &"touch_blocker"
const HINT_IDLE_ALPHA: float = 0.35
const HINT_ACTIVE_ALPHA: float = 0.8

## Swaps the halves: walk on the right, jump on the left.
@export var left_handed: bool = false:
	set(value):
		left_handed = value
		release_all()
		_update_hints()
@export var left_hint: Control
@export var left_hint_label: Label
@export var left_hint_icon: UiIcon
@export var right_hint: Control
@export var right_hint_label: Label
@export var right_hint_icon: UiIcon

## finger index -> action it controls
var _fingers: Dictionary[int, StringName] = {}
var _back_pad: Control
var _back_column: VBoxContainer
var _duck_pad: Control
var _duck_column: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_back_pad()
	_build_duck_pad()
	left_handed = bool(GameState.settings.get("left_handed", false))
	GameState.settings_changed.connect(_on_settings_changed)
	_update_hints()


## A copy of the walk hint with a back arrow, stacked just above it.
func _build_back_pad() -> void:
	if left_hint == null:
		return
	var safe: Node = left_hint.get_parent().get_parent()
	_back_column = VBoxContainer.new()
	_back_column.size_flags_vertical = Control.SIZE_SHRINK_END
	_back_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(_back_column)
	_back_pad = left_hint.duplicate() as Control
	_back_column.add_child(_back_pad)
	var icon: UiIcon = _back_pad.find_child("Icon", true, false) as UiIcon
	if icon != null:
		icon.kind = UiIcon.Kind.BACK
	var label: Label = _back_pad.find_child("Label", true, false) as Label
	if label != null:
		label.text = "TOUCH_HINT_BACK"
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, left_hint.get_combined_minimum_size().y + 14.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_column.add_child(spacer)


## A copy of the jump hint with a down arrow, stacked just above it.
func _build_duck_pad() -> void:
	if right_hint == null:
		return
	var safe: Node = right_hint.get_parent().get_parent()
	_duck_column = VBoxContainer.new()
	_duck_column.size_flags_vertical = Control.SIZE_SHRINK_END
	_duck_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(_duck_column)
	_duck_pad = right_hint.duplicate() as Control
	_duck_column.add_child(_duck_pad)
	var icon: UiIcon = _duck_pad.find_child("Icon", true, false) as UiIcon
	if icon != null:
		icon.kind = UiIcon.Kind.DUCK
	var label: Label = _duck_pad.find_child("Label", true, false) as Label
	if label != null:
		label.text = "TOUCH_HINT_DUCK"
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, right_hint.get_combined_minimum_size().y + 14.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_duck_column.add_child(spacer)


func _exit_tree() -> void:
	release_all()


func _notification(what: int) -> void:
	# A finger lifted while the app was in the background would otherwise leave walk stuck on.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		release_all()


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


## Off while another screen owns touches (photo mode): hides the hints and lets go.
func set_enabled(on: bool) -> void:
	release_all()
	set_process_unhandled_input(on)
	visible = on


func action_for_position(pos: Vector2) -> StringName:
	if _back_pad != null and _back_pad.is_visible_in_tree() and _back_pad.get_global_rect().grow(10.0).has_point(pos):
		return &"walk_back"
	if _duck_pad != null and _duck_pad.is_visible_in_tree() and _duck_pad.get_global_rect().grow(10.0).has_point(pos):
		return &"duck"
	var on_left: bool = pos.x < get_viewport_rect().size.x * 0.5
	return &"walk" if on_left != left_handed else &"jump"


func _is_over_blocker(pos: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group(BLOCKER_GROUP):
		var control: Control = node as Control
		if control != null and control.is_visible_in_tree() and control.get_global_rect().has_point(pos):
			return true
	return false


## Lets go of every held action, e.g. when a menu opens over the game.
func release_all() -> void:
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
	if left_hint_icon != null and right_hint_icon != null:
		left_hint_icon.kind = UiIcon.Kind.JUMP if left_handed else UiIcon.Kind.WALK
		right_hint_icon.kind = UiIcon.Kind.WALK if left_handed else UiIcon.Kind.JUMP
	var walk_held: bool = _fingers.values().has(&"walk")
	var jump_held: bool = _fingers.values().has(&"jump")
	var left_held: bool = jump_held if left_handed else walk_held
	var right_held: bool = walk_held if left_handed else jump_held
	left_hint.modulate.a = HINT_ACTIVE_ALPHA if left_held else HINT_IDLE_ALPHA
	right_hint.modulate.a = HINT_ACTIVE_ALPHA if right_held else HINT_IDLE_ALPHA
	if _back_pad != null:
		# The Back pad sits on the walk side.
		_back_column.size_flags_horizontal = Control.SIZE_SHRINK_END if left_handed else Control.SIZE_SHRINK_BEGIN
		_back_pad.modulate.a = HINT_ACTIVE_ALPHA if _fingers.values().has(&"walk_back") else HINT_IDLE_ALPHA
	if _duck_pad != null:
		# The Duck pad sits on the jump side.
		_duck_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if left_handed else Control.SIZE_SHRINK_END
		_duck_pad.modulate.a = HINT_ACTIVE_ALPHA if _fingers.values().has(&"duck") else HINT_IDLE_ALPHA
