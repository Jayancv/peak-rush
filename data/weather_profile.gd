class_name WeatherProfile
extends Resource
## How a trail's weather affects the hike. M2/M3 use the drain multiplier;
## M5 adds the visuals (fog overlay, rain, snow, wind gusts).

@export var id: StringName = &"clear"
@export var name_key: String = "WEATHER_CLEAR"
## Multiplies walking stamina drain (rain 1.3, snow 1.2 in GAME_DESIGN §5.8).
@export var drain_multiplier: float = 1.0
@export var fog: bool = false
@export var rain: bool = false
@export var snow: bool = false
@export var wind: bool = false
