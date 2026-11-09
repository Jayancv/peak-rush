class_name Backdrop
extends Node2D
## The trail's scenery. Its sky lives on its own CanvasLayer, which the world's
## CanvasModulate doesn't reach, so the trail runner tints it through here and moves
## the sun along its arc as the day passes.

const GROUP: StringName = &"backdrop"
## Sun path across the screen as anchor fractions: rises low-left, peaks, sets low-right.
const SUN_START: Vector2 = Vector2(0.12, 0.42)
const SUN_PEAK: Vector2 = Vector2(0.5, 0.12)
const SUN_END: Vector2 = Vector2(0.88, 0.5)

@export var sky: CanvasItem
@export var sun_anchor: Control
## Warm gradient over the horizon that fades in as the light turns golden.
@export var horizon_glow: CanvasItem

## Multiplying a blue sky by an orange tint turns it grey, so the sky only takes
## part of the tint and the warmth comes from the glow instead.
const SKY_TINT_STRENGTH: float = 0.55


func _ready() -> void:
	add_to_group(GROUP)


func set_daylight(sun_progress: float, tint: Color) -> void:
	if sky != null:
		sky.modulate = Color.WHITE.lerp(tint, SKY_TINT_STRENGTH)
	if horizon_glow != null:
		# Warm tints have less blue than red; that gap is how golden the light is.
		var warmth: float = clampf((tint.r - tint.b) * 3.0, 0.0, 1.0)
		horizon_glow.modulate.a = warmth
	if sun_anchor != null:
		# Quadratic Bézier through the peak gives a natural arc.
		var t: float = sun_progress
		var p: Vector2 = SUN_START.lerp(SUN_PEAK, t).lerp(SUN_PEAK.lerp(SUN_END, t), t)
		sun_anchor.anchor_left = p.x
		sun_anchor.anchor_right = p.x
		sun_anchor.anchor_top = p.y
		sun_anchor.anchor_bottom = p.y
		# The sun dims as it sinks.
		sun_anchor.modulate = Color(1, 1, 1, 1.0 - smoothstep(0.85, 1.0, sun_progress) * 0.8)
