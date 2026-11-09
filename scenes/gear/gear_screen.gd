class_name GearScreen
extends Control
## The gear shop and loadout: buy items with TP, equip up to Balance.gear_slots.
## Built from ContentDB.gear_list(); every change goes through GameState (and saves).

const CARD_SIZE: Vector2 = Vector2(250, 420)
const INK: Color = Color("#2B2D42")
const ACCENT: Color = Color("#E85D3F")
const EQUIPPED: Color = Color("#5E9C6E")
const OWNED: Color = Color("#7FA6A0")
const CREAM: Color = Color("#FFF6E5")
const SLOT_SIZE: float = 64.0
## Scroll movement (px) beyond which a press counts as a swipe, not a tap.
const TAP_SLOP: int = 12

@export var cards: HBoxContainer
@export var tp_label: Label
@export var slots_label: Label
@export var back_button: Button

## Where Back goes (trail select opens the gear screen for a pre-hike loadout).
static var return_to: String = ""


var _loadout: HBoxContainer


func _ready() -> void:
	AudioManager.enter_menu()
	back_button.pressed.connect(_go_back)
	_build_loadout_bar()
	_scroll().scroll_ended.connect(_snap_to_card)
	refresh()
	# Only on arrival: refresh() also runs after every buy/equip, where cards should stay put.
	UiMotion.intro(cards.get_children(), 0.08)


func refresh() -> void:
	tp_label.text = tr("HUD_TP") % GameState.tp
	slots_label.text = tr("GEAR_SLOTS") % [GameState.equipped_gear.size(), ContentDB.balance.gear_slots]
	for old: Node in cards.get_children():
		cards.remove_child(old)
		old.queue_free()
	for g: GearData in ContentDB.gear_list():
		cards.add_child(_make_card(g))
	_refresh_loadout()


## "Equipped 1/2" plus a frame per slot showing what's in it.
func _build_loadout_bar() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent: Node = slots_label.get_parent()
	parent.add_child(bar)
	parent.move_child(bar, slots_label.get_index())
	slots_label.reparent(bar)
	slots_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_loadout = HBoxContainer.new()
	_loadout.add_theme_constant_override("separation", 10)
	bar.add_child(_loadout)


func _refresh_loadout() -> void:
	for old: Node in _loadout.get_children():
		old.queue_free()
	for i: int in ContentDB.balance.gear_slots:
		var frame: ShadedBadge = ShadedBadge.new()
		frame.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		frame.corner = 0.28
		frame.shadow_size = 4.0
		var items: Array[GearData] = GameState.equipped_items()
		if i < items.size():
			frame.base_color = CREAM
			var art: GearArt = GearArt.new()
			art.kind = items[i].icon
			art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_child(art)
		else:
			# An empty slot: a faint "+" waiting for gear.
			frame.base_color = Color(1, 0.964706, 0.898039, 0.45)
			var plus: Label = Label.new()
			plus.text = "+"
			plus.add_theme_font_size_override("font_size", 34)
			plus.add_theme_color_override("font_color", Color(INK, 0.35))
			plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			frame.add_child(plus)
		_loadout.add_child(frame)


func _scroll() -> ScrollContainer:
	return cards.get_parent() as ScrollContainer


## After a swipe settles, glide so the nearest card lines up with the left edge.
func _snap_to_card() -> void:
	var scroll: ScrollContainer = _scroll()
	var step: float = CARD_SIZE.x + float(cards.get_theme_constant("separation"))
	var max_scroll: float = maxf(cards.size.x - scroll.size.x, 0.0)
	var target: float = clampf(roundf(float(scroll.scroll_horizontal) / step) * step, 0.0, max_scroll)
	create_tween().tween_property(scroll, "scroll_horizontal", int(target), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func card_count() -> int:
	return cards.get_child_count()


func _make_card(g: GearData) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size = CARD_SIZE
	# Pass touches on, so a drag that starts on a card still scrolls the row.
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	# Showcase: the item under a soft spotlight, with an Equipped/Owned tag.
	var show: Control = Control.new()
	show.custom_minimum_size = Vector2(0, 170)
	show.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art: GearArt = GearArt.new()
	art.kind = g.icon
	art.showcase = true
	art.dimmed = not GameState.is_owned(g.id)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show.add_child(art)
	if GameState.is_equipped(g.id):
		show.add_child(_tag(tr("GEAR_TAG_EQUIPPED"), EQUIPPED))
	elif GameState.is_owned(g.id):
		show.add_child(_tag(tr("GEAR_TAG_OWNED"), OWNED))
	box.add_child(show)
	box.add_child(_label(tr(g.name_key), 28, true))
	var effect: Label = _label(effect_text(g), 40, true)
	effect.add_theme_color_override("font_color", ACCENT)
	box.add_child(effect)
	var desc: Label = _label(tr(g.description_key), 19, true)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.modulate = Color(1, 1, 1, 0.75)
	box.add_child(desc)
	var button: Button = Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = Vector2(0, 66)
	button.add_theme_font_size_override("font_size", 22)
	_setup_button(button, g)
	box.add_child(button)
	return card


## The item's one effect as a big number: "-75%" (less is better) or "+25%".
static func effect_text(g: GearData) -> String:
	for scale: float in [g.slip_scale, g.uphill_drain_scale, g.weather_drain_scale, g.rest_regen_scale, g.dusk_penalty_scale]:
		if not is_equal_approx(scale, 1.0):
			var pct: int = roundi((scale - 1.0) * 100.0)
			return ("+%d%%" % pct) if pct > 0 else ("-%d%%" % -pct)
	return ""


## A small rounded tag in the showcase's top-right corner.
func _tag(text: String, color: Color) -> Control:
	var tag: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(14)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 4.0
	tag.add_theme_stylebox_override("panel", box)
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", CREAM)
	tag.add_child(label)
	tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tag


## Remembers where the row was when the finger went down, so a swipe that happens to
## end on a button doesn't buy or equip anything.
func _arm_tap_guard(button: Button) -> void:
	button.button_down.connect(func() -> void: button.set_meta("scroll_at", _scroll().scroll_horizontal))


func _was_tap(button: Button) -> bool:
	var start: int = int(button.get_meta("scroll_at", _scroll().scroll_horizontal))
	return absi(_scroll().scroll_horizontal - start) < TAP_SLOP


func _setup_button(button: Button, g: GearData) -> void:
	_arm_tap_guard(button)
	if GameState.is_equipped(g.id):
		button.text = tr("GEAR_UNEQUIP")
		button.pressed.connect(func() -> void:
			if not _was_tap(button):
				return
			GameState.unequip(g.id)
			refresh())
	elif GameState.is_owned(g.id):
		var full: bool = GameState.equipped_gear.size() >= ContentDB.balance.gear_slots
		button.text = tr("GEAR_SLOTS_FULL") if full else tr("GEAR_EQUIP")
		button.disabled = full
		button.theme_type_variation = &"PrimaryButton"
		button.pressed.connect(func() -> void:
			if not _was_tap(button):
				return
			GameState.equip(g.id)
			refresh())
	else:
		var affordable: bool = GameState.tp >= g.cost
		button.text = tr("GEAR_BUY") % g.cost if affordable else tr("GEAR_CANT_AFFORD") % g.cost
		button.disabled = not affordable
		button.pressed.connect(func() -> void:
			if not _was_tap(button):
				return
			if GameState.buy(g.id):
				AudioManager.play_summit()
			refresh())


func _label(text: String, font_size: int, centered: bool) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _go_back() -> void:
	var target: String = return_to if not return_to.is_empty() else SceneRouter.MAIN_MENU
	return_to = ""
	SceneRouter.go_to(target)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_go_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()
