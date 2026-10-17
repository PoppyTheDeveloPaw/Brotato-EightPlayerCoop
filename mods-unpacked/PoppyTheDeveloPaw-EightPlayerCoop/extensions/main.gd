extends "res://main.gd"

# Eight Player Coop - main (the wave scene).
# * HUD, world life bars and "things to process" for players 5-8.
#   Players 5-8 get the HUD spots right next to players 1-4 (5 beside 1, 6 beside 2, ...).
#   With more than 4 players each player's pending level-ups / crates are shown
#   under their own HUD block instead of in the middle of the screen.
# * Material pickups shared between up to 8 players.

const MP8UIMain = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_ui.gd")
const MP8PadMain = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")
const MP8_HUD_GAP: = 24

var _mp_built = false
var _mp_hud: Container = null


func _enter_tree() -> void:
	if _mp_built:
		return
	_mp_built = true

	_mp_refresh_upgrades_ui_scripts()

	MP8PadMain.pad(_upgrades_to_process, "array")
	MP8PadMain.pad(_consumables_to_process, "array")
	MP8PadMain.pad(_proj_on_death_stat_caches, "null")
	MP8PadMain.pad(_player_is_under_half_health, "bool")
	MP8PadMain.auto_pad(self)

	# Life bars above the characters.
	var world_bar4: Node = get_node("%PlayerLifeBarContainerP4")
	for n in range(5, MP8UIMain.MAX_PLAYERS + 1):
		var _bar = MP8UIMain.clone(world_bar4, "PlayerLifeBarContainerP%s" % n, self, "P4", "P%s" % n, null, get_node("%%PlayerLifeBarContainerP%s" % (n - 1)))

	# HUD blocks. Players 5-8 are placed by the HUD margin container in the same
	# corners as players 1-4 and then shifted inwards (see _mp_offset_extra_huds),
	# staying direct children of the HUD like vanilla's blocks.
	var life4: Control = get_node("%LifeContainerP4")
	_mp_hud = life4.get_parent()
	for n in range(5, MP8UIMain.MAX_PLAYERS + 1):
		var _life = MP8UIMain.clone(life4, "LifeContainerP%s" % n, self, "P4", "P%s" % n, null, get_node("%%LifeContainerP%s" % (n - 1)))
	var _e = _mp_hud.connect("sort_children", self, "_mp_offset_extra_huds")

	# Pending level-ups / crates.
	var things4: Node = get_node("%UIThingsToProcessPlayerContainer4")
	for n in range(5, MP8UIMain.MAX_PLAYERS + 1):
		var _things = MP8UIMain.clone(things4, "UIThingsToProcessPlayerContainer%s" % n, self, "", "", null, get_node("%%UIThingsToProcessPlayerContainer%s" % (n - 1)))


# Coop Trading extends the level-up / crate screen while the game starts, but
# other mods (e.g. DmgMeter) load this scene before that, so the scene would keep
# the scripts without Trading's "Give to player N" buttons. The scripts of that
# screen are switched to the current (fully extended) ones before it is set up.
func _mp_refresh_upgrades_ui_scripts() -> void:
	var mod_main = load("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/mod_main.gd")
	if not mod_main.is_other_mod_active("RobocrafterLP-Trade"):
		return
	var coop_ui: Node = get_node_or_null("UI/CoopUpgradesUI")
	if coop_ui == null:
		return
	_mp_refresh_script(coop_ui, "res://ui/menus/ingame/upgrades_ui.gd")
	for n in range(1, MP8UIMain.VANILLA_PLAYERS + 1):
		_mp_refresh_script(coop_ui.get_node_or_null("%%UpgradesUIPlayerContainer%s" % n), "res://ui/menus/ingame/coop_upgrades_ui_player_container.gd")


func _mp_refresh_script(node: Node, path: String) -> void:
	if node == null:
		return
	var latest: Script = load(path)
	if latest == null or node.get_script() == latest or not latest.can_instance():
		return
	var values: = {}
	for property in node.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			values[property.name] = node.get(property.name)
	node.set_script(latest)
	for property_name in values:
		node.set(property_name, values[property_name])


func _mp_offset_extra_huds() -> void:
	if _mp_hud == null:
		return
	var widest = 0.0
	for n in range(1, MP8UIMain.VANILLA_PLAYERS + 1):
		var life: Control = get_node_or_null("%%LifeContainerP%s" % n)
		if life != null and life.visible:
			widest = max(widest, life.rect_size.x)
	var offset = widest + MP8_HUD_GAP
	for n in range(5, MP8UIMain.MAX_PLAYERS + 1):
		var life: Control = get_node_or_null("%%LifeContainerP%s" % n)
		if life == null:
			continue
		var corner = (n - 1) % MP8UIMain.VANILLA_PLAYERS
		var left = corner == 0 or corner == 2
		life.rect_position.x += offset if left else - offset


func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	# Players 5-8 take the corner layout of players 1-4 (5 next to 1, 6 next to 2, ...).
	for i in range(MP8UIMain.VANILLA_PLAYERS, _players_ui.size()):
		_players_ui[i].set_hud_position(i % MP8UIMain.VANILLA_PLAYERS)
	if players.size() > MP8UIMain.VANILLA_PLAYERS:
		_mp_move_things_to_process_under_huds()
	_mp_align_better_display_counters()
	if _mp_hud != null:
		_mp_hud.queue_sort()


func _mp_move_things_to_process_under_huds() -> void:
	for i in _players_ui.size():
		var player_ui = _players_ui[i]
		var things = _things_to_process_player_containers[i]
		var hud_container: Container = player_ui.hud_container
		var corner = i % MP8UIMain.VANILLA_PLAYERS
		var left = corner == 0 or corner == 2
		var top = corner <= 1
		MP8UIMain.reparent(things, hud_container)
		hud_container.move_child(things, hud_container.get_child_count() - 1 if top else 0)
		things.size_flags_horizontal = Control.SIZE_FILL
		things.horizontal_alignment = UIThingsToProcessPlayerContainer.Alignment.BEGIN if left else UIThingsToProcessPlayerContainer.Alignment.END
		things.vertical_alignment = UIThingsToProcessPlayerContainer.Alignment.BEGIN if top else UIThingsToProcessPlayerContainer.Alignment.END
		var box: Control = things.get_node_or_null("VBoxContainer")
		if box != null:
			box.grow_vertical = Control.GROW_DIRECTION_END if top else Control.GROW_DIRECTION_BEGIN
			# Inside the HUD block the container is laid out by a VBox, so it needs a
			# real height (vanilla's version clips its content to its own rect).
			if not box.is_connected("minimum_size_changed", self, "_mp_fit_things_to_process"):
				var _e = box.connect("minimum_size_changed", self, "_mp_fit_things_to_process", [things])
			_mp_fit_things_to_process(things)


func _mp_fit_things_to_process(things: Control) -> void:
	var height: = 0.0
	if things.upgrades.get_child_count() > 0 or things.consumables.get_child_count() > 0:
		height = things.get_node("VBoxContainer").get_combined_minimum_size().y
	things.rect_min_size.y = height


# Compatibility with RobocrafterLP's Better Display: its hit-protection counter
# under the gold amount is aligned for HUD corners 0-3 only.
func _mp_align_better_display_counters() -> void:
	var counters = get("_tardigrades")
	if not counters is Array:
		return
	for i in range(MP8UIMain.VANILLA_PLAYERS, counters.size()):
		var counter = counters[i]
		if counter is BoxContainer:
			var corner = i % MP8UIMain.VANILLA_PLAYERS
			var left = corner == 0 or corner == 2
			counter.alignment = BoxContainer.ALIGN_BEGIN if left else BoxContainer.ALIGN_END


func on_gold_picked_up(gold: Node, player_index: int) -> void:
	if player_index < 0 or gold.already_picked_up or RunData.get_player_count() <= MP8UIMain.VANILLA_PLAYERS:
		.on_gold_picked_up(gold, player_index)
		return

	# The game shares picked-up materials out one by one between up to 4 players.
	# With more players the game is run as if a single player shared it all (see
	# get_player_effect_bool / add_gold / add_xp in extensions/singletons/run_data.gd),
	# and that total is then shared between all players here.
	var first_receiver: int = _next_gold_player
	_next_gold_player = 0
	var collected: = {"collecting": false, "gold": 0, "xp": 0}
	RunData.set("mp8_gold_split", collected)
	.on_gold_picked_up(gold, player_index)
	RunData.set("mp8_gold_split", null)
	RunData.set("mp8_player_count_limit", 0)
	_next_gold_player = _mp_share_out(collected.gold, collected.xp, first_receiver)


# Round-robin: every player gets an equal part, the remainder goes one each to
# the players starting at `first_receiver`. Returns who is first next time.
func _mp_share_out(gold_total: int, xp_total: int, first_receiver: int) -> int:
	var count: int = RunData.get_player_count()
	if count <= 0:
		return 0
	first_receiver = posmod(first_receiver, count)
	for offset in count:
		var receiver: int = (first_receiver + offset) % count
		var gold_share: int = gold_total / count + (1 if offset < gold_total % count else 0)
		var xp_share: int = xp_total / count + (1 if offset < xp_total % count else 0)
		RunData.add_gold(gold_share, receiver)
		RunData.add_xp(xp_share, receiver)
	return (first_receiver + gold_total) % count
