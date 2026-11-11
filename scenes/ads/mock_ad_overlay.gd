class_name MockAdOverlay
extends CanvasLayer
## What MockAdProvider puts on screen: a full-screen card clearly marked TEST AD with a
## countdown, or the ad consent choice. It sits on the root (above every scene) so a
## scene change after the ad can't cut it off, and mutes the game while an ad "plays",
## like real ads do.

const INK: Color = Color("#2B2D42")
const MUTED: Color = Color(0.168627, 0.176471, 0.258824, 0.65)
const LAYER: int = 120

var _seconds_left: float = 0.0
var _rewarded: bool = false
var _on_reward: Callable
var _on_closed: Callable
var _count: Label
var _close: Button
var _skip: Button
var _rewarded_paid: bool = false


static func ad(host: Node, rewarded: bool, seconds: float, on_reward: Callable, on_closed: Callable) -> MockAdOverlay:
	var o: MockAdOverlay = MockAdOverlay.new()
	o._rewarded = rewarded
	o._seconds_left = seconds
	o._on_reward = on_reward
	o._on_closed = on_closed
	host.get_tree().root.add_child(o)
	o._build_ad()
	return o


static func consent(host: Node, on_done: Callable) -> MockAdOverlay:
	var o: MockAdOverlay = MockAdOverlay.new()
	host.get_tree().root.add_child(o)
	o._build_consent(on_done)
	return o


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS


func _box(dim_alpha: float, width: float) -> VBoxContainer:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.08, 0.09, 0.13, dim_alpha)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box


func _build_ad() -> void:
	AudioServer.set_bus_mute(0, true)
	var box: VBoxContainer = _box(0.94, 560)
	box.add_child(_label(tr("AD_TEST_TITLE"), 44, INK))
	box.add_child(_label(tr("AD_TEST_REWARDED") if _rewarded else tr("AD_TEST_INTERSTITIAL"), 22, MUTED))
	_count = _label("", 26, INK)
	box.add_child(_count)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	if _rewarded:
		# Closing a rewarded ad early is allowed; it just doesn't pay.
		_skip = _button(tr("AD_SKIP"), _finish)
		row.add_child(_skip)
	_close = _button(tr("AD_CLOSE"), _finish)
	_close.theme_type_variation = &"PrimaryButton"
	_close.visible = false
	row.add_child(_close)
	_update_count()


func _process(delta: float) -> void:
	if _count == null or _seconds_left <= 0.0:
		return
	_seconds_left -= delta
	if _seconds_left <= 0.0:
		_seconds_left = 0.0
		_close.visible = true
		if _skip != null:
			_skip.visible = false
		if _rewarded:
			_rewarded_paid = true
	_update_count()


func _update_count() -> void:
	if _seconds_left > 0.0:
		_count.text = tr("AD_REWARD_IN" if _rewarded else "AD_CLOSE_IN") % ceili(_seconds_left)
	else:
		_count.text = tr("AD_REWARD_EARNED") if _rewarded else ""


func _finish() -> void:
	AudioServer.set_bus_mute(0, false)
	if _rewarded_paid and _on_reward.is_valid():
		_on_reward.call()
	queue_free()
	if _on_closed.is_valid():
		_on_closed.call()


func _build_consent(on_done: Callable) -> void:
	var box: VBoxContainer = _box(0.6, 620)
	box.add_child(_label(tr("CONSENT_TITLE"), 34, INK))
	box.add_child(_label(tr("CONSENT_BODY"), 20, MUTED))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for choice: String in ["non_personalized", "personalized"]:
		var b: Button = _button(tr("CONSENT_" + choice.to_upper()), func() -> void:
			queue_free()
			on_done.call(choice))
		if choice == "personalized":
			b.theme_type_variation = &"PrimaryButton"
		row.add_child(b)


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(500, 0)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, action: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(230, 66)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(action)
	return b


func _notification(what: int) -> void:
	# Android back closes the ad like its close button (rewarded: only once it's paid).
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _count != null and (_close.visible or _skip != null):
		_finish()
