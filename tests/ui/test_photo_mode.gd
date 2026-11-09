extends GutTest

var photo: PhotoMode
var vp: Viewpoint


func before_each() -> void:
	vp = (load("res://world/interactables/viewpoint.tscn") as PackedScene).instantiate() as Viewpoint
	vp.viewpoint_id = &"test_view"
	add_child_autofree(vp)
	photo = add_child_autofree((load("res://scenes/photo_mode/photo_mode.tscn") as PackedScene).instantiate()) as PhotoMode
	photo.open(vp)


func test_centred_shot_is_perfect_and_reported() -> void:
	watch_signals(photo)
	var q: int = photo.shoot_at(photo.frame_center())
	assert_eq(q, StarRating.PhotoQuality.PERFECT)
	assert_signal_emitted_with_parameters(photo, "shot_taken", [&"test_view", StarRating.PhotoQuality.PERFECT])


func test_off_centre_shot_misses() -> void:
	assert_eq(photo.shoot_at(photo.frame_center() + Vector2(0, 600)), StarRating.PhotoQuality.NONE)


func test_cooldown_stops_double_taps() -> void:
	photo.shoot_at(photo.frame_center())
	assert_eq(photo.shoot_at(photo.frame_center()), -1, "a second tap in the same instant is ignored")


func test_empty_roll_closes_photo_mode() -> void:
	watch_signals(photo)
	for i: int in ContentDB.balance.photo_shots_per_visit:
		photo.shoot_at(photo.frame_center())
		await wait_seconds(PhotoMode.SHOT_COOLDOWN + 0.05)
	assert_false(photo.scoring.has_film())
	await wait_seconds(PhotoMode.EMPTY_ROLL_CLOSE_DELAY + 0.1)
	assert_signal_emitted(photo, "closed")
	assert_false(photo.is_open())


func test_quality_border_colours() -> void:
	assert_eq(Postcard.border_color(StarRating.PhotoQuality.PERFECT), Postcard.GOLD)
	assert_eq(Postcard.border_color(StarRating.PhotoQuality.GREAT), Postcard.SILVER)
	assert_eq(Postcard.border_color(StarRating.PhotoQuality.GOOD), Postcard.BRONZE)
