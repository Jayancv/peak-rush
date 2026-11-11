class_name Steps
extends RefCounted
## The game's one door to the phone's step counter (static, like Ads, so no extra autoload).
## Picks the provider: Health Connect when its plugin is in the build, the mock in debug
## builds, and nothing otherwise (the setting is then hidden). StepLedger does the maths.

static var provider: StepProvider
## The last totals read from the phone (date -> steps), what claim() pays out.
static var _totals: Dictionary = {}
## False after a read failed because access was revoked in the system settings.
static var _access_ok: bool = true


static func _ensure() -> void:
	if provider != null:
		return
	if HealthConnectStepProvider.is_present():
		provider = HealthConnectStepProvider.new()
	elif OS.is_debug_build() and not SaveService.is_test_run():
		provider = MockStepProvider.new()
	else:
		provider = StepProvider.new()


## Tests swap the provider in.
static func use_provider(p: StepProvider) -> void:
	provider = p
	_totals = {}
	_access_ok = true


static func status() -> StepProvider.Status:
	_ensure()
	return provider.status()


static func is_supported() -> bool:
	return status() != StepProvider.Status.UNSUPPORTED


## On, and the phone still lets us read (access can be revoked behind our back).
static func is_on() -> bool:
	return GameState.steps.enabled and _access_ok


## Settings switch on: asks for access; `on_done(on: bool)`.
static func turn_on(on_done: Callable) -> void:
	_ensure()
	if provider.status() == StepProvider.Status.NEEDS_APP:
		provider.install_app()
		on_done.call(false)
		return
	provider.request_access(func(granted: bool) -> void:
		if granted:
			GameState.steps.turn_on(int(Time.get_unix_time_from_system()), GameState.today())
			_access_ok = true
			GameState.progress_changed.emit()
		on_done.call(granted))


static func turn_off() -> void:
	GameState.steps.turn_off()
	_totals = {}
	GameState.progress_changed.emit()


## Reads the phone; `on_done(pending_tp: int)` (0 when off or the read failed).
static func refresh(on_done: Callable) -> void:
	_ensure()
	if not GameState.steps.enabled:
		on_done.call(0)
		return
	var dates: Array[String] = GameState.steps.dates_to_read(GameState.today(), ContentDB.balance)
	provider.read_days(dates, GameState.steps.opt_in_unix, func(totals: Dictionary, ok: bool) -> void:
		_access_ok = ok
		_totals = totals if ok else {}
		on_done.call(pending_tp()))


## Today's steps in the last read (since opting in, if that was today).
static func today_steps() -> int:
	return int(_totals.get(GameState.today(), 0)) if is_on() else 0


## TP waiting in the last read.
static func pending_tp() -> int:
	if not is_on():
		return 0
	return GameState.steps.pending_tp(_totals, GameState.today(), ContentDB.balance)


## Pays out the last read: {tp, steps, badges}.
static func claim() -> Dictionary:
	if not is_on():
		return {"tp": 0, "steps": 0, "badges": []}
	return GameState.claim_steps(_totals)
