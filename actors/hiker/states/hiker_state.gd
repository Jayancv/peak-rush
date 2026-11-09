class_name HikerState
extends RefCounted
## One state of the hiker's state machine. States set velocity and pick the next
## state; Hiker owns move_and_slide() and the shared movement helpers.

var hiker: Hiker


func _init(owner_hiker: Hiker) -> void:
	hiker = owner_hiker


func enter() -> void:
	pass


func exit() -> void:
	pass


## Returns the next Hiker.State, or Hiker.STAY to remain in this one.
func physics_update(_delta: float) -> int:
	return Hiker.STAY
