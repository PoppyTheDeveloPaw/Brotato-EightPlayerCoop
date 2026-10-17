extends "res://singletons/debug_service.gd"

# Eight Player Coop - DebugService: per-player debug state for 8 players.

const MP8PadDS = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


func _init() -> void:
	MP8PadDS.pad(debug_items_added, "bool")
	MP8PadDS.pad(debug_weapons_added, "bool")
	MP8PadDS.pad(starting_weapons_removed, "bool")


# Vanilla's default arguments only have 4 entries (out-of-range reads crash the game).
func log_run_info(upgrades: Array = [], consumables: Array = []) -> void:
	var count = RunData.get_player_count()
	var padded_upgrades = upgrades.duplicate()
	var padded_consumables = consumables.duplicate()
	MP8PadDS.pad(padded_upgrades, "array", max(count, 4))
	MP8PadDS.pad(padded_consumables, "array", max(count, 4))
	.log_run_info(padded_upgrades, padded_consumables)
