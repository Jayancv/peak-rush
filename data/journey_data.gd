class_name JourneyData
extends Resource
## A famous long-distance trail walked over weeks: real steps and finished hikes move the
## player along it (Journey), and each landmark reached unlocks a page of a notebook story.
## Listed in ContentIndex.journeys, played in order.

@export var id: StringName
@export var name_key: String
## One line under the title: whose notebook this is and why you're walking.
@export var intro_key: String
## Real length in km (what the map and the progress show).
@export var length_km: float = 100.0
## In km order; the first is usually at km 0 (the opening page) and the last at length_km.
@export var landmarks: Array[LandmarkData] = []
## Map decoration: lakes as (centre x, centre y, radius x, radius y) in map space (0..1).
@export var lakes: PackedVector4Array = PackedVector4Array()


func landmark(id_: StringName) -> LandmarkData:
	for lm: LandmarkData in landmarks:
		if lm.id == id_:
			return lm
	return null
