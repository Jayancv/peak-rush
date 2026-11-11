class_name StepProvider
extends RefCounted
## Where real-world step counts come from. This base class is also the "no step counter"
## provider (desktop, tests, phones without a health app): unsupported, and every callback
## answers straight away so screens never wait on it.
## HealthConnectStepProvider (Android) and MockStepProvider (debug builds) subclass it.

enum Status {
	## No step source on this device: the setting is hidden.
	UNSUPPORTED,
	## The health app is missing or too old; install_app() opens the store.
	NEEDS_APP,
	## Ready to ask for (or already has) permission.
	READY,
}


func status() -> Status:
	return Status.UNSUPPORTED


## Asks the player for read access to steps; `on_done(granted: bool)`.
func request_access(on_done: Callable) -> void:
	on_done.call(false)


## Daily step totals for `dates` ("YYYY-MM-DD", local days), counting only steps after
## `since_unix`. `on_done(totals: Dictionary, ok: bool)`: ok is false if access was
## revoked or the read failed (totals is then empty).
func read_days(_dates: Array[String], _since_unix: int, on_done: Callable) -> void:
	on_done.call({}, false)


## Opens the store page of the health app (Status.NEEDS_APP).
func install_app() -> void:
	pass
