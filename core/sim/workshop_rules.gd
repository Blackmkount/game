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


## Mejor bono de fiabilidad de los muebles del espacio. Solo cuenta uno, no se
## suman (GDD, sección 5.9).
static func furniture_reliability_bonus(state: GameState, catalog: DataCatalog) -> float:
	var furniture_defs: Dictionary = DataLookup.by_id(catalog, "furniture")
	var best: float = 0.0
	for item: OwnedFurniture in state.furniture:
		best = maxf(best, float(furniture_defs[item.furniture_id]["reliability_bonus"]))
	return best


## Fiabilidad de una impresora en el taller: la de fábrica, menos la
## penalización por estar en el suelo, más el bono de los muebles.
static func printer_reliability(state: GameState, catalog: DataCatalog, printer: OwnedPrinter) -> float:
	var reliability: float = float(DataLookup.by_id(catalog, "printers")[printer.printer_id]["reliability"])
	if printer.is_on_floor():
		reliability -= floor_reliability_penalty(catalog)
	reliability += furniture_reliability_bonus(state, catalog)
	return clampf(reliability, 0.0, 1.0)
