extends GutTest
## Touch audit over every menu screen: swipes reach the scroll areas, and buttons are
## big enough to hit with a thumb.

const SCREENS: Array[String] = [
	"res://scenes/main_menu/main_menu.tscn",
	"res://scenes/trail_select/trail_select.tscn",
	"res://scenes/journal/journal.tscn",
	"res://scenes/settings/settings.tscn",
	"res://scenes/gear/gear_screen.tscn",
	"res://scenes/profile/profile.tscn",
]
## ~48 dp: Android's minimum touch target, in 720p-viewport pixels on a typical phone.
const MIN_TOUCH: float = 44.0


func _open(path: String) -> Node:
	var screen: Node = add_child_autofree((load(path) as PackedScene).instantiate())
	await wait_process_frames(3)
	return screen


func test_swipes_reach_every_scroll_area() -> void:
	for path: String in SCREENS:
		var screen: Node = await _open(path)
		var blockers: Array[String] = []
		for scroll: Node in screen.find_children("*", "ScrollContainer", true, false):
			for node: Node in scroll.find_children("*", "Control", true, false):
				var c: Control = node as Control
				if c.mouse_filter == Control.MOUSE_FILTER_STOP and c.is_visible_in_tree() and not c is ScrollBar:
					blockers.append("%s (%s)" % [c.name, c.get_class()])
		assert_eq(blockers, [] as Array[String], "%s: these swallow swipes" % path.get_file())


func test_buttons_are_thumb_sized() -> void:
	for path: String in SCREENS:
		var screen: Node = await _open(path)
		var small: Array[String] = []
		for node: Node in screen.find_children("*", "BaseButton", true, false):
			var b: Control = node as Control
			if not b.is_visible_in_tree() or (b is BaseButton and (b as BaseButton).disabled):
				continue
			var s: Vector2 = b.size
			if s.x < MIN_TOUCH or s.y < MIN_TOUCH:
				small.append("%s %dx%d" % [b.name, int(s.x), int(s.y)])
		assert_eq(small, [] as Array[String], "%s: buttons under %d px" % [path.get_file(), int(MIN_TOUCH)])


func _scroll_with_button() -> Array:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size = Vector2(300, 200)
	add_child_autofree(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	scroll.add_child(box)
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(280, 120)
	box.add_child(button)
	var filler: Control = Control.new()
	filler.custom_minimum_size = Vector2(10, 900)
	box.add_child(filler)
	await wait_process_frames(2)
	return [scroll, button]


func test_scroll_tap_runs_on_a_tap() -> void:
	var parts: Array = await _scroll_with_button()
	var taps: Array[int] = [0]
	ScrollTap.connect_tap(parts[1], func() -> void: taps[0] += 1)
	(parts[1] as Button).button_down.emit()
	(parts[1] as Button).pressed.emit()
	assert_eq(taps[0], 1)
	assert_eq((parts[1] as Control).mouse_filter, Control.MOUSE_FILTER_PASS, "swipes pass through to the scroll")


func test_scroll_tap_ignores_a_swipe_that_ends_on_the_button() -> void:
	var parts: Array = await _scroll_with_button()
	var taps: Array[int] = [0]
	ScrollTap.connect_tap(parts[1], func() -> void: taps[0] += 1)
	(parts[1] as Button).button_down.emit()
	(parts[0] as ScrollContainer).scroll_vertical = 80
	(parts[1] as Button).pressed.emit()
	assert_eq(taps[0], 0, "the page moved: that was a swipe")
	(parts[1] as Button).button_down.emit()
	(parts[1] as Button).pressed.emit()
	assert_eq(taps[0], 1, "the next real tap works")
