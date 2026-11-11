class_name AdPolicy
extends RefCounted
## When ads may show. Ads never interrupt a hike: the only full-screen (interstitial)
## spot is leaving the results screen, and it's rare. Rewarded ads are always the
## player's choice. Pure rules, so they're tested; the numbers live in Balance.

var _balance: Balance
## Hikes finished since the last interstitial (this app session).
var hikes_since_interstitial: int = 0
## Engine seconds (Time.get_ticks_msec / 1000) of the last interstitial; -INF = never.
var last_interstitial_at: float = -INF


func _init(balance: Balance) -> void:
	_balance = balance


func note_hike_finished() -> void:
	hikes_since_interstitial += 1


## Leaving the results screen: may an interstitial show now?
## `total_hikes` = the player's lifetime hikes (new players get a grace period),
## `tutorial` = the hike was the tutorial trail, `now` = seconds since start.
func may_show_interstitial(total_hikes: int, tutorial: bool, now: float) -> bool:
	if tutorial or total_hikes < _balance.ad_grace_hikes:
		return false
	if hikes_since_interstitial < _balance.ad_interstitial_every:
		return false
	return now - last_interstitial_at >= _balance.ad_interstitial_min_seconds


func note_interstitial_shown(now: float) -> void:
	hikes_since_interstitial = 0
	last_interstitial_at = now


## TP a rewarded ad adds on the results screen (0 = nothing to offer).
func reward_tp(hike_total_tp: int) -> int:
	if hike_total_tp <= 0:
		return 0
	return maxi(int(round(hike_total_tp * _balance.ad_reward_tp_mult)), _balance.ad_reward_min_tp)
