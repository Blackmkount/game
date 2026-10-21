class_name OrderBoard
extends RefCounted
## Tablero de pedidos: qué mensajes pueden llegar, cuándo llegan y si un
## mensaje se puede aceptar.
##
## Solo llegan pedidos que el jugador puede hacer con sus impresoras y su
## material. Los mensajes no vencen; con el tablero lleno se deja de esperar
## el próximo hasta que se responda uno.


## El pedido se puede hacer con lo que hay en el taller: alguna impresora
## (aunque esté ocupada) le da el tamaño, el multicolor y la calidad con el
## mejor modo, y tiene un carrete de un material que aceptan los dos con
## gramos para todas las piezas. Es la misma regla que revisa el validador
## para los pedidos del primer mensaje.
static func is_makeable(state: GameState, rules: SimRules, order_id: String) -> bool:
	var order: Dictionary = rules.orders[order_id]
	var needed_grams: int = int(order["pieces"]) * rules.order_grams[order_id]
	for printer: OwnedPrinter in state.printers:
		var definition: Dictionary = rules.printers[printer.printer_id]
		if not _printer_fits(rules, definition, order):
			continue
		for spool: Spool in state.spools:
			if spool.grams >= needed_grams and spool.material_id in order["materials"] \
					and spool.material_id in definition["materials"]:
				return true
	return false


## Hay algún pedido del nivel del jugador que se pueda hacer.
static func has_makeable(state: GameState, rules: SimRules) -> bool:
	var level: int = rules.levels.level_for_xp(state.xp)
	for order_id: String in rules.order_list:
		if int(rules.orders[order_id]["min_level"]) <= level and is_makeable(state, rules, order_id):
			return true
	return false


## Pedidos que pueden llegar en el próximo mensaje, en el orden del archivo:
## del nivel del jugador, que se puedan hacer y que no estén ya en el tablero.
## Si todos los posibles ya están en el tablero, se permite repetirlos. Si hay
## más de uno, nunca se repite el pedido del último mensaje.
static func candidates(state: GameState, rules: SimRules) -> Array[String]:
	var level: int = rules.levels.level_for_xp(state.xp)
	var makeable: Array[String] = []
	for order_id: String in rules.order_list:
		if int(rules.orders[order_id]["min_level"]) <= level and is_makeable(state, rules, order_id):
			makeable.append(order_id)
	var result: Array[String] = []
	for order_id: String in makeable:
		if not _is_on_board(state, order_id):
			result.append(order_id)
	if result.is_empty():
		result = makeable
	if result.size() > 1:
		result.erase(state.last_offer_order_id)
	return result


## Revisa si un mensaje se puede aceptar. El primer problema gana.
static func check_accept(state: GameState, rules: SimRules, offer_uid: int) -> CommandResult:
	var offer: OrderOffer = state.find_offer(offer_uid)
	if offer == null:
		return CommandResult.fail("ERR_OFFER_GONE")
	if state.orders.size() >= rules.max_active_orders:
		return CommandResult.fail("ERR_TOO_MANY_ORDERS", [rules.max_active_orders])
	if not is_makeable(state, rules, offer.order_id):
		return CommandResult.fail("ERR_NO_MATERIAL_FOR_ORDER")
	return CommandResult.success()


## Evento del tablero en el segundo `t`: llega un mensaje nuevo y se programa
## el siguiente. Siempre usa exactamente un número del azar del tablero, aunque
## el mensaje sea fijo o no haya nada que ofrecer, para que el azar no dependa
## de lo que pasó antes.
static func on_refill(sim: Simulation, t: int) -> void:
	var state: GameState = sim.state
	var rules: SimRules = sim.rules
	var roll: float = state.orders_rng.randf()
	var order_id: String = ""
	var scripted: bool = false
	if not state.scripted_offers.is_empty():
		order_id = state.scripted_offers.pop_front()
		scripted = true
	else:
		var options: Array[String] = candidates(state, rules)
		if not options.is_empty():
			order_id = options[mini(int(roll * options.size()), options.size() - 1)]
	if order_id != "":
		var offer: OrderOffer = OrderOffer.new(state.take_uid(), order_id, t)
		state.offers.append(offer)
		state.last_offer_order_id = order_id
		sim.changes.offers = true
		sim.changes.arrived_offers.append(offer.uid)
	if state.offers.size() >= rules.board_slots:
		state.next_offer_at = -1
	else:
		state.next_offer_at = t + (rules.starting_gap_seconds if scripted else rules.offer_interval_seconds)


## Con el tablero en pausa (lleno) y un lugar libre, el próximo mensaje se
## espera desde `now`.
static func resume_if_paused(state: GameState, rules: SimRules, now: int) -> void:
	if state.next_offer_at == -1 and state.offers.size() < rules.board_slots:
		state.next_offer_at = now + rules.offer_interval_seconds


## La impresora sirve para el pedido sin mirar el material: tamaño, multicolor
## y calidad con el mejor modo.
static func _printer_fits(rules: SimRules, printer: Dictionary, order: Dictionary) -> bool:
	var volumes: Array[String] = DataValidator.VOLUMES
	if volumes.find(printer["volume"]) < volumes.find(order["size"]):
		return false
	if order["multicolor"] and not printer["multicolor"]:
		return false
	var best_quality: int = mini(int(printer["max_quality"]) + rules.best_quality_delta, DataValidator.MAX_QUALITY)
	return best_quality >= int(order["min_quality"])


static func _is_on_board(state: GameState, order_id: String) -> bool:
	for offer: OrderOffer in state.offers:
		if offer.order_id == order_id:
			return true
	return false
