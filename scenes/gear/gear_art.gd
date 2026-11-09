@tool
class_name GearArt
extends Control
## Shaded illustrations of the gear items, drawn in code so they stay crisp at any
## size. Drawn in a 100 x 100 unit box centred in the control. `showcase` adds a soft
## spotlight and a floor shadow, for the shop cards.

@export var kind: GearData.Icon = GearData.Icon.BOOTS:
	set(v):
		kind = v
		queue_redraw()
@export var showcase: bool = false:
	set(v):
		showcase = v
		queue_redraw()
## Faded a little (not owned yet).
@export var dimmed: bool = false:
	set(v):
		dimmed = v
		modulate.a = 0.6 if v else 1.0

const INK: Color = Color("#2B2D42")
const CREAM: Color = Color("#FFF6E5")
const STEEL: Color = Color("#AEB6C1")
const STEEL_DARK: Color = Color("#6E7887")
const ACCENT: Color = Color("#E85D3F")
## Spotlight colour per item, so each card has its own mood.
const SPOT: Array[Color] = [Color("#F3D7B5"), Color("#CFE0E8"), Color("#BFE0DE"), Color("#D9E6CF"), Color("#F5E6B0")]

var _u: float = 1.0
var _c: Vector2 = Vector2.ZERO


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	_u = s / 100.0
	_c = size * 0.5
	if showcase:
		_spotlight()
	match kind:
		GearData.Icon.BOOTS:
			_boots()
		GearData.Icon.POLES:
			_poles()
		GearData.Icon.SHELL:
			_shell()
		GearData.Icon.THERMOS:
			_thermos()
		GearData.Icon.HEADLAMP:
			_headlamp()


func _spotlight() -> void:
	SoftGlow.draw(self, _p(0, -4), Vector2(58, 58) * _u, Color(SPOT[kind], 0.95))
	_ellipse(_p(0, 40), Vector2(30, 4.5), Color(INK, 0.16))


# --- Items ---

func _boots() -> void:
	var leather: Color = Color("#8A5A3A")
	# Microspike chain and spikes under the sole.
	for i: int in 8:
		var x: float = -32.0 + float(i) * 9.5
		_poly([_v(x - 2.5, 37), _v(x + 2.5, 37), _v(x, 42)], STEEL_DARK)
	draw_line(_p(-36, 36.5), _p(40, 36.5), STEEL, 1.4 * _u, true)
	# Sole with lugs, then the midsole stripe.
	_round_rect(Rect2(-38, 27, 80, 9), 3.0, Color("#3A2E26"))
	for i: int in 7:
		_round_rect(Rect2(-34.0 + float(i) * 11.0, 34, 6, 3), 1.0, Color("#2A211B"))
	_round_rect(Rect2(-37, 23, 78, 5), 2.0, Color("#E7DCC6"))
	# Leather upper, lighter at the top.
	_shaded([_v(-34, 24), _v(-36, -4), _v(-33, -32), _v(-11, -35), _v(-6, -12), _v(16, -1), _v(33, 7), _v(40, 16), _v(40, 24)],
		leather.lightened(0.12), leather.darkened(0.15))
	_poly([_v(-34, 24), _v(-36, -4), _v(-33, -32), _v(-27, -32), _v(-29, 0), _v(-27, 24)], Color(leather.darkened(0.3), 0.5))
	# Rubber toe cap and heel counter.
	_shaded([_v(12, 2), _v(33, 7), _v(40, 16), _v(40, 24), _v(12, 24), _v(8, 14)], Color("#6B4E3A"), Color("#4E382A"))
	_shaded([_v(-34, 24), _v(-35, 8), _v(-24, 8), _v(-22, 24)], Color("#6B4E3A"), Color("#4E382A"))
	# Padded collar and tongue.
	_round_rect(Rect2(-35, -38, 26, 8), 4.0, ACCENT)
	_poly([_v(-13, -40), _v(-6, -40), _v(-2, -14), _v(-9, -16)], leather.lightened(0.25))
	# Laces with steel eyelets.
	var lace: PackedVector2Array = PackedVector2Array()
	for i: int in 5:
		var t: float = float(i) / 4.0
		var a: Vector2 = Vector2(lerpf(-12, 6, t), lerpf(-30, -6, t))
		lace.append(_p(a.x - 3, a.y))
		lace.append(_p(a.x + 3, a.y + 3))
		draw_circle(_p(a.x - 3.5, a.y - 0.5), 1.3 * _u, STEEL, true, -1.0, true)
	draw_polyline(lace, CREAM, 1.5 * _u, true)
	# Stitching highlight along the top line.
	draw_polyline(PackedVector2Array([_p(-30, -28), _p(-12, -30)]), Color(1, 1, 1, 0.35), 1.2 * _u, true)


func _poles() -> void:
	for side: float in [-1.0, 1.0]:
		var top: Vector2 = Vector2(side * 9.0 - 6.0, -42)
		var bottom: Vector2 = Vector2(side * 9.0 + 10.0, 42)
		var dir: Vector2 = (bottom - top).normalized()
		var at: Callable = func(t: float) -> Vector2: return top.lerp(bottom, t)
		# Upper shaft (thicker), clamp, lower shaft (thinner) and the tip.
		draw_line(_q(at.call(0.25)), _q(at.call(0.6)), STEEL, 4.0 * _u, true)
		draw_line(_q(at.call(0.25)), _q(at.call(0.6)), Color(1, 1, 1, 0.45), 1.0 * _u, true)
		draw_line(_q(at.call(0.6)), _q(at.call(0.93)), STEEL_DARK, 3.0 * _u, true)
		_round_rect_at(at.call(0.6), Vector2(7, 4), dir, ACCENT)
		draw_line(_q(at.call(0.93)), _q(bottom), INK, 2.0 * _u, true)
		# Snow basket.
		_ellipse(_q(at.call(0.86)), Vector2(7, 2.2), INK)
		# Cork grip with a dark cap, and the wrist strap.
		draw_line(_q(at.call(0.02)), _q(at.call(0.25)), Color("#B98E5F"), 6.5 * _u, true)
		for k: int in 3:
			var g: Vector2 = at.call(0.08 + 0.06 * float(k))
			draw_line(_q(g - dir.orthogonal() * 3.0), _q(g + dir.orthogonal() * 3.0), Color("#9C7448"), 0.9 * _u, true)
		draw_circle(_q(top), 3.6 * _u, INK, true, -1.0, true)
		draw_arc(_q(at.call(0.05) + Vector2(side * 6.0, 4)), 7.0 * _u, -0.6, 2.6, 16, Color("#2F4B7A"), 1.8 * _u, true)


func _shell() -> void:
	var shell: Color = Color("#2E86A8")
	var dark: Color = shell.darkened(0.25)
	# Hood (behind), sleeves, then the body.
	_shaded([_v(-14, -42), _v(14, -42), _v(18, -30), _v(-18, -30)], dark, shell)
	_shaded([_v(-22, -28), _v(-40, 2), _v(-38, 26), _v(-30, 28), _v(-26, 4), _v(-18, -12)], shell.lightened(0.05), dark)
	_shaded([_v(22, -28), _v(40, 2), _v(38, 26), _v(30, 28), _v(26, 4), _v(18, -12)], shell, dark.darkened(0.1))
	_shaded([_v(-22, -32), _v(22, -32), _v(26, 36), _v(-26, 36)], shell.lightened(0.1), shell.darkened(0.12))
	# Hood opening, cuffs, hem.
	_ellipse(_p(0, -33), Vector2(9, 4), INK.lightened(0.15))
	_poly([_v(-38, 24), _v(-30, 26), _v(-31, 30), _v(-39, 28)], INK)
	_poly([_v(38, 24), _v(30, 26), _v(31, 30), _v(39, 28)], INK)
	_round_rect(Rect2(-26, 33, 52, 4), 1.5, dark)
	# Centre zip with its pull, and two pocket zips.
	draw_line(_p(0, -30), _p(0, 35), INK, 1.6 * _u, true)
	_round_rect(Rect2(-1.6, -24, 3.2, 6), 1.0, STEEL)
	draw_line(_p(-18, 6), _p(-8, 14), INK, 1.3 * _u, true)
	draw_line(_p(18, 6), _p(8, 14), INK, 1.3 * _u, true)
	# Sheen and beading rain drops.
	_poly([_v(-18, -28), _v(-12, -28), _v(-16, 24), _v(-21, 24)], Color(1, 1, 1, 0.14))
	for d: Vector2 in [Vector2(10, -16), Vector2(16, 20), Vector2(-10, 26), Vector2(-30, -2), Vector2(32, 10)]:
		_ellipse(_p(d.x, d.y), Vector2(1.6, 2.2), Color(1, 1, 1, 0.65))


func _thermos() -> void:
	# Steam first, so the flask sits in front of it.
	for k: int in 3:
		var x: float = -6.0 + float(k) * 6.0
		var wisp: PackedVector2Array = PackedVector2Array()
		for i: int in 9:
			var t: float = float(i) / 8.0
			wisp.append(_p(x + sin(t * TAU + float(k)) * 2.5, -44.0 - t * 12.0))
		draw_polyline(wisp, Color(1, 1, 1, 0.6), 1.6 * _u, true)
	# Steel flask with a vertical sheen, a green sleeve, then the cup lid.
	_round_rect(Rect2(-16, -26, 32, 64), 7.0, STEEL_DARK)
	_round_rect(Rect2(-14, -26, 22, 64), 7.0, STEEL)
	_round_rect(Rect2(-9, -22, 4, 56), 2.0, Color(1, 1, 1, 0.5))
	_round_rect(Rect2(-16.5, 0, 33, 18), 2.0, Color("#3E6B4F"))
	_round_rect(Rect2(-16.5, 4, 33, 2), 1.0, Color("#5E8C6A"))
	_round_rect(Rect2(-12, -34, 24, 9), 3.0, INK)
	for i: int in 5:
		draw_line(_p(-9.0 + float(i) * 4.5, -33), _p(-9.0 + float(i) * 4.5, -26), Color(1, 1, 1, 0.18), 1.0 * _u, true)
	_round_rect(Rect2(-8, -40, 16, 7), 2.5, INK.lightened(0.15))


func _headlamp() -> void:
	# Light beam behind everything.
	draw_colored_polygon(PackedVector2Array([_p(6, -4), _p(46, -24), _p(46, 18)]), Color("#FFE9A8", 0.35))
	# Elastic band: a thick ring with reflective stripes.
	draw_arc(_p(-8, 6), 30.0 * _u, 0.0, TAU, 48, Color("#2F4B7A"), 7.0 * _u, true)
	for i: int in 6:
		var a: float = 1.2 + float(i) * 0.75
		draw_arc(_p(-8, 6), 30.0 * _u, a, a + 0.18, 6, Color("#F2B33D"), 7.0 * _u, true)
	# Lamp housing with a glowing lens and a button.
	_round_rect(Rect2(-6, -16, 22, 22), 6.0, INK)
	_round_rect(Rect2(-6, -16, 22, 9), 6.0, INK.lightened(0.12))
	draw_circle(_p(7, -5), 7.0 * _u, Color("#FFF1B8"), true, -1.0, true)
	draw_circle(_p(7, -5), 4.0 * _u, Color.WHITE, true, -1.0, true)
	draw_arc(_p(7, -5), 7.0 * _u, 0.0, TAU, 24, STEEL, 1.4 * _u, true)
	_round_rect(Rect2(-3, -19, 6, 3), 1.0, ACCENT)


# --- Drawing helpers (all in 100-unit space around the centre) ---

func _p(x: float, y: float) -> Vector2:
	return _c + Vector2(x, y) * _u


func _q(v: Vector2) -> Vector2:
	return _c + v * _u


func _v(x: float, y: float) -> Vector2:
	return Vector2(x, y)


func _poly(pts: Array, col: Color) -> void:
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in pts:
		out.append(_q(p))
	draw_colored_polygon(out, col)


## A polygon shaded from `top` to `bottom` colour by height.
func _shaded(pts: Array, top: Color, bottom: Color) -> void:
	var lo: float = INF
	var hi: float = -INF
	for p: Vector2 in pts:
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
	var out: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	for p: Vector2 in pts:
		out.append(_q(p))
		cols.append(top.lerp(bottom, (p.y - lo) / maxf(hi - lo, 0.001)))
	draw_polygon(out, cols)


func _round_rect(r: Rect2, radius: float, col: Color) -> void:
	# Just under half the short side: at exactly half the corner arcs share a point
	# and the polygon can't be triangulated.
	var safe: float = minf(radius, minf(r.size.x, r.size.y) * 0.49)
	var pts: PackedVector2Array = ShapeUtil.rounded_rect(Rect2(_q(r.position), r.size * _u), safe * _u)
	draw_colored_polygon(pts, col)


## A small rotated rounded band across a pole (the length clamp).
func _round_rect_at(centre: Vector2, half: Vector2, dir: Vector2, col: Color) -> void:
	var n: Vector2 = dir.orthogonal()
	var a: Vector2 = centre - n * half.x * 0.5 - dir * half.y * 0.5
	_poly([a, a + n * half.x, a + n * half.x + dir * half.y, a + dir * half.y], col)


func _ellipse(centre: Vector2, radii: Vector2, col: Color) -> void:
	draw_colored_polygon(ShapeUtil.ellipse(centre, radii * _u, 18), col)
