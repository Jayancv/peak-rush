extends GutTest
## Gear effects (GAME_DESIGN §5.7) and the shop rules.

const DIRT: TerrainStrip.Surface = TerrainStrip.Surface.DIRT

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func _mods(ids: Array[String]) -> HikeModifiers:
	var m: HikeModifiers = HikeModifiers.new(Balance.new())
	var items: Array[GearData] = []
	for id: String in ids:
		items.append(ContentDB.get_gear(StringName(id)))
	m.gear = GearModifiers.from_gear(items)
	return m


func test_no_gear_changes_nothing() -> void:
	var m: HikeModifiers = _mods([])
	assert_almost_eq(m.drain_multiplier(0.5, DIRT, false, 1.3), 2.0 * 1.3, 0.0001)
	assert_almost_eq(m.speed_multiplier(0.0, DIRT, true, false), 0.7, 0.0001)


func test_poles_cut_uphill_drain_by_20_percent() -> void:
	var m: HikeModifiers = _mods(["hiking_poles"])
	assert_almost_eq(m.drain_multiplier(0.5, DIRT, false), 2.0 * 0.8, 0.0001)
	assert_almost_eq(m.drain_multiplier(-0.5, DIRT, false), 1.0, 0.0001, "no effect downhill")


func test_rain_shell_halves_weather_drain() -> void:
	assert_almost_eq(_mods(["rain_shell"]).drain_multiplier(0.0, DIRT, false, 1.3), 1.15, 0.0001)


func test_headlamp_halves_dusk_penalty() -> void:
	assert_almost_eq(_mods(["bright_headlamp"]).speed_multiplier(0.0, DIRT, true, false), 0.85, 0.0001)


func test_thermos_speeds_up_rest() -> void:
	var gear: GearModifiers = GearModifiers.from_gear([ContentDB.get_gear(&"thermos")] as Array[GearData])
	var s: Stamina = Stamina.new(Balance.new())
	s.spend(50.0)
	s.rest(1.0, false, gear.rest_regen_scale)
	assert_almost_eq(s.value, 50.0 + 15.0 * 1.25, 0.001)


func test_grip_boots_cut_slip_by_75_percent() -> void:
	var gear: GearModifiers = GearModifiers.from_gear([ContentDB.get_gear(&"grip_boots")] as Array[GearData])
	assert_almost_eq(gear.slip_scale, 0.25, 0.0001)


func test_two_items_stack() -> void:
	var m: HikeModifiers = _mods(["hiking_poles", "rain_shell"])
	assert_almost_eq(m.drain_multiplier(0.5, DIRT, false, 1.3), 2.0 * 1.15 * 0.8, 0.0001)


func test_shop_sells_every_design_item() -> void:
	var ids: Array[StringName] = []
	for g: GearData in ContentDB.gear_list():
		ids.append(g.id)
	for id: StringName in [&"grip_boots", &"hiking_poles", &"rain_shell", &"thermos", &"bright_headlamp"]:
		assert_has(ids, id)


func test_buying_needs_enough_tp() -> void:
	GameState.tp = 100
	assert_false(GameState.buy(&"hiking_poles"), "costs 200")
	GameState.tp = 250
	assert_true(GameState.buy(&"hiking_poles"))
	assert_eq(GameState.tp, 50)
	assert_false(GameState.buy(&"hiking_poles"), "can't buy twice")


func test_only_two_slots() -> void:
	GameState.owned_gear = ["grip_boots", "thermos", "rain_shell"] as Array[String]
	assert_true(GameState.equip(&"grip_boots"))
	assert_true(GameState.equip(&"thermos"))
	assert_false(GameState.equip(&"rain_shell"), "both slots full")
	GameState.unequip(&"thermos")
	assert_true(GameState.equip(&"rain_shell"))
	assert_eq(GameState.equipped_items().size(), 2)


func test_cannot_equip_unowned_gear() -> void:
	assert_false(GameState.equip(&"thermos"))


func test_gear_survives_save_round_trip() -> void:
	GameState.owned_gear = ["thermos"] as Array[String]
	GameState.equipped_gear = ["thermos"] as Array[String]
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(data)
	assert_true(GameState.is_equipped(&"thermos"))
