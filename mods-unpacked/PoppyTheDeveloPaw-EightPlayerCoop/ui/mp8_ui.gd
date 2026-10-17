extends Reference

# Eight Player Coop - helpers to grow vanilla's 4-slot scenes to 8 slots.

const ScaleSlot = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_scale_slot.gd")

const MAX_PLAYERS: = 8
const VANILLA_PLAYERS: = 4
const DUPLICATE_FLAGS: = Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS


# Deep-copies `source` (including properties edited on instanced children), names it
# `new_name` and renames every descendant containing `rename_from` to use `rename_to`.
# The copy is added to `parent` (default: next to the source) and ownership is
# restored so `%UniqueName` lookups work on the copy.
static func clone(source: Node, new_name: String, scene_root: Node, rename_from: = "", rename_to: = "", parent: Node = null, add_after: Node = null) -> Node:
	var copy: Node = source.duplicate(DUPLICATE_FLAGS)
	copy.name = new_name
	if rename_from != "":
		_rename_tree(copy, rename_from, rename_to)

	var mapping: = {}
	_map_tree(source, copy, mapping)
	# Owners inside the copy first, so the copy's own %UniqueName lookups work
	# when it becomes ready (which can happen right in add_child below).
	_adopt(source, mapping, scene_root, true)

	if parent == null:
		parent = source.get_parent()
	if add_after == null and parent == source.get_parent():
		add_after = source
	if add_after != null and add_after.get_parent() == parent:
		parent.add_child_below_node(add_after, copy)
	else:
		parent.add_child(copy)

	_adopt(source, mapping, scene_root, false)
	return copy


static func _rename_tree(node: Node, from: String, to: String) -> void:
	for child in node.get_children():
		if from in child.name:
			child.name = child.name.replace(from, to)
		_rename_tree(child, from, to)


static func _map_tree(source: Node, copy: Node, mapping: Dictionary) -> void:
	mapping[source] = copy
	var count: int = min(source.get_child_count(), copy.get_child_count())
	for i in count:
		_map_tree(source.get_child(i), copy.get_child(i), mapping)


static func _adopt(source: Node, mapping: Dictionary, scene_root: Node, internal_only: bool) -> void:
	var copy: Node = mapping[source]
	var owner: Node = source.owner
	if owner != null:
		if mapping.has(owner):
			if internal_only and copy.owner != mapping[owner]:
				copy.owner = mapping[owner]
		elif not internal_only and copy.owner != owner and owner.is_a_parent_of(copy):
			copy.owner = owner
	for child in source.get_children():
		if mapping.has(child):
			_adopt(child, mapping, scene_root, internal_only)


# Moves `node` under `new_parent`, keeping its (and its subtree's) owners.
static func reparent(node: Node, new_parent: Node, index: int = - 1) -> void:
	var owners = {}
	_collect_owners(node, owners)
	node.get_parent().remove_child(node)
	new_parent.add_child(node)
	if index >= 0:
		new_parent.move_child(node, index)
	for n in owners:
		if is_instance_valid(n) and n.owner != owners[n]:
			n.owner = owners[n]


static func _collect_owners(node: Node, owners: Dictionary) -> void:
	if node.owner != null:
		owners[node] = node.owner
	for child in node.get_children():
		_collect_owners(child, owners)


const FOCUS_PATH_ARRAYS: = [
	"contain_horizontal_focus_exception_paths",
	"require_entry_from_control_paths",
	"focus_neighbour_top_paths",
	"focus_neighbour_bottom_paths",
	"focus_neighbour_left_paths",
	"focus_neighbour_right_paths",
]


static func _focus_emulators(scene_root: Node) -> Array:
	var result = []
	for child in scene_root.get_children():
		if child.has_method("get_class") and child.get_class() == "FocusEmulator" and child.name.begins_with("FocusEmulator"):
			result.push_back(child)
	return result


# Resolves every NodePath of every FocusEmulator's base data to the node it points
# to, so the paths can be rebuilt after nodes were moved (see restore_focus_bases).
static func capture_focus_bases(scene_root: Node) -> Array:
	var captured = []
	for emulator in _focus_emulators(scene_root):
		var bases = []
		for base in emulator.focus_base_data:
			var entry = {"base": base, "path": emulator.get_node_or_null(base.path)}
			for field in FOCUS_PATH_ARRAYS:
				var nodes = []
				for path in base.get(field):
					nodes.push_back(emulator.get_node_or_null(path))
				entry[field] = nodes
			bases.push_back(entry)
		captured.push_back([emulator, bases])
	return captured


static func restore_focus_bases(captured: Array) -> void:
	for item in captured:
		var emulator: Node = item[0]
		var new_bases = []
		for entry in item[1]:
			var data = entry.base.duplicate()
			if entry.path != null:
				data.path = emulator.get_path_to(entry.path)
			for field in FOCUS_PATH_ARRAYS:
				var paths = []
				var old_paths: Array = entry.base.get(field)
				for i in old_paths.size():
					var node = entry[field][i]
					paths.push_back(emulator.get_path_to(node) if node != null else old_paths[i])
				data.set(field, paths)
			new_bases.push_back(data)
		_set_focus_bases(emulator, new_bases)


# Clones FocusEmulator<N> (N = 4) for players 5-8. Paths containing a per-player
# name (e.g. "Inventory4" for per_player_names = ["Inventory%s"]) are re-targeted
# to the new player's node.
static func clone_focus_emulators(scene_root: Node, per_player_names: Array = []) -> void:
	var template: Node = scene_root.get_node_or_null("FocusEmulator%s" % VANILLA_PLAYERS)
	if template == null:
		return
	for player_index in range(VANILLA_PLAYERS, MAX_PLAYERS):
		var name = "FocusEmulator%s" % (player_index + 1)
		if scene_root.has_node(name):
			continue
		var emulator = clone(template, name, scene_root, "", "", scene_root, scene_root.get_node("FocusEmulator%s" % player_index))
		emulator.player_index = player_index
		var new_bases = []
		for base in template.focus_base_data:
			var data = base.duplicate()
			data.path = _retarget_path(base.path, per_player_names, player_index)
			for field in FOCUS_PATH_ARRAYS:
				var paths = []
				for path in base.get(field):
					paths.push_back(_retarget_path(path, per_player_names, player_index))
				data.set(field, paths)
			new_bases.push_back(data)
		_set_focus_bases(emulator, new_bases)


# FocusEmulator looks its base nodes up once, when it becomes ready. If that has
# already happened (the screen was being built in _ready), look them up again.
static func _set_focus_bases(emulator: Node, bases: Array) -> void:
	emulator.focus_base_data = bases
	var looked_up = emulator.get("_focus_base_nodes")
	if not looked_up is Array or looked_up.empty():
		return
	var nodes = []
	for data in bases:
		var node = emulator.get_node_or_null(data.path)
		if node != null:
			nodes.push_back(node)
	emulator.set("_focus_base_nodes", nodes)


static func _retarget_path(path: NodePath, per_player_names: Array, player_index: int) -> NodePath:
	var text = String(path)
	for per_player_name in per_player_names:
		var from_name: String = per_player_name % VANILLA_PLAYERS
		var to_name: String = per_player_name % (player_index + 1)
		# Only replace whole node names.
		var parts = text.split("/")
		for i in parts.size():
			if parts[i] == from_name:
				parts[i] = to_name
		text = parts.join("/")
	return NodePath(text)


# Wraps each of `columns` (children of one box) in a scale slot. Returns the slots.
static func wrap_in_slots(columns: Array, scale: float = 1.0) -> Array:
	var slots = []
	for column in columns:
		var box: Node = column.get_parent()
		var slot = make_slot(scale)
		slot.name = "MP8Slot" + column.name
		slot.follow_children_visibility = true
		box.add_child(slot)
		box.move_child(slot, column.get_index())
		reparent(column, slot)
		slot.add_slot_child(column)
		slots.push_back(slot)
	return slots


# Width the columns in `box` may use: the width of the control around `outer`
# (default: the box itself), minus whatever else `outer` needs besides the box.
static func available_width(box: Control, outer: Control = null) -> float:
	if outer == null:
		outer = box
	var viewport_width: float = box.get_viewport_rect().size.x
	var fixed: float = outer.get_combined_minimum_size().x - box.get_combined_minimum_size().x
	var parent: Control = outer.get_parent_control()
	var parent_width: float = parent.rect_size.x if parent != null else viewport_width
	return min(parent_width, viewport_width) - max(fixed, 0.0)


# Scale for `count` columns side by side in `avail`: each column is drawn exactly
# like a column of vanilla's 4-player layout (same layout width), just smaller,
# so 8 players look like the 4-player screen at half size. Columns whose content
# needs more room than that get a bit smaller still.
static func column_scale(slots: Array, count: int, avail: float, separation: float, max_scale: float = 1.0) -> float:
	var widest = 1.0
	for slot in slots:
		for child in slot.get_children():
			if child is Control:
				widest = max(widest, child.get_combined_minimum_size().x)
	var width_per_column = (avail - separation * max(count - 1, 0)) / max(count, 1)
	var vanilla_width = (avail - separation * (VANILLA_PLAYERS - 1)) / VANILLA_PLAYERS
	return clamp(width_per_column / max(vanilla_width, widest), 0.3, max_scale)


static func make_slot(scale: float = 1.0) -> Container:
	var slot = ScaleSlot.new()
	slot.scale_factor = scale
	return slot


static func player_count() -> int:
	return RunData.get_player_count()


static func is_large_coop() -> bool:
	return RunData.is_coop_run and RunData.get_player_count() > VANILLA_PLAYERS
