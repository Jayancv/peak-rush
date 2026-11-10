class_name ScrollTap
extends RefCounted
## Buttons inside a scroll area. Swipes that start on a button still scroll the page,
## and the button's action only runs if the page didn't move while the finger was down
## (so a swipe that ends on a card doesn't open it).

## How far (px) the page may move during a press and still count as a tap.
const SLOP: float = 12.0
const _META: StringName = &"scroll_tap_at"


## Use instead of `button.pressed.connect(action)`.
static func connect_tap(button: BaseButton, action: Callable) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.button_down.connect(func() -> void: button.set_meta(_META, _scroll_position(button)))
	button.pressed.connect(func() -> void:
		# No button_down seen (keyboard focus, tests): treat it as a tap.
		var start: Vector2 = button.get_meta(_META, _scroll_position(button))
		button.remove_meta(_META)
		if _scroll_position(button).distance_to(start) < SLOP:
			action.call())


static func _scroll_position(control: Control) -> Vector2:
	var node: Node = control.get_parent()
	while node != null and not node is ScrollContainer:
		node = node.get_parent()
	var scroll: ScrollContainer = node as ScrollContainer
	return Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) if scroll != null else Vector2.ZERO
