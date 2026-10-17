extends "res://singletons/run_data.gd"

# Eight Player Coop - RunData
# Grows the fixed 4-slot per-player arrays to 8, including after vanilla resets them.

const MP8PadRD = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


# When > 0, get_player_count() reports at most this many players. Only set for
# a moment while vanilla code with room for 4 players runs (selection screens,
# end-of-run screen, material pickup).
var mp8_player_count_limit = 0


func _init() -> void:
	_mp_pad_arrays()


func _mp_pad_arrays() -> void:
	MP8PadRD.pad(remove_speed_effect_cache, "dict")
	MP8PadRD.pad(items_nb_cache, "dict")
	MP8PadRD.pad(different_items_nb_cache, "dict")
	MP8PadRD.pad(duplicate_items_cache, "null")
	MP8PadRD.pad(max_consumable_stats_gained_this_wave, "array")
	MP8PadRD.pad(_are_player_stats_dirty, "bool")
	MP8PadRD.pad(current_charmed_enemies, "int")
	MP8PadRD.pad(steps_taken_this_wave, "int")
	MP8PadRD.pad(locked_shop_items, "array")
	while _players_die_args.size() < MP8PadRD.MAX_PLAYERS:
		_players_die_args.push_back(_players_die_args[0] if not _players_die_args.empty() else null)
	while tracked_item_effects.size() < MP8PadRD.MAX_PLAYERS:
		tracked_item_effects.push_back(init_tracked_effects() if not init_tracked_items.empty() else {})


func _reset_per_wave_properties() -> void:
	._reset_per_wave_properties()
	_mp_pad_arrays()


func reset_players_data_stats_and_effects() -> void:
	.reset_players_data_stats_and_effects()
	_mp_pad_arrays()


func reset_run_caches() -> void:
	.reset_run_caches()
	_mp_pad_arrays()


func resume_from_state(state: Dictionary) -> void:
	.resume_from_state(state)
	_mp_pad_arrays()


func get_player_count() -> int:
	var count: int = .get_player_count()
	if mp8_player_count_limit > 0 and count > mp8_player_count_limit:
		return mp8_player_count_limit
	return count


# Set by the 5+ player material pickup (extensions/main.gd). Once the game starts
# sharing the picked-up value out, it is told there is one player and the gold /
# XP it hands out is collected here instead, to be shared between all players.
var mp8_gold_split = null


func get_player_effect_bool(key: int, player_index: int) -> bool:
	if mp8_gold_split != null and not mp8_gold_split.collecting and key == Keys.reload_when_pickup_gold_hash:
		mp8_gold_split.collecting = true
		mp8_player_count_limit = 1
	return .get_player_effect_bool(key, player_index)


func add_gold(value: int, player_index: int) -> void:
	if mp8_gold_split != null and mp8_gold_split.collecting:
		mp8_gold_split.gold += value
		return
	.add_gold(value, player_index)


func add_xp(value: int, player_index: int) -> void:
	if mp8_gold_split != null and mp8_gold_split.collecting:
		mp8_gold_split.xp += value
		return
	.add_xp(value, player_index)
