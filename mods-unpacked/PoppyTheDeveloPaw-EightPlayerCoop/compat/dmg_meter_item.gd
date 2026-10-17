extends "res://mods-unpacked/lrueckert-DmgMeter/ui/hud/dmg_meter_item.gd"

# Eight Player Coop - compatibility with lrueckert's DmgMeter (only installed when
# that mod is present). DmgMeter aligns its rows for HUD positions 0-3; players
# 5-8 share the corners of players 1-4, so they use the same alignment.


func set_hud_position(position_index: int) -> void:
	.set_hud_position(position_index % 4 if position_index >= 0 else position_index)
