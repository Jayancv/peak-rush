class_name TimeFormat
extends RefCounted
## Clock-style times for the HUD, results and trail cards.


## 83.4 -> "1:23"
static func mmss(seconds: float) -> String:
	var total: int = int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
