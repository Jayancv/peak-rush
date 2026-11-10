@tool
class_name WindZone
extends HikerArea
## An exposed ridge: gusts hit harder here (Balance.exposed_gust_mult) and a steady
## headwind slows the walk. Stopping braces the hiker, as everywhere else. A windsock
## at the start shows what's coming; it flaps with the wind (sway shader).

const GROUP: StringName = &"wind_zone"
const POLE: Color = Color("#5C4A3A")
const SOCK: Color = Color("#E85D3F")
const SOCK_STRIPE: Color = Color("#FFF6E5")

signal hiker_entered_zone

@export var width: float = 800.0:
	set(v):
		width = v
		rebuild()
@export var height: float = 320.0:
	set(v):
		height = v
		rebuild()
## Steady push back down the trail while on the ridge (px/s), on top of the gusts.
@export var headwind: float = 22.0


func _ready() -> void:
	super()
	add_to_group(GROUP)


func build() -> void:
	ShapeUtil.add_rect_shape(self, Rect2(0, -height, width, height + 20.0))
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-2, 6), Vector2(2, 6), Vector2(1.5, -78), Vector2(-1.5, -78)]), POLE)
	# A cone of four stripes pointing back down the trail (the way the wind blows).
	for i: int in 4:
		var x0: float = -float(i) * 9.0
		var x1: float = x0 - 9.0
		var h0: float = 8.0 - float(i) * 1.3
		var h1: float = h0 - 1.3
		var stripe: Polygon2D = ShapeUtil.add_poly(self, PackedVector2Array([Vector2(x0, -76 - h0 * 0.5), Vector2(x1, -76 - h1 * 0.5),
			Vector2(x1, -76 + h1 * 0.5), Vector2(x0, -76 + h0 * 0.5)]), SOCK if i % 2 == 0 else SOCK_STRIPE)
		# The tail end flaps most: sway weight grows along the sock.
		var w0: float = float(i) / 4.0
		var w1: float = float(i + 1) / 4.0
		stripe.uv = PackedVector2Array([Vector2(0, w0), Vector2(0, w1), Vector2(0, w1), Vector2(0, w0)])
		TerrainStrip.apply_sway(stripe, 0.0, 3.0, 10.0)


func _hiker_entered(hiker: Hiker) -> void:
	hiker.condition.enter_wind_zone(headwind)
	hiker_entered_zone.emit()


func _hiker_exited(hiker: Hiker) -> void:
	hiker.condition.exit_wind_zone(headwind)
