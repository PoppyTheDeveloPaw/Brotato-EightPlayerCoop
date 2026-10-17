extends Reference

# Eight Player Coop - places stat / item popups in the scaled 8-player layouts.
#
# With up to 4 players nothing is scaled and the game's own placement is used.
# Once columns are drawn smaller, all sizes have to be taken on screen (rect_size
# times the drawn scale), which is what this helper does. Its rules follow how
# the game's popups behave so both look the same:
#  * the popup opens above an element in the lower half of its area, below one
#    in the upper half, with a small gap;
#  * it lines up with the element's left edge, or its right edge when the element
#    is in the right half (or wider than the popup);
#  * it stays inside its area and, if it would still cover the element, steps
#    sideways off it when there is room.

const GAP: = 10.0
const MAX_WIDTH: = 350.0
# Small icon buttons (e.g. shop reroll/lock) only need a short side step.
const ICON_BUTTON_STEP: = 100.0
const ICON_BUTTON_STEP_ROOM: = 90.0
const BUTTON_WITH_ICON_PATH: = "res://ui/menus/shop/button_with_icon.gd"


# Scale an item is drawn at (product of all parent scales).
static func global_scale(item: CanvasItem) -> Vector2:
	if item == null or not item.is_inside_tree():
		return Vector2.ONE
	var s: Vector2 = item.get_global_transform().get_scale()
	return Vector2(abs(s.x), abs(s.y))


static func is_scaled(popup: Control, control: Control) -> bool:
	return not global_scale(popup).is_equal_approx(Vector2.ONE) or not global_scale(control).is_equal_approx(Vector2.ONE)


static func screen_rect(control: Control) -> Rect2:
	return Rect2(control.rect_global_position, control.rect_size * global_scale(control))


# Width (unscaled) the popup gets: at most MAX_WIDTH on screen, never wider than its area.
static func popup_width(popup: Control) -> float:
	var shown_scale: float = max(global_scale(popup).x, 0.01)
	return min(parent_rect(popup).size.x / shown_scale, MAX_WIDTH)


# Screen-space area the popup has to stay in.
static func parent_rect(popup: Control) -> Rect2:
	if not popup.parent_node_path:
		return Rect2(Vector2.ZERO, Vector2(Utils.project_width, Utils.project_height))
	var area_node: Control = popup.get_node(popup.parent_node_path)
	var frame: StyleBox = area_node.get_stylebox("normal")
	var area_scale: Vector2 = global_scale(area_node)
	var inner_position: Vector2 = area_node.rect_global_position + frame.get_offset() * area_scale
	var inner_size: Vector2 = (area_node.rect_size - frame.get_minimum_size()) * area_scale
	return Rect2(inner_position, inner_size)


static func new_position(popup: Control, control: Control, panel: Node) -> Vector2:
	for node in [control, panel]:
		if not is_instance_valid(node) or not node.is_inside_tree():
			return popup.rect_global_position

	var area: Rect2 = parent_rect(popup)
	var target: Rect2 = screen_rect(control)
	var size: Vector2 = popup.rect_size * global_scale(popup)
	var aligned_width: float = screen_rect(panel).size.x if popup.anchor_to_panel else size.x

	var area_middle: Vector2 = area.position + area.size * 0.5
	var open_upwards: bool = target.position.y >= area_middle.y
	var align_right: bool = target.position.x >= area_middle.x or target.size.x > size.x

	var top_left: = Vector2()
	if align_right:
		top_left.x = min(target.position.x, area.end.x) + target.size.x - aligned_width
	else:
		top_left.x = target.position.x
	if open_upwards:
		top_left.y = min(target.position.y, area.end.y) - GAP - size.y
	else:
		top_left.y = target.end.y + GAP

	top_left = _keep_inside(top_left, size, area)

	if Rect2(top_left, size).intersects(target):
		top_left.x += _side_step(top_left.x, size.x, target, area, align_right, _is_button_with_icon(control))
	return top_left


static func _keep_inside(top_left: Vector2, size: Vector2, area: Rect2) -> Vector2:
	return Vector2(
		clamp(top_left.x, area.position.x, area.end.x - size.x),
		clamp(top_left.y, area.position.y, area.end.y - size.y)
	)


# Horizontal move that takes the popup off the element, or 0 without room.
static func _side_step(x: float, width: float, target: Rect2, area: Rect2, align_right: bool, icon_button: bool) -> float:
	var room_left: float = x - area.position.x
	if icon_button:
		return - ICON_BUTTON_STEP if room_left >= ICON_BUTTON_STEP_ROOM else 0.0
	var step: float = target.size.x + GAP
	if align_right:
		return - step if room_left >= step else 0.0
	var room_right: float = area.end.x - (x + width)
	return step if room_right >= step else 0.0


static func _is_button_with_icon(control: Control) -> bool:
	var script: Script = control.get_script()
	while script != null:
		if script.resource_path == BUTTON_WITH_ICON_PATH:
			return true
		script = script.get_base_script()
	return false
