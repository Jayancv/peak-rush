class_name BadgeData
extends Resource
## An achievement shown on the profile. `rule` says what is counted and `amount` how
## many are needed; BadgeRules does the counting.

## New values go at the end: .tres files store the number.
enum Rule { TRAILS_FINISHED, STARS, PHOTOS, PERFECT_PHOTOS, HIKES, NIGHT_TRAILS, GEAR_OWNED, HIKE_MINUTES, FINDS, ANIMALS, REAL_STEPS, REAL_KM, JOURNEYS }
## Which picture the badge shows (drawn by the profile screen).
enum Art { MOUNTAIN, STAR, CAMERA, BOOTS, HEADLAMP, GEAR, CLOCK, LEAF, PAW }

@export var id: StringName
@export var name_key: String
@export var description_key: String
@export var rule: Rule = Rule.TRAILS_FINISHED
@export var amount: int = 1
@export var art: Art = Art.MOUNTAIN
@export var color: Color = Color("#E85D3F")
