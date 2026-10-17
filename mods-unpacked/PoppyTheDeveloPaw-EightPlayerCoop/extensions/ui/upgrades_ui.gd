extends "res://ui/menus/ingame/upgrades_ui.gd"

# Eight Player Coop - level-up / crate screen (co-op variant).
# Adds player columns, stat popups and focus emulators 5-8; with more than 4
# players the columns are drawn smaller so all of them fit.
# The screen's own start-up code only knows 4 stat popups, so while it runs the
# game reports at most 4 players; players 5-8 are hooked up afterwards in
# _mp_hook_up_player().

const MP8UIUp = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_ui.gd")
const MP8PadUp = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")

var _mp_built = false
var _mp_limit_active = false
var _mp_slots = []
var _mp_box: Container = null


func _init() -> void:
	MP8PadUp.pad(_showing_option, "null")
	MP8PadUp.pad(_player_is_choosing, "bool")
	MP8PadUp.pad(_extra_items_to_process, "array")


func _enter_tree() -> void:
	if _mp_built:
		return
	_mp_built = true
	MP8PadUp.auto_pad(self)
	if not is_coop_ui:
		return
	var container4: Node = get_node_or_null("%UpgradesUIPlayerContainer4")
	var popup4: Node = get_node_or_null("%StatPopup4")
	if container4 == null or popup4 == null:
		return

	var captured = MP8UIUp.capture_focus_bases(self)
	_mp_box = container4.get_parent()

	for player_index in range(MP8UIUp.VANILLA_PLAYERS, MP8UIUp.MAX_PLAYERS):
		var n = player_index + 1
		var container = MP8UIUp.clone(container4, "UpgradesUIPlayerContainer%s" % n, self, "", "", null, get_node("%%UpgradesUIPlayerContainer%s" % player_index))
		container.player_index = player_index
		container.visible = false
		var popup = MP8UIUp.clone(popup4, "StatPopup%s" % n, self, "", "", null, get_node("%%StatPopup%s" % player_index))
		popup.visible = false

	var player_count = RunData.get_player_count()
	if RunData.is_coop_run and player_count > MP8UIUp.VANILLA_PLAYERS:
		var columns = []
		for i in MP8UIUp.MAX_PLAYERS:
			columns.push_back(get_node("%%UpgradesUIPlayerContainer%s" % (i + 1)))
		_mp_slots = MP8UIUp.wrap_in_slots(columns)
		var _e = _mp_box.connect("resized", self, "_mp_update_scale")

	MP8UIUp.restore_focus_bases(captured)
	MP8UIUp.clone_focus_emulators(self, ["UpgradesUIPlayerContainer%s", "MP8SlotUpgradesUIPlayerContainer%s", "StatPopup%s"])

	if RunData.is_coop_run and player_count > MP8UIUp.VANILLA_PLAYERS and get_child_count() > 0:
		# Children become ready before this screen; the last one signals that the
		# screen's own start-up code is next.
		var _e2 = get_child(get_child_count() - 1).connect("ready", self, "_mp_on_children_ready", [], CONNECT_ONESHOT)


func _mp_on_children_ready() -> void:
	_mp_limit_active = true
	RunData.set("mp8_player_count_limit", MP8UIUp.VANILLA_PLAYERS)


func _ready() -> void:
	if _mp_limit_active:
		_mp_limit_active = false
		RunData.set("mp8_player_count_limit", 0)
		for player_index in range(MP8UIUp.VANILLA_PLAYERS, RunData.get_player_count()):
			_mp_hook_up_player(player_index)
	if is_coop_ui and RunData.is_coop_run:
		var player_count = RunData.get_player_count()
		for i in range(MP8UIUp.VANILLA_PLAYERS, MP8UIUp.MAX_PLAYERS):
			var container = _get_player_container(i)
			if container != null:
				container.visible = i < player_count
	call_deferred("_mp_update_scale")


# Connects the column of player 5-8 to this screen and to the popups, the same
# way the game does it for the first four columns.
func _mp_hook_up_player(player_index: int) -> void:
	var column: UpgradesUIPlayerContainer = _get_player_container(player_index)
	if column == null:
		return
	var signal_handlers: = {
		"choose_button_pressed": "_on_choose_button_pressed",
		"item_take_button_pressed": "_on_take_button_pressed",
		"item_discard_button_pressed": "_on_discard_button_pressed",
		"item_ban_button_pressed": "_on_ban_button_pressed",
	}
	for signal_name in signal_handlers:
		var _e = column.connect(signal_name, self, signal_handlers[signal_name], [player_index])
	column.focus_emulator = Utils.get_focus_emulator(player_index, self)

	var popup = _mp_get_stat_popup(player_index)
	popup.parent_node_path = column.carousel.get_path()
	_popup_manager.add_stat_popup(popup, player_index)
	_popup_manager.add_item_popup(column.item_popup, player_index)

	for stats_box in [column.primary_stats_container, column.secondary_stats_container]:
		_popup_manager.connect_stats_container(stats_box)
	var gear = column.player_gear_container
	for inventory_box in [gear.weapons_container, gear.items_container]:
		_popup_manager.connect_inventory_container(inventory_box)


func _mp_update_scale() -> void:
	if _mp_slots.empty() or _mp_box == null:
		return
	var count = RunData.get_player_count()
	var separation: float = _mp_box.get_constant("separation")
	var scale = MP8UIUp.column_scale(_mp_slots, count, MP8UIUp.available_width(_mp_box), separation)
	for slot in _mp_slots:
		slot.scale_factor = scale
	for i in MP8UIUp.MAX_PLAYERS:
		var popup = _mp_get_stat_popup(i)
		if popup != null:
			popup.rect_scale = Vector2(scale, scale)


func _mp_get_stat_popup(player_index: int) -> Node:
	return get_node_or_null("%%StatPopup%s" % (player_index + 1))


func _get_player_container(player_index: int) -> UpgradesUIPlayerContainer:
	if player_index < MP8UIUp.VANILLA_PLAYERS:
		return ._get_player_container(player_index)
	return get_node_or_null("%%UpgradesUIPlayerContainer%s" % (player_index + 1)) as UpgradesUIPlayerContainer
