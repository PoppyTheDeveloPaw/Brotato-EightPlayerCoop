extends "res://ui/menus/run/character_selection.gd"

# Eight Player Coop - character selection.
# Adds slots 5-8 (character panel, locked panel, join panel, focus emulator).
# In co-op the player slots are always shown as two rows of four at half size, so
# all 8 join tiles are visible from the start. Solo looks exactly like vanilla.

const MP8UICS = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_ui.gd")
const MP8_LARGE_SCALE: = 0.5
# Minimum width of vanilla's locked / join panels (character_selection.tscn).
const MP8_VANILLA_SLOT_WIDTH: = 370.0

var _mp_slots = []
var _mp_rows: VBoxContainer = null
var _mp_row2: HBoxContainer = null
var _mp_large_layout = false


func _init() -> void:
	while _player_characters.size() < MP8UICS.MAX_PLAYERS:
		_player_characters.push_back(null)


# Vanilla handles coop players here without the shared start-up step, so the
# 8-player preparation is hooked in again.
func _init_players() -> void:
	_mp_prepare_extra_players()
	._init_players()
	_mp_begin_vanilla_focus_restore()


func _mp_build_extra_slots() -> void:
	var panel4: Node = get_node("%Panel4")
	var locked4: Node = get_node("%LockedPanel4")
	var join4: Node = get_node("%CoopJoinPanel4")
	var box: Container = panel4.get_parent()

	for player_index in range(MP8UICS.VANILLA_PLAYERS, MP8UICS.MAX_PLAYERS):
		var n = player_index + 1
		var panel = MP8UICS.clone(panel4, "Panel%s" % n, self)
		panel.player_index = player_index
		var locked = MP8UICS.clone(locked4, "LockedPanel%s" % n, self)
		var join = MP8UICS.clone(join4, "CoopJoinPanel%s" % n, self)
		join.player_index = player_index
		panel.visible = false
		locked.visible = false
		join.visible = false

	# Rows of slots, placed where the vanilla panels were.
	_mp_rows = VBoxContainer.new()
	_mp_rows.name = "MP8Rows"
	_mp_rows.mouse_filter = MOUSE_FILTER_IGNORE
	_mp_rows.size_flags_vertical = SIZE_EXPAND_FILL
	_mp_rows.add_constant_override("separation", 12)
	box.add_child(_mp_rows)
	box.move_child(_mp_rows, 0)

	var separation: int = box.get_constant("separation")
	var row1 = HBoxContainer.new()
	row1.name = "Row1"
	_mp_row2 = HBoxContainer.new()
	_mp_row2.name = "Row2"
	for row in [row1, _mp_row2]:
		row.mouse_filter = MOUSE_FILTER_IGNORE
		row.size_flags_vertical = SIZE_EXPAND_FILL
		row.add_constant_override("separation", separation)
		_mp_rows.add_child(row)

	for player_index in MP8UICS.MAX_PLAYERS:
		var n = player_index + 1
		var slot = MP8UICS.make_slot(1.0)
		slot.name = "Slot%s" % n
		(row1 if player_index < MP8UICS.VANILLA_PLAYERS else _mp_row2).add_child(slot)
		for node_name in ["Panel%s", "LockedPanel%s", "CoopJoinPanel%s"]:
			var node = get_node("%" + node_name % n)
			MP8UICS.reparent(node, slot)
			slot.add_slot_child(node)
		_mp_slots.push_back(slot)

	MP8UICS.clone_focus_emulators(self, ["Panel%s", "LockedPanel%s", "CoopJoinPanel%s", "Slot%s"])
	_mp_update_layout()


func _mp_update_layout() -> void:
	if _mp_rows == null:
		return
	# Co-op always uses the 8-slot layout, so every join tile is visible.
	var large: bool = RunData.is_coop_run and CoopService.get_max_players() > MP8UICS.VANILLA_PLAYERS
	_mp_large_layout = large
	_mp_row2.visible = large
	for slot in _mp_slots:
		slot.scale_factor = MP8_LARGE_SCALE if large else 1.0
	# Both rows span the same width as vanilla's single row of 4 panels, so the
	# half-size panels are laid out wider and long character names fit.
	var width = 0.0
	if large:
		width = MP8_VANILLA_SLOT_WIDTH
		for slot in _mp_slots:
			width = max(width, slot.natural_width())
	for slot in _mp_slots:
		slot.rect_min_size.x = width


func _on_connection_progress_updated(progress_values: Array) -> void:
	._on_connection_progress_updated(progress_values)
	var was_large = _mp_large_layout
	_mp_update_layout()
	if was_large != _mp_large_layout:
		# The join panels changed size: redraw their progress indicators.
		for join_panel in _get_coop_join_panels():
			if join_panel != null:
				join_panel.update_indicators(CoopService.connected_players, progress_values)
	_mp_update_first_join_prompt(progress_values)


func _update_character_selection_player_count_ui() -> void:
	._update_character_selection_player_count_ui()
	_mp_update_layout()
	_mp_update_first_join_prompt(CoopService.connection_progress)


# With nobody joined yet the game shows its join prompt below the player slots.
# In the 8-slot layout that prompt is far away from the slots, so the first slot
# shows it instead, the same way the next free slot does once someone has joined.
func _mp_update_first_join_prompt(progress_values: Array) -> void:
	var waiting: bool = RunData.is_coop_run and RunData.get_player_count() == 0 and CoopService.connected_players.empty()
	var in_first_slot: bool = waiting and _mp_large_layout
	_coop_join_instructions.visible = waiting and not _mp_large_layout
	var join_panels: Array = _get_coop_join_panels()
	if join_panels.empty() or join_panels[0] == null:
		return
	if in_first_slot:
		join_panels[0].instructions_visible = progress_values.empty()
	elif waiting:
		join_panels[0].instructions_visible = false


# The co-op toggle keeps the real keyboard / controller focus after it has been
# switched on. Players join by pressing the accept button, so once someone has
# joined, a press on another controller would also reach the toggle and switch
# co-op off again (removing everyone who joined). From the first join on the
# toggle lets go of that focus; player 1 still reaches it with their own cursor.
func _input(_event: InputEvent) -> void:
	if not RunData.is_coop_run or RunData.get_player_count() == 0:
		return
	if _coop_button != null and get_focus_owner() == _coop_button:
		_coop_button.release_focus()


func _get_coop_join_panels() -> Array:
	var ret = []
	for i in CoopService.get_max_players():
		ret.push_back(get_node_or_null("%%CoopJoinPanel%s" % (i + 1)))
	return ret


func _get_locked_panels() -> Array:
	var ret = []
	for i in CoopService.get_max_players():
		ret.push_back(get_node_or_null("%%LockedPanel%s" % (i + 1)))
	return ret


func _on_ZoneSelectionButton_item_selected(index: int) -> void:
	._on_ZoneSelectionButton_item_selected(index)
	_mp_update_extra_panel_backgrounds()


func _setup_zone(index: int) -> void:
	._setup_zone(index)
	_mp_update_extra_panel_backgrounds()


func _mp_update_extra_panel_backgrounds() -> void:
	for i in range(MP8UICS.VANILLA_PLAYERS + 1, MP8UICS.MAX_PLAYERS + 1):
		var panel = get_node_or_null("%%Panel%s" % i)
		if panel != null and panel.is_inside_tree() and panel.has_method("_update_bg"):
			panel._update_bg()
