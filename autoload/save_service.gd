extends Node
## Reads and writes user://save.json. Saves are sacred:
## - every file carries save_version, and migrate() walks old versions forward one step
##   at a time via SaveMigrations (every format change = a new step + a test),
## - writes go to a temp file first, so a crash mid-write can't destroy the save,
## - a file that won't parse is moved aside (kept for support) and the game starts fresh.

const SAVE_VERSION: int = 10
const SAVE_PATH: String = "user://save.json"
## Tests must never touch a real player's save.
const TEST_SAVE_PATH: String = "user://save_test.json"

var save_path: String = SAVE_PATH
## Off under tests, which call save/load explicitly.
var autosave: bool = true


func _ready() -> void:
	if _running_tests():
		save_path = TEST_SAVE_PATH
		autosave = false
	load_game()
	GameState.progress_changed.connect(_autosave)
	GameState.settings_changed.connect(_autosave)


func save_game() -> bool:
	return write_to(save_path, GameState.to_dict())


func load_game() -> void:
	GameState.from_dict(read_from(save_path))


func _autosave() -> void:
	if autosave:
		save_game()


func _notification(what: int) -> void:
	# Phones can kill a backgrounded app without warning, so save on pause too.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if autosave:
			save_game()


# --- File handling (static so tests can use their own paths) ---

static func write_to(path: String, data: Dictionary) -> bool:
	var out: Dictionary = data.duplicate(true)
	out["save_version"] = SAVE_VERSION
	var tmp: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: can't write %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	# Swap the finished file in. The previous save survives as .bak until the swap is done.
	var bak: String = path + ".bak"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(path, bak)
	var err: Error = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		push_error("SaveService: couldn't move save into place (%s)" % error_string(err))
		DirAccess.rename_absolute(bak, path)
		return false
	DirAccess.remove_absolute(bak)
	return true


## Returns the migrated save, or {} for a missing or unreadable file (= fresh start).
static func read_from(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		# A crash between the two renames in write_to leaves only the backup.
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.rename_absolute(path + ".bak", path)
		else:
			return {}
	var json: JSON = JSON.new()
	# JSON.parse (unlike parse_string) reports a bad file quietly instead of as an engine error.
	var ok: bool = json.parse(FileAccess.get_file_as_string(path)) == OK
	var parsed: Variant = json.data if ok else null
	if not parsed is Dictionary:
		quarantine(path)
		return {}
	if int((parsed as Dictionary).get("save_version", 0)) > SAVE_VERSION:
		keep_newer_copy(path, int(parsed.save_version))
	return migrate(parsed)


## A save from a newer app (the player went back a version) would lose its newer
## fields on the next autosave, so keep the original beside it, once per version.
static func keep_newer_copy(path: String, version: int) -> String:
	var copy: String = "%s.v%d-backup.json" % [path.get_basename(), version]
	if not FileAccess.file_exists(copy):
		DirAccess.copy_absolute(path, copy)
	return copy


static func migrate(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var version: int = int(out.get("save_version", 0))
	if version > SAVE_VERSION:
		# Written by a newer app (e.g. after a downgrade). Load what we understand.
		push_warning("SaveService: save is version %d, this app knows %d" % [version, SAVE_VERSION])
		return out
	while version < SAVE_VERSION:
		out = SaveMigrations.step(version, out)
		version += 1
		out["save_version"] = version
	return out


## Moves an unreadable save aside instead of overwriting it, so it can be recovered.
static func quarantine(path: String) -> String:
	var backup: String = "%s.corrupt-%d.json" % [path.get_basename(), int(Time.get_unix_time_from_system())]
	DirAccess.rename_absolute(path, backup)
	push_warning("SaveService: save at %s was unreadable; moved to %s and starting fresh" % [path, backup])
	return backup


## True under GUT (tests must not touch real saves, show ads, ...).
static func is_test_run() -> bool:
	return _running_tests()


static func _running_tests() -> bool:
	for arg: String in OS.get_cmdline_args():
		if arg.ends_with("gut_cmdln.gd"):
			return true
	return false
