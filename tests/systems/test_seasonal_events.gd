extends GutTest
## Seasonal events: which one is on, the year key (winter runs over New Year), days left,
## collecting towards the goal, and the share picture / seasonal particles plumbing.

var _b: Balance = Balance.new()


func _event(id: StringName) -> EventData:
	for ev: EventData in ContentDB.events():
		if ev.id == id:
			return ev
	return null


func test_the_calendar_picks_the_right_event() -> void:
	var events: Array[EventData] = ContentDB.events()
	assert_eq(SeasonalEvents.active(events, "2026-11-12").id, &"autumn")
	assert_eq(SeasonalEvents.active(events, "2026-12-24").id, &"winter_lights")
	assert_eq(SeasonalEvents.active(events, "2027-01-10").id, &"winter_lights", "winter runs over New Year")
	assert_eq(SeasonalEvents.active(events, "2027-04-02").id, &"spring_blossom")
	assert_eq(SeasonalEvents.active(events, "2027-07-01").id, &"midsummer")
	assert_null(SeasonalEvents.active(events, "2026-09-01"), "quiet weeks between events")


func test_winter_in_january_belongs_to_the_december_it_began() -> void:
	var winter: EventData = _event(&"winter_lights")
	assert_eq(SeasonalEvents.key_for(winter, "2026-12-20"), "winter_lights_2026")
	assert_eq(SeasonalEvents.key_for(winter, "2027-01-05"), "winter_lights_2026")
	assert_eq(SeasonalEvents.days_left(_event(&"autumn"), "2026-11-12"), 19)
	assert_eq(SeasonalEvents.days_left(winter, "2026-12-31"), 16)


func test_collecting_pays_per_token_and_once_for_the_goal() -> void:
	var autumn: EventData = _event(&"autumn")
	var profile: PlayerProfile = PlayerProfile.new()
	var out: Dictionary = SeasonalEvents.record(profile, autumn, "2026-11-12", 4, _b)
	assert_eq(int(out.count), 4)
	assert_eq(int(out.tp), 4 * _b.event_token_tp)
	assert_false(bool(out.done_now))
	out = SeasonalEvents.record(profile, autumn, "2026-11-13", 99, _b)
	assert_eq(int(out.count), autumn.goal, "the count stops at the goal")
	assert_true(bool(out.done_now))
	assert_eq(int(out.tp), (autumn.goal - 4) * _b.event_token_tp + _b.event_goal_tp)
	out = SeasonalEvents.record(profile, autumn, "2026-11-14", 3, _b)
	assert_eq(int(out.tp), 0, "nothing more once complete")
	out = SeasonalEvents.record(profile, autumn, "2027-10-02", 2, _b)
	assert_eq(int(out.count), 2, "next year's autumn is a fresh collection")


func test_share_writes_the_picture() -> void:
	var card_setup: Callable = func(card: Postcard) -> void:
		card.title = "Lake mirror"
		card.quality = 3
	var path: String = await PostcardShare.share(self, card_setup)
	assert_true(FileAccess.file_exists(path))


func test_seasonal_particles_join_the_weather_layer() -> void:
	var fx: WeatherFx = add_child_autofree((load("res://scenes/trail_runner/weather_fx.tscn") as PackedScene).instantiate()) as WeatherFx
	var leaves: CPUParticles2D = fx.add_seasonal(EventData.Particles.LEAVES, Color.ORANGE, 20)
	assert_not_null(leaves)
	assert_true(leaves.emitting)
	assert_eq(leaves.amount, 20)
	assert_null(fx.add_seasonal(EventData.Particles.NONE, Color.WHITE, 20))
