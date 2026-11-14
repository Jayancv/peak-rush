extends GutTest
## The long journey: kilometres from hikes and real steps, landmark pages and their TP,
## finishing, unread pages, the map walker, the content itself and the save migration.

var _b: Balance = Balance.new()
var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func _kungsleden() -> JourneyData:
	return ContentDB.journeys()[0]


func test_opening_the_journey_unlocks_the_first_page_for_free() -> void:
	var p: PlayerProfile = PlayerProfile.new()
	var out: Dictionary = Journey.advance(p, ContentDB.journeys(), 0.0, _b)
	assert_eq(out.journey_id, &"kungsleden")
	assert_eq(out.pages.size(), 1, "the km-0 page (Abisko)")
	assert_eq(int(out.tp), 0, "the opening page is a welcome, not a reward")
	assert_eq(Journey.unread(p), 1)
	assert_eq(Journey.next_landmark(p, _kungsleden()).id, &"abiskojaure")


func test_walking_past_landmarks_unlocks_pages_and_pays() -> void:
	var p: PlayerProfile = PlayerProfile.new()
	Journey.advance(p, ContentDB.journeys(), 0.0, _b)
	var out: Dictionary = Journey.advance(p, ContentDB.journeys(), 40.0, _b)
	assert_eq(out.pages.map(func(lm: LandmarkData) -> StringName: return lm.id), [&"abiskojaure", &"alesjaure"])
	assert_eq(int(out.tp), 2 * _b.journey_landmark_tp)
	assert_almost_eq(Journey.km(p, _kungsleden()), 40.0, 0.001)
	out = Journey.advance(p, ContentDB.journeys(), 1.0, _b)
	assert_eq(out.pages.size(), 0, "no landmark between 40 and 41 km")
	assert_eq(int(out.tp), 0)


func test_finishing_caps_at_the_end_and_pays_once() -> void:
	var p: PlayerProfile = PlayerProfile.new()
	var out: Dictionary = Journey.advance(p, ContentDB.journeys(), 5000.0, _b)
	var j: JourneyData = _kungsleden()
	assert_true(bool(out.finished))
	assert_almost_eq(float(out.km), j.length_km, 0.001)
	assert_eq(int(out.tp), (j.landmarks.size() - 1) * _b.journey_landmark_tp + _b.journey_finish_tp)
	assert_true(p.journeys_done.has("kungsleden"))
	assert_null(Journey.active(ContentDB.journeys(), p), "nothing left to walk")
	assert_eq(Journey.advance(p, ContentDB.journeys(), 10.0, _b), {}, "no second payout")
	var facts: Dictionary = ProfileFacts.build({}, p, 0, 0, ContentDB.get_trail)
	assert_eq(int(facts.journeys_done), 1, "the badge fact")


func test_real_steps_count_several_times_over() -> void:
	# 10 000 steps x 0.75 m = 7.5 km, x4 on the journey.
	assert_almost_eq(Journey.km_from_steps(10000, _b), 7.5 * _b.journey_real_km_mult, 0.001)
	assert_eq(Journey.km_from_steps(-5, _b), 0.0)


func test_reading_a_page_clears_it_from_unread() -> void:
	var p: PlayerProfile = PlayerProfile.new()
	var j: JourneyData = _kungsleden()
	Journey.advance(p, ContentDB.journeys(), 20.0, _b)
	assert_eq(Journey.unread(p), 2)
	Journey.mark_read(p, j, j.landmarks[0])
	Journey.mark_read(p, j, j.landmarks[0])
	assert_eq(Journey.unread(p), 1)
	Journey.mark_read(p, j, j.landmarks[5])
	assert_false(p.journey_seen.has(Journey.page_key(j, j.landmarks[5])), "a locked page can't be read")


func test_the_walker_sits_between_landmarks() -> void:
	var j: JourneyData = _kungsleden()
	var a: LandmarkData = j.landmarks[1]
	var b: LandmarkData = j.landmarks[2]
	var mid: Vector2 = Journey.map_position(j, (a.km + b.km) * 0.5)
	assert_almost_eq(mid.x, (a.map_pos.x + b.map_pos.x) * 0.5, 0.001)
	assert_eq(Journey.map_position(j, 0.0), j.landmarks[0].map_pos)
	assert_eq(Journey.map_position(j, 9999.0), j.landmarks[-1].map_pos)


func test_journey_content_is_well_formed() -> void:
	for j: JourneyData in ContentDB.journeys():
		assert_eq(j.landmarks[0].km, 0.0, "%s starts at km 0" % j.id)
		assert_almost_eq(j.landmarks[-1].km, j.length_km, 0.001, "%s ends at its length" % j.id)
		assert_ne(tr(j.name_key), j.name_key)
		assert_ne(tr(j.intro_key), j.intro_key)
		var last: float = -1.0
		for lm: LandmarkData in j.landmarks:
			assert_gt(lm.km, last, "%s landmarks in km order" % lm.id)
			last = lm.km
			for key: String in [lm.name_key, lm.page_title_key, lm.page_text_key]:
				assert_ne(tr(key), key, "string %s exists" % key)
			assert_true(Rect2(0, 0, 1, 1).has_point(lm.map_pos), "%s on the map" % lm.id)


func test_finished_hikes_and_claimed_steps_walk_the_journey() -> void:
	var trail: TrailData = ContentDB.get_trail(&"t01_forest_lake")
	var r: TrailResult = TrailResult.new(trail.id)
	r.finished = true
	r.time_seconds = 200.0
	var out: Dictionary = GameState.record_result(r)
	assert_almost_eq(float(out.journey.added), ContentDB.balance.journey_km_per_hike, 0.001)
	var unfinished: TrailResult = TrailResult.new(trail.id)
	assert_false(GameState.record_result(unfinished).has("journey"), "giving up walks nowhere")
	GameState.steps.turn_on(int(Time.get_unix_time_from_system()), GameState.today())
	var claim: Dictionary = GameState.claim_steps({GameState.today(): 4000})
	assert_eq(int(claim.steps), 4000)
	assert_true(claim.has("journey"), "claimed steps move the journey on")
	assert_almost_eq(float(claim.journey.added), Journey.km_from_steps(4000, ContentDB.balance), 0.001)
	assert_gt(Journey.km(GameState.profile, _kungsleden()), ContentDB.balance.journey_km_per_hike - 0.001)


func test_migrates_v9_save_to_v10_with_no_journey_yet() -> void:
	var v9: Dictionary = {"save_version": 9, "tp": 9, "profile": {"name": "Aino", "events": {"autumn_2026": 3}}}
	var out: Dictionary = SaveService.migrate(v9)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(out.profile.journeys, {})
	assert_eq(out.profile.journey_pages, [])
	assert_eq(out.profile.journeys_done, [])
	assert_eq(int(out.profile.events.autumn_2026), 3, "the rest of the profile is untouched")
	GameState.from_dict(out)
	assert_eq(GameState.profile.journeys, {})
	GameState.profile.journeys["kungsleden"] = 12.5
	GameState.profile.journey_pages.append("kungsleden/abisko")
	var round_trip: PlayerProfile = PlayerProfile.new()
	round_trip.from_dict(GameState.profile.to_dict())
	assert_almost_eq(float(round_trip.journeys.kungsleden), 12.5, 0.001)
	assert_eq(round_trip.journey_pages, ["kungsleden/abisko"] as Array[String])
