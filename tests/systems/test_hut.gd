extends GutTest
## The hut title screen: light by the real clock, weather by the month, which keepsakes
## go on the walls, the summit lines and the phone feel (vibrate permission, setting).

var _b: Balance = Balance.new()


# These are statics, so a failing test must not leave them set for the rest of the run.
func after_each() -> void:
	HutRoom.hour_override = -1.0
	HutRoom.month_override = 0
	Journal.open_finds = false


func _trails() -> Array[TrailData]:
	var out: Array[TrailData] = []
	for s: SeasonData in ContentDB.seasons():
		out.append_array(s.trails)
	return out


func test_the_light_follows_the_clock() -> void:
	assert_eq(HutView.phase(3.0, _b), HutView.Phase.NIGHT)
	assert_eq(HutView.phase(6.5, _b), HutView.Phase.DAWN)
	assert_eq(HutView.phase(12.0, _b), HutView.Phase.DAY)
	assert_eq(HutView.phase(19.0, _b), HutView.Phase.DUSK)
	assert_eq(HutView.phase(23.0, _b), HutView.Phase.NIGHT)
	assert_eq(HutView.tint(12.0, _b), _b.tint_midday, "midday is untinted")
	assert_eq(HutView.tint(2.0, _b), _b.hut_night_tint, "moonlit, not pitch dark")
	assert_eq(HutView.tint(_b.hut_dusk_hour, _b), _b.tint_golden)
	assert_almost_eq(HutView.sun_progress(_b.hut_dawn_hour, _b), 0.0, 0.001)
	assert_almost_eq(HutView.sun_progress(23.0, _b), 1.0, 0.001)


func test_the_weather_follows_the_month() -> void:
	assert_eq(HutView.weather(12), HutView.Weather.SNOW)
	assert_eq(HutView.weather(1), HutView.Weather.SNOW)
	assert_eq(HutView.weather(11), HutView.Weather.SNOW)
	assert_eq(HutView.weather(4), HutView.Weather.BLOSSOM)
	assert_eq(HutView.weather(7), HutView.Weather.NONE)
	assert_eq(HutView.weather(10), HutView.Weather.LEAVES)


func test_elsas_traces_go_on_the_shelf_first() -> void:
	var t01: TrailData = ContentDB.get_trail(&"t01_forest_lake")
	var finds: Array = []
	for f: FindData in t01.finds:
		finds.append(String(f.id))
	var records: Dictionary = {"t01_forest_lake": {"finds": finds}}
	var shelf: Array[FindData] = HutView.shelf_finds(records, _trails(), 99)
	assert_eq(shelf.size(), t01.finds.size(), "only finds the player has")
	assert_eq(shelf[0].kind, FindData.Kind.TRACE)
	assert_eq(HutView.shelf_finds(records, _trails(), 2).size(), 2, "shelf slots cap it")
	assert_true(HutView.shelf_finds({}, _trails(), 8).is_empty())


func test_the_best_photos_go_on_the_wall() -> void:
	var t01: TrailData = ContentDB.get_trail(&"t01_forest_lake")
	var t02: TrailData = ContentDB.get_trail(&"t02_archipelago_rocks")
	var good: String = String(t01.viewpoints[0].id)
	var perfect: String = String(t02.viewpoints[0].id)
	var records: Dictionary = {
		"t01_forest_lake": {"photos": {good: StarRating.PhotoQuality.GOOD}},
		"t02_archipelago_rocks": {"photos": {perfect: StarRating.PhotoQuality.PERFECT}},
	}
	var cards: Array[Dictionary] = HutView.wall_postcards(records, _trails(), 3)
	assert_eq(cards.size(), 2)
	assert_eq((cards[0].viewpoint as ViewpointData).id, t02.viewpoints[0].id, "perfect shot first")
	assert_eq(HutView.wall_postcards(records, _trails(), 1).size(), 1)


func test_the_menu_builds_the_hut_with_keepsakes() -> void:
	var saved: Dictionary = GameState.to_dict()
	GameState.reset()
	HutRoom.hour_override = 23.0
	var menu: Node = add_child_autofree((load(SceneRouter.MAIN_MENU) as PackedScene).instantiate())
	var hut: HutRoom = menu.get_node_or_null("Hut") as HutRoom
	assert_not_null(hut)
	assert_eq(hut.phase, HutView.Phase.NIGHT)
	assert_not_null(hut.get_node_or_null("Keepsakes"))
	assert_lt(hut.get_index(), menu.get_node("SafeArea").get_index(), "the hut sits under the buttons")
	HutRoom.hour_override = -1.0
	GameState.from_dict(saved)


func test_the_snow_takes_the_light_of_the_hour() -> void:
	HutRoom.hour_override = 23.0
	HutRoom.month_override = 12
	var menu: Node = add_child_autofree((load(SceneRouter.MAIN_MENU) as PackedScene).instantiate())
	var snow: Node = menu.get_node_or_null("Weather")
	if UiMotion.reduced():
		assert_null(snow, "no snow with reduce motion")
		return
	assert_not_null(snow)
	assert_lt(snow.get_index(), menu.get_node("OutsideLight").get_index(), "under the light, so night snow isn't glowing white")


func test_a_respawn_or_ladder_is_not_a_hard_landing() -> void:
	var hiker: Hiker = add_child_autofree((load("res://actors/hiker/hiker.tscn") as PackedScene).instantiate())
	hiker.set("_air_seconds", 2.0)
	hiker.teleport(Vector2(100, 100))
	assert_eq(float(hiker.get("_air_seconds")), 0.0, "a fall's air time is dropped on respawn")


func test_every_trail_has_a_summit_line() -> void:
	for t: TrailData in _trails():
		assert_ne(t.summit_line_key, "", "%s has no summit line" % t.id)
		assert_ne(tr(t.summit_line_key), t.summit_line_key, "%s summit line has no text" % t.id)


func test_android_can_vibrate() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load("res://export_presets.cfg") != OK:
		pending("no export presets in this checkout")
		return
	var i: int = 0
	while cfg.has_section("preset.%d" % i):
		if str(cfg.get_value("preset.%d" % i, "platform", "")) == "Android":
			assert_true(bool(cfg.get_value("preset.%d.options" % i, "permissions/vibrate", false)),
				"preset %d needs permissions/vibrate or no haptics reach the phone" % i)
		i += 1


func test_haptics_stay_quiet_when_vibration_is_off() -> void:
	var before: bool = bool(GameState.settings.get("vibration", true))
	GameState.set_setting("vibration", false)
	Haptics.pulse(100)
	Haptics.pulse(0)
	pass_test("no crash with vibration off or a zero-length pulse")
	GameState.set_setting("vibration", before)


func test_every_keepsake_leads_somewhere() -> void:
	var room: HutRoom = HutRoom.new()
	room.size = Vector2(1560, 720)
	add_child_autofree(room)
	var wall: HutWall = HutWall.new()
	wall.room = room
	wall.size = room.size
	room.add_child(wall)
	var t01: TrailData = ContentDB.get_trail(&"t01_forest_lake")
	var cards: Array[Dictionary] = [{"trail": t01, "viewpoint": t01.viewpoints[0], "quality": 3}]
	var finds: Array[FindData] = [t01.finds[0]]
	var badges: Array[BadgeData] = [ContentDB.badge_list()[0]]
	wall.fill(cards, finds, badges)
	var elsa: Rect2 = wall.get("_card_rects")[0]
	var mine: Rect2 = wall.get("_card_rects")[1]
	assert_eq(wall.target_at(elsa.get_center()), SceneRouter.JOURNEY, "Elsa's photo opens her journey")
	assert_eq(wall.target_at(mine.get_center()), SceneRouter.JOURNAL, "a postcard opens the journal")
	assert_eq(wall.target_at(wall.call("_shelf_area").get_center()), "finds")
	assert_eq(wall.target_at(wall.call("_patch_area").get_center()), SceneRouter.PROFILE)
	assert_eq(wall.target_at(Vector2(780, 360)), "", "the window itself isn't a keepsake")
	assert_true(room.notebook_rect().position.x >= room.wall_width(), "the notebook lies on the sill")
	assert_true(room.hiker_rect().end.x <= room.wall_width() + 20.0, "the hiker sits by the wall")


func test_the_journal_can_open_on_the_finds() -> void:
	Journal.open_finds = true
	var journal: Node = add_child_autofree((load(SceneRouter.JOURNAL) as PackedScene).instantiate())
	assert_true(bool(journal.get("_showing_finds")))
	assert_false(Journal.open_finds, "only once")
