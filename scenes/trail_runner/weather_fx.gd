class_name WeatherFx
extends CanvasLayer
## Screen-space weather on top of the world (under the HUD): a faint fog veil, rain
## streaks, snowflakes and wind streaks during gusts. The thick fog is a FogBank
## placed in the level behind the terrain (see add_world_fog), so the path stays clear.
## Emitters are sized to the viewport so wider phones get the same density. The trail runner feeds it the
## day tint, because CanvasModulate doesn't reach other canvas layers.

@export var fog_veil: ColorRect
@export var rain: CPUParticles2D
@export var snow: CPUParticles2D
@export var gusts: CPUParticles2D

## Over the path itself the fog is only a faint veil; the FogBank does the rest.
const FOG_VEIL_SHARE: float = 0.14

var _fog_alpha: float = 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_emitters)
	_fit_emitters()
	apply(null)


## Turns effects on and off for a weather profile (null = clear).
func apply(profile: WeatherProfile) -> void:
	var p: WeatherProfile = profile if profile != null else WeatherProfile.new()
	_fog_alpha = p.fog_density if p.fog else 0.0
	fog_veil.visible = p.fog
	fog_veil.color = Color(p.fog_color, _fog_alpha * FOG_VEIL_SHARE)
	rain.emitting = p.rain
	rain.amount = maxi(p.rain_amount, 1)
	snow.emitting = p.snow
	snow.amount = maxi(p.snow_amount, 1)
	gusts.emitting = false


## Puts a FogBank into `level` just after its backdrop, following `camera`.
func add_world_fog(profile: WeatherProfile, level: Node, after: Node, camera: Camera2D) -> FogBank:
	if profile == null or not profile.fog:
		return null
	var bank: FogBank = FogBank.new()
	bank.name = "FogBank"
	level.add_child(bank)
	level.move_child(bank, after.get_index() + 1 if after != null and after.get_parent() == level else 0)
	bank.setup(profile.fog_color, profile.fog_density, camera)
	return bank


func set_gusting(on: bool) -> void:
	gusts.emitting = on


## Day tint for everything on this layer (fog at dusk shouldn't glow white).
func set_tint(tint: Color) -> void:
	for item: CanvasItem in [fog_veil, rain, snow, gusts]:
		item.self_modulate = tint


func _fit_emitters() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	# Rain and snow fall from a strip just above the screen, a bit wider than it
	# (they drift sideways); wind streaks blow in from just past the right edge.
	for emitter: CPUParticles2D in [rain, snow]:
		emitter.position = Vector2(size.x * 0.5, -20.0)
		emitter.emission_rect_extents = Vector2(size.x * 0.6, 10.0)
	gusts.position = Vector2(size.x + 40.0, size.y * 0.5)
	gusts.emission_rect_extents = Vector2(20.0, size.y * 0.45)
