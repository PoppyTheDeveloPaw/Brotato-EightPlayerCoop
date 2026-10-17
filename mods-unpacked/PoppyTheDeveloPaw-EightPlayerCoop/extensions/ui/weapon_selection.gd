extends "res://ui/menus/run/weapon_selection.gd"

# Eight Player Coop - starting weapon selection.
# Adds panels / inventories 5-8. With more than 4 players the description panels
# are shown at a smaller scale so all of them fit on one row, every column gets
# the same width and each inventory sits right under its player's panel (the
# inventories already shrink to 2 columns each in vanilla).

const MP8UIWS = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_ui.gd")
const MP8_LARGE_PANEL_SCALE: = 0.6
const MP8_SIDE_MARGIN: = 60

var _mp_slots = []
var _mp_panels_box: Container = null
var _mp_inventories_box: Container = null


func _mp_build_extra_slots() -> void:
	var panel4: Node = get_node("%Panel4")
	var inventory4: Node = get_node("%Inventory4")

	for player_index in range(MP8UIWS.VANILLA_PLAYERS, MP8UIWS.MAX_PLAYERS):
		var n = player_index + 1
		var panel = MP8UIWS.clone(panel4, "Panel%s" % n, self, "", "", null, get_node("%%Panel%s" % player_index))
		panel.visible = false
		var inventory = MP8UIWS.clone(inventory4, "Inventory%s" % n, self, "", "", null, get_node("%%Inventory%s" % player_index))
		inventory.visible = false

	var large = MP8UIWS.is_large_coop()
	var panels_box: Container = panel4.get_parent()
	for player_index in MP8UIWS.MAX_PLAYERS:
		var panel: Control = get_node("%%Panel%s" % (player_index + 1))
		var slot = MP8UIWS.make_slot(MP8_LARGE_PANEL_SCALE if large else 1.0)
		slot.name = "Slot%s" % (player_index + 1)
		_mp_slots.push_back(slot)
		panels_box.add_child(slot)
		panels_box.move_child(slot, panel.get_index())
		MP8UIWS.reparent(panel, slot)
		slot.add_slot_child(panel)

	MP8UIWS.clone_focus_emulators(self, ["Inventory%s", "Panel%s", "Slot%s"])

	_mp_panels_box = panels_box
	_mp_inventories_box = inventory4.get_parent()
	if large:
		_mp_inventories_box.add_constant_override("separation", panels_box.get_constant("separation"))


func _ready() -> void:
	if MP8UIWS.is_large_coop():
		_mp_update_columns()
		var _e = get_viewport().connect("size_changed", self, "_mp_update_columns")


# One width for every player column; the inventory below uses the same width so
# panels and inventories line up. Vanilla sizes the inventory of a character
# without weapon slots to its panel's unscaled width, which is replaced here too.
func _mp_update_columns() -> void:
	if _mp_panels_box == null or _mp_slots.empty():
		return
	var count: int = RunData.get_player_count()
	var separation: float = _mp_panels_box.get_constant("separation")
	var inventories = _get_inventory_containers()

	var narrowest_fit: float = 0.0
	for player_index in min(count, inventories.size()):
		var inventory: Control = inventories[player_index]
		inventory.rect_min_size.x = 0
		narrowest_fit = max(narrowest_fit, inventory.get_combined_minimum_size().x)

	var available: float = get_viewport_rect().size.x - 2 * MP8_SIDE_MARGIN
	var width: float = floor((available - separation * (count - 1)) / count)
	width = max(width, narrowest_fit)

	for player_index in _mp_slots.size():
		_mp_slots[player_index].rect_min_size.x = width if player_index < count else 0.0
	for player_index in min(count, inventories.size()):
		inventories[player_index].rect_min_size.x = width
