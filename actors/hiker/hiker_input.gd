class_name HikerInput
extends RefCounted
## Reads the walk/jump actions for the hiker and keeps the jump buffer (a jump tapped
## just before it's possible still fires).

var jump_buffer_left: float = 0.0

var _jump_was_down: bool = false
## Physics ticks since spawn; input is ignored on the first one.
var _ticks: int = 0


func wants_walk(allowed: bool) -> bool:
	return allowed and Input.is_action_pressed("walk")


func wants_back(allowed: bool) -> bool:
	return allowed and Input.is_action_pressed("walk_back")


func update(delta: float, allowed: bool, buffer_seconds: float) -> void:
	_ticks += 1
	if _ticks == 1:
		# A tap from the previous screen still reads as "just pressed" on the first
		# tick; don't let it make a freshly spawned hiker jump.
		_jump_was_down = Input.is_action_pressed("jump")
		return
	# Touch presses arrive via Input.action_press, which can land between physics
	# ticks; checking the held edge too means a quick tap is never lost.
	var down: bool = allowed and Input.is_action_pressed("jump")
	if (allowed and Input.is_action_just_pressed("jump")) or (down and not _jump_was_down):
		jump_buffer_left = buffer_seconds
	else:
		jump_buffer_left = maxf(jump_buffer_left - delta, 0.0)
	_jump_was_down = down
