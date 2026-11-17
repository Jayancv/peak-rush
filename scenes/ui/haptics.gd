class_name Haptics
extends RefCounted
## Short vibrations for the moments that should be felt: a landing, the shutter, a find,
## the summit, a stumble. All go through here so the Vibration setting switches every one
## off. (Android needs the VIBRATE permission: export preset permissions/vibrate.)


static func pulse(ms: int, strength: float = -1.0) -> void:
	if ms <= 0 or not bool(GameState.settings.get("vibration", true)):
		return
	Input.vibrate_handheld(ms, strength)
