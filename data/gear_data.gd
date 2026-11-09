class_name GearData
extends Resource
## A piece of gear bought with TP; two can be equipped (Balance.gear_slots).
## Each effect is a scale on part of the hike: 1.0 = no effect.
## GAME_DESIGN §5.7: grip boots, hiking poles, rain shell, thermos, bright headlamp.

enum Icon { BOOTS, POLES, SHELL, THERMOS, HEADLAMP }

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var cost: int = 150
@export var icon: Icon = Icon.BOOTS

@export_group("Effects")
## Ice/snow slip (0.25 = slip 75% less).
@export var slip_scale: float = 1.0
## Extra stamina drain from walking uphill (0.8 = 20% less).
@export var uphill_drain_scale: float = 1.0
## The weather's extra drain (0.5 = halved: rain ×1.3 becomes ×1.15).
@export var weather_drain_scale: float = 1.0
## Stamina regen while resting (1.25 = 25% faster).
@export var rest_regen_scale: float = 1.0
## The dusk walking-speed penalty (0.5 = halved).
@export var dusk_penalty_scale: float = 1.0
