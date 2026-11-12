class_name GhostTrack
extends Node2D
## The ghost of your best run: records where the hiker is every Balance.ghost_sample_seconds,
## keeps the samples of a new best time in user://ghosts/<trail>.json (a cache, not part of
## the save: losing it just loses the ghost), and replays the stored run as a faint hiker.

const DIR: String = "user://ghosts/"
const TEST_DIR: String = "user://ghosts_test/"
const COLOR: Color = Color(0.82, 0.93, 1.0, 0.6)

var _trail_id: StringName
var _daylight: Daylight
var _hiker: Hiker
var _step: float = 0.1
var _recorded: PackedVector2Array = PackedVector2Array()
var _since_sample: float = 0.0
var _replay: PackedVector2Array = PackedVector2Array()
var _replay_step: float = 0.1
var _at: Vector2 = Vector2.INF
var _facing: float = 1.0
var _phase: float = 0.0


static func file_for(trail_id: StringName) -> String:
	return (TEST_DIR if SaveService.is_test_run() else DIR) + String(trail_id) + ".json"


## {"step": s, "points": PackedVector2Array} of the stored best run, or {} if none.
static func load_run(trail_id: StringName) -> Dictionary:
	var path: String = file_for(trail_id)
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not (data as Dictionary).get("xy") is Array:
		return {}
	var xy: Array = data.xy
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(0, xy.size() - 1, 2):
		pts.append(Vector2(float(xy[i]), float(xy[i + 1])))
	return {"step": maxf(float(data.get("step", 0.1)), 0.02), "points": pts}


static func save_run(trail_id: StringName, step: float, points: PackedVector2Array) -> void:
	DirAccess.make_dir_recursive_absolute(file_for(trail_id).get_base_dir())
	var xy: Array = []
	for p: Vector2 in points:
		xy.append(snappedf(p.x, 0.1))
		xy.append(snappedf(p.y, 0.1))
	var f: FileAccess = FileAccess.open(file_for(trail_id), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"step": step, "xy": xy}))


func setup(hiker: Hiker, trail_id: StringName, daylight: Daylight, step: float, replay: bool) -> void:
	_hiker = hiker
	_trail_id = trail_id
	_daylight = daylight
	_step = step
	z_index = 2
	if replay:
		var run: Dictionary = load_run(trail_id)
		if not run.is_empty():
			_replay = run.points
			_replay_step = run.step


func has_ghost() -> bool:
	return _replay.size() >= 2


func recorded_samples() -> int:
	return _recorded.size()


## Keeps this hike's run as the new ghost (call after a new best time).
func keep_run() -> void:
	if _recorded.size() >= 2:
		save_run(_trail_id, _step, _recorded)


func _process(delta: float) -> void:
	if _hiker != null and not _hiker.finished:
		_since_sample += delta
		if _since_sample >= _step or _recorded.is_empty():
			_since_sample = 0.0
			_recorded.append(_hiker.global_position)
	if not has_ghost() or _daylight == null:
		return
	var f: float = _daylight.elapsed / _replay_step
	var i: int = mini(int(f), _replay.size() - 1)
	var j: int = mini(i + 1, _replay.size() - 1)
	var now: Vector2 = _replay[i].lerp(_replay[j], f - floorf(f))
	if _at != Vector2.INF and absf(now.x - _at.x) > 0.5:
		_facing = signf(now.x - _at.x)
		_phase += absf(now.x - _at.x) * 0.12
	_at = now
	queue_redraw()


func _draw() -> void:
	if _at == Vector2.INF:
		return
	var o: Vector2 = to_local(_at)
	var swing: float = sin(_phase) * 7.0
	draw_line(o + Vector2(-2, -24), o + Vector2(-2 + swing, 0), COLOR, 3.0, true)
	draw_line(o + Vector2(2, -24), o + Vector2(2 - swing, 0), COLOR, 3.0, true)
	draw_rect(Rect2(o + Vector2(-7, -50), Vector2(14, 28)), COLOR, true)
	var pack_x: float = -16.0 if _facing > 0.0 else 7.0
	draw_rect(Rect2(o + Vector2(pack_x, -48), Vector2(9, 22)), COLOR, true)
	draw_circle(o + Vector2(0, -58), 8.0, COLOR, true, -1.0, true)
