extends "res://singletons/linked_stats.gd"

# Eight Player Coop - LinkedStats

const MP8PadLS = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


func _init() -> void:
	MP8PadLS.pad(player_stats, "dict")
	MP8PadLS.pad(are_player_stats_dirty, "bool")
	MP8PadLS.pad(update_for_player_every_half_sec, "bool")
