class_name PostcardShare
extends RefCounted
## "Share" on an enlarged postcard: renders the card with the game's name under it into
## user://share/postcard.png, then opens the phone's share sheet (PeakRushSteps.sharePicture,
## the game's Android plugin). On desktop debug builds it opens the folder instead.

const DIR: String = "user://share/"
const FILE: String = "user://share/postcard.png"
const SIZE: Vector2i = Vector2i(1200, 900)
const PLUGIN: String = "PeakRushSteps"
const BG: Color = Color("#2F4A3F")
const CREAM: Color = Color("#FFF6E5")


## Renders and shares `card_setup` (a Callable that fills a Postcard). Returns the image path.
static func share(host: Node, card_setup: Callable) -> String:
	var img: Image = await render(host, card_setup)
	if img == null or img.is_empty():
		# Headless runs (tests) have no renderer: keep the flow working with a blank picture.
		img = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGB8)
		img.fill(BG)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	img.save_png(ProjectSettings.globalize_path(FILE))
	var path: String = ProjectSettings.globalize_path(FILE)
	var text: String = TranslationServer.translate("SHARE_TEXT")
	if Engine.has_singleton(PLUGIN) and Engine.get_singleton(PLUGIN).has_method("sharePicture"):
		Engine.get_singleton(PLUGIN).sharePicture(path, text)
	elif OS.is_debug_build() and not SaveService.is_test_run():
		OS.shell_open(ProjectSettings.globalize_path(DIR))
	return path


## The share picture: the postcard, tilted a touch, on the season green with the game's name.
static func render(host: Node, card_setup: Callable) -> Image:
	if DisplayServer.get_name() == "headless":
		# Nothing draws without a display (headless tests): no frame would ever arrive.
		return null
	var vp: SubViewport = SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(vp)
	var bg: ColorRect = ColorRect.new()
	bg.color = BG
	bg.size = Vector2(SIZE)
	vp.add_child(bg)
	var card: Postcard = Postcard.new()
	card.size = Vector2(SIZE.x * 0.78, SIZE.x * 0.78 * 0.72)
	card.position = Vector2((SIZE.x - card.size.x) * 0.5, 70)
	card.pivot_offset = card.size * 0.5
	card.rotation = deg_to_rad(-2.0)
	card_setup.call(card)
	vp.add_child(card)
	var title: Label = Label.new()
	title.text = TranslationServer.translate("MENU_TITLE")
	title.add_theme_font_override("font", Postcard.TITLE_FONT)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, SIZE.y - 170)
	title.size = Vector2(SIZE.x, 80)
	vp.add_child(title)
	var line: Label = Label.new()
	line.text = TranslationServer.translate("SHARE_CAPTION")
	line.add_theme_font_size_override("font_size", 30)
	line.add_theme_color_override("font_color", Color(CREAM, 0.8))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.position = Vector2(0, SIZE.y - 86)
	line.size = Vector2(SIZE.x, 44)
	vp.add_child(line)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	return img
