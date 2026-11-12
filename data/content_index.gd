class_name ContentIndex
extends Resource
## The one list of all shipped content. Adding a season = adding it here.
## Listed explicitly because exported builds can't reliably scan folders.

@export var seasons: Array[SeasonData] = []
## Everything the gear shop sells.
@export var gear: Array[GearData] = []
## Outfit colours for the hiker (profile screen).
@export var cosmetics: CosmeticCatalog
## Achievements shown on the profile.
@export var badges: BadgeCatalog
## Seasonal events on the calendar (SeasonalEvents picks today's).
@export var events: Array[EventData] = []
