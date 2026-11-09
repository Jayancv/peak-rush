class_name TrailCard
extends Button
## One trail on the trail select screen: number, name, stars earned, best time,
## and a lock when the previous trail hasn't been finished yet.

const STAR_ON: Color = Color("#F2B33D")
const STAR_OFF: Color = Color(0.168627, 0.176471, 0.258824, 0.3)

@export var number_label: Label
@export var name_label: Label
@export var detail_label: Label
@export var stars: Array[UiIcon] = []
@export var lock_row: Control
@export var lock_label: Label
@export var theme_strip: ColorRect

var trail: TrailData


func _ready() -> void:
	# Children are decoration; the card itself takes the tap.
	for node: Node in find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(number: int, data: TrailData, record: Dictionary, unlocked: bool, theme_color: Color, unlock_hint: String) -> void:
	trail = data
	number_label.text = str(number)
	name_label.text = tr(data.name_key)
	theme_strip.color = theme_color
	var mask: int = int(record.get("stars", 0))
	var bits: Array[int] = [StarRating.STAR_SUMMIT, StarRating.STAR_PHOTOS, StarRating.STAR_BEFORE_DUSK]
	for i: int in stars.size():
		var earned: bool = mask & bits[i] != 0
		stars[i].kind = UiIcon.Kind.STAR if earned else UiIcon.Kind.STAR_EMPTY
		stars[i].color = STAR_ON if earned else STAR_OFF
	var best: float = float(record.get("best_time", 0.0))
	detail_label.text = tr("SELECT_BEST") % TimeFormat.mmss(best) if best > 0.0 else tr("SELECT_NOT_HIKED")
	disabled = not unlocked
	lock_row.visible = not unlocked
	detail_label.visible = unlocked
	lock_label.text = unlock_hint
	modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.85)
