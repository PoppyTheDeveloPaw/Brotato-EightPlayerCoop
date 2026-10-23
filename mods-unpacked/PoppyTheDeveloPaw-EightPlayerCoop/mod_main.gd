extends Node

# Eight Player Coop
# Local co-op for up to 8 players.

const MOD_ID: = "PoppyTheDeveloPaw-EightPlayerCoop"
const LOG_NAME: = "PoppyTheDeveloPaw-EightPlayerCoop:Main"

# All changes are regular ModLoader script extensions.
# ProgressData is extended at runtime instead, see _mp_extend_progress_data().
const PROGRESS_DATA_EXTENSION: = "extensions/singletons/progress_data.gd"

const EXTENSIONS: = [
	"extensions/singletons/coop_service.gd",
	"extensions/singletons/input_service.gd",
	"extensions/singletons/ui_service.gd",
	"extensions/singletons/utils.gd",
	"extensions/singletons/run_data.gd",
	"extensions/singletons/temp_stats.gd",
	"extensions/singletons/linked_stats.gd",
	"extensions/singletons/debug_service.gd",
	"extensions/main.gd",
	"extensions/global/entity_spawner.gd",
	"extensions/global/stats_manager.gd",
	"extensions/ui/focus_emulator.gd",
	"extensions/ui/player_gear_container.gd",
	"extensions/ui/stat_popup.gd",
	"extensions/ui/coop_item_popup.gd",
	"extensions/ui/popup_manager.gd",
	"extensions/ui/base_selection.gd",
	"extensions/ui/character_selection.gd",
	"extensions/ui/weapon_selection.gd",
	"extensions/ui/upgrades_ui.gd",
	"extensions/ui/coop_shop.gd",
	"extensions/ui/coop_player_selector.gd",
	"extensions/ui/coop_end_run.gd",
]

# Compatibility patches for mods that add their own extensions while the game
# starts (after ModLoader's init), so ours must be installed after theirs.
# [mod id, our extension]
const LATE_COMPAT_EXTENSIONS: = [
	["RobocrafterLP-Trade", "compat/trade_coop_upgrades_ui_player_container.gd"],
]

# "Give to player N" labels for players 5-8, in the languages Coop Trading ships.
const TRADE_LABELS: = {
	"en": "Give to player %s",
	"de": "Gebe Spieler %s",
	"ru": "Передать игроку %s",
}

# Fixes for other mods that only know 4 players, installed with our own
# extensions when that mod is active. Coop Trading is an optional dependency, so
# it loads first and these patches sit on top of its extensions.
# [mod id, our extension]
const COMPAT_EXTENSIONS: = [
	["lrueckert-DmgMeter", "compat/dmg_meter_item.gd"],
	["RobocrafterLP-Trade", "compat/trade_coop_item_popup.gd"],
]

var _mod_dir = ""


func _init() -> void:
	_mod_dir = ModLoaderMod.get_unpacked_dir().plus_file(MOD_ID)
	if _is_dev_vanilla_mode():
		return

	for extension in EXTENSIONS:
		ModLoaderMod.install_script_extension(_mod_dir.plus_file(extension))

	# Optional fixes for other mods that only know 4 players.
	for compat in COMPAT_EXTENSIONS:
		if is_other_mod_active(compat[0]):
			ModLoaderMod.install_script_extension(_mod_dir.plus_file(compat[1]))


func _ready() -> void:
	# ProgressData can only be extended once every autoload is up (see below).
	if not _is_dev_vanilla_mode():
		call_deferred("_mp_extend_progress_data")
		call_deferred("_mp_install_late_compat")
	var dev_script_path = _mod_dir.plus_file("dev/mp8_dev.gd")
	if File.new().file_exists("user://mp8_dev.txt") and ResourceLoader.exists(dev_script_path):
		var dev = load(dev_script_path).new()
		dev.name = "MP8Dev"
		add_child(dev)
	ModLoaderLog.info("Ready", LOG_NAME)


func _mp_install_late_compat() -> void:
	for compat in LATE_COMPAT_EXTENSIONS:
		if is_other_mod_active(compat[0]):
			ModLoaderMod.install_script_extension(_mod_dir.plus_file(compat[1]))

	if is_other_mod_active("RobocrafterLP-Trade"):
		for locale in TRADE_LABELS:
			var translation: = Translation.new()
			translation.locale = locale
			for player_number in range(5, 9):
				translation.add_message("TRADE_GIVE_TO_PLAYER_BUTTON_%s" % player_number, TRADE_LABELS[locale] % player_number)
			TranslationServer.add_translation(translation)


# ProgressData's script pulls in most of the game while compiling, which fails
# while autoloads are still being created, so it cannot use a regular ModLoader
# script extension. Once everything is loaded the extension compiles fine; it is
# then put on the live ProgressData node, keeping all of its current values.
func _mp_extend_progress_data() -> void:
	var progress_data: Node = get_node_or_null("/root/ProgressData")
	var extension: Script = load(_mod_dir.plus_file(PROGRESS_DATA_EXTENSION))
	if progress_data == null or extension == null or not extension.can_instance():
		ModLoaderLog.error("Could not extend ProgressData, runs with more than 4 players won't be saved", LOG_NAME)
		return
	if progress_data.has_method("_mp_merge_extra_players"):
		return

	var values: = {}
	for property in progress_data.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			values[property.name] = progress_data.get(property.name)
	var was_processing: bool = progress_data.is_processing()
	progress_data.set_script(extension)
	for property_name in values:
		progress_data.set(property_name, values[property_name])
	progress_data.set_process(was_processing)

	# The save was already loaded by vanilla code: restore players 5-8 now.
	progress_data._mp_merge_extra_players()
	ModLoaderLog.info("Extended ProgressData", LOG_NAME)


static func is_other_mod_active(mod_id: String) -> bool:
	if not ModLoaderStore.mod_data.has(mod_id):
		return false
	var data = ModLoaderStore.mod_data[mod_id]
	return data.is_loadable and data.is_active


# Development only: with the dev harness present, user://mp8_vanilla.txt loads
# the mod without any of its changes (to take vanilla reference screenshots).
func _is_dev_vanilla_mode() -> bool:
	return ResourceLoader.exists(_mod_dir.plus_file("dev/mp8_dev.gd")) and File.new().file_exists("user://mp8_vanilla.txt")

