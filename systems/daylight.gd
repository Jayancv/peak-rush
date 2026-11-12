class_name Daylight
extends RefCounted
## The trail's clock. `daylight_seconds` is the time until dusk; the day runs
## morning -> midday -> golden hour -> dusk and the world tint follows it.
## Dusk is not a fail: the hike continues (slower, by headlamp) and ★3 is lost.

signal phase_changed(phase: Phase)

enum Phase { MORNING, MIDDAY, GOLDEN, DUSK }

var elapsed: float = 0.0
var daylight_seconds: float
## Night trails stay dark; "dusk" then means the window (e.g. the aurora) has closed.
var night: bool = false
## Night trails that end at dawn (a sunrise climb): the dark lifts to sunrise colours
## over the last part of the window instead of deepening.
var sunrise: bool = false

var _balance: Balance
var _phase: Phase = Phase.MORNING


func _init(balance: Balance, seconds_of_daylight: float, is_night: bool = false, ends_at_sunrise: bool = false) -> void:
	_balance = balance
	daylight_seconds = maxf(seconds_of_daylight, 1.0)
	night = is_night
	sunrise = is_night and ends_at_sunrise


func advance(delta: float) -> void:
	elapsed += delta
	var now: Phase = phase()
	if now != _phase:
		_phase = now
		phase_changed.emit(now)


## 0 at the start, 1 when dusk begins; keeps growing after dusk.
func fraction() -> float:
	return elapsed / daylight_seconds


## Where the sun is on its arc, 0 (rising) to 1 (setting).
func sun_progress() -> float:
	return clampf(fraction(), 0.0, 1.0)


func phase() -> Phase:
	var f: float = fraction()
	if f >= 1.0:
		return Phase.DUSK
	if f >= _balance.golden_start:
		return Phase.GOLDEN
	if f >= _balance.midday_start:
		return Phase.MIDDAY
	return Phase.MORNING


func is_dusk() -> bool:
	return fraction() >= 1.0


## World tint for CanvasModulate. Blends smoothly between the phase colours:
## morning warms up to clear midday, which warms into golden hour, then dusk falls.
func tint() -> Color:
	var f: float = fraction()
	var b: Balance = _balance
	if sunrise:
		var dawn: float = smoothstep(b.sunrise_start, 1.0, f)
		return b.tint_night.lerp(b.tint_sunrise, dawn) if dawn < 0.999 else b.tint_sunrise
	if night:
		return b.tint_night.lerp(b.tint_night_late, smoothstep(1.0 - b.dusk_fade, 1.0, f))
	if f < b.midday_start:
		return b.tint_morning.lerp(b.tint_midday, smoothstep(0.0, b.midday_start, f))
	if f < b.golden_start:
		return b.tint_midday
	var dusk_begin: float = 1.0 - b.dusk_fade
	if f < dusk_begin:
		return b.tint_midday.lerp(b.tint_golden, smoothstep(b.golden_start, dusk_begin, f))
	return b.tint_golden.lerp(b.tint_dusk, smoothstep(dusk_begin, 1.0, f))
