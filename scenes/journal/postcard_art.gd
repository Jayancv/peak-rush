class_name PostcardArt
extends RefCounted
## Code-drawn postcard pictures, one little scene per ViewpointData.Motif, in the flat
## palette of the game. Used until a viewpoint gets a painted postcard texture.
## Everything is drawn into `pic` (a Rect2 in the card's local space) with plain
## polygons, so it scales to any card size and costs nothing to load.

const DAY_TOP: Color = Color("#7FBCDD")
const DAY_LOW: Color = Color("#DCEFF4")
const NIGHT_TOP: Color = Color("#141B36")
const NIGHT_LOW: Color = Color("#3C4C7E")
const SUN: Color = Color("#FFF1C9")
const SNOW: Color = Color("#F4F1EC")
const ROCK: Color = Color("#8A8F99")
const WATER: Color = Color("#5C9DBE")
const ICE: Color = Color("#BFDDEA")
const PINE: Color = Color("#2F5D4A")
const WOOD: Color = Color("#7A4E34")
const RED: Color = Color("#D9573B")
const INK: Color = Color("#2B2D42")
const AURORA: Color = Color("#5BE3B0")


static func draw(ci: CanvasItem, pic: Rect2, motif: int, night: bool, theme: Color, seed: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	var is_night: bool = night or motif == ViewpointData.Motif.AURORA
	_sky(ci, pic, is_night)
	if is_night:
		_stars(ci, pic, rng)
		if motif == ViewpointData.Motif.AURORA:
			_aurora(ci, pic)
		ci.draw_circle(_at(pic, 0.8, 0.2), pic.size.y * 0.07, SNOW, true, -1.0, true)
	else:
		ci.draw_circle(_at(pic, rng.randf_range(0.2, 0.8), 0.24), pic.size.y * 0.1, SUN, true, -1.0, true)
	var hill: Color = theme.lerp(NIGHT_LOW, 0.55) if is_night else theme.lightened(0.3)
	match motif:
		ViewpointData.Motif.LAKE, ViewpointData.Motif.FROZEN_LAKE:
			_peaks(ci, pic, rng, hill, 0.5, motif == ViewpointData.Motif.FROZEN_LAKE)
			_ridge(ci, pic, rng, theme, 0.62, 0.05)
			var frozen: bool = motif == ViewpointData.Motif.FROZEN_LAKE
			ci.draw_rect(_band(pic, 0.66, 1.0), ICE if frozen else WATER)
			for i: int in 4:
				var y: float = 0.72 + i * 0.07
				ci.draw_line(_at(pic, rng.randf_range(0.1, 0.5), y), _at(pic, rng.randf_range(0.55, 0.9), y), Color(1, 1, 1, 0.45), maxf(pic.size.y * 0.012, 1.0))
			_pines(ci, pic, rng, 0.66, 5, 0.16)
		ViewpointData.Motif.BIRD:
			_ridge(ci, pic, rng, hill, 0.6, 0.1)
			_ridge(ci, pic, rng, theme, 0.8, 0.06)
			ci.draw_rect(Rect2(_at(pic, 0.7, 0.0), Vector2(pic.size.x * 0.1, pic.size.y)), WOOD)
			_woodpecker(ci, pic, _at(pic, 0.7, 0.5), pic.size.y * 0.3)
		ViewpointData.Motif.SEA, ViewpointData.Motif.LIGHTHOUSE:
			ci.draw_rect(_band(pic, 0.6, 1.0), WATER)
			_island(ci, pic, 0.22, 0.6, 0.3)
			if motif == ViewpointData.Motif.LIGHTHOUSE:
				_island(ci, pic, 0.72, 0.62, 0.22)
				_lighthouse(ci, pic, _at(pic, 0.72, 0.58), pic.size.y * 0.36)
			else:
				for i: int in 4:
					_bird(ci, _at(pic, rng.randf_range(0.4, 0.9), rng.randf_range(0.2, 0.45)), pic.size.y * 0.1, INK, 1.0)
		ViewpointData.Motif.REINDEER, ViewpointData.Motif.FELL:
			_ridge(ci, pic, rng, hill, 0.5, 0.08)
			_ridge(ci, pic, rng, theme.lerp(Color("#B08A5A"), 0.4), 0.72, 0.05)
			if motif == ViewpointData.Motif.REINDEER:
				for i: int in 3:
					_reindeer(ci, _at(pic, 0.25 + i * 0.22, 0.8 + rng.randf_range(-0.03, 0.03)), pic.size.y * 0.13)
			else:
				_cairn(ci, pic, _at(pic, 0.6, 0.66), pic.size.y * 0.16)
		ViewpointData.Motif.WATERFALL:
			_peaks(ci, pic, rng, hill, 0.45, false)
			_ridge(ci, pic, rng, theme, 0.7, 0.04)
			_poly(ci, pic, PackedVector2Array([_at(pic, 0, 0.26), _at(pic, 0.22, 0.32), _at(pic, 0.38, 0.29), _at(pic, 0.5, 0.33),
				_at(pic, 0.58, 0.5), _at(pic, 0.6, 1), _at(pic, 0, 1)]), ROCK.darkened(0.15))
			ci.draw_rect(Rect2(_at(pic, 0.39, 0.3), Vector2(pic.size.x * 0.08, pic.size.y * 0.58)), SNOW)
			ci.draw_rect(Rect2(_at(pic, 0.41, 0.3), Vector2(pic.size.x * 0.02, pic.size.y * 0.58)), ICE)
			ci.draw_rect(_band(pic, 0.86, 1.0), WATER)
			_pines(ci, pic, rng, 0.86, 3, 0.2, 0.6)
		ViewpointData.Motif.FJORD:
			ci.draw_rect(_band(pic, 0.7, 1.0), WATER)
			_poly(ci, pic, PackedVector2Array([_at(pic, 0, 0.25), _at(pic, 0.42, 0.72), _at(pic, 0, 0.72)]), theme.darkened(0.1))
			_poly(ci, pic, PackedVector2Array([_at(pic, 1, 0.2), _at(pic, 1, 0.72), _at(pic, 0.55, 0.72)]), theme)
			_poly(ci, pic, PackedVector2Array([_at(pic, 1, 0.2), _at(pic, 0.9, 0.34), _at(pic, 1, 0.34)]), SNOW)
		ViewpointData.Motif.GLACIER:
			_peaks(ci, pic, rng, ROCK, 0.35, true)
			_poly(ci, pic, PackedVector2Array([_at(pic, 0.3, 0.45), _at(pic, 0.7, 0.45), _at(pic, 0.85, 1.0), _at(pic, 0.15, 1.0)]), ICE)
			for i: int in 3:
				var x: float = 0.4 + i * 0.1
				ci.draw_line(_at(pic, x, 0.5), _at(pic, x + (x - 0.5) * 0.6, 1.0), Color(WATER, 0.5), maxf(pic.size.y * 0.012, 1.0))
		ViewpointData.Motif.CABIN, ViewpointData.Motif.AURORA:
			_peaks(ci, pic, rng, hill, 0.45, true)
			ci.draw_rect(_band(pic, 0.74, 1.0), SNOW.darkened(0.12) if is_night else SNOW)
			_pines(ci, pic, rng, 0.76, 4, 0.18, 1.0, PINE.darkened(0.35) if is_night else PINE)
			if motif == ViewpointData.Motif.CABIN:
				_cabin(ci, pic, _at(pic, 0.55, 0.78), pic.size.y * 0.2, is_night)
		_:
			_ridge(ci, pic, rng, hill, 0.55, 0.12)
			_ridge(ci, pic, rng, theme, 0.75, 0.08)


## Filled polygon clipped to the picture (peaks and ridges overhang its edges).
static func _poly(ci: CanvasItem, pic: Rect2, pts: PackedVector2Array, col: Color) -> void:
	var frame: PackedVector2Array = PackedVector2Array([pic.position, _at(pic, 1, 0), pic.end, _at(pic, 0, 1)])
	for part: PackedVector2Array in Geometry2D.intersect_polygons(pts, frame):
		ci.draw_colored_polygon(part, col)


static func _at(pic: Rect2, fx: float, fy: float) -> Vector2:
	return pic.position + Vector2(pic.size.x * fx, pic.size.y * fy)


static func _band(pic: Rect2, top: float, bottom: float) -> Rect2:
	return Rect2(_at(pic, 0.0, top), Vector2(pic.size.x, pic.size.y * (bottom - top)))


static func _sky(ci: CanvasItem, pic: Rect2, night: bool) -> void:
	var top: Color = NIGHT_TOP if night else DAY_TOP
	var low: Color = NIGHT_LOW if night else DAY_LOW
	ci.draw_polygon(PackedVector2Array([pic.position, _at(pic, 1, 0), pic.end, _at(pic, 0, 1)]),
		PackedColorArray([top, top, low, low]))


static func _stars(ci: CanvasItem, pic: Rect2, rng: RandomNumberGenerator) -> void:
	for i: int in 14:
		ci.draw_circle(_at(pic, rng.randf(), rng.randf_range(0.02, 0.5)), maxf(pic.size.y * 0.008, 0.8), Color(1, 1, 1, rng.randf_range(0.5, 1.0)))


static func _aurora(ci: CanvasItem, pic: Rect2) -> void:
	for band: int in 2:
		var pts: PackedVector2Array = PackedVector2Array()
		var cols: PackedColorArray = PackedColorArray()
		var steps: int = 10
		for i: int in steps + 1:
			var fx: float = float(i) / steps
			pts.append(_at(pic, fx, 0.18 + band * 0.12 + sin(fx * 5.0 + band) * 0.06))
			cols.append(Color(AURORA, 0.0))
		for i: int in range(steps, -1, -1):
			var fx: float = float(i) / steps
			pts.append(_at(pic, fx, 0.32 + band * 0.12 + sin(fx * 5.0 + band) * 0.06))
			cols.append(Color(AURORA, 0.55 - band * 0.2))
		ci.draw_polygon(pts, cols)


## Jagged peaks; snowy tips when `snow`.
static func _peaks(ci: CanvasItem, pic: Rect2, rng: RandomNumberGenerator, col: Color, base: float, snow: bool) -> void:
	var x: float = -0.1
	while x < 1.0:
		var w: float = rng.randf_range(0.25, 0.4)
		var h: float = rng.randf_range(0.2, 0.32)
		var peak: Vector2 = _at(pic, x + w * 0.5, base - h)
		_poly(ci, pic, PackedVector2Array([_at(pic, x, base + 0.3), peak, _at(pic, x + w, base + 0.3)]), col)
		if snow:
			var cap: float = 0.3
			_poly(ci, pic, PackedVector2Array([peak, peak.lerp(_at(pic, x + w, base + 0.3), cap * 0.5),
				peak.lerp(_at(pic, x, base + 0.3), cap * 0.5)]), SNOW)
		x += w * 0.7


## A rolling ridge from `top` (fraction of the height) to the bottom.
static func _ridge(ci: CanvasItem, pic: Rect2, rng: RandomNumberGenerator, col: Color, top: float, wobble: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 8
	for i: int in steps + 1:
		pts.append(_at(pic, float(i) / steps, top + rng.randf_range(-wobble, wobble)))
	pts.append(pic.end)
	pts.append(_at(pic, 0, 1))
	_poly(ci, pic, pts, col)


static func _pines(ci: CanvasItem, pic: Rect2, rng: RandomNumberGenerator, ground: float, count: int, height: float, max_x: float = 1.0, col: Color = PINE) -> void:
	for i: int in count:
		var base: Vector2 = _at(pic, rng.randf_range(0.03, max_x - 0.03), ground + 0.02)
		var h: float = pic.size.y * height * rng.randf_range(0.7, 1.2)
		_poly(ci, pic, PackedVector2Array([base + Vector2(0, -h), base + Vector2(h * 0.3, 0), base + Vector2(-h * 0.3, 0)]), col)


static func _bird(ci: CanvasItem, at: Vector2, s: float, col: Color, facing: float) -> void:
	var w: float = maxf(s * 0.18, 1.0)
	ci.draw_polyline(PackedVector2Array([at + Vector2(-s * 0.5 * facing, -s * 0.25), at, at + Vector2(s * 0.5 * facing, -s * 0.3)]), col, w, true)


static func _island(ci: CanvasItem, pic: Rect2, cx: float, top: float, width: float) -> void:
	_poly(ci, pic, PackedVector2Array([_at(pic, cx - width * 0.5, top + 0.08), _at(pic, cx - width * 0.2, top - 0.04),
		_at(pic, cx + width * 0.25, top - 0.02), _at(pic, cx + width * 0.5, top + 0.08)]), ROCK)


static func _lighthouse(ci: CanvasItem, pic: Rect2, base: Vector2, h: float) -> void:
	var w: float = h * 0.18
	_poly(ci, pic, PackedVector2Array([base + Vector2(-w, 0), base + Vector2(w, 0), base + Vector2(w * 0.65, -h), base + Vector2(-w * 0.65, -h)]), SNOW)
	for i: int in 2:
		var y: float = -h * (0.25 + i * 0.35)
		ci.draw_rect(Rect2(base + Vector2(-w * 0.85, y - h * 0.08), Vector2(w * 1.7, h * 0.12)), RED)
	ci.draw_rect(Rect2(base + Vector2(-w * 0.8, -h * 1.15), Vector2(w * 1.6, h * 0.15)), Color("#FFE08A"))
	_poly(ci, pic, PackedVector2Array([base + Vector2(-w, -h * 1.15), base + Vector2(w, -h * 1.15), base + Vector2(0, -h * 1.35)]), RED)


static func _reindeer(ci: CanvasItem, feet: Vector2, s: float) -> void:
	var col: Color = Color("#6B5240")
	ci.draw_rect(Rect2(feet + Vector2(-s * 0.4, -s * 0.75), Vector2(s * 0.8, s * 0.35)), col)
	for lx: float in [-0.35, -0.2, 0.2, 0.35]:
		ci.draw_rect(Rect2(feet + Vector2(s * lx - s * 0.03, -s * 0.42), Vector2(s * 0.06, s * 0.42)), col)
	ci.draw_rect(Rect2(feet + Vector2(s * 0.32, -s * 0.98), Vector2(s * 0.2, s * 0.26)), col)
	var w: float = maxf(s * 0.05, 1.0)
	ci.draw_polyline(PackedVector2Array([feet + Vector2(s * 0.4, -s * 0.98), feet + Vector2(s * 0.3, -s * 1.25), feet + Vector2(s * 0.18, -s * 1.3)]), col.darkened(0.2), w)
	ci.draw_polyline(PackedVector2Array([feet + Vector2(s * 0.46, -s * 0.98), feet + Vector2(s * 0.56, -s * 1.25), feet + Vector2(s * 0.68, -s * 1.3)]), col.darkened(0.2), w)


static func _cairn(ci: CanvasItem, pic: Rect2, base: Vector2, h: float) -> void:
	for i: int in 4:
		var w: float = h * (0.55 - i * 0.1)
		var c: Vector2 = base + Vector2(0, -h * (0.12 + i * 0.22))
		ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.5))
		ci.draw_circle(Vector2.ZERO, w, ROCK.darkened(0.05 * i), true, -1.0, true)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	ci.draw_line(base + Vector2(h * 0.15, -h * 0.9), base + Vector2(h * 0.15, -h * 1.6), WOOD, maxf(h * 0.05, 1.0))
	_poly(ci, pic, PackedVector2Array([base + Vector2(h * 0.15, -h * 1.6), base + Vector2(h * 0.55, -h * 1.48), base + Vector2(h * 0.15, -h * 1.36)]), RED)


static func _cabin(ci: CanvasItem, pic: Rect2, base: Vector2, h: float, lit: bool) -> void:
	var w: float = h * 1.4
	ci.draw_rect(Rect2(base + Vector2(-w * 0.5, -h * 0.7), Vector2(w, h * 0.7)), RED.darkened(0.25))
	_poly(ci, pic, PackedVector2Array([base + Vector2(-w * 0.62, -h * 0.68), base + Vector2(0, -h * 1.15), base + Vector2(w * 0.62, -h * 0.68)]), SNOW)
	ci.draw_rect(Rect2(base + Vector2(-w * 0.3, -h * 0.5), Vector2(w * 0.22, h * 0.22)), Color("#FFD36B") if lit else Color("#9CC3D5"))


## A woodpecker clinging to the left side of a trunk at `at` (x = trunk edge).
static func _woodpecker(ci: CanvasItem, pic: Rect2, at: Vector2, s: float) -> void:
	_poly(ci, pic, PackedVector2Array([at + Vector2(0, -s * 0.3), at + Vector2(-s * 0.22, -s * 0.15),
		at + Vector2(-s * 0.2, s * 0.25), at + Vector2(-s * 0.02, s * 0.45), at + Vector2(0, s * 0.2)]), INK)
	_poly(ci, pic, PackedVector2Array([at + Vector2(-s * 0.18, s * 0.0), at + Vector2(-s * 0.1, -s * 0.05),
		at + Vector2(-s * 0.1, s * 0.2), at + Vector2(-s * 0.17, s * 0.22)]), SNOW)
	ci.draw_circle(at + Vector2(-s * 0.16, -s * 0.32), s * 0.12, INK, true, -1.0, true)
	ci.draw_circle(at + Vector2(-s * 0.17, -s * 0.4), s * 0.07, RED, true, -1.0, true)
	_poly(ci, pic, PackedVector2Array([at + Vector2(-s * 0.26, -s * 0.34), at + Vector2(-s * 0.42, -s * 0.3),
		at + Vector2(-s * 0.26, -s * 0.27)]), Color("#D9B26B"))
	ci.draw_circle(at + Vector2(-s * 0.2, -s * 0.34), s * 0.025, SNOW, true, -1.0, true)
