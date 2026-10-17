extends "res://ui/menus/global/popup_manager.gd"

# Eight Player Coop - popup bookkeeping for 8 players.

const MP8PadPM = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


func _init() -> void:
	MP8PadPM.pad(_item_popups, "null")
	MP8PadPM.pad(_elements_hovered, "null")
	MP8PadPM.pad(_elements_focused, "null")
	MP8PadPM.pad(_elements_pressed, "null")
	MP8PadPM.pad(_stat_popups, "null")

