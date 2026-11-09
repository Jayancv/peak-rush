extends GutTest
## Every player-facing string goes through translations/strings.csv: any text set in
## a scene file must be a key that the CSV defines (CLAUDE.md rule 10).

const SCAN_ROOTS: Array[String] = ["res://scenes", "res://world", "res://actors", "res://content"]
## Texts that are deliberately not words.
const ALLOWED: Array[String] = ["0", "0/0", "1", "?"]

var _keys: Dictionary = {}


func before_all() -> void:
	var csv: String = FileAccess.get_file_as_string("res://translations/strings.csv")
	for line: String in csv.split("\n"):
		var key: String = line.get_slice(",", 0).strip_edges()
		if not key.is_empty() and key != "keys":
			_keys[key] = true


func _scene_files(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	for f: String in dir.get_files():
		if f.ends_with(".tscn"):
			out.append(dir_path + "/" + f)
	for d: String in dir.get_directories():
		_scene_files(dir_path + "/" + d, out)


func test_scene_texts_are_translation_keys() -> void:
	var files: Array[String] = []
	for root: String in SCAN_ROOTS:
		_scene_files(root, files)
	assert_gt(files.size(), 10)
	var missing: Array[String] = []
	var regex: RegEx = RegEx.create_from_string('^(text|tooltip_text) = "(.*)"$')
	for path: String in files:
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var m: RegExMatch = regex.search(line)
			if m == null:
				continue
			var value: String = m.get_string(2)
			if ALLOWED.has(value) or _keys.has(value):
				continue
			missing.append("%s: %s" % [path, value])
	assert_eq(missing, [] as Array[String], "\n".join(missing))


func test_keys_used_in_code_exist() -> void:
	# The tr("KEY") calls in scripts.
	var regex: RegEx = RegEx.create_from_string('tr\\("([A-Z0-9_]+)"\\)')
	var files: Array[String] = []
	for root: String in ["res://scenes", "res://world", "res://actors", "res://autoload"]:
		var stack: Array[String] = [root]
		while not stack.is_empty():
			var d: String = stack.pop_back()
			var dir: DirAccess = DirAccess.open(d)
			if dir == null:
				continue
			for f: String in dir.get_files():
				if f.ends_with(".gd"):
					files.append(d + "/" + f)
			for sub: String in dir.get_directories():
				stack.append(d + "/" + sub)
	var missing: Array[String] = []
	for path: String in files:
		for m: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
			if not _keys.has(m.get_string(1)):
				missing.append("%s: %s" % [path, m.get_string(1)])
	assert_eq(missing, [] as Array[String], "\n".join(missing))


func test_no_duplicate_keys() -> void:
	var seen: Dictionary = {}
	var dupes: Array[String] = []
	for line: String in FileAccess.get_file_as_string("res://translations/strings.csv").split("\n"):
		var key: String = line.get_slice(",", 0).strip_edges()
		if key.is_empty():
			continue
		if seen.has(key):
			dupes.append(key)
		seen[key] = true
	assert_eq(dupes, [] as Array[String])
