extends "res://singletons/ui_service.gd"

# Eight Player Coop - UIService
# The game works out the controller type (for button prompts) from the joypad's
# name, but for gamepads 6 and 7 it looks at gamepad 0 / the keyboard instead.

const MP_STICK_NOISE: = 0.1


func _check_input(event: InputEvent) -> int:
	var detected: int = ._check_input(event)
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return detected
	if event.device < CoopService.GAMEPAD_REMAPPED_DEVICE_ID:
		return detected
	if event is InputEventJoypadMotion and abs(event.axis_value) < MP_STICK_NOISE:
		return detected
	return CoopService.mp_gamepad_type(event.device)
