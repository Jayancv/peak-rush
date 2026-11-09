class_name GearScreen
extends Control
## The gear shop and loadout: buy items with TP, equip up to Balance.gear_slots.
## Built from ContentDB.gear_list(); every change goes through GameState (and saves).

const CARD_SIZE: Vector2 = Vector2(232, 330)

@export var cards: HBoxContainer
@export var tp_label: Label
@export var slots_label: Label
@export var back_button: Button

## Where Back goes (trail select opens the gear screen for a pre-hike loadout).
static var return_to: String = ""


func _ready() -> void:
	AudioManager.enter_menu()
	back_button.pressed.connect(_go_back)
	refresh()


func refresh() -> void:
	tp_label.text = tr("HUD_TP") % GameState.tp
	slots_label.text = tr("GEAR_SLOTS") % [GameState.equipped_gear.size(), ContentDB.balance.gear_slots]
	for old: Node in cards.get_children():
		cards.remove_child(old)
		old.queue_free()
	for g: GearData in ContentDB.gear_list():
		cards.add_child(_make_card(g))


func card_count() -> int:
	return cards.get_child_count()


func _make_card(g: GearData) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size = CARD_SIZE
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var icon: UiIcon = UiIcon.new()
	icon.kind = (UiIcon.Kind.BOOTS + g.icon) as UiIcon.Kind
	icon.custom_minimum_size = Vector2(84, 84)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.modulate = Color.WHITE if GameState.is_owned(g.id) else Color(1, 1, 1, 0.55)
	box.add_child(icon)
	box.add_child(_label(tr(g.name_key), 28, true))
	var desc: Label = _label(tr(g.description_key), 20, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.modulate = Color(1, 1, 1, 0.75)
	box.add_child(desc)
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(0, 66)
	button.add_theme_font_size_override("font_size", 22)
	_setup_button(button, g)
	box.add_child(button)
	return card


func _setup_button(button: Button, g: GearData) -> void:
	if GameState.is_equipped(g.id):
		button.text = tr("GEAR_UNEQUIP")
		button.pressed.connect(func() -> void:
			GameState.unequip(g.id)
			refresh())
	elif GameState.is_owned(g.id):
		var full: bool = GameState.equipped_gear.size() >= ContentDB.balance.gear_slots
		button.text = tr("GEAR_SLOTS_FULL") if full else tr("GEAR_EQUIP")
		button.disabled = full
		button.theme_type_variation = &"PrimaryButton"
		button.pressed.connect(func() -> void:
			GameState.equip(g.id)
			refresh())
	else:
		var affordable: bool = GameState.tp >= g.cost
		button.text = tr("GEAR_BUY") % g.cost if affordable else tr("GEAR_CANT_AFFORD") % g.cost
		button.disabled = not affordable
		button.pressed.connect(func() -> void:
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
