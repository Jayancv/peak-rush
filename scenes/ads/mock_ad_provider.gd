class_name MockAdProvider
extends AdProvider
## Fake ads for debug builds and tests: a full-screen "TEST AD" card with a countdown,
## a consent form, and a short pretend load after each ad. Never used in release
## builds (see Ads), so players can't see it.

## Seconds a mock rewarded ad runs before it pays out, and an interstitial before it can close.
const REWARDED_SECONDS: float = 5.0
const INTERSTITIAL_SECONDS: float = 3.0
## Pretend network time before the next ad is ready again.
const LOAD_SECONDS: float = 1.5

## Tests: make loads fail (no fill), or skip the countdowns.
var fail_loads: bool = false
var instant: bool = false
var shown_rewarded: int = 0
var shown_interstitials: int = 0

var _ready_at_msec: int = 0
var _overlay: MockAdOverlay


func needs_consent() -> bool:
	return true


func show_consent(host: Node, on_done: Callable) -> void:
	MockAdOverlay.consent(host, on_done)


func is_rewarded_ready() -> bool:
	return not fail_loads and Time.get_ticks_msec() >= _ready_at_msec


func is_interstitial_ready() -> bool:
	return is_rewarded_ready()


func show_rewarded(host: Node, on_reward: Callable, on_closed: Callable) -> void:
	shown_rewarded += 1
	_reload()
	if instant:
		on_reward.call()
		on_closed.call()
		return
	_overlay = MockAdOverlay.ad(host, true, REWARDED_SECONDS, on_reward, on_closed)


func show_interstitial(host: Node, on_closed: Callable) -> void:
	shown_interstitials += 1
	_reload()
	if instant:
		on_closed.call()
		return
	_overlay = MockAdOverlay.ad(host, false, INTERSTITIAL_SECONDS, Callable(), on_closed)


func is_showing() -> bool:
	return is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion()


func _reload() -> void:
	_ready_at_msec = Time.get_ticks_msec() + int(LOAD_SECONDS * 1000.0)
