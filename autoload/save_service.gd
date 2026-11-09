extends Node
## Reads and writes user://save.json. Stub for M0; JSON, migrations and the
## corrupt-file fallback arrive in M3. The notification hooks are wired now so
## saving on app pause/close is never forgotten later.

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1


func save_game() -> void:
	pass  # M3


func _notification(what: int) -> void:
	# Phones can kill a backgrounded app without warning, so save on pause too.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
