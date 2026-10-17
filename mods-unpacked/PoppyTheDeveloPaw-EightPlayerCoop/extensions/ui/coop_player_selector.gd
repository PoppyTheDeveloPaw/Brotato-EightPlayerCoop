extends "res://ui/menus/ingame/coop_player_selector.gd"

# Eight Player Coop - "Player N" selector in the pause menu: headings for players 5-8.

const MP8UISel = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_ui.gd")

var _mp_built = false


func _enter_tree() -> void:
	if _mp_built:
		return
	_mp_built = true
	var headings: Node = get_node_or_null("%Headings")
	if headings == null:
		return
	var template: Node = headings.get_node_or_null("CoopPlayerLabel4")
	if template == null:
		return
	var owner_node: Node = template.owner if template.owner != null else self
	for player_index in range(MP8UISel.VANILLA_PLAYERS, MP8UISel.MAX_PLAYERS):
		var label = MP8UISel.clone(template, "CoopPlayerLabel%s" % (player_index + 1), owner_node, "", "", headings, headings.get_child(headings.get_child_count() - 1))
		label.player_index = player_index
