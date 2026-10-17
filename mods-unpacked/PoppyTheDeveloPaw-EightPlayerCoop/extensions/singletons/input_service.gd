extends "res://singletons/input_service.gd"

# Eight Player Coop - InputService
# Builds per-device actions for gamepads 6-15 (see CoopService.mp_remap_joypad)
# and removes the gamepad-7 events vanilla puts into the keyboard actions (*_7).

const MP_MAX_RAW_JOYPADS: = 16


func _copy_device_actions():
	var base_actions = {}
	for action_name in InputMap.get_actions():
		base_actions[action_name] = [InputMap.get_action_list(action_name), InputMap.action_get_deadzone(action_name)]

	._copy_device_actions()

	var keyboard_suffix: String = "_%s" % CoopService.KEYBOARD_REMAPPED_DEVICE_ID
	for action_name in base_actions:
		var keyboard_action: String = action_name + keyboard_suffix
		if not InputMap.has_action(keyboard_action):
			continue
		for event in InputMap.get_action_list(keyboard_action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(keyboard_action, event)

	# Gamepads 6+ get their own copies of every gamepad binding.
	for raw_device in range(CoopService.GAMEPAD_REMAPPED_DEVICE_ID, MP_MAX_RAW_JOYPADS):
		var remapped_device: int = CoopService.mp_remap_joypad(raw_device)
		for action_name in base_actions:
			var deadzone: float = base_actions[action_name][1]
			for event in base_actions[action_name][0]:
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					var device_event: InputEvent = event.duplicate()
					device_event.device = raw_device
					add_action(action_name, remapped_device, deadzone, device_event)


# Menu navigation repeat (held d-pad / stick): the game only looks at the first
# 8 gamepads for new presses; gamepads 8-15 are picked up here. Running timers of
# any gamepad are then advanced by the game itself.
func _process(_delta: float) -> void:
	if _disable_input:
		return
	for device in range(MAX_DEVICE_COUNT, MP_MAX_RAW_JOYPADS):
		_mp_start_repeat(device, _dpad_timers, _d_pad_button_range(), "button", "_on_dpad_timer_timeout")
		_mp_start_repeat(device, _joystick_timers, [JOY_AXIS_0, JOY_AXIS_1], "axis", "_on_joystick_timer_timeout")


func _mp_start_repeat(device: int, timers: Dictionary, inputs: Array, input_type: String, on_timeout: String) -> void:
	if timers.has(device):
		return
	var held: = false
	for input in inputs:
		held = held or _is_input_pressed(device, input, input_type)
	if not held:
		return
	var repeat_timer: = FixedTimer.new()
	repeat_timer.wait_time = _echo_delay
	repeat_timer.start()
	timers[device] = repeat_timer
	# A stick moves the selection right away, the d-pad on its own key press.
	if input_type == "axis":
		call(on_timeout, device)


# Gamepads 6+ belong to the remapped device ids (see CoopService.mp_remap_joypad).
func _emulate_action(device: int, input, action: String) -> void:
	if device < CoopService.GAMEPAD_REMAPPED_DEVICE_ID:
		._emulate_action(device, input, action)
		return
	var kind: String = "axis" if input == JOY_AXIS_0 or input == JOY_AXIS_1 else "button"
	if not _is_input_pressed(device, input, kind):
		return
	var owner_device: int = CoopService.mp_remap_joypad(device)
	var emulated: = InputEventAction.new()
	emulated.action = action + "_" + str(owner_device) if CoopService.is_device_assigned(owner_device) else action
	emulated.device = device
	emulated.pressed = true
	Input.parse_input_event(emulated)
