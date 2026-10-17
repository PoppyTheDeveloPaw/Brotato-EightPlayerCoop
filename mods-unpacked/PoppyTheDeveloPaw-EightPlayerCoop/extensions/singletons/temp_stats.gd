extends "res://singletons/temp_stats.gd"

# Eight Player Coop - TempStats

const MP8PadTS = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


func _init() -> void:
	MP8PadTS.pad(player_stats, "dict")
	MP8PadTS.pad(are_player_stats_dirty, "bool")
