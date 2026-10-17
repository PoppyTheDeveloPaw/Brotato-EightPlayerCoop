extends "res://global/stats_manager.gd"

# Eight Player Coop - per-player stat queues for 8 players.

const MP8PadSM = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


func _init() -> void:
	MP8PadSM.pad(_structure_queues, "dict")
	MP8PadSM.pad(_pet_queues, "dict")
