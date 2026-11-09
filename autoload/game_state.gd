extends Node
## Holds the player's progress and settings while the game runs.
## Stub for M0; progress, stars, TP and gear arrive in M3 (see docs/PLAN.md).

signal settings_changed

var settings: Dictionary = {
	"left_handed": false,
	"vibration": true,
}


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	settings_changed.emit()
