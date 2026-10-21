class_name WorldSheets
extends RefCounted
## Arma el panel inferior de cada objeto del mundo con datos de la partida.
## Solo lee el estado: los números salen de core/ y de data/*.json.
##
## Los botones avisan con action_pressed un id de acción; Hud lo convierte en
## la pantalla que corresponde (ver Hud.ACTION_SCREENS).

## Cuántos muebles sugiere un lugar libre.
const SLOT_SUGGESTIONS: int = 3


static func build(item: WorldInteractable) -> BottomSheet:
	match item.kind:
		WorldInteractable.Kind.PRINTER:
			return _printer(item.ref)
		WorldInteractable.Kind.FURNITURE:
			return _furniture(item.ref)
		WorldInteractable.Kind.SLOT:
			return _slot()
		WorldInteractable.Kind.DOOR:
			return _door()
	return null


static func _printer(uid: int) -> BottomSheet:
	var state: GameState = Game.state
	var catalog: DataCatalog = Game.catalog
	var printer: OwnedPrinter = _find_printer(uid)
	var definition: Dictionary = DataLookup.by_id(catalog, "printers")[printer.printer_id]
	var place: String = _t("SHEET_PRINTER_ON_FLOOR")
	if not printer.is_on_floor():
		var furniture_id: String = _find_furniture(printer.furniture_uid).furniture_id
		place = UiFormat.tr_format("SHEET_PRINTER_ON_FURNITURE", [_t(DataLookup.by_id(catalog, "furniture")[furniture_id]["name_key"])])
	var sheet: BottomSheet = BottomSheet.new(Previews.printer(printer.printer_id), _t(definition["name_key"]), place)
	sheet.add_line("star", _t("SHEET_PRINTER_IDLE"), UiPalette.XP_FILL)
	sheet.add_line("printer", UiFormat.tr_format("SHOP_PRINTER_STATS", [UiFormat.decimal(float(definition["speed"])), int(definition["max_quality"]), definition["volume"]]))
	var reliability: float = WorkshopRules.printer_reliability(state, catalog, printer)
	sheet.add_line("check", UiFormat.tr_format("SHEET_PRINTER_RELIABILITY", [roundi(reliability * 100.0)]))
	var accessories: Array[String] = []
	var accessory_defs: Dictionary = DataLookup.by_id(catalog, "accessories")
	for accessory_id: String in definition["built_in_accessories"] + printer.accessories:
		accessories.append(_t(accessory_defs[accessory_id]["name_key"]))
	if accessories.is_empty():
		sheet.add_line("wrench", _t("SHEET_PRINTER_NO_ACCESSORIES"), UiPalette.TEXT_MUTED)
	else:
		sheet.add_line("wrench", UiFormat.tr_format("SHEET_PRINTER_ACCESSORIES", [", ".join(accessories)]))
	if printer.is_on_floor():
		var penalty: int = roundi(WorkshopRules.floor_reliability_penalty(catalog) * 100.0)
		sheet.add_tip(UiFormat.tr_format("SHEET_PRINTER_FLOOR_TIP", [penalty]))
		sheet.add_action("shop_furniture", _t("SHEET_BUY_TABLE"), true)
	sheet.add_action("orders", _t("SHEET_SEE_ORDERS"), not printer.is_on_floor())
	return sheet


static func _furniture(uid: int) -> BottomSheet:
	var catalog: DataCatalog = Game.catalog
	var item: OwnedFurniture = _find_furniture(uid)
	var definition: Dictionary = DataLookup.by_id(catalog, "furniture")[item.furniture_id]
	var sheet: BottomSheet = BottomSheet.new(Previews.furniture(item.furniture_id), _t(definition["name_key"]), _t(definition["name_key"] + "_DESC"))
	var printer_slots: int = int(definition["printer_slots"])
	if printer_slots > 0:
		var used: int = Game.state.printers.filter(func(printer: OwnedPrinter) -> bool: return printer.furniture_uid == uid).size()
		sheet.add_line("printer", UiFormat.tr_format("SHEET_FURNITURE_PRINTERS", [used, printer_slots]))
	if int(definition["storage_grams"]) > 0:
		sheet.add_line("spool", UiFormat.tr_format("SHOP_FURNITURE_STORAGE", [UiFormat.kilograms(int(definition["storage_grams"]))]))
	if float(definition["reliability_bonus"]) > 0.0:
		sheet.add_line("check", UiFormat.tr_format("SHOP_FURNITURE_RELIABILITY", [roundi(float(definition["reliability_bonus"]) * 100.0)]))
	if item.furniture_id == "mesa_computador":
		sheet.add_line("chat", _t("SHEET_COMPUTER_MESSAGES"))
		sheet.add_action("orders", _t("SHEET_SEE_ORDERS"), true)
	else:
		sheet.add_action("inventory", _t("SHEET_SEE_INVENTORY"), true)
	return sheet


static func _slot() -> BottomSheet:
	var sheet: BottomSheet = BottomSheet.new(Previews.icon("box"), _t("SHEET_SLOT_TITLE"), _t("SHEET_SLOT_TEXT"))
	var shown: int = 0
	for definition: Dictionary in Game.catalog.files["furniture"]:
		if shown >= SLOT_SUGGESTIONS:
			break
		if not definition["purchasable"] or int(definition["unlock_level"]) > Game.level():
			continue
		var price: int = int(round(float(definition["price"]) * 100.0))
		sheet.add_line("cart", "%s · %s" % [_t(definition["name_key"]), UiFormat.money(price)])
		shown += 1
	sheet.add_action("shop_furniture", _t("SHEET_SEE_FURNITURE"), true)
	return sheet


static func _door() -> BottomSheet:
	var sheet: BottomSheet = BottomSheet.new(Previews.icon("map"), _t("SHEET_DOOR_TITLE"), _t("SHEET_DOOR_TEXT"))
	sheet.add_action("map", _t("SHEET_SEE_MAP"), true)
	return sheet


static func _find_printer(uid: int) -> OwnedPrinter:
	for printer: OwnedPrinter in Game.state.printers:
		if printer.uid == uid:
			return printer
	return null


static func _find_furniture(uid: int) -> OwnedFurniture:
	for item: OwnedFurniture in Game.state.furniture:
		if item.uid == uid:
			return item
	return null


## tr() no se puede usar en funciones estáticas.
static func _t(key: String) -> String:
	return TranslationServer.translate(key)
