extends "res://ui/menus/shop/coop_shop.gd"

# Eight Player Coop - co-op shop.
# Adds player columns, stat popups and focus emulators 5-8. With more than 4
# players the columns are drawn smaller so that all of them fit side by side.

const MP8UIShop = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/ui/mp8_ui.gd")
const MP8PadShop = preload("res://mods-unpacked/PoppyTheDeveloPaw-EightPlayerCoop/extensions/singletons/mp8_pad.gd")

var _mp_built = false
var _mp_slots = []
var _mp_box: Container = null


func _init() -> void:
	MP8PadShop.pad(_shop_items, "array")
	MP8PadShop.pad(_focused_shop_item, "null")
	MP8PadShop.pad(_latest_focused_shop_item, "null")
	MP8PadShop.pad(_player_pressed_go_button, "bool")
	MP8PadShop.pad(_has_bonus_free_reroll, "bool")
	MP8PadShop.pad(_reroll_price, "int")
	MP8PadShop.pad(_initial_free_rerolls, "int")
	MP8PadShop.pad(_free_rerolls, "int")
	MP8PadShop.pad(_item_steals, "int")
	MP8PadShop.pad(_reroll_count, "int")
	MP8PadShop.pad(_paid_reroll_count, "int")
	MP8PadShop.pad(_reroll_discount, "int")


func _enter_tree() -> void:
	if _mp_built:
		return
	_mp_built = true
	MP8PadShop.auto_pad(self)

	var captured = MP8UIShop.capture_focus_bases(self)
	var container4: Node = get_node("%CoopShopPlayerContainer4")
	var popup4: Node = get_node("%StatPopup4")
	_mp_box = container4.get_parent()

	for player_index in range(MP8UIShop.VANILLA_PLAYERS, MP8UIShop.MAX_PLAYERS):
		var n = player_index + 1
		var container = MP8UIShop.clone(container4, "CoopShopPlayerContainer%s" % n, self, "", "", null, get_node("%%CoopShopPlayerContainer%s" % player_index))
		container.player_index = player_index
		# Visible before vanilla's _ready, which gives every player their focus.
		container.visible = player_index < RunData.get_player_count()
		var popup = MP8UIShop.clone(popup4, "StatPopup%s" % n, self, "", "", null, get_node("%%StatPopup%s" % player_index))
		popup.visible = false

	var player_count = RunData.get_player_count()
	if player_count > MP8UIShop.VANILLA_PLAYERS:
		var columns = []
		for i in MP8UIShop.MAX_PLAYERS:
			columns.push_back(get_node("%%CoopShopPlayerContainer%s" % (i + 1)))
		_mp_slots = MP8UIShop.wrap_in_slots(columns)
		var _e = _mp_box.connect("resized", self, "_mp_update_scale")

	MP8UIShop.restore_focus_bases(captured)
	MP8UIShop.clone_focus_emulators(self, ["CoopShopPlayerContainer%s", "MP8SlotCoopShopPlayerContainer%s", "StatPopup%s"])


func _ready() -> void:
	call_deferred("_mp_update_scale")


func _mp_update_scale() -> void:
	if _mp_slots.empty() or _mp_box == null:
		return
	var count = RunData.get_player_count()
	var separation: float = _mp_box.get_constant("separation")
	var scale = MP8UIShop.column_scale(_mp_slots, count, MP8UIShop.available_width(_mp_box), separation)
	for slot in _mp_slots:
		slot.scale_factor = scale
	for i in MP8UIShop.MAX_PLAYERS:
		var popup = _get_stat_popup(i)
		if popup != null:
			popup.rect_scale = Vector2(scale, scale)


func _get_coop_player_container(player_index: int) -> CoopShopPlayerContainer:
	if player_index < MP8UIShop.VANILLA_PLAYERS:
		return ._get_coop_player_container(player_index)
	return get_node("%%CoopShopPlayerContainer%s" % (player_index + 1)) as CoopShopPlayerContainer


func _get_stat_popup(player_index: int) -> StatPopup:
	if player_index < MP8UIShop.VANILLA_PLAYERS:
		return ._get_stat_popup(player_index)
	return get_node("%%StatPopup%s" % (player_index + 1)) as StatPopup
