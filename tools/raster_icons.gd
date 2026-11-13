extends SceneTree
## Builds every icon/splash PNG from the painted source art (shared_art/icons/source/,
## kept out of the game by .gdignore). The themed (monochrome) icon is still drawn
## from adaptive_monochrome.svg, because it has to be a plain silhouette.
## Run: godot --headless --path . -s tools/raster_icons.gd

const DIR := "res://shared_art/icons/"
const SOURCE := "res://shared_art/icons/source/icon_source.png"
## Legacy launchers mask nothing, so the square icon gets its own rounded corners.
const CORNER_FRACTION: float = 0.22
## Launchers only ever show the central 72/108 of an adaptive layer. These pick which part
## of the painting lands there: VIEW = fraction of the painting's width that is visible,
## CENTRE = where in the painting (0..1) that window is centred. Outside it, edge pixels
## are stretched (only seen during launcher parallax).
const ADAPTIVE_VIEW: float = 0.95
const ADAPTIVE_CENTRE := Vector2(0.4, 0.56)


func _initialize() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if src == null:
		push_error("missing %s" % SOURCE)
		quit(1)
		return
	src.convert(Image.FORMAT_RGBA8)
	# Adaptive icon: the painting is the background layer (the launcher crops it to its
	# own shape); the foreground layer is empty.
	_save(_framed(src, 432), "adaptive_background_432.png")
	_save(Image.create_empty(432, 432, false, Image.FORMAT_RGBA8), "adaptive_foreground_432.png")
	_save(_masked(_scaled(src, 192), 192 * CORNER_FRACTION), "icon_192.png")
	_save(_masked(_scaled(src, 512), 512 * CORNER_FRACTION), "icon_512.png")
	var mono := Image.new()
	if mono.load_svg_from_string(FileAccess.get_file_as_string(DIR + "adaptive_monochrome.svg")) == OK:
		_save(mono, "adaptive_monochrome_432.png")
	quit()


func _framed(src: Image, size: int) -> Image:
	var visible: float = size * 72.0 / 108.0
	# Resample the painting so its ADAPTIVE_VIEW width spans the visible window.
	var scale: float = visible / (src.get_width() * ADAPTIVE_VIEW)
	var big := src.duplicate() as Image
	big.resize(roundi(src.get_width() * scale), roundi(src.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var centre := Vector2(big.get_width(), big.get_height()) * ADAPTIVE_CENTRE
	var out := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var sx: int = clampi(roundi(centre.x + x - size * 0.5), 0, big.get_width() - 1)
			var sy: int = clampi(roundi(centre.y + y - size * 0.5), 0, big.get_height() - 1)
			out.set_pixel(x, y, big.get_pixel(sx, sy))
	return out


func _scaled(src: Image, size: int) -> Image:
	var img := src.duplicate() as Image
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return img


## Rounded-square alpha mask with a one-pixel soft edge (radius = size/2 makes a circle).
func _masked(img: Image, radius: float) -> Image:
	var size: int = img.get_width()
	var inner := Vector2(size, size) * 0.5 - Vector2(radius, radius)
	for y: int in size:
		for x: int in size:
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) - Vector2(size, size) * 0.5
			var q := Vector2(maxf(absf(p.x) - inner.x, 0.0), maxf(absf(p.y) - inner.y, 0.0))
			var coverage: float = clampf(radius - q.length() + 0.5, 0.0, 1.0)
			if coverage < 1.0:
				var c := img.get_pixel(x, y)
				c.a *= coverage
				img.set_pixel(x, y, c)
	return img


func _save(img: Image, file: String) -> void:
	img.save_png(ProjectSettings.globalize_path(DIR + file))
	print("wrote ", file, " ", img.get_size())
