class_name PrintPlanner
extends RefCounted
## Planes de impresión para la interfaz: los números de una combinación de
## impresora, carrete y modo, y la combinación recomendada para un pedido.
##
## evaluate revisa con PrintRules.check, igual que el comando Imprimir y con
## los mismos datos, así un plan válido siempre se puede imprimir y uno
## inválido muestra el mismo motivo con que fallaría el comando.


## Plan para imprimir el pedido con esa impresora, carrete y modo. Si no se
## puede, `ok` es false y `reason` dice por qué. Los números se llenan aunque
## el plan no sea válido, siempre que existan el pedido, la impresora y el
## carrete y el modo sea conocido.
static func evaluate(state: GameState, rules: SimRules, order: Order, printer: OwnedPrinter, spool: Spool, mode_id: String) -> PrintPlan:
	var result: CommandResult = PrintRules.check(state, rules, order, printer, spool, mode_id)
	if order == null:
		return _plan(state, rules, result, "", 0, printer, spool, mode_id)
	var plan: PrintPlan = _plan(state, rules, result, order.order_id, PrintRules.pieces_left(rules, order), printer, spool, mode_id)
	plan.order_uid = order.uid
	return plan


## Mejor plan para el pedido entre todas las impresoras (o solo la de
## `printer_uid`), los carretes con material y los modos. Gana, en este orden:
## el modo (normal, fino, borrador), menos tiempo, menos riesgo, el material
## que el cliente nombra primero, el carrete con menos gramos (se terminan los
## empezados) y el menor uid de impresora y de carrete. Si ninguno sirve,
## devuelve el primer plan probado, con su motivo.
static func recommend(state: GameState, rules: SimRules, order: Order, printer_uid: int = -1) -> PrintPlan:
	var printers: Array[OwnedPrinter] = state.printers
	if printer_uid >= 0 or printers.is_empty():
		printers = [state.find_printer(printer_uid)]
	var materials: Array = rules.orders[order.order_id]["materials"] if order != null else []
	var plan_for: Callable = func(printer: OwnedPrinter, spool: Spool, mode_id: String) -> PrintPlan:
		return evaluate(state, rules, order, printer, spool, mode_id)
	return _search(rules, materials, printers, _usable_spools(state), plan_for)


## Estimación para la tarjeta de un mensaje todavía sin aceptar: el mejor plan
## para todas las piezas del pedido sin mirar si las impresoras están ocupadas.
static func estimate_for_offer(state: GameState, rules: SimRules, order_id: String) -> PrintPlan:
	if state.printers.is_empty():
		return _plan(state, rules, CommandResult.fail("ERR_PRINTER_GONE"), "", 0, null, null, "")
	var pieces: int = int(rules.orders[order_id]["pieces"])
	var plan_for: Callable = func(printer: OwnedPrinter, spool: Spool, mode_id: String) -> PrintPlan:
		var result: CommandResult = PrintRules.check_setup(rules, order_id, printer.printer_id, spool, mode_id, pieces)
		return _plan(state, rules, result, order_id, pieces, printer, spool, mode_id)
	return _search(rules, rules.orders[order_id]["materials"], state.printers, _usable_spools(state), plan_for)


## Prueba cada impresora × carrete × modo (en ese orden) y se queda con el
## mejor plan válido, o con el primero si ninguno sirve.
static func _search(rules: SimRules, materials: Array, printers: Array[OwnedPrinter], spools: Array[Spool], plan_for: Callable) -> PrintPlan:
	var first: PrintPlan = null
	var best: PrintPlan = null
	var best_rank: Array = []
	for printer: OwnedPrinter in printers:
		for spool: Spool in spools:
			for mode_id: String in rules.mode_list:
				var plan: PrintPlan = plan_for.call(printer, spool, mode_id)
				if first == null:
					first = plan
				if not plan.ok:
					continue
				var rank: Array = _rank(rules, materials, plan)
				if best == null or _is_lower(rank, best_rank):
					best = plan
					best_rank = rank
	return best if best != null else first


## Carretes para probar, en orden de uid: los que tienen material. Si todos
## están vacíos se prueban igual, para que el motivo diga cuánto falta; sin
## carretes se prueba "ninguno".
static func _usable_spools(state: GameState) -> Array[Spool]:
	var usable: Array[Spool] = []
	for spool: Spool in state.spools:
		if spool.grams > 0:
			usable.append(spool)
	if usable.is_empty():
		usable.assign(state.spools)
	if usable.is_empty():
		usable.append(null)
	return usable


## Clave para ordenar los planes válidos: el menor gana.
static func _rank(rules: SimRules, materials: Array, plan: PrintPlan) -> Array:
	return [rules.mode_list.find(plan.mode_id), plan.total_seconds, plan.chance, materials.find(plan.material_id),
			plan.spool_grams, plan.printer_uid, plan.spool_uid]


## `a` va antes que `b` comparando elemento por elemento.
static func _is_lower(a: Array, b: Array) -> bool:
	for i: int in a.size():
		if a[i] != b[i]:
			return a[i] < b[i]
	return false


## Arma el plan con el resultado de la revisión y llena los números si se
## puede calcularlos.
static func _plan(state: GameState, rules: SimRules, result: CommandResult, order_id: String, pieces: int,
		printer: OwnedPrinter, spool: Spool, mode_id: String) -> PrintPlan:
	var plan: PrintPlan = PrintPlan.new()
	plan.ok = result.ok
	plan.reason = null if result.ok else result
	plan.printer_uid = printer.uid if printer != null else -1
	plan.spool_uid = spool.uid if spool != null else -1
	plan.mode_id = mode_id
	if order_id == "" or printer == null or spool == null or not rules.modes.has(mode_id):
		return plan
	var order: Dictionary = rules.orders[order_id]
	plan.material_id = spool.material_id
	plan.color_id = spool.color_id
	plan.quality = PrintRules.quality(rules, printer.printer_id, mode_id)
	plan.min_quality = int(order["min_quality"])
	plan.pieces = pieces
	plan.piece_seconds = PrintRules.piece_seconds(rules, order_id, printer.printer_id, spool.material_id, mode_id)
	plan.total_seconds = plan.piece_seconds * pieces
	var piece_chances: Vector2 = FailureRules.chances(state, rules, printer, spool.material_id, mode_id)
	plan.chance = piece_chances.x + piece_chances.y
	plan.graced = state.pieces_started + pieces <= rules.grace_pieces
	plan.grams_per_piece = rules.order_grams[order_id]
	plan.grams_total = plan.grams_per_piece * pieces
	plan.spool_grams = spool.grams
	plan.cost_cents = PrintRules.cost_cents(rules, spool.material_id, plan.grams_total)
	plan.payment_cents = rules.payment_cents[order_id]
	plan.profit_cents = plan.payment_cents - plan.cost_cents
	plan.xp = int(order["xp"])
	return plan
