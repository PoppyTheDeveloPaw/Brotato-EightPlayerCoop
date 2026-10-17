extends "res://ui/menus/shop/coop_item_popup.gd"

# Eight Player Coop - compatibility with RobocrafterLP's Coop Trading (only
# installed when that mod is active, on top of its own extension).
# Trading creates a "Give to player N" button for every player, but only has
# press handlers and focus navigation for players 1-4.
# Trading's members are accessed dynamically: this script is first compiled
# against the vanilla popup, before the extensions are stacked.


func _ready() -> void:
	if not RunData.is_coop_run or RunData.get_player_count() <= 1:
		return
	var trade_buttons = get("_ptrade")
	if not trade_buttons is Array:
		return
	for to_player_index in range(4, min(trade_buttons.size(), RunData.get_player_count())):
		var button = trade_buttons[to_player_index]
		if button != null and not button.is_connected("pressed", self, "_on_TradeButton_pressed_coop"):
			var _e = button.connect("pressed", self, "_on_TradeButton_pressed_coop", [to_player_index])


# For any number of players: the buttons of all other players are listed and
# chained below the cancel button, in player order.
func update_trade_buttons() -> void:
	yield(get_tree().create_timer(.1), "timeout")
	if not is_instance_valid(_cancel_button):
		return

	var trade_buttons = get("_ptrade")
	if not trade_buttons is Array:
		return
	var others: = []
	for other_index in min(trade_buttons.size(), RunData.get_player_count()):
		if other_index != player_index and trade_buttons[other_index] != null:
			others.push_back(trade_buttons[other_index])

	# Shown in player order right below the cancel button (Trading inserts each
	# new button directly after it, which lists them in reverse).
	var box: Node = _cancel_button.get_parent()
	for i in others.size():
		if others[i].get_parent() == box:
			box.move_child(others[i], _cancel_button.get_index() + 1 + i)

	var below_last = _cancel_button.get_focus_neighbour(MARGIN_BOTTOM)
	for i in others.size():
		var button: Control = others[i]
		button.set_focus_neighbour(MARGIN_TOP, _cancel_button.get_path() if i == 0 else others[i - 1].get_path())
		button.set_focus_neighbour(MARGIN_BOTTOM, others[i + 1].get_path() if i < others.size() - 1 else below_last)
		button.visible = _focused

	if others.empty():
		return

	_cancel_button.set_focus_neighbour(MARGIN_BOTTOM, others[0].get_path())
	_cancel_button.visible = _focused

	# With trade buttons shown, Discard (kept when Item Selling is installed) and
	# Combine are only offered for a focused weapon, as Trading does for players 1-4.
	if _focused and _item_data is WeaponData:
		_discard_button.show()
		var combinable: bool = RunData.can_combine(_item_data, player_index)
		_combine_button.visible = combinable
	else:
		_combine_button.hide()
		if not ModLoaderStore.mod_data.has("RobocrafterLP-ItemSelling"):
			_discard_button.hide()
