extends GutTest

var hud: Hud


func before_each() -> void:
	hud = add_child_autofree((load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()) as Hud


func test_bench_shows_boost_badge() -> void:
	assert_false(hud.is_boosted())
	hud.set_regen(HikerCondition.Regen.BENCH)
	assert_true(hud.is_boosted())
	assert_eq(hud.stamina_bar.boost, HikerCondition.Regen.BENCH)


func test_plain_rest_sweeps_bar_without_badge() -> void:
	hud.set_regen(HikerCondition.Regen.REST)
	assert_false(hud.is_boosted())
	assert_eq(hud.stamina_bar.boost, HikerCondition.Regen.REST)


func test_walking_clears_boost() -> void:
	hud.set_regen(HikerCondition.Regen.BENCH)
	hud.set_regen(HikerCondition.Regen.NONE)
	assert_false(hud.is_boosted())
	assert_eq(hud.stamina_bar.boost, 0)


func test_photo_counter_format() -> void:
	hud.set_photos(1, 3)
	assert_eq(hud.photo_label.text, "1/3")
