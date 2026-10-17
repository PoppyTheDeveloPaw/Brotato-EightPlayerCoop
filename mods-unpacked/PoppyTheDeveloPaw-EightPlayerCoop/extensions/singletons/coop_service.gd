extends "res://singletons/coop_service.gd"

# Eight Player Coop - CoopService
#
# * Raises the local player cap to 8.
# * Adds 4 more player colours.
# * Fixes device bookkeeping so up to 16 gamepads can be told apart.
#   Vanilla remaps gamepad 0 to id 6 and the keyboard to id 7, which collides with
#   real gamepads 6 and 7. Those (and any higher gamepad ids) are moved to raw id + 10.
#   Gamepads 1-5 and the vanilla ids 6/7 are unchanged, so nothing else needs to know.

const MP_MAX_PLAYERS: = 8
const MP_MAX_RAW_JOYPADS: = 16
const MP_HIGH_JOYPAD_OFFSET: = 10

const MP_EXTRA_PLAYER_COLORS: = [
	Color("a1b2fc"),
	Color("fca1e4"),
	Color("fca7a1"),
	Color("cba1fc"),
]

var mp_dev_max_players = 0


func _ready() -> void:
	_mp_ensure_player_colors()


func _mp_ensure_player_colors() -> void:
	if player_colors.size() >= MP_MAX_PLAYERS:
		return
	var colors: Array = player_colors.duplicate()
	while colors.size() < MP_MAX_PLAYERS:
		var extra_index: int = int(max(0, colors.size() - 4)) % MP_EXTRA_PLAYER_COLORS.size()
		colors.push_back(MP_EXTRA_PLAYER_COLORS[extra_index])
	player_colors = colors


func get_max_players():
	var vanilla_max: int = .get_max_players()
	if vanilla_max < UI_MAX_PLAYER_COUNT:
		return vanilla_max  # platforms with a lower limit keep it
	if mp_dev_max_players > 0:
		return mp_dev_max_players
	return MP_MAX_PLAYERS


func get_player_color(player_index: int, value: = 1.0) -> Color:
	if player_index < 0 or player_index >= player_colors.size():
		_mp_ensure_player_colors()
	if player_index < 0 or player_index >= player_colors.size():
		return Color.white
	return .get_player_color(player_index, value)


# ---------------------------------------------------------------------------
# Device ids
# ---------------------------------------------------------------------------

func mp_remap_joypad(raw_device: int) -> int:
	if raw_device == 0:
		return GAMEPAD_REMAPPED_DEVICE_ID
	if raw_device >= GAMEPAD_REMAPPED_DEVICE_ID:
		return raw_device + MP_HIGH_JOYPAD_OFFSET
	return raw_device


# Returns the raw joypad id behind a remapped device id, or -1 for the keyboard / debug devices.
func mp_raw_joypad(remapped_device: int) -> int:
	if remapped_device == GAMEPAD_REMAPPED_DEVICE_ID:
		return 0
	if remapped_device == KEYBOARD_REMAPPED_DEVICE_ID:
		return - 1
	if remapped_device >= GAMEPAD_REMAPPED_DEVICE_ID + MP_HIGH_JOYPAD_OFFSET:
		return remapped_device - MP_HIGH_JOYPAD_OFFSET
	if remapped_device > 0 and remapped_device < GAMEPAD_REMAPPED_DEVICE_ID:
		return remapped_device
	return - 1


func mp_get_remapped_devices() -> Array:
	var devices = [KEYBOARD_REMAPPED_DEVICE_ID]
	for raw in MP_MAX_RAW_JOYPADS:
		devices.push_back(mp_remap_joypad(raw))
	return devices


# ---------------------------------------------------------------------------
# Joining. The game's own join handling (_input / _process, called for every
# script level by Godot) covers the keyboard and gamepads 0-5. Gamepads 6 and up
# use the remapped ids above, so their "hold accept" is started here and the
# game's _process then finishes the join as usual.
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if Utils.on_nintendo_nx_or_ounce:
		return
	if not event is InputEventJoypadButton or event.device < GAMEPAD_REMAPPED_DEVICE_ID:
		return
	var remapped: int = mp_remap_joypad(event.device)
	if _hold_timers.has(remapped):
		return
	var accept_action: String = "ui_accept_" + str(remapped)
	if InputMap.has_action(accept_action) and event.is_action_pressed(accept_action):
		_hold_timers[remapped] = 0.0
		set_process(true)


# The game names the controller type after the raw joypad's name, which it can't
# find for the remapped ids of gamepads 6+.
func _add_player(device: int, player_type: int) -> void:
	if device >= GAMEPAD_REMAPPED_DEVICE_ID + MP_HIGH_JOYPAD_OFFSET and player_type == PlayerType.KEYBOARD_AND_MOUSE:
		player_type = mp_gamepad_type(mp_raw_joypad(device))
	._add_player(device, player_type)


# Controller type of a raw joypad, from its name.
func mp_gamepad_type(raw_joypad: int) -> int:
	if Utils.on_nintendo_nx_or_ounce:
		return PlayerType.GAMEPAD_SWITCH
	if Utils.on_playstation:
		return PlayerType.GAMEPAD_PLAYSTATION
	if Utils.on_gdk:
		return PlayerType.GAMEPAD_XBOX
	for word in Input.get_joy_name(raw_joypad).to_lower().split(" "):
		match word:
			"playstation", "dualsense", "ps4", "ps5":
				return PlayerType.GAMEPAD_PLAYSTATION
			"nintendo", "switch":
				return PlayerType.GAMEPAD_SWITCH
	return PlayerType.GAMEPAD_XBOX


func _on_Input_joy_connection_changed(device: int, connected: bool) -> void:
	if device < GAMEPAD_REMAPPED_DEVICE_ID:
		._on_Input_joy_connection_changed(device, connected)
		return
	# Gamepads 6+: the game would mistake them for gamepad 0 / the keyboard.
	var remapped: int = mp_remap_joypad(device)
	if not connected and listening_for_inputs and is_device_assigned(remapped):
		_remove_player(remapped)
