extends GutTest

const DIRT: TerrainStrip.Surface = TerrainStrip.Surface.DIRT
const MUD: TerrainStrip.Surface = TerrainStrip.Surface.MUD
const ICE: TerrainStrip.Surface = TerrainStrip.Surface.ICE

var mods: HikeModifiers


func before_each() -> void:
	mods = HikeModifiers.new(Balance.new())


func test_flat_dirt_is_neutral() -> void:
	assert_almost_eq(mods.speed_multiplier(0.0, DIRT, false, false), 1.0, 0.0001)
	assert_almost_eq(mods.drain_multiplier(0.0, DIRT, false), 1.0, 0.0001)


func test_mud_is_slow_and_tiring() -> void:
	assert_almost_eq(mods.speed_multiplier(0.0, MUD, false, false), 0.6, 0.0001)
	assert_almost_eq(mods.drain_multiplier(0.0, MUD, false), 2.0, 0.0001)


func test_ice_is_slippery_and_a_bit_slower() -> void:
	assert_true(HikeModifiers.is_slippery(ICE))
	assert_false(HikeModifiers.is_slippery(DIRT))
	assert_almost_eq(mods.speed_multiplier(0.0, ICE, false, false), 0.85, 0.0001)


func test_dusk_slows_by_30_percent() -> void:
	assert_almost_eq(mods.speed_multiplier(0.0, DIRT, true, false), 0.7, 0.0001)


func test_recovering_halves_speed() -> void:
	assert_almost_eq(mods.speed_multiplier(0.0, DIRT, false, true), 0.5, 0.0001)


func test_wet_feet_add_20_percent_drain() -> void:
	assert_almost_eq(mods.drain_multiplier(0.0, DIRT, true), 1.2, 0.0001)


func test_effects_multiply_together() -> void:
	# Uphill 0.5 in mud at dusk: 0.75 × 0.6 × 0.7
	assert_almost_eq(mods.speed_multiplier(0.5, MUD, true, false), 0.315, 0.0001)
	# Uphill 0.5 in mud with wet feet in rain ×1.3: 2 × 2 × 1.2 × 1.3
	assert_almost_eq(mods.drain_multiplier(0.5, MUD, true, 1.3), 6.24, 0.0001)
