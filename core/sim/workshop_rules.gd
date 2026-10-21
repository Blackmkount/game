class_name WorkshopRules
extends RefCounted
## Reglas del taller que dependen de los muebles: lugares ocupados,
## capacidad de almacenamiento e impresoras en el suelo.


static func floor_slots_total(state: GameState, catalog: DataCatalog) -> int:
	return int(DataLookup.by_id(catalog, "spaces")[state.space_id]["floor_slots"])


static func floor_slots_used(state: GameState, catalog: DataCatalog) -> int:
	var furniture_defs: Dictionary = DataLookup.by_id(catalog, "furniture")
	var used: int = 0
	for item: OwnedFurniture in state.furniture:
		used += int(furniture_defs[item.furniture_id]["floor_slots"])
	return used


static func storage_capacity_grams(state: GameState, catalog: DataCatalog) -> int:
	var furniture_defs: Dictionary = DataLookup.by_id(catalog, "furniture")
	var capacity: int = int(catalog.files["config"]["storage"]["base_capacity_grams"])
	for item: OwnedFurniture in state.furniture:
		capacity += int(furniture_defs[item.furniture_id]["storage_grams"])
	return capacity


static func printers_on_floor(state: GameState) -> int:
	return state.printers.filter(func(printer: OwnedPrinter) -> bool: return printer.is_on_floor()).size()


static func floor_printer_limit(catalog: DataCatalog) -> int:
	return int(catalog.files["config"]["floor_printing"]["max_printers"])


static func floor_reliability_penalty(catalog: DataCatalog) -> float:
	return float(catalog.files["config"]["floor_printing"]["reliability_penalty"])
