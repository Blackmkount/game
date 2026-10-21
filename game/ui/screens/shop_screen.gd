class_name ShopScreen
extends ScreenBase
## Tienda: catálogo completo por categoría, con precio, desbloqueo por nivel
## y días de envío. La compra se activa en la tarea 3 de la Fase 1.

const CATEGORIES: Array[Dictionary] = [
	{"id": "printers", "text": "SHOP_TAB_PRINTERS"},
	{"id": "materials", "text": "SHOP_TAB_MATERIALS"},
	{"id": "accessories", "text": "SHOP_TAB_ACCESSORIES"},
	{"id": "furniture", "text": "SHOP_TAB_FURNITURE"},
]

var _category: String = "printers"
var _tabs: Dictionary[String, Button] = {}


func _init() -> void:
	super("cart", "SCREEN_SHOP")


func _build_header(column: VBoxContainer) -> void:
	add_notice(column, "SHOP_COMING_SOON")
	var tabs: HBoxContainer = UiKit.hbox(8)
	column.add_child(tabs)
	var group: ButtonGroup = ButtonGroup.new()
	for category: Dictionary in CATEGORIES:
		var tab: Button = Button.new()
		tab.name = "Tab_" + category["id"]
		tab.text = tr(category["text"])
		tab.theme_type_variation = "TabButton"
		tab.toggle_mode = true
		tab.button_group = group
		tab.button_pressed = category["id"] == _category
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(func() -> void: show_category(category["id"]))
		tabs.add_child(tab)
		_tabs[category["id"]] = tab


func _build_content() -> void:
	show_category(_category)


func show_category(category: String) -> void:
	_category = category
	for tab_id: String in _tabs:
		_tabs[tab_id].set_pressed_no_signal(tab_id == category)
	clear_content()
	match category:
		"printers":
			for item: Dictionary in Game.catalog.files["printers"]:
				_add_card(Previews.printer(item["id"]), item, _printer_text(item))
		"materials":
			for item: Dictionary in Game.catalog.files["materials"]:
				_add_card(Previews.spool(_material_color(item["id"])), item, _material_text(item))
		"accessories":
			for item: Dictionary in Game.catalog.files["accessories"]:
				_add_card(Previews.icon("printer", UiPalette.GOLD), item, tr(item["name_key"] + "_DESC") + "\n" + _shipping(item))
		"furniture":
			for item: Dictionary in Game.catalog.files["furniture"]:
				if item["purchasable"]:
					_add_card(Previews.furniture(item["id"]), item, _furniture_text(item))


func _add_card(preview: Control, item: Dictionary, description: String) -> void:
	var card: ItemCard = ItemCard.new(preview, tr(item["name_key"]), description)
	card.name = "Item_" + item["id"]
	content.add_child(card)
	card.add_price(int(round(float(item["price"]) * 100.0)))
	if int(item["unlock_level"]) > Game.level():
		card.right.add_child(UiKit.lock_tag(int(item["unlock_level"])))
	else:
		var buy: Button = Button.new()
		buy.text = tr("SHOP_BUY")
		buy.theme_type_variation = "PrimaryButton"
		buy.disabled = true
		buy.focus_mode = Control.FOCUS_NONE
		card.right.add_child(buy)


func _printer_text(item: Dictionary) -> String:
	var materials: Array[String] = []
	for material_id: String in item["materials"]:
		materials.append(tr(DataLookup.by_id(Game.catalog, "materials")[material_id]["name_key"]))
	var text: String = UiFormat.tr_format("SHOP_PRINTER_STATS", [UiFormat.decimal(float(item["speed"])), int(item["max_quality"]), item["volume"]])
	text += "\n" + ", ".join(materials)
	if item["multicolor"]:
		text += " · " + tr("SHOP_MULTICOLOR")
	return text + "\n" + _shipping(item)


func _material_text(item: Dictionary) -> String:
	var text: String = UiFormat.tr_format("SHOP_MATERIAL_UNIT", [UiFormat.kilograms(int(item["unit_grams"]))])
	text += " · " + UiFormat.tr_format("SHOP_FAILURES", [UiFormat.decimal(float(item["failure_multiplier"]), 2)])
	if float(item["time_multiplier"]) != 1.0:
		text += " · " + UiFormat.tr_format("SHOP_TIME", [UiFormat.decimal(float(item["time_multiplier"]))])
	return text + "\n" + _shipping(item)


func _furniture_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	if int(item["printer_slots"]) > 0:
		var key: String = "SHOP_FURNITURE_PRINTER" if int(item["printer_slots"]) == 1 else "SHOP_FURNITURE_PRINTERS"
		parts.append(UiFormat.tr_format(key, [int(item["printer_slots"])]))
	if int(item["storage_grams"]) > 0:
		parts.append(UiFormat.tr_format("SHOP_FURNITURE_STORAGE", [UiFormat.kilograms(int(item["storage_grams"]))]))
	if float(item["reliability_bonus"]) > 0.0:
		parts.append(UiFormat.tr_format("SHOP_FURNITURE_RELIABILITY", [int(round(float(item["reliability_bonus"]) * 100.0))]))
	return " · ".join(parts) + "\n" + _shipping(item)


func _shipping(item: Dictionary) -> String:
	return UiFormat.tr_format("SHOP_SHIPPING", [UiFormat.day_range(item["shipping_days"])])


## Color de muestra para el icono de cada material.
func _material_color(material_id: String) -> Color:
	match material_id:
		"petg":
			return Color("3b7fe0")
		"tpu":
			return Color("f28c28")
		"resina":
			return Color("f5cf3c")
	return Color("f2efe6")
