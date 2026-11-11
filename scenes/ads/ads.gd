class_name Ads
extends RefCounted
## The game's one door to ads (static, so no extra autoload). Picks the provider:
## a real network when its plugin is present (M7.9), the mock in debug builds, and no ads
## at all otherwise, so a release build without the SDK can never show a fake ad.
## AdPolicy decides when; screens just ask.

static var provider: AdProvider
static var policy: AdPolicy


static func _ensure() -> void:
	if provider == null:
		# Tests drive ads explicitly through use_provider().
		provider = MockAdProvider.new() if OS.is_debug_build() and not SaveService.is_test_run() else AdProvider.new()
	if policy == null:
		policy = AdPolicy.new(ContentDB.balance)


## Tests (and the real network later) swap the provider in.
static func use_provider(p: AdProvider) -> void:
	provider = p
	policy = AdPolicy.new(ContentDB.balance)


## First launch: ask for ad consent once, if the network needs it.
static func ensure_consent(host: Node) -> void:
	_ensure()
	if provider.needs_consent() and str(GameState.settings.get("ad_consent", "")).is_empty():
		open_consent(host)


## "Ad privacy choices" in About: ask again.
static func open_consent(host: Node) -> void:
	_ensure()
	provider.show_consent(host, func(choice: String) -> void: GameState.set_setting("ad_consent", choice))


static func rewarded_ready() -> bool:
	_ensure()
	return provider.is_rewarded_ready()


static func show_rewarded(host: Node, on_reward: Callable, on_closed: Callable = func() -> void: pass) -> void:
	_ensure()
	provider.show_rewarded(host, on_reward, on_closed)


static func is_showing() -> bool:
	return provider != null and provider.is_showing()


static func note_hike_finished() -> void:
	_ensure()
	policy.note_hike_finished()


## Leaving the results screen: maybe an interstitial first, then `then`.
static func between_hikes(host: Node, tutorial: bool, then: Callable) -> void:
	_ensure()
	var now: float = Time.get_ticks_msec() / 1000.0
	if not provider.is_interstitial_ready() or not policy.may_show_interstitial(GameState.profile.hikes, tutorial, now):
		then.call()
		return
	policy.note_interstitial_shown(now)
	provider.show_interstitial(host, then)
