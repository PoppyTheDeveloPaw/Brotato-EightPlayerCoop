extends Container

# Eight Player Coop - a container that lays out its children (overlapping, like a
# MarginContainer without margins) at a reduced scale, so a vanilla 4-player panel
# can be shown at 8-player size while keeping its own layout intact.
# With scale_factor = 1 it behaves like a plain stacking container.

var scale_factor = 1.0 setget set_scale_factor
# When true the slot hides itself while none of its children are visible,
# so it takes no space in its parent box (same as vanilla's loose panels).
var follow_children_visibility = true


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func set_scale_factor(value: float) -> void:
	scale_factor = max(value, 0.05)
	minimum_size_changed()
	queue_sort()


func add_slot_child(child: Control) -> void:
	if child.get_parent() != self:
		add_child(child)
	if not child.is_connected("visibility_changed", self, "_on_child_visibility_changed"):
		var _e = child.connect("visibility_changed", self, "_on_child_visibility_changed")
	_on_child_visibility_changed()


func _on_child_visibility_changed() -> void:
	if not follow_children_visibility:
		return
	var any_visible = false
	var h_flags = - 1
	var v_flags = - 1
	for child in get_children():
		if child is Control and child.visible and not child.is_set_as_toplevel():
			any_visible = true
			if h_flags < 0:
				h_flags = child.size_flags_horizontal
				v_flags = child.size_flags_vertical
	if h_flags >= 0:
		size_flags_horizontal = h_flags
		size_flags_vertical = v_flags
	if visible != any_visible:
		visible = any_visible
	minimum_size_changed()
	queue_sort()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var s = scale_factor
		for child in get_children():
			if not child is Control or child.is_set_as_toplevel():
				continue
			# The slot is the player's column, so the panel always fills it (some vanilla
			# panels are shrink-centered, which would leave gaps once scaled).
			child.rect_position = Vector2.ZERO
			child.rect_size = rect_size / s
			child.rect_scale = Vector2(s, s)
			# Controls scale around their pivot; some vanilla panels have a stray
			# pivot offset, so move them back to the slot's top-left corner.
			child.rect_position -= child.rect_pivot_offset * (1.0 - s)


# Width this slot would need to show any of its children (visible or not).
func natural_width() -> float:
	var result: = 0.0
	for child in get_children():
		if child is Control and not child.is_set_as_toplevel():
			result = max(result, child.get_combined_minimum_size().x)
	return result * scale_factor


func _get_minimum_size() -> Vector2:
	var result = Vector2.ZERO
	for child in get_children():
		if not child is Control or not child.visible or child.is_set_as_toplevel():
			continue
		var child_min: Vector2 = child.get_combined_minimum_size()
		result.x = max(result.x, child_min.x)
		result.y = max(result.y, child_min.y)
	return result * scale_factor
