extends "res://ui/menus/ingame/coop_upgrades_ui_player_container.gd"

# Eight Player Coop - compatibility with RobocrafterLP's Coop Trading.
# On the "item found" screen Trading adds one "Give to player N" button per other
# player. It only has press handlers for players 1-4 and labels every button with the
# giving player's number. Once the column is set up its buttons are relabelled
# and pointed at the right players here.


func _ready() -> void:
	call_deferred("_mp_rebuild_trade_buttons")


func _mp_rebuild_trade_buttons() -> void:
	if not is_instance_valid(_take_button) or not RunData.is_coop_run:
		return
	if player_index < 0 or player_index >= RunData.get_player_count():
		return

	var take_box: Node = _take_button.get_parent()
	var holder: Node = take_box.get_parent()
	if holder == null or take_box.get_index() + 1 >= holder.get_child_count():
		return
	var trade_box: Node = holder.get_child(take_box.get_index() + 1)
	if not trade_box is Container or trade_box == take_box:
		return

	var others: = []
	for other_index in RunData.get_player_count():
		if other_index != player_index:
			others.push_back(other_index)

	# Trading's own buttons already have the right look; reuse them, adding copies
	# or dropping extras so there is exactly one per other player.
	var buttons: = []
	for child in trade_box.get_children():
		if child is BaseButton:
			buttons.push_back(child)
	if buttons.empty():
		return
	while buttons.size() < others.size():
		var extra: BaseButton = buttons[0].duplicate()
		trade_box.add_child(extra)
		buttons.push_back(extra)
	while buttons.size() > others.size():
		var surplus: BaseButton = buttons.pop_back()
		trade_box.remove_child(surplus)
		surplus.queue_free()

	for i in others.size():
		var button: BaseButton = buttons[i]
		var receiver: int = others[i]
		button.name = "TradeToPlayer%s" % (receiver + 1)
		button.text = "TRADE_GIVE_TO_PLAYER_BUTTON_%s" % (receiver + 1)
		for connection in button.get_signal_connection_list("pressed"):
			if connection.target == self:
				button.disconnect("pressed", self, connection.method)
		var _e = button.connect("pressed", self, "_on_item_trade_button_pressed", [receiver])
