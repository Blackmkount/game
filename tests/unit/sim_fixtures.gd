class_name SimFixtures
extends RefCounted
## Partidas armadas para las pruebas de la simulación. No es un archivo de
## pruebas.
##
## Se arman solo con GameState, los flujos y GameCommands, como se armarían
## jugando, así el estado siempre es coherente. Si un comando falla o un evento
## no llega a su hora, avisan con push_error y la prueba que los usa falla
## enseguida, sin quedar esperando para siempre.

## Semilla de las partidas armadas.
const SEED: int = 1234
## Los mensajes del tablero quedan lejos: un mes de juego.
const QUIET_BOARD_SECONDS: int = 30 * GameClock.SECONDS_PER_DAY


## Taller ocupado para comparar un avance grande con muchos pequeños, con todo
## lo que puede pasar a la vez:
## - la Cubo Uno en el suelo y dos Rayo X1 en una mesa de trabajo;
## - 3.000 g de PLA y 3.000 g de PETG;
## - un casco (6 piezas) en la Cubo Uno, y un engranaje (4) y una perilla (2) en
##   las Rayo X1, imprimiéndose;
## - dos pedidos en la fila del computador y el tablero andando.
## Cambia las reglas: sin piezas de gracia (para que haya fallas) y con lugar
## para 5 pedidos en curso.
static func busy_workshop(rules: SimRules) -> Simulation:
	rules.grace_pieces = 0
	rules.max_active_orders = maxi(rules.max_active_orders, 5)
	var sim: Simulation = new_sim(rules)
	var state: GameState = sim.state
	var cubo: OwnedPrinter = state.printers[0]
	var rayos: Array[OwnedPrinter] = add_rayos(state, rules, 2)
	var pla: Spool = state.spools[0]
	pla.grams = 3000
	var petg: Spool = add_spool(state, "petg", 3000)
	var helmet: Order = accept(sim, "casco_cosplay")
	var gear: Order = accept(sim, "engranaje")
	var knob: Order = accept(sim, "perilla")
	finish_designs(sim)
	start_print(sim, helmet, cubo, pla)
	start_print(sim, gear, rayos[0], petg)
	start_print(sim, knob, rayos[1], petg)
	accept(sim, "soporte_celular")
	accept(sim, "maceta")
	return sim


## `count` Rayo X1 en mesas de trabajo, cada una imprimiendo un pedido
## `order_id` (todas sus piezas), y el tablero andando. Cada impresora toma su
## pedido apenas el computador termina de modelarlo, así los trabajos quedan
## escalonados. Cambia las reglas: con lugar para `count` pedidos en curso.
static func farm(rules: SimRules, count: int, order_id: String = "casco_cosplay") -> Simulation:
	rules.max_active_orders = maxi(rules.max_active_orders, count)
	var sim: Simulation = new_sim(rules)
	var state: GameState = sim.state
	var printers: Array[OwnedPrinter] = add_rayos(state, rules, count)
	var order: Dictionary = rules.orders[order_id]
	var grams: int = count * int(order["pieces"]) * rules.order_grams[order_id]
	var spool: Spool = add_spool(state, order["materials"][0], grams)
	for i: int in count:
		accept(sim, order_id)
	for printer: OwnedPrinter in printers:
		var designed: Order = state.find_order(state.designing_uid)
		if not _finish_design(sim):
			break
		start_print(sim, designed, printer, spool)
	return sim


## Partida nueva con la semilla de las pruebas.
static func new_sim(rules: SimRules) -> Simulation:
	return Simulation.new(GameState.new_game(rules, SEED), rules)


## Deja el próximo mensaje del tablero muy lejos, para que no llegue ninguno
## durante la prueba.
static func quiet_board(state: GameState) -> void:
	state.scripted_offers.clear()
	state.next_offer_at = state.game_seconds + QUIET_BOARD_SECONDS


## Agrega `count` Rayo X1, cada una en el primer lugar libre de una mesa; si no
## hay, agrega una mesa de trabajo.
static func add_rayos(state: GameState, rules: SimRules, count: int) -> Array[OwnedPrinter]:
	var added: Array[OwnedPrinter] = []
	for i: int in count:
		var place: int = state.free_printer_place(rules)
		if place == OwnedPrinter.ON_FLOOR:
			var table: OwnedFurniture = OwnedFurniture.new(state.take_uid(), "mesa_trabajo", state.furniture.size())
			state.furniture.append(table)
			place = table.uid
		var printer: OwnedPrinter = OwnedPrinter.new(state.take_uid(), "rayo_x1", place)
		state.printers.append(printer)
		added.append(printer)
	return added


static func add_spool(state: GameState, material_id: String, grams: int) -> Spool:
	var spool: Spool = Spool.new(state.take_uid(), material_id, "negro", grams)
	state.spools.append(spool)
	return spool


## Llega un mensaje con ese pedido y se acepta. Si el computador está libre,
## empieza a modelarlo.
static func accept(sim: Simulation, order_id: String) -> Order:
	var state: GameState = sim.state
	var offer: OrderOffer = OrderOffer.new(state.take_uid(), order_id, state.game_seconds)
	state.offers.append(offer)
	_expect_ok(GameCommands.new(sim).accept_offer(offer.uid), "aceptar " + order_id)
	return state.find_order(offer.uid)


## Avanza hasta que el computador termina de modelar toda la fila.
static func finish_designs(sim: Simulation) -> void:
	while sim.state.designing_uid >= 0 and _finish_design(sim):
		pass


static func start_print(sim: Simulation, order: Order, printer: OwnedPrinter, spool: Spool, mode_id: String = "normal") -> void:
	var result: CommandResult = GameCommands.new(sim).start_print(order.uid, printer.uid, spool.uid, mode_id)
	_expect_ok(result, "imprimir " + order.order_id)


## Lleva un pedido nuevo por el ciclo con comandos hasta la etapa `stage`: lo
## acepta, espera el modelo, lo imprime con el plan recomendado, espera las
## piezas, las retira y las embala. Las piezas no deben fallar (usar con
## suficientes piezas de gracia).
static func order_at(sim: Simulation, order_id: String, stage: Order.Stage) -> Order:
	var state: GameState = sim.state
	var commands: GameCommands = GameCommands.new(sim)
	var order: Order = accept(sim, order_id)
	var ok: bool = order != null
	while ok and order.stage < stage:
		match order.stage:
			Order.Stage.WAITING_DESIGN, Order.Stage.DESIGNING:
				ok = _finish_design(sim)
			Order.Stage.READY_TO_PRINT:
				var plan: PrintPlan = PrintPlanner.recommend(state, sim.rules, order)
				var printed: CommandResult = commands.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id)
				ok = _expect_ok(printed, "imprimir " + order_id)
			Order.Stage.PRINTING:
				ok = _finish_piece(sim, state.find_printer(order.printer_uid).job, order_id)
			Order.Stage.PRINTED:
				ok = _expect_ok(commands.remove_pieces(order.printer_uid), "retirar " + order_id)
			Order.Stage.TO_PACK:
				ok = _expect_ok(commands.pack_order(order.uid), "embalar " + order_id)
	return order


## Avanza justo hasta el fin del modelado en curso. Si el modelo no quedó
## listo, la simulación no procesó el evento: avisa y devuelve false, para que
## las vueltas que esperan eventos nunca queden girando sin fin.
static func _finish_design(sim: Simulation) -> bool:
	var designing: Order = sim.state.find_order(sim.state.designing_uid)
	sim.advance_game_seconds(designing.design_ends_at - sim.state.game_seconds)
	if designing.stage == Order.Stage.DESIGNING:
		push_error("SimFixtures: el modelo de %s no terminó a tiempo" % designing.order_id)
		return false
	return true


## Avanza justo hasta el fin de la pieza en curso. Avisa y devuelve false si
## la pieza falló o si la simulación no procesó su fin.
static func _finish_piece(sim: Simulation, job: PrintJob, order_id: String) -> bool:
	if job.status != PrintJob.Status.PRINTING:
		push_error("SimFixtures: falló una pieza de " + order_id)
		return false
	var ends_at: int = job.ends_at
	sim.advance_game_seconds(ends_at - sim.state.game_seconds)
	if job.status == PrintJob.Status.PRINTING and job.ends_at == ends_at:
		push_error("SimFixtures: la pieza de %s no terminó a tiempo" % order_id)
		return false
	return true


static func _expect_ok(result: CommandResult, what: String) -> bool:
	if not result.ok:
		push_error("SimFixtures: no se pudo %s: %s" % [what, result.reason])
	return result.ok
