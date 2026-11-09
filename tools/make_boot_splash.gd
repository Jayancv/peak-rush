extends SceneTree
## Renders the engine boot image from the Splash scene's first frame, so the hand-over
## from boot image to animated splash is seamless. Needs a real window (not --headless):
##   godot --path . -s tools/make_boot_splash.gd
## 2560 x 1080 covers phones up to ~21:9; project.godot shows it with stretch mode
## "Keep Height", which matches how the game's `expand` aspect scales the scene.

const OUT := "res://shared_art/icons/boot_splash.png"
const SIZE := Vector2i(2560, 1080)
## The same 720-unit-tall view the game gets on a screen this shape.
const BASE_HEIGHT: int = 720


func _initialize() -> void:
	_run()


func _run() -> void:
	# Loaded at runtime: tool scripts compile before autoloads exist, so no class names here.
	var splash_script: GDScript = load("res://scenes/splash/splash.gd")
	splash_script.set("autoplay", false)
	var vp: SubViewport = SubViewport.new()
	vp.size = SIZE
	vp.size_2d_override = Vector2i(roundi(float(SIZE.x) * BASE_HEIGHT / SIZE.y), BASE_HEIGHT)
	vp.size_2d_override_stretch = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	vp.add_child((load("res://scenes/splash/splash.tscn") as PackedScene).instantiate())
	for i: int in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("wrote ", OUT, " ", img.get_size())
	quit()
