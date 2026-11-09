@tool
class_name Viewpoint
extends HikerArea
## A photo spot. Walking in offers the 📷 prompt (optional); photo mode then frames
## `frame_offset` and the player shoots the moving subject when it's centred.
## `viewpoint_id` must match one of the trail's ViewpointData entries (the content
## validator checks this).

signal hiker_entered(viewpoint: Viewpoint)
signal hiker_left(viewpoint: Viewpoint)

const GROUP: StringName = &"viewpoint"
const POST: Color = Color("#6B4F35")
const SIGN: Color = Color("#FFF6E5")
const SIGN_INK: Color = Color("#2B2D42")

@export var viewpoint_id: StringName
## Where photo mode points the camera, relative to this node (usually up and ahead).
@export var frame_offset: Vector2 = Vector2(260, -220):
	set(v):
		frame_offset = v
		_place_subject()
		queue_redraw()
@export var subject_kind: PhotoSubject.Kind = PhotoSubject.Kind.BIRD:
	set(v):
		subject_kind = v
		if _subject != null:
			_subject.kind = v
## Path of the subject relative to the frame centre, and its speed (px/s).
@export var subject_path: PackedVector2Array = PackedVector2Array([Vector2(-260, 0), Vector2(260, 0)]):
	set(v):
		subject_path = v
		if _subject != null:
			_subject.path = v
		queue_redraw()
@export var subject_speed: float = 90.0:
	set(v):
		subject_speed = v
		if _subject != null:
			_subject.speed = v
@export var subject_color: Color = PhotoSubject.INK:
	set(v):
		subject_color = v
		if _subject != null:
			_subject.color = v
@export var subject_size: float = 1.0:
	set(v):
		subject_size = v
		if _subject != null:
			_subject.size = v

var _subject: PhotoSubject
var _frame: Node2D


func _ready() -> void:
	add_to_group(GROUP)
	super()


func build() -> void:
	# A short post with a little camera sign.
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-3, -58, 6, 58), 2.0), POST)
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-20, -80, 40, 28), 6.0), SIGN)
	ShapeUtil.add_poly(self, ShapeUtil.rounded_rect(Rect2(-12, -73, 24, 15), 2.0), SIGN_INK)
	ShapeUtil.add_poly(self, ShapeUtil.ellipse(Vector2(0, -65.5), Vector2(4.5, 4.5), 10), SIGN)
	# The subject lives under a "frame" node at the photo's centre, so its path is
	# authored relative to what the camera will show.
	_frame = Node2D.new()
	add_child(_frame, false, Node.INTERNAL_MODE_BACK)
	_subject = PhotoSubject.new()
	_subject.kind = subject_kind
	_subject.path = subject_path
	_subject.speed = subject_speed
	_subject.size = subject_size
	_subject.color = subject_color
	_frame.add_child(_subject, false, Node.INTERNAL_MODE_BACK)
	_place_subject()
	ShapeUtil.add_rect_shape(self, Rect2(-70, -120, 140, 124))


func frame_center() -> Vector2:
	return global_position + frame_offset


func subject() -> PhotoSubject:
	return _subject


## The subject's position on screen (viewport coordinates), for scoring a shot.
func subject_screen_position() -> Vector2:
	return get_viewport().get_canvas_transform() * _subject.global_position


func _place_subject() -> void:
	if _frame != null:
		_frame.position = frame_offset


func _draw() -> void:
	# Editor guide: the photo frame and the subject's path.
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(frame_offset - Vector2(300, 190), Vector2(600, 380)), Color(1, 1, 1, 0.5), false, 2.0)
	if subject_path.size() > 1:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in subject_path:
			pts.append(frame_offset + p)
		draw_polyline(pts, Color(0.9, 0.4, 0.2, 0.8), 2.0)


func _hiker_entered(_hiker: Hiker) -> void:
	hiker_entered.emit(self)


func _hiker_exited(_hiker: Hiker) -> void:
	hiker_left.emit(self)
