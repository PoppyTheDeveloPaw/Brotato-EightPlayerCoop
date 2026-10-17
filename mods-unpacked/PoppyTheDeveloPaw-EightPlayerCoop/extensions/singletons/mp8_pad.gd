extends Reference

# Eight Player Coop - helpers for growing vanilla's fixed 4-slot per-player arrays.

const MAX_PLAYERS: = 8


static func pad(array: Array, kind: String, size: int = MAX_PLAYERS) -> Array:
	while array.size() < size:
		match kind:
			"array":
				array.push_back([])
			"dict":
				array.push_back({})
			"bool":
				array.push_back(false)
			"int":
				array.push_back(0)
			_:
				array.push_back(null)
	return array


static func filled(kind: String, size: int = MAX_PLAYERS) -> Array:
	return pad([], kind, size)


# Grows every script variable of `object` that looks like a per-player array
# (exactly 4 identical "empty" entries: null, false, 0, [], {}) to 8 entries.
# This also covers 4-slot arrays added by other mods to the same scripts.
static func auto_pad(object: Object, exclude: Array = []) -> void:
	for property in object.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if property.name in exclude:
			continue
		var value = object.get(property.name)
		if typeof(value) != TYPE_ARRAY or value.size() != 4:
			continue
		var kind = _empty_kind(value[0])
		if kind == "":
			continue
		var same = true
		for element in value:
			if _empty_kind(element) != kind:
				same = false
				break
		if same:
			pad(value, kind)


static func _empty_kind(value) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool" if value == false else ""
		TYPE_INT:
			return "int" if value == 0 else ""
		TYPE_ARRAY:
			return "array" if value.empty() else ""
		TYPE_DICTIONARY:
			return "dict" if value.empty() else ""
	return ""
