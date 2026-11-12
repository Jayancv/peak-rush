class_name EventData
extends Resource
## A seasonal event on the calendar (every year, no update needed): falling leaves, petals,
## snow or fireflies on every trail, and a little collectible to gather towards a goal.
## Listed in ContentIndex.events; SeasonalEvents decides which one is on today.

enum Token { LEAF, LANTERN, BLOSSOM, BERRY }
enum Particles { NONE, LEAVES, SNOW, PETALS, FIREFLIES }

@export var id: StringName
@export var name_key: String
## The collectible's name ("Golden leaves"), for toasts and the Daily card.
@export var token_key: String
## First and last day, "MM-DD". An event may run over New Year (start after end).
@export var start: String = "10-01"
@export var end: String = "10-31"
@export var token: Token = Token.LEAF
@export var token_color: Color = Color("#E0A030")
@export var particles: Particles = Particles.NONE
@export var particle_color: Color = Color("#E0A030")
## Tokens to gather this year for the event reward.
@export var goal: int = 25
