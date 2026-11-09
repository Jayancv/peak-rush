class_name WeatherProfile
extends Resource
## How a trail's weather affects the hike (GAME_DESIGN §5.8): a stamina drain
## multiplier, wind gusts that push the hiker back, and the look (fog, rain, snow).

@export var id: StringName = &"clear"
@export var name_key: String = "WEATHER_CLEAR"
## Multiplies walking stamina drain (rain 1.3, snow 1.2).
@export var drain_multiplier: float = 1.0

@export_group("Fog")
@export var fog: bool = false
## Overlay opacity at its thickest (0..1). Thick fog also hides viewpoints until close.
@export_range(0.0, 1.0) var fog_density: float = 0.5
@export var fog_color: Color = Color("#E6E9EC")

@export_group("Rain and snow")
@export var rain: bool = false
## Particles on screen at once.
@export var rain_amount: int = 160
@export var snow: bool = false
@export var snow_amount: int = 90

@export_group("Wind")
@export var wind: bool = false
## Steady headwind (px/s pushed back) while walking or in the air.
@export var wind_base: float = 6.0
## Extra push at the peak of a gust.
@export var gust_strength: float = 75.0
## Seconds between gusts (random in this range) and how long a gust lasts.
@export var gust_interval: Vector2 = Vector2(5.0, 9.0)
@export var gust_seconds: float = 1.8
