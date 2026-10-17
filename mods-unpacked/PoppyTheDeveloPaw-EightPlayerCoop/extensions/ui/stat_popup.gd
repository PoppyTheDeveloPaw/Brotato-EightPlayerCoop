extends "res://ui/menus/shop/stat_popup.gd"

# Eight Player Coop - places the popup correctly in scaled 8-player layouts.

const MP8PopupPosSP = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_popup_position.gd")


func set_pos_from(control: Control, panel: Node) -> void:
	.set_pos_from(control, panel)
	if is_instance_valid(control) and is_instance_valid(panel) and MP8PopupPosSP.is_scaled(self, control):
		rect_min_size = Vector2(MP8PopupPosSP.popup_width(self), 0)
		_reposition()


func _get_new_position(control: Control, panel: Node) -> Vector2:
	if is_instance_valid(control) and control.is_inside_tree() and MP8PopupPosSP.is_scaled(self, control):
		return MP8PopupPosSP.new_position(self, control, panel)
	return ._get_new_position(control, panel)


func _get_parent_rect() -> Rect2:
	return MP8PopupPosSP.parent_rect(self)
