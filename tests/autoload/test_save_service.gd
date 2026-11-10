extends GutTest
## Saves are sacred: round trips, migrations and broken files.

const PATH: String = "user://test_save_service.json"


func after_each() -> void:
	for f: String in [PATH, PATH + ".tmp", PATH + ".bak"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	for f: String in DirAccess.get_files_at("user://"):
		if f.begins_with("test_save_service.corrupt-"):
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
	assert_eq(int(out.save_version), 3)
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
