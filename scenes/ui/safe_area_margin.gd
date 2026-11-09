class_name SafeAreaMargin
extends MarginContainer
## Keeps its children clear of notches and rounded corners. Put every screen's
## UI inside one of these.

## Breathing room added on top of the safe-area inset.
@export var padding: int = 24


func _ready() -> void:
	# A full-screen container must never swallow touches meant for TouchControls.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var insets: Vector4 = _safe_insets()
	# A hole-punch camera only insets one side, and that side flips when the phone
	# rotates. Mirroring it keeps centred UI centred and corner buttons in the same place.
	var side: int = padding + int(maxf(insets.x, insets.z))
	add_theme_constant_override("margin_left", side)
	add_theme_constant_override("margin_top", padding + int(insets.y))
	add_theme_constant_override("margin_right", side)
	add_theme_constant_override("margin_bottom", padding + int(insets.w))


## Returns (left, top, right, bottom) insets in viewport units.
func _safe_insets() -> Vector4:
	# On desktop the "safe area" is the whole monitor, not the window, so it
	# would produce nonsense margins. Only phones have notches.
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Vector4.ZERO
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	# Safe area is in screen pixels; margins are in stretched viewport units.
	var to_view: Vector2 = get_viewport_rect().size / window_size
	return Vector4(
		maxf(safe.position.x, 0.0) * to_view.x,
		maxf(safe.position.y, 0.0) * to_view.y,
		maxf(window_size.x - safe.end.x, 0.0) * to_view.x,
		maxf(window_size.y - safe.end.y, 0.0) * to_view.y,
	)
