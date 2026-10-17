extends "res://ui/menus/shop/coop_item_popup.gd"

# Eight Player Coop - grows 4-slot per-player arrays (incl. ones added by other mods)
# and places the popup correctly in scaled 8-player layouts.

const MP8PadCIP = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")
const MP8PopupPosCIP = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_popup_position.gd")


func _enter_tree() -> void:
	MP8PadCIP.auto_pad(self)


func set_pos_from(control: Control, panel: Node) -> void:
	.set_pos_from(control, panel)
	if is_instance_valid(control) and is_instance_valid(panel) and MP8PopupPosCIP.is_scaled(self, control):
		rect_min_size = Vector2(MP8PopupPosCIP.popup_width(self), 0)
		_reposition()


func _get_new_position(control: Control, panel: Node) -> Vector2:
	if is_instance_valid(control) and control.is_inside_tree() and MP8PopupPosCIP.is_scaled(self, control):
		return MP8PopupPosCIP.new_position(self, control, panel)
	return ._get_new_position(control, panel)


func _get_parent_rect() -> Rect2:
	return MP8PopupPosCIP.parent_rect(self)
