class_name TrailFx
extends Node2D
## Small physical touches driven by the hiker's footsteps: loose pebbles kicked off
## rocky (and now and then dirt) paths that bounce down the real terrain, and
## footprints pressed into snow and mud that slowly fade. Sits between the level
## and the hiker, so prints lie on the path and pebbles pass behind the boots.

## Pebbles get their own physics layer: they hit the ground (layer 1) but never the hiker.
const PEBBLE_LAYER: int = 1 << 5
const PEBBLE_COLORS: Array[Color] = [Color("#8C8B84"), Color("#A39C8E"), Color("#6F6E68")]
const PRINT_SNOW: Color = Color(0.55, 0.64, 0.78, 0.55)
const PRINT_MUD: Color = Color(0.2, 0.13, 0.08, 0.6)

var _hiker: Hiker
var _balance: Balance
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _prints: Array[Polygon2D] = []
var _print_age: PackedFloat32Array = PackedFloat32Array()
var _next_print: int = 0
var _left_foot: bool = false


func setup(hiker: Hiker, balance: Balance) -> void:
	_hiker = hiker
	_balance = balance
	_rng.randomize()
	if hiker.visual != null:
		hiker.visual.stepped.connect(_on_stepped)


func _process(delta: float) -> void:
	for i: int in _prints.size():
		if not _prints[i].visible:
			continue
		_print_age[i] += delta
		var t: float = _print_age[i] / _balance.footprint_seconds
		if t >= 1.0:
			_prints[i].visible = false
		else:
			_prints[i].modulate.a = 1.0 - t * t


func _on_stepped(surface: TerrainStrip.Surface) -> void:
	if not _hiker.is_on_floor():
		return
	if surface == TerrainStrip.Surface.SNOW or surface == TerrainStrip.Surface.MUD:
		_footprint(surface)
	var chance: float = 0.0
	if surface == TerrainStrip.Surface.ROCK:
		chance = _balance.pebble_chance_rock
	elif surface == TerrainStrip.Surface.DIRT:
		chance = _balance.pebble_chance_dirt
	if _rng.randf() < chance:
		_kick_pebble()


func _footprint(surface: TerrainStrip.Surface) -> void:
	var print_poly: Polygon2D
	if _prints.size() < _balance.footprint_max:
		print_poly = Polygon2D.new()
		print_poly.polygon = ShapeUtil.ellipse(Vector2.ZERO, Vector2(4.5, 1.6), 10)
		print_poly.antialiased = true
		add_child(print_poly)
		_prints.append(print_poly)
		_print_age.append(0.0)
		_next_print = _prints.size() - 1
	else:
		# Reuse the oldest print instead of allocating a new one.
		_next_print = (_next_print + 1) % _prints.size()
		print_poly = _prints[_next_print]
	_left_foot = not _left_foot
	print_poly.color = PRINT_SNOW if surface == TerrainStrip.Surface.SNOW else PRINT_MUD
	print_poly.position = to_local(_hiker.global_position + Vector2(-3.0 if _left_foot else 3.0, -1.0))
	print_poly.rotation = -atan(_hiker.signed_grade)
	print_poly.modulate.a = 1.0
	print_poly.visible = true
	_print_age[_next_print] = 0.0


func _kick_pebble() -> void:
	var pebble: RigidBody2D = RigidBody2D.new()
	pebble.collision_layer = PEBBLE_LAYER
	pebble.collision_mask = 1
	pebble.mass = 0.05
	var r: float = _rng.randf_range(2.0, 3.4)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = r
	shape.shape = circle
	pebble.add_child(shape)
	var art: Polygon2D = Polygon2D.new()
	art.polygon = ShapeUtil.ellipse(Vector2.ZERO, Vector2(r * 1.2, r), 8)
	art.color = PEBBLE_COLORS[_rng.randi() % PEBBLE_COLORS.size()]
	art.antialiased = true
	pebble.add_child(art)
	pebble.position = to_local(_hiker.global_position + Vector2(9.0 * _hiker.facing, -4.0))
	pebble.linear_velocity = Vector2(_rng.randf_range(60.0, 150.0) * _hiker.facing, _rng.randf_range(-170.0, -80.0))
	pebble.angular_velocity = _rng.randf_range(-12.0, 12.0)
	add_child(pebble)
	var fade: Tween = pebble.create_tween()
	fade.tween_interval(_balance.pebble_seconds)
	fade.tween_property(pebble, "modulate:a", 0.0, 0.4)
	fade.tween_callback(pebble.queue_free)
