class_name FindCard
extends PanelContainer
## One find in the journal: a drawing, its name and a short nature fact (or "?" and
## the trail it hides on, until it's found).

const SIZE: Vector2 = Vector2(200, 214)
const INK: Color = Color("#2B2D42")
const MUTED: Color = Color(0.168627, 0.176471, 0.258824, 0.6)


static func create(data: FindData, trail: TrailData, found: bool) -> FindCard:
	var card: FindCard = FindCard.new()
	card.custom_minimum_size = SIZE
	card.theme_type_variation = &"CardPanel"
	# Cards aren't tappable: let touches through so a swipe anywhere scrolls the page.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var art: FindArt = FindArt.new()
	art.kind = data.kind
	art.color = data.color
	art.found = found
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(0, 84)
	box.add_child(art)
	box.add_child(_label(tr_static(data.name_key) if found else "???", 20, INK))
	var fact: Label = _label(tr_static(data.name_key + "_FACT") if found else tr_static("JOURNAL_NOT_FOUND") % tr_static(trail.name_key), 15, MUTED)
	fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fact.custom_minimum_size = Vector2(SIZE.x - 30.0, 0)
	box.add_child(fact)
	return card


static func tr_static(key: String) -> String:
	return TranslationServer.translate(key)


static func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
