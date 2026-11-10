@tool
class_name Spring
extends HikerArea
## A mountain spring: water runs from a wooden spout in a mossy rock into a small
## stone basin. Standing at it refills the hiker's bottle (HikerCondition.enter_spring).

const GROUP: StringName = &"spring"
const ROCK: Color = Color("#7E7C74")
const ROCK_DARK: Color = Color("#5A5852")
const MOSS: Color = Color("#6F8D4A")
const WOOD: Color = Color("#8A5E3B")
const WATER: Color = Color(0.62, 0.84, 0.93, 0.85)
const WATER_DARK: Color = Color(0.35, 0.6, 0.75, 0.9)

signal hiker_arrived


func _ready() -> void:
	super()
	add_to_group(GROUP)


func build() -> void:
	# Rock behind, with moss on top.
	var rock: Polygon2D = ShapeUtil.add_poly(self, PackedVector2Array([Vector2(8, 2), Vector2(4, -34), Vector2(14, -52), Vector2(34, -58),
		Vector2(52, -46), Vector2(56, -12), Vector2(54, 2)]), ROCK)
	rock.vertex_colors = PackedColorArray([ROCK_DARK, ROCK, ROCK.lightened(0.12), ROCK.lightened(0.15), ROCK, ROCK_DARK, ROCK_DARK])
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(30, -55), Vector2(16, 5), 14), MOSS)
	# Wooden spout and the falling stream.
	ShapeUtil.add_poly(self, PackedVector2Array([Vector2(8, -30), Vector2(-14, -27), Vector2(-14, -23), Vector2(8, -25)]), WOOD)
	var stream: Polygon2D = ShapeUtil.add_poly(self, PackedVector2Array([Vector2(-13, -24), Vector2(-9, -24), Vector2(-8, -6), Vector2(-14, -6)]), WATER)
	stream.vertex_colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), WATER, WATER])
	# Stone basin with water in it.
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-34, -10, 44, 12), 4.0), ROCK_DARK, 1)
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-31, -9, 38, 5), 2.0), WATER_DARK, 1)
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(-11, -7), Vector2(5, 1.4), 10), Color(1, 1, 1, 0.7), 1)
	if not Engine.is_editor_hint():
		var drips: CPUParticles2D = CPUParticles2D.new()
		drips.position = Vector2(-11, -8)
		drips.amount = 6
		drips.lifetime = 0.5
		drips.direction = Vector2.UP
		drips.spread = 60.0
		drips.initial_velocity_min = 20.0
		drips.initial_velocity_max = 45.0
		drips.gravity = Vector2(0, 260)
		drips.scale_amount_min = 1.2
		drips.scale_amount_max = 2.2
		drips.color = Color(0.85, 0.95, 1.0, 0.85)
		drips.z_index = 1
		add_child(drips, false, Node.INTERNAL_MODE_BACK)
	ShapeUtil.add_rect_shape(self, Rect2(-50, -60, 110, 64))


func _hiker_entered(hiker: Hiker) -> void:
	hiker.condition.enter_spring()
	hiker_arrived.emit()


func _hiker_exited(hiker: Hiker) -> void:
	hiker.condition.exit_spring()
