extends GutTest
## The store review request (once, after a happy first summit, once the player knows the
## game) and the feedback mail link.

var _b: Balance = Balance.new()
var _saved: Dictionary


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()


func after_each() -> void:
	GameState.from_dict(_saved)


func test_asks_once_after_enough_first_summits() -> void:
	var n: int = _b.review_after_summits
	assert_false(ReviewPolicy.should_ask(true, n - 1, false, _b), "too early: still learning the game")
	assert_true(ReviewPolicy.should_ask(true, n, false, _b))
	assert_false(ReviewPolicy.should_ask(false, n, false, _b), "only right after a first summit, a happy moment")
	assert_false(ReviewPolicy.should_ask(true, n + 2, true, _b), "never twice")


func test_counts_only_summited_trails() -> void:
	var trails: Dictionary = {
		"a": {"stars": StarRating.STAR_SUMMIT},
		"b": {"stars": StarRating.STAR_SUMMIT | StarRating.STAR_PHOTOS},
		"c": {"stars": 0},
	}
	assert_eq(ReviewPolicy.completed_trails(trails), 2)


func test_prompt_is_remembered_and_silent_under_tests() -> void:
	for i: int in _b.review_after_summits:
		GameState.trails["t%d" % i] = {"stars": StarRating.STAR_SUMMIT}
	var host: Node = add_child_autofree(Node.new())
	assert_true(ReviewPrompt.maybe_ask(host, {"first_completion": true}))
	assert_true(bool(GameState.settings.review_asked))
	assert_false(ReviewPrompt.maybe_ask(host, {"first_completion": true}), "asked once, never again")
	for child: Node in get_tree().root.get_children():
		assert_false(child is ReviewPrompt, "no stand-in card in tests")


func test_feedback_mail_carries_version_and_phone() -> void:
	var url: String = AboutCard.feedback_url("help@example.com")
	assert_true(url.begins_with("mailto:help@example.com?subject="))
	assert_true(url.contains(AboutCard.version().uri_encode()), "the version is in the mail")
	assert_false(url.contains(" "), "spaces are encoded")
