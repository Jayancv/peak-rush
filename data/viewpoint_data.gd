class_name ViewpointData
extends Resource
## A photo spot on a trail. The scene places a Viewpoint node with the same id (M4).

@export var id: StringName
@export var name_key: String
## Pre-drawn postcard unlocked by photographing this viewpoint.
@export var postcard: Texture2D
## What the code-drawn postcard shows until `postcard` has painted art (PostcardArt).
## New motifs go at the END: trail.tres files store the number.
enum Motif { DEFAULT, LAKE, BIRD, SEA, LIGHTHOUSE, REINDEER, FELL, WATERFALL, FJORD, GLACIER, CABIN, AURORA, FROZEN_LAKE, MARSH, TOWER, MISTY_POND }
@export var motif: Motif = Motif.DEFAULT
