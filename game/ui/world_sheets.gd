class_name WorldSheets
extends RefCounted
## Arma el panel inferior de cada objeto del mundo con datos de la partida.
## Solo lee el estado: los números salen de core/ y de data/*.json.
##
## Las impresoras, la mesa del computador y el rincón de despacho tienen su
## propio panel (PrinterSheet, DeskSheet y DispatchSheet); aquí se elige cuál
## y se arman los demás (otros muebles, lugares libres y la puerta).
##
## Los botones avisan con action_pressed un id de acción. Hud convierte en
## pantallas los que abren una sección (ver Hud.ACTION_SCREENS); el resto
## (imprimir, retirar, embalar...) lo corre OrderLoopController.

## Cuántos muebles sugiere un lugar libre.
const SLOT_SUGGESTIONS: int = 3


## Panel de `item`, o null si su objeto ya no está en la partida. `choice` es
## lo elegido en el panel de una impresora; `error_text`, por qué no se pudo lo
## último que se intentó en este panel.
static func build(item: WorldInteractable, choice: PrintChoice, error_text: String = "") -> BottomSheet:
	match item.kind:
		WorldInteractable.Kind.PRINTER:
			return PrinterSheet.build(item.ref, choice, error_text)
		WorldInteractable.Kind.FURNITURE:
			if QuickActions.is_computer_desk(Game.state, item.ref):
				return DeskSheet.build(item.ref, error_text)
			return _furniture(item.ref)
		WorldInteractable.Kind.SLOT:
			return _slot()
		WorldInteractable.Kind.DOOR:
			return _door()
		WorldInteractable.Kind.DISPATCH:
			return DispatchSheet.build(error_text)
	return null


static func _furniture(uid: int) -> BottomSheet:
	var rules: SimRules = Game.rules
	var item: OwnedFurniture = _find_furniture(uid)
	if item == null:
		return null
	var definition: Dictionary = rules.furniture[item.furniture_id]
	var sheet: BottomSheet = BottomSheet.new(Previews.furniture(item.furniture_id), _t(definition["name_key"]), _t(definition["name_key"] + "_DESC"))
	var printer_slots: int = int(definition["printer_slots"])
	if printer_slots > 0:
		var used: int = Game.state.printers.filter(func(printer: OwnedPrinter) -> bool: return printer.furniture_uid == uid).size()
		sheet.add_line("printer", UiFormat.tr_format("SHEET_FURNITURE_PRINTERS", [used, printer_slots]))
	if int(definition["storage_grams"]) > 0:
		sheet.add_line("spool", UiFormat.tr_format("SHOP_FURNITURE_STORAGE", [UiFormat.kilograms(int(definition["storage_grams"]))]))
	if float(definition["reliability_bonus"]) > 0.0:
		sheet.add_line("check", UiFormat.tr_format("SHOP_FURNITURE_RELIABILITY", [roundi(float(definition["reliability_bonus"]) * 100.0)]))
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


static func _find_furniture(uid: int) -> OwnedFurniture:
	for item: OwnedFurniture in Game.state.furniture:
		if item.uid == uid:
			return item
	return null


## tr() no se puede usar en funciones estáticas.
static func _t(key: String) -> String:
	return TranslationServer.translate(key)
