class_name WorkshopRules
extends RefCounted
## Reglas del taller que dependen de los muebles: lugares ocupados,
## capacidad de almacenamiento e impresoras en el suelo. Es la única fórmula
## de fiabilidad de una impresora.


static func floor_slots_total(state: GameState, rules: SimRules) -> int:
	return int(rules.spaces[state.space_id]["floor_slots"])


static func floor_slots_used(state: GameState, rules: SimRules) -> int:
	var used: int = 0
	for item: OwnedFurniture in state.furniture:
		used += int(rules.furniture[item.furniture_id]["floor_slots"])
	return used


static func storage_capacity_grams(state: GameState, rules: SimRules) -> int:
	var capacity: int = rules.base_storage_grams
	for item: OwnedFurniture in state.furniture:
		capacity += int(rules.furniture[item.furniture_id]["storage_grams"])
	return capacity


## Gramos apartados por las impresiones en curso: ya no están en el carrete,
## pero siguen ocupando lugar, porque lo que no se imprima vuelve a él.
## Cuenta entera la pieza que se está imprimiendo (si falla, vuelve una parte).
static func reserved_grams(state: GameState) -> int:
	var grams: int = 0
	for printer: OwnedPrinter in state.printers:
		var job: PrintJob = printer.job
		if job == null or job.status == PrintJob.Status.DONE:
			continue
		var order: Order = state.find_order(job.order_uid)
		var pieces_done: int = order.pieces_done if order != null else 0
		var pieces: int = job.pieces_total - pieces_done
		if job.status == PrintJob.Status.FAILED:
			# Lo que no se imprimió de la pieza fallida ya volvió al carrete.
			pieces -= 1
		grams += maxi(pieces, 0) * job.grams_per_piece
	return grams


static func printers_on_floor(state: GameState) -> int:
	var count: int = 0
	for printer: OwnedPrinter in state.printers:
		if printer.is_on_floor():
			count += 1
	return count


static func floor_printer_limit(rules: SimRules) -> int:
	return rules.floor_printer_limit


static func floor_reliability_penalty(rules: SimRules) -> float:
	return rules.floor_reliability_penalty


## Mejor bono de fiabilidad de los muebles del espacio. Solo cuenta uno, no se
## suman (GDD, sección 5.9).
static func furniture_reliability_bonus(state: GameState, rules: SimRules) -> float:
	var best: float = 0.0
	for item: OwnedFurniture in state.furniture:
		best = maxf(best, float(rules.furniture[item.furniture_id]["reliability_bonus"]))
	return best


## Fiabilidad de una impresora en el taller: la de fábrica, menos la
## penalización por estar en el suelo, más el bono de los muebles.
static func printer_reliability(state: GameState, rules: SimRules, printer: OwnedPrinter) -> float:
	var reliability: float = float(rules.printers[printer.printer_id]["reliability"])
	if printer.is_on_floor():
		reliability -= rules.floor_reliability_penalty
	reliability += furniture_reliability_bonus(state, rules)
	return clampf(reliability, 0.0, 1.0)
