class_name HikerPhotoState
extends HikerState
## Standing at a viewpoint taking a photo. Only Hiker.exit_photo() ends it (M4).


func physics_update(delta: float) -> int:
	ground_stop(hiker.balance.walk_decel, delta)
	apply_gravity(delta)
	return Hiker.STAY
