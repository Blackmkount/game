class_name InventoryScreen
extends ScreenBase
## Inventario: material en carretes, espacio de almacenamiento, impresoras y
## muebles del jugador.


func _init() -> void:
	super("box", "SCREEN_INVENTORY")


func _build_content() -> void:
	var state: GameState = Game.state
	add_section("INVENTORY_MATERIALS")
	var materials: Dictionary = DataLookup.by_id(Game.catalog, "materials")
	for spool: Spool in state.spools:
		var color: Dictionary = DataLookup.config_entry(Game.catalog, "filament_colors", spool.color_id)
		var title: String = "%s · %s" % [tr(materials[spool.material_id]["name_key"]), tr(color["name_key"])]
		content.add_child(ItemCard.new(Previews.spool(Color(color["hex"])), title, UiFormat.grams(spool.grams)))
	var capacity: int = WorkshopRules.storage_capacity_grams(state, Game.catalog)
	content.add_child(StatBar.new(tr("INVENTORY_STORAGE"), UiFormat.tr_format("FORMAT_KG_OF", [UiFormat.kilograms(state.total_grams()), UiFormat.kilograms(capacity)]), state.total_grams(), capacity))

	add_section("INVENTORY_PRINTERS")
	var printers: Dictionary = DataLookup.by_id(Game.catalog, "printers")
	for printer: OwnedPrinter in state.printers:
		var place: String = tr("INVENTORY_ON_FLOOR") if printer.is_on_floor() else tr("INVENTORY_ON_FURNITURE")
		content.add_child(ItemCard.new(Previews.printer(printer.printer_id), tr(printers[printer.printer_id]["name_key"]), place))

	add_section("INVENTORY_FURNITURE")
	var furniture: Dictionary = DataLookup.by_id(Game.catalog, "furniture")
	for item: OwnedFurniture in state.furniture:
		content.add_child(ItemCard.new(Previews.furniture(item.furniture_id), tr(furniture[item.furniture_id]["name_key"]), tr(furniture[item.furniture_id]["name_key"] + "_DESC")))
