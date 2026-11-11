class_name ReviewPrompt
extends CanvasLayer
## The Play Store review request after a happy summit (ReviewPolicy decides when).
## Google's In-App Review dialog needs its Android plugin (not added yet: ask first).
## Until then, debug builds show a clearly marked stand-in so the timing can be checked
## on the phone, and release builds and tests show nothing.

## The Android singleton a review plugin would register (checked, never required).
const PLUGIN: String = "GodotGooglePlayInAppReview"
const INK: Color = Color("#2B2D42")


## Called by the results screen; true if a prompt (or its stand-in) was shown.
static func maybe_ask(host: Node, result: Dictionary) -> bool:
	var completed: int = ReviewPolicy.completed_trails(GameState.trails)
	var asked: bool = bool(GameState.settings.get("review_asked", false))
	if not ReviewPolicy.should_ask(bool(result.get("first_completion", false)), completed, asked, ContentDB.balance):
		return false
	GameState.set_setting("review_asked", true)
	if Engine.has_singleton(PLUGIN):
		# Wire the plugin's request/launch flow here when it's added.
		return true
	if OS.is_debug_build() and not SaveService.is_test_run():
		var card: ReviewPrompt = ReviewPrompt.new()
		host.get_tree().root.add_child(card)
		card._build()
	return true


func _build() -> void:
	layer = 110
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.08, 0.09, 0.13, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	for line: Array in [["REVIEW_TEST_TITLE", 32], ["REVIEW_TEST_BODY", 20]]:
		var label: Label = Label.new()
		label.text = tr(line[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(480, 0)
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", INK)
		box.add_child(label)
	var ok: Button = Button.new()
	ok.text = tr("ABOUT_CLOSE")
	ok.custom_minimum_size = Vector2(200, 64)
	ok.theme_type_variation = &"PrimaryButton"
	ok.pressed.connect(queue_free)
	box.add_child(ok)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		queue_free()
