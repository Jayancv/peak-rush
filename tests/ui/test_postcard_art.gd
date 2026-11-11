extends GutTest
## Code-drawn postcards: every motif draws (day and night), and every Season 1
## viewpoint picked a motif so no two postcards fall back to the same generic scene.


func test_every_motif_draws_by_day_and_night() -> void:
	var cards: Array[Postcard] = []
	for night: bool in [false, true]:
		for motif: int in ViewpointData.Motif.values():
			var card: Postcard = Postcard.new()
			card.custom_minimum_size = Vector2(300, 216)
			card.size = card.custom_minimum_size
			card.quality = StarRating.PhotoQuality.GREAT
			card.motif = motif
			card.night = night
			add_child_autofree(card)
			cards.append(card)
	await wait_process_frames(2)
	assert_eq(cards.size(), ViewpointData.Motif.size() * 2)
	for card: Postcard in cards:
		assert_true(card.is_inside_tree() and card.is_collected(), "motif %d drew" % card.motif)


func test_season_one_viewpoints_have_distinct_motifs() -> void:
	var seen: Dictionary = {}
	for trail: TrailData in ContentDB.seasons()[0].ordered_trails():
		for vp: ViewpointData in trail.viewpoints:
			assert_ne(vp.motif, ViewpointData.Motif.DEFAULT, "%s has a postcard motif" % vp.id)
			assert_false(seen.has(vp.motif), "%s shares its motif" % vp.id)
			seen[vp.motif] = true


func test_trail_card_detail_wraps_instead_of_overflowing() -> void:
	var card: TrailCard = (load("res://scenes/trail_select/trail_card.tscn") as PackedScene).instantiate()
	add_child_autofree(card)
	assert_ne(card.detail_label.autowrap_mode, TextServer.AUTOWRAP_OFF)


func test_every_viewpoint_has_its_rendered_postcard() -> void:
	# Pictures come from tools/postcards/make_postcards.tscn (the real game view).
	for season: SeasonData in ContentDB.seasons():
		for trail: TrailData in season.trails:
			for vp: ViewpointData in trail.viewpoints:
				assert_not_null(vp.postcard, "%s has a postcard picture" % vp.id)
				if vp.postcard != null:
					assert_almost_eq(vp.postcard.get_size().aspect(), 1.5, 0.01, "%s is a 3:2 print" % vp.id)
