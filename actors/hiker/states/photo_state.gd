class_name HikerPhotoState
extends HikerState
## Standing at a viewpoint taking a photo. Only Hiker.exit_photo() ends it (M4).


func physics_update(delta: float) -> int:
	hiker.ground_stop(hiker.balance.walk_decel, delta)
	hiker.apply_gravity(delta)
	return Hiker.STAY
