extends GutTest
## Finds UI: the journal's Finds page and stamp counts, find cards (found and not),
## the HUD finds pill, and the pause map's find markers.

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func _collect(trail: TrailData, ids: Array[StringName]) -> void:
	var r: TrailResult = TrailResult.new(trail.id)
	r.finished = true
	r.time_seconds = 100.0
	r.finds = ids
	GameState.record_result(r)


func _season_find_total() -> int:
	var total: int = 0
	for t: TrailData in ContentDB.seasons()[0].ordered_trails():
		total += t.finds.size()
	return total


func _open_journal() -> Node:
	var journal: Node = add_child_autofree((load(SceneRouter.JOURNAL) as PackedScene).instantiate())
	await wait_process_frames(2)
	return journal


func _card_texts(card: FindCard) -> Array[String]:
	var out: Array[String] = []
	for child: Node in card.get_child(0).get_children():
		if child is Label:
			out.append((child as Label).text)
	return out


# --- Find cards ---

func test_found_card_shows_name_and_fact() -> void:
	var trail: TrailData = ContentDB.first_trail()
	var f: FindData = trail.finds[0]
	var card: FindCard = add_child_autofree(FindCard.create(f, trail, true)) as FindCard
	var texts: Array[String] = _card_texts(card)
	assert_eq(texts[0], tr(f.name_key))
	assert_eq(texts[1], tr(f.name_key + "_FACT"))
	assert_ne(texts[1], f.name_key + "_FACT", "the fact is translated, not a raw key")


func test_unfound_card_hides_name_and_names_the_trail() -> void:
	var trail: TrailData = ContentDB.first_trail()
	var card: FindCard = add_child_autofree(FindCard.create(trail.finds[0], trail, false)) as FindCard
	var texts: Array[String] = _card_texts(card)
	assert_eq(texts[0], "???")
	assert_string_contains(texts[1], tr(trail.name_key))
	var art: FindArt = card.get_child(0).get_child(0) as FindArt
	assert_false(art.found, "unfound art is drawn faded")


func test_every_find_has_a_name_and_fact_string() -> void:
	for season: SeasonData in ContentDB.seasons():
		for trail: TrailData in season.trails:
			for f: FindData in trail.finds:
				assert_ne(tr(f.name_key), f.name_key, "%s has no name string" % f.id)
				assert_ne(tr(f.name_key + "_FACT"), f.name_key + "_FACT", "%s has no fact string" % f.id)


# --- Journal ---

func test_journal_finds_page_lists_every_find() -> void:
	var journal: Node = await _open_journal()
	var grid: GridContainer = journal.get("_finds_grid") as GridContainer
	assert_eq(grid.get_child_count(), _season_find_total())


func test_journal_switch_toggles_pages() -> void:
	var journal: Node = await _open_journal()
	var finds_scroll: Control = journal.get("_finds_scroll") as Control
	var postcards_scroll: Control = (journal.get("postcards") as Control).get_parent() as Control
	var buttons: Array = journal.get("_page_buttons")
	assert_false(finds_scroll.visible, "opens on postcards")
	var count: Label = journal.get("count_label") as Label
	var postcards_text: String = count.text
	(buttons[1] as Button).pressed.emit()
	assert_eq(count.text, tr("JOURNAL_COLLECTED") % [0, _season_find_total()], "the counter shows finds on the Finds page")
	assert_true(finds_scroll.visible)
	assert_false(postcards_scroll.visible)
	assert_eq((buttons[1] as Button).theme_type_variation, &"PrimaryButton")
	(buttons[0] as Button).pressed.emit()
	assert_false(finds_scroll.visible)
	assert_true(postcards_scroll.visible)
	assert_eq(count.text, postcards_text, "and postcards again on the Postcards page")


func test_journal_marks_collected_finds_and_counts_on_stamp() -> void:
	var trail: TrailData = ContentDB.first_trail()
	var first: FindData = trail.finds[0]
	_collect(trail, [first.id] as Array[StringName])
	var journal: Node = await _open_journal()
	var grid: GridContainer = journal.get("_finds_grid") as GridContainer
	var found_names: Array[String] = []
	var hidden: int = 0
	for card: Node in grid.get_children():
		var name_text: String = _card_texts(card as FindCard)[0]
		if name_text == "???":
			hidden += 1
		else:
			found_names.append(name_text)
	assert_eq(found_names, [tr(first.name_key)] as Array[String])
	assert_eq(hidden, _season_find_total() - 1)
	var stamp_text: String = tr("JOURNAL_FINDS") % [1, trail.finds.size()]
	var labels: Array[Node] = (journal.get("stamps") as Node).find_children("*", "Label", true, false)
	var texts: Array[String] = []
	for l: Node in labels:
		texts.append((l as Label).text)
	assert_has(texts, stamp_text, "the first trail's stamp says 1/%d finds" % trail.finds.size())


func test_finds_page_stays_inside_the_journal_on_wide_phones() -> void:
	# Pixel 7 Pro proportions (19.5:9 -> 1560x720 viewport): the grid once grew a
	# column at a time until the page ran off screen.
	var host: Control = Control.new()
	host.size = Vector2(1560, 720)
	add_child_autofree(host)
	var journal: Control = (load(SceneRouter.JOURNAL) as PackedScene).instantiate() as Control
	host.add_child(journal)
	journal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	(journal.get("_page_buttons")[1] as Button).pressed.emit()
	await wait_process_frames(10)
	var scroll: ScrollContainer = journal.get("_finds_scroll") as ScrollContainer
	var grid: GridContainer = journal.get("_finds_grid") as GridContainer
	assert_lte(scroll.get_global_rect().end.x, 1560.0, "the finds page ends on screen")
	assert_lte(grid.get_combined_minimum_size().x, scroll.size.x, "the cards fit across the page")
	assert_gt(grid.columns, 1)


func test_swiping_over_find_cards_reaches_the_scroll() -> void:
	var journal: Node = await _open_journal()
	var grid: GridContainer = journal.get("_finds_grid") as GridContainer
	var blockers: Array[String] = []
	for node: Node in [grid as Node] + grid.find_children("*", "Control", true, false):
		if (node as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			blockers.append(String(node.get_path()))
	assert_eq(blockers, [] as Array[String], "nothing on the Finds page swallows the swipe")


# --- HUD pill ---

func test_hud_finds_pill_counts_and_hides_without_finds() -> void:
	var hud: Hud = add_child_autofree((load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()) as Hud
	var label: Label = hud.get("_finds_label") as Label
	var pill: Control = label.get_parent().get_parent() as Control
	hud.set_finds(2, 4)
	assert_eq(label.text, "2/4")
	assert_true(pill.visible)
	hud.set_finds(0, 0)
	assert_false(pill.visible, "trails without finds don't show the pill")


# --- Pause map ---

func test_trail_map_has_a_marker_per_find() -> void:
	var trail: TrailData = ContentDB.first_trail()
	var level: Node = add_child_autofree((load(trail.scene_path) as PackedScene).instantiate())
	var map: TrailMap = add_child_autofree(TrailMap.new()) as TrailMap
	map.scan(level)
	var finds: Array[StringName] = []
	for m: Array in map.get("_marks"):
		if m[1] == TrailMap.Mark.FIND:
			finds.append(m[2])
	finds.sort()
	var expected: Array[StringName] = trail.find_ids()
	expected.sort()
	assert_eq(finds, expected)
	map.show_progress(Vector2.ZERO, 0.0, [String(expected[0])])
	assert_eq((map.get("_found") as Array).size(), 1)
