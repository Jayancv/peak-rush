class_name BadgePills
extends RefCounted
## "New badge" pills that slide down from the top of a screen and step aside after a few
## seconds. Used by the results screen and by step claims on the main menu.

const SHOW_SECONDS: float = 3.5


## `ids` are badge ids (String); shown in catalog order. Does nothing if empty.
static func show(parent: Control, ids: Array) -> void:
	if ids.is_empty():
		return
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.offset_top = 18.0
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(column)
	var i: int = 0
	for badge: BadgeData in ContentDB.badge_list():
		if not ids.has(String(badge.id)):
			continue
		column.add_child(_pill(badge, parent))
		UiMotion.intro([column.get_child(-1)], 0.15 + 0.25 * float(i))
		i += 1
	var fade: Tween = column.create_tween()
	fade.tween_interval(SHOW_SECONDS + 0.25 * float(i))
	fade.tween_property(column, "modulate:a", 0.0, 0.5)
	fade.tween_callback(column.queue_free)


static func _pill(badge: BadgeData, translator: Node) -> PanelContainer:
	var pill: PanelContainer = PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(1, 0.964706, 0.898039, 0.96)
	box.set_corner_radius_all(34)
	box.content_margin_left = 10.0
	box.content_margin_right = 24.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	box.shadow_color = Color(0.168627, 0.176471, 0.258824, 0.2)
	box.shadow_size = 8
	pill.add_theme_stylebox_override("panel", box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(BadgeView.medal(badge, true, 52.0))
	var label: Label = Label.new()
	label.text = translator.tr("RESULTS_NEW_BADGE") % translator.tr(badge.name_key)
	label.add_theme_font_size_override("font_size", 26)
	row.add_child(label)
	pill.add_child(row)
	return pill
