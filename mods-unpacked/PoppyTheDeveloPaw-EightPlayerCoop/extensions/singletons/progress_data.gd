extends "res://singletons/progress_data.gd"

# Eight Player Coop - ProgressData
# The save format stores shop / locked shop items in fixed 4-slot arrays. Before a
# run is written to disk, the slots of players 5-8 are moved into an extra key
# (already serialized), and they are put back after the save is loaded. The vanilla
# fields keep their exact shape, so saves stay readable without the mod.

const MP8_EXTRA_KEY: = "mp8_extra_players"
const MP8_SPLIT_KEYS: = ["locked_shop_items", "shop_items"]
const MP8_VANILLA_SLOTS: = 4


func _set_loader_properties(loader_v3: ProgressDataLoaderV3, run_state: Dictionary) -> void:
	._set_loader_properties(loader_v3, run_state)
	loader_v3.run_state_deserialized = _mp_split_run_state(loader_v3.run_state_deserialized)


func load_with_generic_loader(loader, path: = "") -> void:
	.load_with_generic_loader(loader, path)
	_mp_merge_extra_players()


func _mp_split_run_state(state: Dictionary) -> Dictionary:
	var result: Dictionary = state.duplicate()
	var _erased = result.erase(MP8_EXTRA_KEY)
	if not state.get("has_run_state", false):
		return result

	var extra: = {}
	for key in MP8_SPLIT_KEYS:
		if not state.has(key) or not state[key] is Array:
			continue
		var slots: Array = state[key]
		var vanilla_part: = []
		for i in MP8_VANILLA_SLOTS:
			vanilla_part.push_back(slots[i] if i < slots.size() else [])
		result[key] = vanilla_part

		var extra_part: = []
		var has_items: = false
		for i in range(MP8_VANILLA_SLOTS, slots.size()):
			var serialized: = []
			for entry in slots[i]:
				if entry is Array and entry.size() >= 2 and entry[0] is Resource and entry[0].has_method("serialize"):
					serialized.push_back([entry[0].serialize(), entry[1]])
			has_items = has_items or not serialized.empty()
			extra_part.push_back(serialized)
		if has_items:
			extra[key] = extra_part

	if not extra.empty():
		result[MP8_EXTRA_KEY] = extra
	return result


func _mp_merge_extra_players() -> void:
	if not saved_run_state.has(MP8_EXTRA_KEY):
		return
	var extra = saved_run_state[MP8_EXTRA_KEY]
	var _erased = saved_run_state.erase(MP8_EXTRA_KEY)
	if not extra is Dictionary:
		return

	for key in MP8_SPLIT_KEYS:
		if not extra.has(key) or not extra[key] is Array:
			continue
		var slots: Array = saved_run_state[key] if saved_run_state.has(key) and saved_run_state[key] is Array else []
		while slots.size() < MP8_VANILLA_SLOTS:
			slots.push_back([])
		for player_extra in extra[key]:
			var player_items: = []
			if player_extra is Array:
				for entry in player_extra:
					var element = _mp_deserialize_element(entry)
					if element != null:
						player_items.push_back(element)
			slots.push_back(player_items)
		saved_run_state[key] = slots


func _mp_deserialize_element(entry):
	if not entry is Array or entry.size() < 2 or not entry[0] is Dictionary:
		return null
	var serialized: Dictionary = entry[0]
	var id: String = str(serialized.get("my_id", ""))
	if id.empty():
		return null
	for source in [ItemService.items, ItemService.weapons]:
		var data = ItemService.get_element_safe(source, id)
		if data != null:
			data = data.duplicate()
			data.deserialize_and_merge(serialized)
			return [data, entry[1]]
	return null
