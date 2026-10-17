extends "res://global/entity_spawner.gd"

# Eight Player Coop - entity spawner: per-player queues for 8 players and a
# 4x2 starting formation when more than 4 players spawn.

const MP8PadES = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")


func _init() -> void:
	MP8PadES.pad(lootworms, "null")
	MP8PadES.pad(queues_to_spawn_structures, "array")
	MP8PadES.pad(queues_to_spawn_pets, "array")


func _enter_tree() -> void:
	MP8PadES.auto_pad(self)


func init(
		zone_min_pos: Vector2,
		zone_max_pos: Vector2,
		current_wave_data: WaveData,
		wave_timer: Timer
	) -> void:
	.init(zone_min_pos, zone_max_pos, current_wave_data, wave_timer)

	var count = _players.size()
	if count <= 4:
		return
	for player_index in count:
		var player = _players[player_index]
		if not is_instance_valid(player):
			continue
		player.global_position = Vector2(
			zone_max_pos.x / 2 - 150 + (player_index % 4) * 100,
			zone_max_pos.y / 2 + (player_index / 4) * 100
		)
