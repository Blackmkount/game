class_name WorkshopScreen
extends ScreenBase
## Taller: lugares para muebles, impresoras en el suelo y muebles colocados.


func _init() -> void:
	super("wrench", "SCREEN_WORKSHOP")


func _build_content() -> void:
	var state: GameState = Game.state
	var catalog: DataCatalog = Game.catalog
	var used: int = WorkshopRules.floor_slots_used(state, catalog)
	var total: int = WorkshopRules.floor_slots_total(state, catalog)
	content.add_child(StatBar.new(tr("WORKSHOP_SLOTS"), "%d / %d" % [used, total], used, total))
	var on_floor: int = WorkshopRules.printers_on_floor(state)
	var limit: int = WorkshopRules.floor_printer_limit(catalog)
	content.add_child(StatBar.new(tr("WORKSHOP_FLOOR_PRINTERS"), "%d / %d" % [on_floor, limit], on_floor, limit))
	if on_floor > 0:
		var penalty: int = int(round(WorkshopRules.floor_reliability_penalty(catalog) * 100.0))
		add_notice(content, "WORKSHOP_TIP_FLOOR")
		content.add_child(UiKit.label(UiFormat.tr_format("WORKSHOP_FLOOR_PENALTY", [penalty]), "SmallLabel", true))
	add_section("WORKSHOP_PLACED")
	var furniture: Dictionary = DataLookup.by_id(catalog, "furniture")
	for item: OwnedFurniture in state.furniture:
		content.add_child(ItemCard.new(Previews.furniture(item.furniture_id), tr(furniture[item.furniture_id]["name_key"]), tr(furniture[item.furniture_id]["name_key"] + "_DESC")))
	content.add_child(UiKit.label(UiFormat.tr_format("WORKSHOP_FREE_SLOTS", [total - used]), "MutedLabel", true))
