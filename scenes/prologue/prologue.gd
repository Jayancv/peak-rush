class_name Prologue
extends Control
## The opening (first launch, or "Watch the opening" on the Journey screen): Grandma
## Elsa's attic, a box with her hiking things, her notebook opening on its first page,
## "Walk it with her." Tap to hurry it along; Skip or the last button leaves.
## A new player goes straight onto the first trail; a replay goes back to the Journey.

const CREAM: Color = Color("#FFF6E5")
const INK: Color = Color("#2B2D42")
const ACCENT: Color = Color("#C0492F")
const TITLE_FONT: Font = preload("res://shared_art/title_font.tres")
const BOOK_SIZE: Vector2 = Vector2(820, 430)

## Where to go afterwards ("" = decide: first trail for a new player, else the menu).
static var return_to: String = ""

var _attic: AtticArt
var _book: NotebookArt
var _caption: Label
var _page_title: Label
var _page_text: Label
var _closing: Label
var _start: Button
var _fade: ColorRect
var _tween: Tween
var _done: bool = false
var _leaving: bool = false


func _ready() -> void:
	AudioManager.enter_menu()
	_build()
	# Wait one frame so the layout has its real size before placing the book.
	_play.call_deferred()


func _play() -> void:
	var slow: float = 0.35 if UiMotion.reduced() else 1.0
	var book_open: Vector2 = (size - BOOK_SIZE) * 0.5 + Vector2(0, -70)
	var book_closed: Vector2 = book_open + Vector2(-BOOK_SIZE.x * 0.25, 0)
	_book.position = _attic.box_top() - Vector2(BOOK_SIZE.x * 0.75, 30)
	_book.scale = Vector2(0.3, 0.3)
	_tween = create_tween()
	_tween.tween_property(_fade, "color:a", 0.0, 1.4 * slow)
	_tween.parallel().tween_property(_caption, "modulate:a", 1.0, 1.0 * slow).set_delay(0.6 * slow)
	_tween.tween_interval(1.6 * slow)
	_tween.tween_property(_attic, "lid_open", 1.0, 0.9 * slow).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_book, "modulate:a", 1.0, 0.3 * slow)
	_tween.parallel().tween_property(_book, "position", book_closed, 1.2 * slow).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_book, "scale", Vector2.ONE, 1.2 * slow).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_caption, "modulate:a", 0.0, 0.6 * slow)
	_tween.tween_interval(0.5 * slow)
	_tween.tween_property(_book, "open", 1.0, 1.1 * slow).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.parallel().tween_property(_book, "position", book_open, 1.1 * slow).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_page_title, "modulate:a", 1.0, 0.6 * slow)
	_tween.tween_property(_page_text, "modulate:a", 1.0, 1.2 * slow)
	_tween.tween_interval(1.2 * slow)
	_tween.tween_callback(_finish)


## Everything in its final place: the open notebook, the closing line and the button.
func _finish() -> void:
	if _done:
		return
	_done = true
	if _tween != null:
		_tween.kill()
	_fade.color.a = 0.0
	_caption.modulate.a = 0.0
	_attic.lid_open = 1.0
	_book.open = 1.0
	_book.scale = Vector2.ONE
	_book.modulate.a = 1.0
	_book.position = (size - BOOK_SIZE) * 0.5 + Vector2(0, -70)
	_page_title.modulate.a = 1.0
	_page_text.modulate.a = 1.0
	var t: Tween = create_tween()
	t.tween_property(_closing, "modulate:a", 1.0, 0.6)
	t.parallel().tween_property(_start, "modulate:a", 1.0, 0.6)
	_start.disabled = false


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.set_setting("prologue_seen", true)
	# Opening the notebook unlocks (and reads) its first page.
	var j: JourneyData = GameState.journey()
	if j != null and not j.landmarks.is_empty():
		Journey.mark_read(GameState.profile, j, j.landmarks[0])
	GameState.progress_changed.emit()
	var target: String = return_to
	return_to = ""
	if target == "":
		var first: TrailData = GameState.next_trail_to_play()
		if GameState.profile.hikes == 0 and first != null:
			GameState.current_trail_id = first.id
			target = SceneRouter.TRAIL_RUNNER
		else:
			target = SceneRouter.MAIN_MENU
	SceneRouter.go_to(target)


## Whether to show the opening at start-up: new players only, once.
static func should_show() -> bool:
	return not bool(GameState.settings.get("prologue_seen", false)) and GameState.profile.hikes == 0 \
		and not ContentDB.journeys().is_empty()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if tapped and not _done:
		accept_event()
		_finish()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_leave()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_leave()


# --- Layout ---

func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_attic = AtticArt.new()
	_attic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_attic)
	_book = NotebookArt.new()
	_book.size = BOOK_SIZE
	_book.pivot_offset = Vector2(BOOK_SIZE.x * 0.75, BOOK_SIZE.y * 0.5)
	_book.modulate.a = 0.0
	add_child(_book)
	var page: Rect2 = _book.right_page()
	_page_title = _label(tr("LM_ABISKO_TITLE"), 30, ACCENT)
	_page_title.add_theme_font_override("font", TITLE_FONT)
	_page_title.position = page.position
	_page_title.size = Vector2(page.size.x, 44)
	_book.add_child(_page_title)
	_page_text = _label(tr("LM_ABISKO_TEXT"), 21, INK)
	_page_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page_text.position = page.position + Vector2(0, 56)
	_page_text.size = Vector2(page.size.x, page.size.y - 56)
	_page_text.add_theme_constant_override("line_spacing", 3)
	_book.add_child(_page_text)
	_caption = _outlined(tr("PROLOGUE_CAPTION"), 30)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_caption.position.y = 70
	add_child(_caption)
	# The closing line is written at the foot of her page, like the next line of the entry.
	_closing = _label(tr("PROLOGUE_CLOSING"), 34, ACCENT)
	_closing.add_theme_font_override("font", TITLE_FONT)
	_closing.position = page.position + Vector2(0, page.size.y - 48)
	_closing.size = Vector2(page.size.x, 48)
	_closing.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_book.add_child(_closing)
	_start = Button.new()
	_start.text = tr("PROLOGUE_START")
	_start.theme_type_variation = &"PrimaryButton"
	_start.add_theme_font_size_override("font_size", 30)
	_start.custom_minimum_size = Vector2(320, 84)
	_start.modulate.a = 0.0
	_start.disabled = true
	_start.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_start.offset_left = -160
	_start.offset_right = 160
	_start.offset_top = -112
	_start.offset_bottom = -28
	_start.pressed.connect(_leave)
	add_child(_start)
	var skip: Button = Button.new()
	skip.text = tr("PROLOGUE_SKIP")
	skip.add_theme_font_size_override("font_size", 24)
	skip.custom_minimum_size = Vector2(140, 64)
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip.position += Vector2(-170, 28)
	skip.pressed.connect(_leave)
	add_child(skip)
	_fade = ColorRect.new()
	_fade.color = Color(0.06, 0.04, 0.04, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## A line of cream text with a dark outline, centred on the screen.
func _outlined(text: String, font_size: int) -> Label:
	var label: Label = _label(text, font_size, CREAM)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return label
