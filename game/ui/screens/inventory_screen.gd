class_name InventoryScreen
extends ScreenBase
## Inventario: material en carretes, espacio de almacenamiento, la ferretería
## del barrio, impresoras y muebles del jugador.
##
## Se vuelve a armar (sin perder el desplazamiento) cuando cambian el material
## o el dinero, por ejemplo después de comprar en la ferretería.

## Se tocó comprar un carrete en la ferretería. Hud lo reenvía.
signal local_store_requested(material_id: String)


func _init() -> void:
	super("box", "SCREEN_INVENTORY")


func _ready() -> void:
	super()
	Events.spools_changed.connect(queue_rebuild)
	Events.money_changed.connect(queue_rebuild.unbind(1))
	Events.game_loaded.connect(queue_rebuild)


func _build_content() -> void:
	var state: GameState = Game.state
	add_section("INVENTORY_MATERIALS")
	var materials: Dictionary = DataLookup.by_id(Game.catalog, "materials")
	for spool: Spool in state.spools:
		# Los carretes vacíos siguen en la partida (allí vuelve el material
		# apartado si se cancela), pero no se muestran.
		if spool.grams <= 0:
			continue
		var color: Dictionary = DataLookup.config_entry(Game.catalog, "filament_colors", spool.color_id)
		var title: String = "%s · %s" % [tr(materials[spool.material_id]["name_key"]), tr(color["name_key"])]
		content.add_child(ItemCard.new(Previews.spool(Color(color["hex"])), title, UiFormat.grams(spool.grams)))
	var capacity: int = WorkshopRules.storage_capacity_grams(state, Game.rules)
	# Lo apartado para las impresiones en curso sigue ocupando lugar.
	var stored: int = state.total_grams() + WorkshopRules.reserved_grams(state)
	content.add_child(StatBar.new(tr("INVENTORY_STORAGE"), UiFormat.tr_format("FORMAT_KG_OF", [UiFormat.kilograms(stored), UiFormat.kilograms(capacity)]), stored, capacity))

	add_heading(LocalStoreButtons.title(Game.rules)).name = "SectionLocalStore"
	var store: LocalStoreButtons = LocalStoreButtons.new()
	store.buy_requested.connect(local_store_requested.emit)
	content.add_child(store)

	add_section("INVENTORY_PRINTERS")
	var printers: Dictionary = DataLookup.by_id(Game.catalog, "printers")
	for printer: OwnedPrinter in state.printers:
		var place: String = tr("INVENTORY_ON_FLOOR") if printer.is_on_floor() else tr("INVENTORY_ON_FURNITURE")
		content.add_child(ItemCard.new(Previews.printer(printer.printer_id), tr(printers[printer.printer_id]["name_key"]), place))

	add_section("INVENTORY_FURNITURE")
	var furniture: Dictionary = DataLookup.by_id(Game.catalog, "furniture")
	for item: OwnedFurniture in state.furniture:
		content.add_child(ItemCard.new(Previews.furniture(item.furniture_id), tr(furniture[item.furniture_id]["name_key"]), tr(furniture[item.furniture_id]["name_key"] + "_DESC")))
