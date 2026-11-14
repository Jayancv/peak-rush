class_name SketchView
extends RefCounted
## "Elsa's sketch" on an enlarged postcard: a pencil-sketch overlay (pencil_sketch.gdshader
## reads the card drawn beneath it) and the button that flips between the photo and
## the sketch. Season 1 sketches are Elsa's; Season 2 (Tea Country) ones are Kerstin's.

const SHADER: Shader = preload("res://scenes/journal/pencil_sketch.gdshader")

var overlay: ColorRect
var button: Button
var _sketch_key: String = "JOURNAL_SKETCH_ELSA"


## Adds the (hidden) overlay over `card` and the toggle button to `button_parent`.
func attach(card: Control, button_parent: Node) -> void:
	overlay = ColorRect.new()
	overlay.material = ShaderMaterial.new()
	(overlay.material as ShaderMaterial).shader = SHADER
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	card.add_child(overlay)
	button = Button.new()
	button.add_theme_font_size_override("font_size", 24)
	button.custom_minimum_size = Vector2(0, 64)
	button.pressed.connect(func() -> void: show_sketch(not overlay.visible))
	button_parent.add_child(button)


## Which sketcher the season belongs to; the photo shows first.
func set_season(season: SeasonData, seasons: Array[SeasonData]) -> void:
	_sketch_key = "JOURNAL_SKETCH_KERSTIN" if seasons.find(season) >= 1 else "JOURNAL_SKETCH_ELSA"
	show_sketch(false)


func show_sketch(on: bool) -> void:
	overlay.visible = on
	button.text = TranslationServer.translate("JOURNAL_SHOW_PHOTO" if on else _sketch_key)
