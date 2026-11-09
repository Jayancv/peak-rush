@tool
class_name GroundPatch
extends HikerArea
## A stretch of mud, ice or snow lying on the path. While the hiker is in it, the
## patch's surface replaces the ground's (mud: slow and tiring, ice: slippery).

@export var surface: TerrainStrip.Surface = TerrainStrip.Surface.MUD:
	set(v):
		surface = v
		rebuild()
@export var width: float = 160.0:
	set(v):
		width = v
		rebuild()

const COLORS: Dictionary = {
	TerrainStrip.Surface.MUD: [Color("#5C4331"), Color("#7A5C45")],
	TerrainStrip.Surface.ICE: [Color("#BFE3F0"), Color("#F2FBFF")],
	TerrainStrip.Surface.SNOW: [Color("#EEF3F7"), Color("#FFFFFF")],
}


func build() -> void:
	var pair: Array = COLORS.get(surface, COLORS[TerrainStrip.Surface.MUD])
	var half: float = width * 0.5
	# Drawn slightly in front of the path so the patch reads as lying on it.
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2.ZERO, Vector2(half, 7.0), 20), pair[0], 1)
	# A few highlights: puddle shine on mud, glints on ice.
	for i: int in 3:
		var x: float = lerpf(-half * 0.6, half * 0.6, float(i) / 2.0)
		ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(x, -1.5), Vector2(width * 0.07, 1.6), 10), pair[1], 1)
	ShapeUtil.add_rect_shape(self, Rect2(-half, -40.0, width, 44.0))


func _hiker_entered(hiker: Hiker) -> void:
	hiker.condition.enter_patch(surface)


func _hiker_exited(hiker: Hiker) -> void:
	hiker.condition.exit_patch(surface)
