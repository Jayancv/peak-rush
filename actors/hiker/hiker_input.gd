class_name HikerInput
extends RefCounted
## Reads the walk/jump actions for the hiker, keeps the jump buffer (a jump tapped
## just before it's possible still fires) and picks which way to face.

var jump_buffer_left: float = 0.0
## Set by choose_facing() the moment walking back first hits the limit (once per push).
var back_just_blocked: bool = false

var _back_was_blocked: bool = false

var _jump_was_down: bool = false
## Physics ticks since spawn; input is ignored on the first one.
var _ticks: int = 0


func wants_walk(allowed: bool) -> bool:
	return allowed and Input.is_action_pressed("walk")


func wants_back(allowed: bool) -> bool:
	return allowed and Input.is_action_pressed("walk_back")


## Forward wins if both directions are held; back only while `back_ok` (not at the
## last checkpoint yet). Returns the new facing (+1 / -1).
func choose_facing(allowed: bool, current: float, back_ok: bool) -> float:
	back_just_blocked = false
	if wants_walk(allowed):
		return 1.0
	if wants_back(allowed):
		if back_ok:
			_back_was_blocked = false
			return -1.0
		if not _back_was_blocked:
			_back_was_blocked = true
			back_just_blocked = true
	return current


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
