class_name UiMotion
extends RefCounted
## Shared UI motion so every screen moves the same way: buttons give a soft squish
## when pressed, and screens and lists ease in one item after another. Only scale and
## alpha are animated, because containers leave those alone. Timings are UI feel,
## not gameplay tuning, so they live here instead of balance.tres.

const PRESS_SCALE: float = 0.94
const PRESS_IN_SECONDS: float = 0.06
const PRESS_OUT_SECONDS: float = 0.24
const INTRO_SECONDS: float = 0.38
const INTRO_STAGGER: float = 0.06
## Long lists (journal stamps/postcards) stop staggering after this, so the last item
## never waits long.
const INTRO_MAX_DELAY: float = 0.45
const INTRO_START_SCALE: float = 0.92
## Set this meta on a button to opt it out of the press squish.
const NO_PRESS: StringName = &"no_press_motion"
const _TWEEN_META: StringName = &"_ui_motion_tween"
const _ALPHA_META: StringName = &"_ui_motion_alpha"


## Gives every button that ever enters `tree` the press squish (called once at boot).
static func watch(tree: SceneTree) -> void:
	tree.node_added.connect(func(node: Node) -> void:
		var button: BaseButton = node as BaseButton
		if button != null and not button.has_meta(NO_PRESS):
			button.button_down.connect(func() -> void: press(button))
	)


## A quick squish and spring back. It's a one-shot pulse rather than "hold while
## pressed", so a press cancelled by a scroll drag can never leave a button shrunk.
static func press(control: Control) -> void:
	if not control.is_inside_tree():
		return
	control.pivot_offset = control.size * 0.5
	var tween: Tween = _restart(control)
	tween.tween_property(control, "scale", Vector2.ONE * PRESS_SCALE, PRESS_IN_SECONDS).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, PRESS_OUT_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Eases `items` in one after another: fade up and grow from slightly small.
## Hidden items are skipped so the stagger has no gaps.
static func intro(items: Array, delay: float = 0.0) -> void:
	var i: int = 0
	for item: Variant in items:
		var control: Control = item as Control
		# Skips hidden items and old ones being replaced (freed at the end of the frame).
		if control == null or not control.visible or control.is_queued_for_deletion():
			continue
		var tween: Tween = _restart(control)
		# Some items are deliberately faded (locked trail cards), so return to their own alpha.
		var target_alpha: float = control.modulate.a
		control.set_meta(_ALPHA_META, target_alpha)
		control.modulate.a = 0.0
		control.scale = Vector2.ONE * INTRO_START_SCALE
		tween.tween_interval(delay + minf(float(i) * INTRO_STAGGER, INTRO_MAX_DELAY))
		# The size is only final after the container lays it out, so set the pivot late.
		tween.tween_callback(func() -> void: control.pivot_offset = control.size * 0.5)
		tween.tween_property(control, "modulate:a", target_alpha, INTRO_SECONDS * 0.7).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(control, "scale", Vector2.ONE, INTRO_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1


## A small bounce to draw the eye to something that just changed (a counter, a badge).
static func bump(control: Control, amount: float = 1.18) -> void:
	if not control.is_inside_tree():
		return
	control.pivot_offset = control.size * 0.5
	var tween: Tween = _restart(control)
	tween.tween_property(control, "scale", Vector2.ONE * amount, 0.09).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## One motion tween per control at a time, and it keeps running while the game is
## paused (the pause button squish would otherwise freeze half-way).
static func _restart(control: Control) -> Tween:
	# get_meta() with a null default still errors when the key is missing, hence has_meta().
	var old: Tween = control.get_meta(_TWEEN_META) as Tween if control.has_meta(_TWEEN_META) else null
	if old != null and old.is_valid():
		old.kill()
		# Finish what was interrupted (e.g. tapped mid-intro) instead of freezing half-faded.
		if control.has_meta(_ALPHA_META):
			control.modulate.a = float(control.get_meta(_ALPHA_META))
		control.scale = Vector2.ONE
	var tween: Tween = control.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	control.set_meta(_TWEEN_META, tween)
	return tween
