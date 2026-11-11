class_name Ads
extends RefCounted
## The game's one door to ads (static, so no extra autoload). Picks the provider:
## a real network when its plugin is present (M7.9), the mock in debug builds, and no ads
## at all otherwise, so a release build without the SDK can never show a fake ad.
## AdPolicy decides when; screens just ask.
## Consent is asked when ads first matter (the first "watch an ad" tap, or just before the
## first interstitial after the grace period), not on first launch: a new player's first
## minute is the game. Nothing loads before the player has chosen.

static var provider: AdProvider
static var policy: AdPolicy
static var _started: bool = false


static func _ensure() -> void:
	if provider == null:
		# Tests drive ads explicitly through use_provider().
		provider = MockAdProvider.new() if OS.is_debug_build() and not SaveService.is_test_run() else AdProvider.new()
	if policy == null:
		policy = AdPolicy.new(ContentDB.balance)
	if not consent_pending() and not _started:
		_started = true
		provider.start(str(GameState.settings.get("ad_consent", "")) == "personalized")


## Tests (and the real network later) swap the provider in.
static func use_provider(p: AdProvider) -> void:
	provider = p
	policy = AdPolicy.new(ContentDB.balance)
	_started = false


## True until the player has answered the consent question (when the network needs one).
static func consent_pending() -> bool:
	return provider != null and provider.needs_consent() and str(GameState.settings.get("ad_consent", "")).is_empty()


## Main menu fallback: once past the grace period, ask if still unanswered.
static func ensure_consent(host: Node) -> void:
	_ensure()
	if consent_pending() and GameState.profile.hikes >= ContentDB.balance.ad_grace_hikes:
		open_consent(host)


## Asks (or, from About > Ad privacy choices, asks again); `then` runs after the choice.
static func open_consent(host: Node, then: Callable = func() -> void: pass) -> void:
	_ensure()
	provider.show_consent(host, func(choice: String) -> void:
		GameState.set_setting("ad_consent", choice)
		_started = false
		_ensure()
		then.call())


static func rewarded_ready() -> bool:
	_ensure()
	return not consent_pending() and provider.is_rewarded_ready()


## Whether the results screen may offer "watch an ad": a loaded ad, or the consent question first.
static func can_offer_reward() -> bool:
	_ensure()
	return consent_pending() or rewarded_ready()


## The "watch an ad" button: consent first if needed, then the ad once it has loaded
## (gives up after `wait_seconds`; `on_closed` runs either way).
static func request_rewarded(host: Node, on_reward: Callable, on_closed: Callable = func() -> void: pass, wait_seconds: float = 8.0) -> void:
	_ensure()
	if consent_pending():
		open_consent(host, func() -> void: request_rewarded(host, on_reward, on_closed, wait_seconds))
		return
	var waited: float = 0.0
	while not provider.is_rewarded_ready() and waited < wait_seconds and is_instance_valid(host):
		await host.get_tree().create_timer(0.25).timeout
		waited += 0.25
	if provider.is_rewarded_ready() and is_instance_valid(host):
		provider.show_rewarded(host, on_reward, on_closed)
	else:
		on_closed.call()


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
	if consent_pending() and policy.may_show_interstitial(GameState.profile.hikes, tutorial, now):
		# The first ad is due: ask now, and let this exit go ad-free.
		open_consent(host, then)
		return
	if not provider.is_interstitial_ready() or not policy.may_show_interstitial(GameState.profile.hikes, tutorial, now):
		then.call()
		return
	policy.note_interstitial_shown(now)
	provider.show_interstitial(host, then)
