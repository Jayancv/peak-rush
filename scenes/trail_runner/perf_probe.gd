class_name PerfProbe
extends Node
## Debug builds only: logs frame-rate stats every few seconds to the device log
## ("PERF ..." lines, read with `adb logcat -s godot`), so performance can be
## checked on a real phone without an on-screen overlay.

const REPORT_SECONDS: float = 5.0
## A frame slower than this (ms) counts as a hitch the player can feel.
const HITCH_MS: float = 33.4

var _frames: int = 0
var _elapsed: float = 0.0
var _worst_ms: float = 0.0
var _hitches: int = 0


static func attach_if_debug(parent: Node) -> void:
	if OS.is_debug_build() and not OS.has_feature("editor"):
		var probe: PerfProbe = PerfProbe.new()
		probe.name = "PerfProbe"
		parent.add_child(probe)


func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	var ms: float = delta * 1000.0
	_worst_ms = maxf(_worst_ms, ms)
	if ms > HITCH_MS:
		_hitches += 1
	if _elapsed >= REPORT_SECONDS:
		print("PERF fps=%.1f worst_frame_ms=%.1f hitches=%d static_mem_mb=%.1f objects=%d" % [
			_frames / _elapsed, _worst_ms, _hitches,
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			int(Performance.get_monitor(Performance.OBJECT_COUNT))])
		_frames = 0
		_elapsed = 0.0
		_worst_ms = 0.0
		_hitches = 0
