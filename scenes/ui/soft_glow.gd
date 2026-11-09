class_name SoftGlow
extends RefCounted
## One smooth radial glow texture (white in the middle, fading to clear at the edge)
## shared by everything that glows: tint it with the draw colour or `modulate`.
## Many gradient stops on an ease-out curve, at a decent resolution, so there are no
## visible rings even when it's stretched across a phone screen.

const RESOLUTION: int = 512
const STOPS: int = 24

static var _texture: GradientTexture2D


static func texture() -> GradientTexture2D:
	if _texture == null:
		var gradient: Gradient = Gradient.new()
		var offsets: PackedFloat32Array = PackedFloat32Array()
		var colors: PackedColorArray = PackedColorArray()
		for i: int in STOPS + 1:
			var t: float = float(i) / float(STOPS)
			offsets.append(t)
			# Smooth falloff: bright core, long soft tail, exactly clear at the rim.
			var a: float = pow(1.0 - t, 2.2) * (1.0 - smoothstep(0.85, 1.0, t))
			colors.append(Color(1, 1, 1, a))
		gradient.offsets = offsets
		gradient.colors = colors
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.width = RESOLUTION
		_texture.height = RESOLUTION
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(0.5, 0.0)
	return _texture


## Draws the glow into `canvas` centred on `centre`, `radius` px out, tinted `color`.
static func draw(canvas: CanvasItem, centre: Vector2, radius: Vector2, color: Color) -> void:
	canvas.draw_texture_rect(texture(), Rect2(centre - radius, radius * 2.0), false, color)
