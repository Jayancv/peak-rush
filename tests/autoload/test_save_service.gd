extends GutTest
## Saves are sacred: round trips, migrations and broken files.

const PATH: String = "user://test_save_service.json"


func after_each() -> void:
	for f: String in [PATH, PATH + ".tmp", PATH + ".bak"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	for f: String in DirAccess.get_files_at("user://"):
		if f.begins_with("test_save_service.corrupt-") or f.begins_with("test_save_service.v"):
			DirAccess.remove_absolute("user://" + f)


func test_tests_never_use_the_real_save() -> void:
	assert_eq(SaveService.save_path, SaveService.TEST_SAVE_PATH)
	assert_false(SaveService.autosave)


func test_round_trip_stamps_version() -> void:
	assert_true(SaveService.write_to(PATH, {"tp": 120}))
	var back: Dictionary = SaveService.read_from(PATH)
	assert_eq(int(back.tp), 120)
	assert_eq(int(back.save_version), SaveService.SAVE_VERSION)
	assert_false(FileAccess.file_exists(PATH + ".tmp"), "temp file is cleaned up")


func test_overwrite_keeps_latest() -> void:
	SaveService.write_to(PATH, {"tp": 1})
	SaveService.write_to(PATH, {"tp": 2})
	assert_eq(int(SaveService.read_from(PATH).tp), 2)
	assert_false(FileAccess.file_exists(PATH + ".bak"))


func test_missing_file_is_a_fresh_start() -> void:
	assert_eq(SaveService.read_from(PATH), {})


func test_leftover_backup_is_recovered() -> void:
	# Simulates a crash between the two renames: only the .bak survived.
	SaveService.write_to(PATH, {"tp": 7})
	DirAccess.rename_absolute(PATH, PATH + ".bak")
	assert_eq(int(SaveService.read_from(PATH).tp), 7)


func test_corrupt_file_is_moved_aside_not_overwritten() -> void:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{ this is not json")
	f.close()
	assert_eq(SaveService.read_from(PATH), {})
	assert_push_warning("unreadable")
	assert_false(FileAccess.file_exists(PATH))
	var backups: Array = Array(DirAccess.get_files_at("user://")).filter(
		func(n: String) -> bool: return n.begins_with("test_save_service.corrupt-"))
	assert_eq(backups.size(), 1, "the bad file is kept for recovery")


func test_migrates_v0_prototype_save() -> void:
	var v0: Dictionary = {"points": 40, "stars": {"t01_forest_lake": 2}}
	var out: Dictionary = SaveService.migrate(v0)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(int(out.tp), 40)
	assert_false(out.has("points"))
	assert_eq(int(out.trails.t01_forest_lake.stars), StarRating.STAR_SUMMIT | StarRating.STAR_PHOTOS)


func test_current_version_passes_through_unchanged() -> void:
	var current: Dictionary = {"save_version": SaveService.SAVE_VERSION, "tp": 5, "profile": {"name": "Aino"}}
	assert_eq(SaveService.migrate(current), current)


func test_migrates_v1_save_to_v2_with_an_empty_profile() -> void:
	var v1: Dictionary = {"save_version": 1, "tp": 5, "trails": {"t01_forest_lake": {"stars": 1}}}
	var out: Dictionary = SaveService.migrate(v1)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(int(out.tp), 5)
	assert_true(out.profile is Dictionary)
	assert_eq(str(out.profile.name), "")
	assert_eq((out.profile.badges as Array).size(), 0)
	assert_eq(int(out.trails.t01_forest_lake.stars), 1, "progress is untouched")


func test_migrates_v2_save_to_v3_with_empty_finds() -> void:
	var v2: Dictionary = {"save_version": 2, "tp": 7, "trails": {"t01_forest_lake": {"stars": 3, "photos": {}}}, "profile": {"name": "Aino"}}
	var out: Dictionary = SaveService.migrate(v2)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq((out.trails.t01_forest_lake.finds as Array).size(), 0)
	assert_eq(int(out.trails.t01_forest_lake.stars), 3, "progress is untouched")
	assert_eq(str(out.profile.name), "Aino")


func test_newer_save_is_loaded_not_destroyed() -> void:
	var future: Dictionary = {"save_version": SaveService.SAVE_VERSION + 1, "tp": 9}
	assert_eq(int(SaveService.migrate(future).tp), 9)
	assert_push_warning("this app knows")


func test_full_game_state_survives_save_and_load() -> void:
	var saved: Dictionary = GameState.to_dict()
	GameState.reset()
	GameState.tp = 321
	GameState.trails = {"t01_forest_lake": {"stars": 5, "best_time": 77.5, "photos": {}, "completions": 2}}
	SaveService.write_to(PATH, GameState.to_dict())
	GameState.reset()
	GameState.from_dict(SaveService.read_from(PATH))
	assert_eq(GameState.tp, 321)
	assert_eq(GameState.best_time(&"t01_forest_lake"), 77.5)
	GameState.from_dict(saved)


func test_migrates_v3_save_to_v4_with_a_fresh_daily_streak() -> void:
	var v3: Dictionary = {"save_version": 3, "tp": 9, "profile": {"name": "Aino", "hikes": 4}}
	var out: Dictionary = SaveService.migrate(v3)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(str(out.profile.daily_last), "")
	assert_eq(int(out.profile.daily_streak), 0)
	assert_eq(int(out.profile.hikes), 4, "the rest of the profile is untouched")


func test_migrates_v4_save_to_v5_with_no_hints_seen() -> void:
	var v4: Dictionary = {"save_version": 4, "tp": 9, "profile": {"name": "Aino", "daily_streak": 3}}
	var out: Dictionary = SaveService.migrate(v4)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(out.profile.hints_seen, [])
	assert_eq(out.profile.daily_pick, {})
	assert_eq(int(out.profile.daily_streak), 3, "the rest of the profile is untouched")


func test_migrates_v5_save_to_v6_with_the_step_counter_off() -> void:
	var v5: Dictionary = {"save_version": 5, "tp": 9, "profile": {"name": "Aino"}}
	var out: Dictionary = SaveService.migrate(v5)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_false(bool(out.steps.enabled))
	assert_eq(int(out.steps.lifetime_steps), 0)
	assert_eq(int(out.tp), 9)
	GameState.from_dict(out)
	assert_false(GameState.steps.enabled, "migrated players must opt in themselves")
	GameState.reset()


func test_migrates_v6_save_to_v7_with_fresh_weekly_goals() -> void:
	var v6: Dictionary = {"save_version": 6, "tp": 9, "profile": {"name": "Aino", "hikes": 4}, "steps": {"enabled": true}}
	var out: Dictionary = SaveService.migrate(v6)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(out.profile.weekly, {})
	assert_eq(int(out.profile.hikes), 4, "the rest of the profile is untouched")
	assert_true(bool(out.steps.enabled), "and so is everything else")
	GameState.from_dict(out)
	assert_eq(GameState.profile.weekly, {})
	GameState.reset()


func test_migrates_v7_save_to_v8_with_no_shortcuts_found() -> void:
	var v7: Dictionary = {"save_version": 7, "tp": 9, "trails": {"t01_forest_lake": {"stars": 7, "best_time": 99.0}}, "profile": {"weekly": {}}}
	var out: Dictionary = SaveService.migrate(v7)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(out.trails.t01_forest_lake.shortcuts, [])
	assert_eq(int(out.trails.t01_forest_lake.stars), 7, "the rest of the record is untouched")
	GameState.from_dict(out)
	assert_eq(GameState.record(&"t01_forest_lake").shortcuts, [] as Array[String])
	GameState.reset()


func test_migrates_v8_save_to_v9_with_no_event_tokens() -> void:
	var v8: Dictionary = {"save_version": 8, "tp": 9, "profile": {"name": "Aino", "hikes": 3}}
	var out: Dictionary = SaveService.migrate(v8)
	assert_eq(int(out.save_version), SaveService.SAVE_VERSION)
	assert_eq(out.profile.events, {})
	assert_eq(out.profile.events_done, [])
	assert_eq(int(out.profile.hikes), 3, "the rest of the profile is untouched")
	GameState.from_dict(out)
	assert_eq(GameState.profile.events, {})
	GameState.reset()


func _write_raw(text: String) -> void:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_newer_save_file_is_copied_aside_before_this_app_touches_it() -> void:
	# The player went back an app version: the newer fields would vanish on the next autosave.
	var newer: int = SaveService.SAVE_VERSION + 1
	_write_raw(JSON.stringify({"save_version": newer, "tp": 9, "future_field": {"a": 1}}))
	assert_eq(int(SaveService.read_from(PATH).tp), 9)
	assert_push_warning("this app knows")
	var copy: String = "user://test_save_service.v%d-backup.json" % newer
	assert_true(FileAccess.file_exists(copy), "the original newer save is kept")
	var kept: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(copy))
	assert_true(kept.has("future_field"))
	SaveService.write_to(PATH, {"tp": 10})
	assert_true(JSON.parse_string(FileAccess.get_file_as_string(copy)).has("future_field"), "later saves don't overwrite the copy")


func test_killed_mid_write_keeps_the_old_save() -> void:
	# The app died while writing: a half-written .tmp is all that's new.
	SaveService.write_to(PATH, {"tp": 5})
	var f: FileAccess = FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	f.store_string("{\"tp\": 99, \"tra")
	f.close()
	assert_eq(int(SaveService.read_from(PATH).tp), 5, "the half-written file is ignored")
	assert_true(SaveService.write_to(PATH, {"tp": 6}), "and the next save still works")
	assert_eq(int(SaveService.read_from(PATH).tp), 6)


func test_empty_save_file_is_a_fresh_start_and_kept() -> void:
	# e.g. the phone ran out of storage.
	_write_raw("")
	assert_eq(SaveService.read_from(PATH), {})
	assert_push_warning("unreadable")
	assert_false(FileAccess.file_exists(PATH))


func test_damaged_fields_lose_only_that_field() -> void:
	var saved: Dictionary = GameState.to_dict()
	GameState.from_dict({"tp": 50, "trails": {"t01_forest_lake": {"stars": "lots", "best_time": 80.0, "photos": [1, 2], "finds": "oops"}}, "owned_gear": 7, "profile": "?"})
	var rec: Dictionary = GameState.record(&"t01_forest_lake")
	assert_eq(GameState.tp, 50)
	assert_eq(float(rec.best_time), 80.0)
	assert_eq(rec.photos, {}, "bad photos fall back to none")
	assert_eq(rec.finds, [] as Array[String])
	assert_eq(GameState.owned_gear, [] as Array[String])
	GameState.from_dict(saved)
