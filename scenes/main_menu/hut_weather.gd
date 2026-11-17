class_name HutWeather
extends RefCounted
## The real season falling past the hut window: snow in winter, blossom in spring,
## leaves in autumn. Soft round flakes from a radial gradient (no image files).
## Nothing with Reduce motion on, or in summer.


static func create(kind: HutView.Weather, view: Vector2) -> CPUParticles2D:
	if kind == HutView.Weather.NONE or UiMotion.reduced():
		return null
	var p: CPUParticles2D = CPUParticles2D.new()
	p.name = "Weather"
	p.texture = _flake()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(view.x * 0.5 + 120.0, 4.0)
	p.position = Vector2(view.x * 0.5, -16.0)
	p.direction = Vector2(0.25, 1.0)
	p.spread = 14.0
	p.gravity = Vector2(0, 10)
	p.lifetime = 11.0
	p.preprocess = 11.0
	match kind:
		HutView.Weather.SNOW:
			p.amount = 70
			p.color = Color(1, 1, 1, 0.9)
			p.initial_velocity_min = 34.0
			p.initial_velocity_max = 58.0
			p.scale_amount_min = 0.25
			p.scale_amount_max = 0.6
		HutView.Weather.BLOSSOM:
			p.amount = 34
			p.color = Color("#F7BFD0")
			p.initial_velocity_min = 26.0
			p.initial_velocity_max = 44.0
			p.direction = Vector2(0.6, 1.0)
			p.scale_amount_min = 0.35
			p.scale_amount_max = 0.6
		HutView.Weather.LEAVES:
			p.amount = 30
			p.color = Color("#E0883A")
			p.color_ramp = null
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 50.0
			p.direction = Vector2(0.8, 1.0)
			p.scale_amount_min = 0.7
			p.scale_amount_max = 1.1
	# A little drift so nothing falls in a straight line.
	p.tangential_accel_min = -6.0
	p.tangential_accel_max = 6.0
	return p


static func _flake() -> GradientTexture2D:
	var g: Gradient = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.85), Color(1, 1, 1, 0)])
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = g
	tex.width = 16
	tex.height = 16
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex
