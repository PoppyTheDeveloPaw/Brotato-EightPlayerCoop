extends "res://singletons/utils.gd"

# Eight Player Coop - Utils
# Keeps the per-player caches at 8 entries, also after the game resets them.

const MP8PadU = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


func _init() -> void:
	MP8PadU.pad(last_elt_selected, "null")
	MP8PadU.pad(_stat_caches, "dict")
	MP8PadU.pad(_manual_aim_cache, "null")


# The game swaps in a fresh 4-entry aim cache at the end of every frame
# (deferred); grow that one as soon as it is in place.
func _process(_delta: float) -> void:
	call_deferred("_mp_pad_manual_aim_cache")


func _mp_pad_manual_aim_cache() -> void:
	MP8PadU.pad(_manual_aim_cache, "null")


func reset_stat_caches() -> void:
	.reset_stat_caches()
	MP8PadU.pad(_stat_caches, "dict")


func reset_last_elt_selected() -> void:
	.reset_last_elt_selected()
	MP8PadU.pad(last_elt_selected, "null")
