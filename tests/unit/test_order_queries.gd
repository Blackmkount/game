extends GutTest
## Consultas para la interfaz (OrderQueries): el número del botón Pedidos, el
## próximo paso, el estado de cada impresora y los tiempos que se muestran.
## Son de solo lectura y nunca adelantan una falla.

var _rules: SimRules
var _sim: Simulation
var _state: GameState
var _commands: GameCommands


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	# Las piezas salen bien salvo que se fuerce una falla.
	_rules.grace_pieces = 1000
	_sim = SimFixtures.new_sim(_rules)
	_state = _sim.state
	_commands = GameCommands.new(_sim)
	SimFixtures.quiet_board(_state)


# --- Número del botón Pedidos ----------------------------------------------


func test_pending_actions_follow_an_order_through_its_steps() -> void:
	assert_eq(_pending(), 0, "Partida nueva, sin mensajes")
	var offer: OrderOffer = _add_offer("llavero")
	assert_eq(_pending(), 1, "Un mensaje por responder")
	assert_true(_commands.accept_offer(offer.uid).ok)
	assert_eq(_pending(), 0, "Modelando: no hay nada que hacer")
	SimFixtures.finish_designs(_sim)
	assert_eq(_pending(), 1, "Modelo listo y la impresora libre")
	var cubo: OwnedPrinter = _state.printers[0]
	assert_true(_commands.start_print(offer.uid, cubo.uid, _state.spools[0].uid, "normal").ok)
	assert_eq(_pending(), 0, "Imprimiendo")
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	assert_eq(_pending(), 1, "Piezas por retirar")
	assert_true(_commands.remove_pieces(cubo.uid).ok)
	assert_eq(_pending(), 1, "Por embalar")
	assert_true(_commands.pack_order(offer.uid).ok)
	assert_eq(_pending(), 1, "Por despachar")
	assert_true(_commands.dispatch_order(offer.uid).ok)
	assert_eq(_pending(), 0)


func test_pending_actions_count_failures_and_need_a_free_printer_to_print() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	var printing: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTING)
	SimFixtures.order_at(_sim, "maceta", Order.Stage.READY_TO_PRINT)
	assert_eq(_pending(), 0, "El modelo listo espera: la única impresora está ocupada")
	DebugTools.force_fail(_sim, cubo.uid, FailureRules.SPAGHETTI)
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	assert_eq(_pending(), 1, "Una falla por atender")
	assert_true(_commands.clean_printer(cubo.uid).ok)
	assert_eq(printing.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(_pending(), 2, "Dos modelos listos y la impresora libre")


# --- Próximo paso ----------------------------------------------------------


func test_next_step_goes_from_the_most_urgent_to_waiting() -> void:
	_rules.max_active_orders = 10
	SimFixtures.add_rayos(_state, _rules, 3)
	var packed: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	var to_pack: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.TO_PACK)
	var printed: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTED)
	var failing: Order = SimFixtures.order_at(_sim, "maceta", Order.Stage.PRINTING)
	var failing_printer: int = failing.printer_uid
	DebugTools.force_fail(_sim, failing_printer, FailureRules.SPAGHETTI)
	_sim.advance_game_seconds(_state.find_printer(failing_printer).job.ends_at - _state.game_seconds)
	var ready: Order = SimFixtures.order_at(_sim, "soporte_celular", Order.Stage.READY_TO_PRINT)
	var designing: Order = SimFixtures.accept(_sim, "llavero")
	var offer: OrderOffer = _add_offer("maceta")

	assert_eq(_next(), OrderQueries.NextStep.FAILED)
	assert_true(_commands.cancel_order(failing.uid).ok)
	assert_eq(_next(), OrderQueries.NextStep.REMOVE)
	assert_true(_commands.remove_pieces(printed.printer_uid).ok)
	assert_eq(_next(), OrderQueries.NextStep.PACK)
	assert_true(_commands.pack_order(to_pack.uid).ok)
	assert_true(_commands.pack_order(printed.uid).ok)
	assert_eq(_next(), OrderQueries.NextStep.DISPATCH)
	for order: Order in [packed, to_pack, printed]:
		assert_true(_commands.dispatch_order(order.uid).ok)
	assert_eq(_next(), OrderQueries.NextStep.PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, ready)
	assert_true(_commands.start_print(ready.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	assert_eq(_next(), OrderQueries.NextStep.MESSAGES)
	assert_true(_commands.reject_offer(offer.uid).ok)
	assert_eq(_next(), OrderQueries.NextStep.NONE, "Se modela y se imprime: solo queda esperar")
	assert_true(_commands.cancel_order(designing.uid).ok)
	assert_true(_commands.cancel_order(ready.uid).ok)
	assert_eq(_next(), OrderQueries.NextStep.WAIT, "Esperar el próximo mensaje")
	for spool: Spool in _state.spools:
		spool.grams = 0
	assert_eq(_next(), OrderQueries.NextStep.NO_MAKEABLE, "Sin material nadie pide nada que se pueda hacer")


func test_messages_wait_while_there_are_too_many_orders() -> void:
	for order_id: String in ["llavero", "maceta", "soporte_celular"]:
		SimFixtures.accept(_sim, order_id)
	_add_offer("llavero")
	assert_eq(_next(), OrderQueries.NextStep.NONE, "3 pedidos en curso: el mensaje espera")


func test_a_ready_model_needs_a_printer_that_can_take_it_now() -> void:
	SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTING)
	SimFixtures.order_at(_sim, "maceta", Order.Stage.READY_TO_PRINT)
	assert_eq(_next(), OrderQueries.NextStep.NONE, "La única impresora está ocupada")


# --- Estado de la impresora ------------------------------------------------


func test_printer_status_through_a_print() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	assert_eq(_status(cubo), OrderQueries.PrinterStatus.IDLE)
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	assert_eq(_status(cubo), OrderQueries.PrinterStatus.IDLE_READY)
	var pla: Spool = _state.spools[0]
	var grams: int = pla.grams
	pla.grams = 0
	assert_eq(_status(cubo), OrderQueries.PrinterStatus.IDLE, "Sin material no lo puede imprimir")
	pla.grams = grams
	assert_true(_commands.start_print(order.uid, cubo.uid, pla.uid, "normal").ok)
	assert_eq(_status(cubo), OrderQueries.PrinterStatus.PRINTING)
	assert_eq(OrderQueries.printer_for_order(_state, order), cubo)
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	assert_eq(_status(cubo), OrderQueries.PrinterStatus.DONE)
	assert_eq(OrderQueries.printer_for_order(_state, order), cubo, "Guarda las piezas hasta que se retiren")
	assert_true(_commands.remove_pieces(cubo.uid).ok)
	assert_null(OrderQueries.printer_for_order(_state, order))
	SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTING)
	DebugTools.force_fail(_sim, cubo.uid, FailureRules.WARPING)
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	assert_eq(_status(cubo), OrderQueries.PrinterStatus.FAILED)


# --- Tiempos ---------------------------------------------------------------


func test_time_left_never_reveals_a_coming_failure() -> void:
	SimFixtures.add_spool(_state, "petg", 1000)
	var cubo: OwnedPrinter = _state.printers[0]
	# Perilla: 2 piezas de 3.000 s de PETG en la Cubo Uno.
	var order: Order = SimFixtures.order_at(_sim, "perilla", Order.Stage.PRINTING)
	_sim.advance_game_seconds(500)
	var now: int = _state.game_seconds
	assert_eq(OrderQueries.order_seconds_left(cubo.job, order, now), 5500)
	var progress: float = cubo.job.progress_at(now)
	DebugTools.force_fail(_sim, cubo.uid, FailureRules.SPAGHETTI)
	assert_eq(cubo.job.ends_at, cubo.job.piece_started_at + 1050, "Va a fallar al 35%")
	assert_eq(OrderQueries.order_seconds_left(cubo.job, order, now), 5500, "Sigue mostrando el tiempo normal")
	assert_eq(cubo.job.progress_at(now), progress)


func test_step_index_of_each_stage() -> void:
	var expected: Dictionary[Order.Stage, int] = {
		Order.Stage.WAITING_DESIGN: 2, Order.Stage.DESIGNING: 2,
		Order.Stage.READY_TO_PRINT: 3, Order.Stage.PRINTING: 3,
		Order.Stage.PRINTED: 4, Order.Stage.TO_PACK: 5, Order.Stage.PACKED: 6,
	}
	assert_eq(expected.size(), Order.Stage.size(), "Todas las etapas")
	for stage: Order.Stage in expected:
		var order: Order = Order.new(1, "llavero", 0)
		order.stage = stage
		assert_eq(OrderQueries.step_index(order), expected[stage], Order.Stage.keys()[stage])


func test_design_time_progress_and_queue() -> void:
	var first: Order = SimFixtures.accept(_sim, "llavero")
	var second: Order = SimFixtures.accept(_sim, "soporte_celular")
	var third: Order = SimFixtures.accept(_sim, "maceta")
	_sim.advance_game_seconds(60)
	var now: int = _state.game_seconds
	assert_eq(OrderQueries.design_seconds_left(first, now), 180)
	assert_almost_eq(OrderQueries.design_progress(first, _rules, now), 0.25, 0.0001)
	assert_eq(OrderQueries.queue_wait_seconds(_state, _rules, first, now), 0, "Ya se está modelando")
	assert_eq(OrderQueries.queue_wait_seconds(_state, _rules, second, now), 180)
	assert_eq(OrderQueries.queue_wait_seconds(_state, _rules, third, now), 180 + 720, "Espera también al de adelante")
	assert_eq(OrderQueries.design_seconds_left(second, now), 0)
	assert_eq(OrderQueries.design_progress(second, _rules, now), 0.0, "En la fila no avanza")
	_sim.advance_game_seconds(180)
	now = _state.game_seconds
	assert_eq(first.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(OrderQueries.design_progress(first, _rules, now), 1.0)
	assert_eq(OrderQueries.queue_wait_seconds(_state, _rules, third, now), 720, "Empezó el segundo justo a tiempo")


func test_due_date_moves_with_time_away() -> void:
	SimFixtures.add_spool(_state, "petg", 1000)
	var order: Order = SimFixtures.accept(_sim, "perilla")
	var no_deadline: Order = SimFixtures.accept(_sim, "llavero")
	var due: int = OrderQueries.due_game_seconds(_state, order)
	assert_eq(due, _state.game_seconds + _rules.deadline_seconds["perilla"])
	_sim.advance_game_seconds(1000)
	assert_eq(OrderQueries.due_game_seconds(_state, order), due, "Jugando, el plazo no se mueve")
	_sim.advance_game_seconds(1000, false)
	assert_eq(OrderQueries.due_game_seconds(_state, order), due + 1000, "Fuera del juego, el plazo se corre")
	_sim.advance_game_seconds(order.due_live - _state.live_seconds)
	assert_false(OrderQueries.is_late(_state, order), "Justo en el plazo todavía está a tiempo")
	_sim.advance_game_seconds(1)
	assert_true(OrderQueries.is_late(_state, order))
	assert_eq(OrderQueries.due_game_seconds(_state, no_deadline), -1)
	assert_false(OrderQueries.is_late(_state, no_deadline))


func test_seconds_to_next_offer() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var simulation: Simulation = Simulation.new(state, _rules)
	assert_eq(OrderQueries.seconds_to_next_offer(state), _rules.first_offer_seconds)
	simulation.advance_game_seconds(20)
	assert_eq(OrderQueries.seconds_to_next_offer(state), _rules.first_offer_seconds - 20)
	simulation.advance_game_seconds(40 + _rules.starting_gap_seconds + _rules.offer_interval_seconds)
	assert_eq(state.offers.size(), _rules.board_slots)
	assert_eq(OrderQueries.seconds_to_next_offer(state), -1, "Tablero lleno: en pausa")


func test_focus_is_available_once_while_designing() -> void:
	var designing: Order = SimFixtures.accept(_sim, "llavero")
	var waiting: Order = SimFixtures.accept(_sim, "maceta")
	assert_true(OrderQueries.focus_available(designing, _rules))
	assert_false(OrderQueries.focus_available(waiting, _rules), "En la fila no")
	assert_true(_commands.focus_design(designing.uid).ok)
	assert_false(OrderQueries.focus_available(designing, _rules), "Una sola vez")
	_rules.focus_multiplier = 1.0
	_sim.advance_game_seconds(designing.design_ends_at - _state.game_seconds)
	assert_eq(waiting.stage, Order.Stage.DESIGNING)
	assert_false(OrderQueries.focus_available(waiting, _rules), "Con el multiplicador en 1 está apagado")


func test_level_comes_from_the_xp() -> void:
	assert_eq(OrderQueries.level(_state, _rules), 1)
	_state.xp = 99
	assert_eq(OrderQueries.level(_state, _rules), 1)
	_state.xp = 100
	assert_eq(OrderQueries.level(_state, _rules), 2)


func test_queries_never_change_the_state() -> void:
	var simulation: Simulation = SimFixtures.busy_workshop(_rules)
	var state: GameState = simulation.state
	simulation.advance_game_seconds(20000)
	var before: String = JSON.stringify(SaveCodec.encode(state), "", true)
	var orders_state: int = state.orders_rng.state
	var prints_state: int = state.prints_rng.state
	simulation.changes.clear()
	var now: int = state.game_seconds
	OrderQueries.next_step(state, _rules)
	OrderQueries.pending_actions(state, _rules)
	OrderQueries.seconds_to_next_offer(state)
	OrderQueries.level(state, _rules)
	for printer: OwnedPrinter in state.printers:
		OrderQueries.printer_status(state, _rules, printer)
	for order: Order in state.orders:
		OrderQueries.step_index(order)
		OrderQueries.design_seconds_left(order, now)
		OrderQueries.design_progress(order, _rules, now)
		OrderQueries.queue_wait_seconds(state, _rules, order, now)
		OrderQueries.due_game_seconds(state, order)
		OrderQueries.is_late(state, order)
		OrderQueries.focus_available(order, _rules)
		var printer: OwnedPrinter = OrderQueries.printer_for_order(state, order)
		if printer != null:
			OrderQueries.order_seconds_left(printer.job, order, now)
	assert_eq(JSON.stringify(SaveCodec.encode(state), "", true), before)
	assert_eq(state.orders_rng.state, orders_state)
	assert_eq(state.prints_rng.state, prints_state)
	assert_true(simulation.changes.is_empty())


# --- Ayudantes -------------------------------------------------------------


func _add_offer(order_id: String) -> OrderOffer:
	var offer: OrderOffer = OrderOffer.new(_state.take_uid(), order_id, _state.game_seconds)
	_state.offers.append(offer)
	return offer


func _pending() -> int:
	return OrderQueries.pending_actions(_state, _rules)


func _next() -> OrderQueries.NextStep:
	return OrderQueries.next_step(_state, _rules)


func _status(printer: OwnedPrinter) -> OrderQueries.PrinterStatus:
	return OrderQueries.printer_status(_state, _rules, printer)
