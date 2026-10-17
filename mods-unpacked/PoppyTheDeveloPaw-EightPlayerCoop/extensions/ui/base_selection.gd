extends "res://ui/menus/run/base_selection.gd"

# Eight Player Coop - shared part of the character / weapon / difficulty screens.
#
# The selection screens keep their per-player state in arrays of 4 and look up
# 4 panels / inventories. This extension grows the arrays, lets each screen add
# its slots 5-8 (_mp_build_extra_slots) and appends those to the panel and
# inventory lists.
#
# While the screen's start-up code restores each player's last focused element
# it only has room for 4 players, so for that short moment the player count
# seen by the game is limited to 4 and players 5-8 get their focus restored here.

const MP8PadBS = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")
const MP8_FIRST_EXTRA_PLAYER: = 4

var _mp_slots_built = false
var _mp_focus_restore_pending = false
var _mp_saved_focus_ids = {}


func _init() -> void:
	MP8PadBS.pad(displayed_elements, "array")
	MP8PadBS.pad(_has_player_selected, "bool")
	MP8PadBS.pad(_displayed_panel_data_element, "null")
	MP8PadBS.pad(_latest_focused_element, "null")


func _ready() -> void:
	# Runs right after the shared start-up code, before the screen's own _ready.
	if _mp_focus_restore_pending:
		_mp_focus_restore_pending = false
		RunData.set("mp8_player_count_limit", 0)
		_mp_focus_extra_players()


func _init_players() -> void:
	_mp_prepare_extra_players()
	._init_players()
	_mp_begin_vanilla_focus_restore()


# Builds the screen's slots for players 5-8 once (must happen before the
# inventories are wired up).
func _mp_prepare_extra_players() -> void:
	if _mp_slots_built:
		return
	_mp_slots_built = true
	_mp_build_extra_slots()


# Overridden by the 8-player extensions of each selection screen.
func _mp_build_extra_slots() -> void:
	pass


func _mp_begin_vanilla_focus_restore() -> void:
	if _mp_focus_restore_pending:
		return
	var count: int = RunData.get_player_count()
	if count <= MP8_FIRST_EXTRA_PLAYER:
		return
	_mp_saved_focus_ids.clear()
	for player_index in range(MP8_FIRST_EXTRA_PLAYER, count):
		if player_index >= Utils.last_elt_selected.size():
			break
		var element = Utils.last_elt_selected[player_index]
		if element != null:
			_mp_saved_focus_ids[player_index] = element.my_id_hash
	_mp_focus_restore_pending = true
	RunData.set("mp8_player_count_limit", MP8_FIRST_EXTRA_PLAYER)


# Players 5-8: focus the element they had selected before (e.g. when coming back
# from the next screen), otherwise the first element of their inventory.
func _mp_focus_extra_players() -> void:
	var inventories: Array = _get_inventories()
	if inventories.empty():
		return
	for player_index in range(MP8_FIRST_EXTRA_PLAYER, RunData.get_player_count()):
		var target: Node = null
		if _mp_saved_focus_ids.has(player_index):
			target = _find_inventory_element_by_id(_mp_saved_focus_ids[player_index], player_index)
		if target == null:
			var own_inventory: Node = inventories[player_index % inventories.size()]
			if own_inventory.get_child_count() > 0:
				target = own_inventory.get_child(0)
		if target != null:
			Utils.call_deferred("focus_player_control", target, player_index)
	_mp_saved_focus_ids.clear()


func _set_base_ui_player_count(count: int, is_coop_run: bool, initialize: bool = false) -> void:
	._set_base_ui_player_count(count, is_coop_run, initialize)
	# The shared code only deselects the first 4 players when coop is left.
	if count != 0 and is_coop_run:
		return
	var panels: Array = _get_panels()
	for player_index in range(MP8_FIRST_EXTRA_PLAYER, panels.size()):
		_clear_selected_element(player_index)


func _get_inventory_containers() -> Array:
	var containers: Array = ._get_inventory_containers()
	if containers.size() == MP8_FIRST_EXTRA_PLAYER:
		_mp_append_numbered(containers, "Inventory")
	return containers


func _get_panels() -> Array:
	var panels: Array = ._get_panels()
	_mp_append_numbered(panels, "Panel")
	return panels


# Appends the nodes "%<prefix>5" .. "%<prefix>8" that exist on this screen.
func _mp_append_numbered(list: Array, prefix: String) -> void:
	for number in range(MP8_FIRST_EXTRA_PLAYER + 1, MP8PadBS.MAX_PLAYERS + 1):
		var node = get_node_or_null("%" + prefix + str(number))
		if node == null:
			return
		list.push_back(node)
