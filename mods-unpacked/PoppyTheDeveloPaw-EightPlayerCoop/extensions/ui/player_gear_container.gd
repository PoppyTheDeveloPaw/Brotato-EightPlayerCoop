extends "res://ui/menus/shop/player_gear_container.gd"

# Eight Player Coop - weapon row of a player's gear (shop, end of run).
#
# The game picks how many weapons fit in one row from a table with one entry per
# player count (1-4). With 5-8 players the columns are drawn at the size used
# for 4 players, so the 4-player entry is used for them as well. Without it the
# weapon row of players 5-8 was not laid out (two short rows instead of one).


func _init() -> void:
	var four_players: int = _default_weapon_columns[_default_weapon_columns.size() - 1]
	while _default_weapon_columns.size() < 8:
		_default_weapon_columns.push_back(four_players)
