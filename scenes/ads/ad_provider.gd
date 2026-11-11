class_name AdProvider
extends RefCounted
## What the game needs from an ad network. This base class is also the "no ads" provider:
## nothing is ever ready and callbacks run straight away, so screens never wait on it.
## MockAdProvider (debug builds) fakes ads on screen; a real AdMob provider will subclass this.


func needs_consent() -> bool:
	return false


## Shows the consent form; `on_done(choice: String)` gets "personalized" or "non_personalized".
func show_consent(_host: Node, on_done: Callable) -> void:
	on_done.call("non_personalized")


func is_rewarded_ready() -> bool:
	return false


## `on_reward` runs only if the player watched to the end; `on_closed` always runs.
func show_rewarded(_host: Node, _on_reward: Callable, on_closed: Callable) -> void:
	on_closed.call()


## True while an ad covers the screen (screens ignore back/navigation meanwhile).
func is_showing() -> bool:
	return false


func is_interstitial_ready() -> bool:
	return false


func show_interstitial(_host: Node, on_closed: Callable) -> void:
	on_closed.call()
