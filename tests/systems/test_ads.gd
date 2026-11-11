extends GutTest
## Ads: the policy (rare interstitials, grace period, never after the tutorial), the
## rewarded payout, the mock flow, and that tests/release builds don't show mock ads.

var _b: Balance = Balance.new()
var _saved: Dictionary
var _mock: MockAdProvider


func before_each() -> void:
	_saved = GameState.to_dict()
	GameState.reset()
	GameState.settings["ad_consent"] = "personalized"
	_mock = MockAdProvider.new()
	_mock.instant = true
	_mock.auto_consent = "non_personalized"
	Ads.use_provider(_mock)


func after_each() -> void:
	Ads.use_provider(AdProvider.new())
	GameState.from_dict(_saved)


func test_interstitials_are_rare_and_spare_new_players() -> void:
	var p: AdPolicy = AdPolicy.new(_b)
	var veteran: int = _b.ad_grace_hikes + 10
	assert_false(p.may_show_interstitial(veteran, false, 1000.0), "not before N hikes this session")
	for i: int in _b.ad_interstitial_every:
		p.note_hike_finished()
	assert_true(p.may_show_interstitial(veteran, false, 1000.0))
	assert_false(p.may_show_interstitial(_b.ad_grace_hikes - 1, false, 1000.0), "new players get a grace period")
	assert_false(p.may_show_interstitial(veteran, true, 1000.0), "never after the tutorial trail")
	p.note_interstitial_shown(1000.0)
	for i: int in _b.ad_interstitial_every:
		p.note_hike_finished()
	assert_false(p.may_show_interstitial(veteran, false, 1000.0 + _b.ad_interstitial_min_seconds - 1.0), "minimum gap between ads")
	assert_true(p.may_show_interstitial(veteran, false, 1000.0 + _b.ad_interstitial_min_seconds))


func test_reward_is_a_share_of_the_hike_with_a_floor() -> void:
	var p: AdPolicy = AdPolicy.new(_b)
	assert_eq(p.reward_tp(0), 0, "nothing earned, nothing to double")
	assert_eq(p.reward_tp(200), int(round(200 * _b.ad_reward_tp_mult)))
	assert_eq(p.reward_tp(10), _b.ad_reward_min_tp)


func test_between_hikes_shows_an_interstitial_only_when_allowed() -> void:
	var went: Array[int] = [0]
	var go: Callable = func() -> void: went[0] += 1
	var host: Node = add_child_autofree(Node.new())
	Ads.between_hikes(host, false, go)
	assert_eq(went[0], 1, "the player always gets where they were going")
	assert_eq(_mock.shown_interstitials, 0, "a brand-new player sees no ad")
	GameState.profile.hikes = _b.ad_grace_hikes + 5
	for i: int in ContentDB.balance.ad_interstitial_every:
		Ads.note_hike_finished()
	Ads.between_hikes(host, false, go)
	assert_eq(_mock.shown_interstitials, 1)
	assert_eq(went[0], 2)


func test_failed_loads_hide_the_reward_and_skip_interstitials() -> void:
	_mock.fail_loads = true
	assert_false(Ads.rewarded_ready())
	GameState.profile.hikes = 99
	for i: int in ContentDB.balance.ad_interstitial_every:
		Ads.note_hike_finished()
	var went: Array[int] = [0]
	Ads.between_hikes(add_child_autofree(Node.new()), false, func() -> void: went[0] += 1)
	assert_eq(went[0], 1)
	assert_eq(_mock.shown_interstitials, 0)


func test_watching_a_rewarded_ad_pays_tp() -> void:
	GameState.tp = 100
	var paid: Array[bool] = [false]
	Ads.show_rewarded(add_child_autofree(Node.new()), func() -> void:
		paid[0] = true
		GameState.add_bonus_tp(40))
	assert_true(paid[0])
	assert_eq(GameState.tp, 140)
	assert_eq(int(GameState.last_result.ad_bonus), 40)


func test_consent_is_asked_once_and_remembered() -> void:
	GameState.settings["ad_consent"] = ""
	_mock.auto_consent = ""
	GameState.profile.hikes = _b.ad_grace_hikes
	var host: Node = add_child_autofree(Node.new())
	Ads.ensure_consent(host)
	var overlay: MockAdOverlay = null
	for child: Node in get_tree().root.get_children():
		if child is MockAdOverlay:
			overlay = child
	assert_not_null(overlay, "the consent form is up")
	# Pick "personalised".
	for b: Node in overlay.find_children("*", "Button", true, false):
		if (b as Button).text == tr("CONSENT_PERSONALIZED"):
			(b as Button).pressed.emit()
	assert_eq(str(GameState.settings.ad_consent), "personalized")


func test_tests_and_release_never_get_the_mock() -> void:
	Ads.provider = null
	Ads._ensure()
	assert_false(Ads.provider is MockAdProvider, "under GUT (and in release) the no-ads provider is used")
	assert_false(Ads.provider.is_rewarded_ready())


func test_nothing_loads_and_nobody_is_asked_before_ads_matter() -> void:
	GameState.settings["ad_consent"] = ""
	Ads.use_provider(_mock)
	Ads.ensure_consent(add_child_autofree(Node.new()))
	assert_eq(_mock.consent_asked, 0, "a new player's first launch goes straight to the game")
	assert_false(_mock.started, "no ad requests before the player has chosen")
	assert_false(Ads.rewarded_ready())
	assert_true(Ads.can_offer_reward(), "the results screen can still offer the reward")


func test_watch_an_ad_asks_consent_first_then_shows_the_ad() -> void:
	GameState.settings["ad_consent"] = ""
	Ads.use_provider(_mock)
	var paid: Array[bool] = [false]
	await Ads.request_rewarded(add_child_autofree(Node.new()), func() -> void: paid[0] = true)
	assert_eq(_mock.consent_asked, 1)
	assert_eq(GameState.settings.ad_consent, "non_personalized")
	assert_true(_mock.started)
	assert_true(paid[0], "the ad the player asked for still plays")


func test_first_due_interstitial_becomes_the_consent_question() -> void:
	GameState.settings["ad_consent"] = ""
	Ads.use_provider(_mock)
	GameState.profile.hikes = _b.ad_grace_hikes + 5
	for i: int in ContentDB.balance.ad_interstitial_every:
		Ads.note_hike_finished()
	var went: Array[int] = [0]
	Ads.between_hikes(add_child_autofree(Node.new()), false, func() -> void: went[0] += 1)
	assert_eq(_mock.consent_asked, 1)
	assert_eq(_mock.shown_interstitials, 0, "the exit that asked stays ad-free")
	assert_eq(went[0], 1)


func test_menu_asks_players_past_the_grace_period() -> void:
	GameState.settings["ad_consent"] = ""
	Ads.use_provider(_mock)
	GameState.profile.hikes = _b.ad_grace_hikes
	Ads.ensure_consent(add_child_autofree(Node.new()))
	assert_eq(_mock.consent_asked, 1)
