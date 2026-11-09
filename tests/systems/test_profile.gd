extends GutTest
## Player profile: badge rules, outfit unlocking, name cleaning, save round trip.

var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func _badge(rule: BadgeData.Rule, amount: int, id: StringName = &"b") -> BadgeData:
	var b: BadgeData = BadgeData.new()
	b.id = id
	b.rule = rule
	b.amount = amount
	return b


func test_badge_progress_is_capped_at_the_amount() -> void:
	var b: BadgeData = _badge(BadgeData.Rule.STARS, 6)
	assert_eq(BadgeRules.progress(b, {"stars": 4}), 4)
	assert_eq(BadgeRules.progress(b, {"stars": 40}), 6)
	assert_eq(BadgeRules.progress(b, {}), 0, "missing facts count as zero")
	assert_false(BadgeRules.is_earned(b, {"stars": 5}))
	assert_true(BadgeRules.is_earned(b, {"stars": 6}))


func test_newly_earned_skips_badges_already_held() -> void:
	var a: BadgeData = _badge(BadgeData.Rule.HIKES, 1, &"a")
	var b: BadgeData = _badge(BadgeData.Rule.HIKES, 1, &"b")
	var c: BadgeData = _badge(BadgeData.Rule.HIKES, 5, &"c")
	var earned: Array[BadgeData] = BadgeRules.newly_earned([a, b, c] as Array[BadgeData], {"hikes": 2}, ["a"] as Array[String])
	assert_eq(earned.size(), 1)
	assert_eq(earned[0].id, &"b")


func test_name_is_trimmed_and_shortened() -> void:
	assert_eq(PlayerProfile.clean_name("  Aino  "), "Aino")
	assert_eq(PlayerProfile.clean_name("A".repeat(40)).length(), PlayerProfile.MAX_NAME_LENGTH)
	GameState.set_hiker_name("   ")
	assert_eq(GameState.hiker_display_name(), tr("PROFILE_DEFAULT_NAME"), "blank falls back to the default")


func test_every_slot_has_a_free_default_and_skin_is_all_free() -> void:
	for slot: int in CosmeticData.Slot.values():
		assert_not_null(ContentDB.default_cosmetic(slot), "slot %s needs a free item" % CosmeticData.Slot.keys()[slot])
	for item: CosmeticData in ContentDB.cosmetics(CosmeticData.Slot.SKIN):
		assert_eq(item.stars_required, 0, "skin tones are never locked")


func test_cosmetic_ids_are_unique() -> void:
	var seen: Dictionary = {}
	for item: CosmeticData in ContentDB.index.cosmetics.items:
		assert_false(seen.has(item.id), "duplicate cosmetic id %s" % item.id)
		seen[item.id] = true


func test_locked_items_cannot_be_worn() -> void:
	var locked: CosmeticData = null
	for item: CosmeticData in ContentDB.cosmetics(CosmeticData.Slot.JACKET):
		if item.stars_required > 0:
			locked = item
			break
	assert_not_null(locked)
	assert_false(GameState.wear(locked))
	assert_eq(GameState.worn(CosmeticData.Slot.JACKET), ContentDB.default_cosmetic(CosmeticData.Slot.JACKET))
	# A save that names a locked item (e.g. edited by hand) still shows the default.
	GameState.profile.wear(locked)
	assert_eq(GameState.worn(CosmeticData.Slot.JACKET), ContentDB.default_cosmetic(CosmeticData.Slot.JACKET))


func test_free_items_can_be_worn_and_change_the_colours() -> void:
	var items: Array[CosmeticData] = ContentDB.cosmetics(CosmeticData.Slot.HAT)
	var second: CosmeticData = items[1]
	assert_eq(second.stars_required, 0)
	assert_true(GameState.wear(second))
	assert_eq(GameState.look_colors()[CosmeticData.Slot.HAT], second.color)


func test_finishing_a_hike_counts_it_and_awards_first_summit() -> void:
	var result: TrailResult = TrailResult.new(ContentDB.first_trail().id)
	result.finished = true
	result.time_seconds = 90.0
	var out: Dictionary = GameState.record_result(result)
	assert_eq(GameState.profile.hikes, 1)
	assert_almost_eq(GameState.profile.hike_seconds, 90.0, 0.01)
	assert_true((out.new_badges as Array).has("first_summit"))
	assert_true(GameState.profile.badges.has("first_summit"))
	var again: Dictionary = GameState.record_result(result)
	assert_false((again.new_badges as Array).has("first_summit"), "a badge is only new once")


func test_profile_survives_a_save_round_trip() -> void:
	GameState.set_hiker_name("Aino")
	GameState.wear(ContentDB.cosmetics(CosmeticData.Slot.PACK)[2])
	GameState.profile.add_hike(61.0)
	GameState.profile.badges.append("first_summit")
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.reset()
	GameState.from_dict(data)
	assert_eq(GameState.profile.hiker_name, "Aino")
	assert_eq(GameState.worn(CosmeticData.Slot.PACK), ContentDB.cosmetics(CosmeticData.Slot.PACK)[2])
	assert_eq(GameState.profile.hikes, 1)
	assert_true(GameState.profile.badges.has("first_summit"))


func test_badge_text_keys_exist() -> void:
	for badge: BadgeData in ContentDB.badge_list():
		assert_ne(tr(badge.name_key), badge.name_key, "missing string %s" % badge.name_key)
		assert_ne(tr(badge.description_key), badge.description_key, "missing string %s" % badge.description_key)
