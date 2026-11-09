class_name FogBank
extends Polygon2D
## Fog that sits *between* the backdrop and the trail: distant scenery fades into
## it while the path and the hiker stay clear. It follows the camera, thickest
## around the horizon, and lives in the world canvas so the day tint reaches it.

## How far above/below the screen centre each row of the fog sits, and how dense
## it is there (as a fraction of the profile's fog_density).
const ROWS: Array[Vector2] = [Vector2(-1600, 0.1), Vector2(-260, 0.45), Vector2(40, 1.0), Vector2(320, 0.95), Vector2(1600, 0.8)]
const HALF_WIDTH: float = 3000.0

var camera: Camera2D


func setup(fog_color: Color, density: float, follow: Camera2D) -> void:
	camera = follow
	var pts: PackedVector2Array = PackedVector2Array()
	var cols: PackedColorArray = PackedColorArray()
	for row: Vector2 in ROWS:
		pts.append(Vector2(-HALF_WIDTH, row.x))
		pts.append(Vector2(HALF_WIDTH, row.x))
		var c: Color = Color(fog_color, clampf(density * row.y, 0.0, 1.0))
		cols.append(c)
		cols.append(c)
	var quads: Array = []
	for i: int in ROWS.size() - 1:
		var a: int = i * 2
		quads.append(PackedInt32Array([a, a + 1, a + 3, a + 2]))
	polygon = pts
	vertex_colors = cols
	polygons = quads


func _process(_delta: float) -> void:
	if camera != null:
		global_position = camera.get_screen_center_position()
