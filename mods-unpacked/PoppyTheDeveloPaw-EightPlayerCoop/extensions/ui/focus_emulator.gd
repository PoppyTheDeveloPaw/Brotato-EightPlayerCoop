extends "res://ui/menus/global/focus_emulator.gd"

# Eight Player Coop - player cursors in scaled-down layouts.
#
# When a player's cursor moves onto an element that is scrolled out of view,
# the list scrolls so the element becomes visible. The engine's built-in
# scrolling mixes on-screen and unscaled sizes, so in the 5-8 player layouts
# (where every player column is drawn smaller) the item lists never scrolled.
# For scaled lists the scroll distance is worked out in the list's own
# coordinates instead. Lists drawn at normal size (1-4 players) use the
# game's own scrolling unchanged.


func _ensure_control_visible(control: Control) -> void:
	var scroll_container: ScrollContainer = _find_parent_scroll_container(control)
	if scroll_container == null:
		return
	if scroll_container.get_global_transform().get_scale().is_equal_approx(Vector2.ONE):
		._ensure_control_visible(control)
		return
	_mp_scroll_into_view(scroll_container, control)


func _mp_scroll_into_view(scroll_container: ScrollContainer, control: Control) -> void:
	# The element's corners in the list's own (unscaled) coordinates. These
	# already include the current scroll offset.
	var to_list: Transform2D = scroll_container.get_global_transform().affine_inverse()
	var to_screen: Transform2D = control.get_global_transform()
	var top_left: Vector2 = to_list.xform(to_screen.xform(Vector2.ZERO))
	var bottom_right: Vector2 = to_list.xform(to_screen.xform(control.rect_size))

	var visible_size: Vector2 = scroll_container.rect_size
	var v_bar: ScrollBar = scroll_container.get_v_scrollbar()
	var h_bar: ScrollBar = scroll_container.get_h_scrollbar()
	if v_bar != null and v_bar.visible:
		visible_size.x -= v_bar.rect_size.x
	if h_bar != null and h_bar.visible:
		visible_size.y -= h_bar.rect_size.y

	var shift: = Vector2.ZERO
	for axis in [0, 1]:
		if top_left[axis] < 0.0:
			shift[axis] = top_left[axis]
		elif bottom_right[axis] > visible_size[axis]:
			shift[axis] = min(bottom_right[axis] - visible_size[axis], top_left[axis])

	if shift.x != 0.0:
		scroll_container.scroll_horizontal += int(round(shift.x))
	if shift.y != 0.0:
		scroll_container.scroll_vertical += int(round(shift.y))
