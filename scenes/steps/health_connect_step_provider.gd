class_name HealthConnectStepProvider
extends StepProvider
## Steps from Android Health Connect, through the PeakRushSteps plugin
## (android/plugins/peak_rush_steps, packaged by addons/peak_rush_steps). The plugin answers
## asynchronously with signals; callbacks wait here keyed by a request id.

const SINGLETON: String = "PeakRushSteps"

var _plugin: Object
var _next_id: int = 1
var _pending_reads: Dictionary = {}
var _pending_access: Array[Callable] = []


static func is_present() -> bool:
	return Engine.has_singleton(SINGLETON)


func _init() -> void:
	_plugin = Engine.get_singleton(SINGLETON)
	_plugin.connect("access_result", _on_access_result)
	_plugin.connect("days_read", _on_days_read)


func status() -> Status:
	# The plugin's numbers follow StepProvider.Status.
	return int(_plugin.call("getStatus")) as Status


func request_access(on_done: Callable) -> void:
	_pending_access.append(on_done)
	_plugin.call("requestAccess")


func read_days(dates: Array[String], since_unix: int, on_done: Callable) -> void:
	var id: int = _next_id
	_next_id += 1
	_pending_reads[id] = on_done
	_plugin.call("readDays", id, JSON.stringify({"dates": dates, "since_unix": since_unix}))


func install_app() -> void:
	_plugin.call("openStore")


func _on_access_result(granted: bool) -> void:
	var waiting: Array[Callable] = _pending_access.duplicate()
	_pending_access.clear()
	for cb: Callable in waiting:
		cb.call(granted)


func _on_days_read(id: int, totals_json: String, ok: bool) -> void:
	var cb: Callable = _pending_reads.get(id, Callable())
	_pending_reads.erase(id)
	if not cb.is_valid():
		return
	var parsed: Variant = JSON.parse_string(totals_json)
	var totals: Dictionary = {}
	if parsed is Dictionary:
		for date: Variant in parsed:
			totals[str(date)] = int(parsed[date])
	cb.call(totals, ok and parsed is Dictionary)
