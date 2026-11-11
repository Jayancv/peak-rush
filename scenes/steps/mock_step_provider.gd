class_name MockStepProvider
extends StepProvider
## Fake steps for debug builds on desktop, so the whole flow can be tried without a phone.
## Today ramps up (STEPS_PER_MINUTE since midnight, or since opting in if that was today);
## earlier days get a fixed made-up total. Tests set `fixed` instead.

## Far faster than walking, so a desktop test sees TP within minutes.
const STEPS_PER_MINUTE: int = 100
const PAST_DAY_STEPS: int = 6500

## Date -> steps; when set, it's returned as-is (tests).
var fixed: Dictionary = {}
var grant: bool = true
var access_ok: bool = true


func status() -> Status:
	return Status.READY


func request_access(on_done: Callable) -> void:
	on_done.call(grant)


func read_days(dates: Array[String], since_unix: int, on_done: Callable) -> void:
	if not access_ok:
		on_done.call({}, false)
		return
	var out: Dictionary = {}
	for date: String in dates:
		out[date] = int(fixed.get(date, 0)) if not fixed.is_empty() else _fake(date, since_unix)
	on_done.call(out, true)


func _fake(date: String, since_unix: int) -> int:
	if date != Time.get_date_string_from_system():
		return PAST_DAY_STEPS
	var t: Dictionary = Time.get_time_dict_from_system()
	var minutes_today: int = int(t.hour) * 60 + int(t.minute)
	var minutes_since_opt_in: int = int(Time.get_unix_time_from_system() - since_unix) / 60
	return mini(minutes_today, minutes_since_opt_in) * STEPS_PER_MINUTE
