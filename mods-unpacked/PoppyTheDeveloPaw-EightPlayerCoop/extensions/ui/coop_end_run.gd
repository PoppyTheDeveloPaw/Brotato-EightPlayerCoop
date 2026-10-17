extends "res://ui/menus/run/coop_end_run.gd"

# Eight Player Coop - coop end-of-run screen.
#
# Adds player columns, item popups and stat popups 5-8 (copies of player 4's).
# The screen's own start-up code fills one column per player but only knows 4
# columns, so while it runs the game reports at most 4 players; columns 5-8 are
# filled afterwards by _mp_fill_extra_column(). From 5 players on the columns are
# scaled down so all of them fit next to each other.

const MP8UIEnd = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_ui.gd")
const MP8PadEnd = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")

var _mp_built = false
var _mp_limit_active = false
var _mp_slots = []
var _mp_box: Container = null


func _enter_tree() -> void:
	if _mp_built:
		return
	_mp_built = true
	MP8PadEnd.auto_pad(self)
	_mp_build_extra_columns()

	if RunData.get_player_count() > MP8UIEnd.VANILLA_PLAYERS and get_child_count() > 0:
		# Children become ready before this screen; the last one signals that the
		# screen's own start-up code is next.
		var last_child: Node = get_child(get_child_count() - 1)
		var _e = last_child.connect("ready", self, "_mp_on_children_ready", [], CONNECT_ONESHOT)


func _mp_build_extra_columns() -> void:
	var captured = MP8UIEnd.capture_focus_bases(self)
	var container4: Node = get_node("%PlayerContainer4")
	_mp_box = container4.get_parent()
	for player_index in range(MP8UIEnd.VANILLA_PLAYERS, MP8UIEnd.MAX_PLAYERS):
		var n = player_index + 1
		var container = MP8UIEnd.clone(container4, "PlayerContainer%s" % n, self, "", "", null, get_node("%%PlayerContainer%s" % player_index))
		container.player_index = player_index
		container.visible = false
		for kind in ["ItemPopup", "StatPopup"]:
			var popup = MP8UIEnd.clone(get_node("%" + kind + "4"), kind + str(n), self, "", "", null, get_node("%" + kind + str(player_index)))
			popup.visible = false

	if RunData.get_player_count() > MP8UIEnd.VANILLA_PLAYERS:
		var columns: = []
		for i in MP8UIEnd.MAX_PLAYERS:
			columns.push_back(get_node("%%PlayerContainer%s" % (i + 1)))
		_mp_slots = MP8UIEnd.wrap_in_slots(columns)
		var _e = _mp_box.connect("resized", self, "_mp_update_scale")

	MP8UIEnd.restore_focus_bases(captured)
	MP8UIEnd.clone_focus_emulators(self, ["PlayerContainer%s", "MP8SlotPlayerContainer%s", "ItemPopup%s", "StatPopup%s"])


func _mp_on_children_ready() -> void:
	_mp_limit_active = true
	RunData.set("mp8_player_count_limit", MP8UIEnd.VANILLA_PLAYERS)


func _ready() -> void:
	if not _mp_limit_active:
		return
	_mp_limit_active = false
	RunData.set("mp8_player_count_limit", 0)

	for number in range(MP8UIEnd.VANILLA_PLAYERS + 1, MP8UIEnd.MAX_PLAYERS + 1):
		player_containers.push_back(get_node("%%PlayerContainer%s" % number))
		item_popups.push_back(get_node("%%ItemPopup%s" % number))
		stat_popups.push_back(get_node("%%StatPopup%s" % number))

	for player_index in range(MP8UIEnd.VANILLA_PLAYERS, RunData.get_player_count()):
		_mp_fill_extra_column(player_index)
	call_deferred("_mp_update_scale")


# Shows one of the added columns with that player's weapons, items and stats and
# hooks its popups up like the first four.
func _mp_fill_extra_column(player_index: int) -> void:
	var column = player_containers[player_index]
	column.visible = true
	var popup_parent: NodePath = column.carousel.get_path()

	var weapon_list = RunData.get_player_weapons(player_index)
	column.weapons_container.set_data("WEAPONS", Category.WEAPON, weapon_list)
	column.weapons_container.visible = weapon_list.size() > 0
	column.items_container.set_data("ITEMS", Category.ITEM, RunData.get_player_items(player_index), true, true)
	for inventory_container in [column.weapons_container, column.items_container]:
		_popup_manager.connect_inventory_container(inventory_container)
	for stats_container in [column.primary_stats_container, column.secondary_stats_container]:
		_popup_manager.connect_stats_container(stats_container)

	var items_popup = item_popups[player_index]
	items_popup.player_index = player_index
	items_popup.parent_node_path = popup_parent
	var _e = items_popup.connect("popup_toggled", self, "_on_popup_toggled")
	_popup_manager.add_item_popup(items_popup, player_index)

	var stats_popup = stat_popups[player_index]
	stats_popup.parent_node_path = popup_parent
	_popup_manager.add_stat_popup(stats_popup, player_index)

	column.focus()


func _mp_update_scale() -> void:
	if _mp_slots.empty() or _mp_box == null:
		return
	var count = RunData.get_player_count()
	var separation: float = _mp_box.get_constant("separation")
	var scale = MP8UIEnd.column_scale(_mp_slots, count, MP8UIEnd.available_width(_mp_box, _margin_container), separation)
	for slot in _mp_slots:
		slot.scale_factor = scale
	for popup in item_popups + stat_popups:
		popup.rect_scale = Vector2(scale, scale)
