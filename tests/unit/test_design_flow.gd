extends GutTest
## Modelado en el computador: empieza solo al aceptar, va en fila de a un
## pedido, corre mientras se imprime y "Concentrarse" acorta lo que falta.

var _rules: SimRules
var _state: GameState
var _sim: Simulation
var _commands: GameCommands


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_state = GameState.new_game(_rules, 1234)
	_sim = Simulation.new(_state, _rules)
	_commands = GameCommands.new(_sim)
	# Sin mensajes del tablero: los pedidos de cada prueba se arman a mano.
	_state.scripted_offers.clear()
	_state.next_offer_at = _state.game_seconds + GameClock.SECONDS_PER_DAY


func test_accepting_starts_the_design() -> void:
	var start: int = _state.game_seconds
	var order: Order = _accept("llavero")
	assert_eq(order.stage, Order.Stage.DESIGNING)
	assert_eq(order.design_ends_at, start + 240, "4 minutos de juego")
	assert_eq(_state.designing_uid, order.uid)
	assert_true(_sim.changes.computer)
	_sim.advance_game_seconds(239)
	assert_eq(order.stage, Order.Stage.DESIGNING)
	_sim.advance_game_seconds(1)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(order.design_ends_at, -1)
	assert_eq(_state.designing_uid, -1, "El computador queda libre")


func test_designs_wait_in_line_and_start_at_the_previous_end() -> void:
	var start: int = _state.game_seconds
	var first: Order = _accept("llavero")
	var second: Order = _accept("soporte_celular")
	assert_eq(second.stage, Order.Stage.WAITING_DESIGN, "Se modela un pedido a la vez")
	assert_eq(second.design_ends_at, -1)
	_sim.advance_game_seconds(240)
	assert_eq(first.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(second.stage, Order.Stage.DESIGNING)
	assert_eq(second.design_ends_at, start + 240 + 720, "Empieza en el segundo exacto en que termina el anterior")
	assert_eq(_state.designing_uid, second.uid)
	_sim.advance_game_seconds(720)
	assert_eq(second.stage, Order.Stage.READY_TO_PRINT)


func test_the_line_follows_uid_order() -> void:
	var older: OrderOffer = _add_offer("llavero")
	var middle: OrderOffer = _add_offer("soporte_celular")
	var newest: OrderOffer = _add_offer("maceta")
	_commands.accept_offer(newest.uid)
	_commands.accept_offer(middle.uid)
	_commands.accept_offer(older.uid)
	assert_eq(_state.designing_uid, newest.uid, "El computador estaba libre")
	_sim.advance_game_seconds(960)
	assert_eq(_state.designing_uid, older.uid, "Sigue el de menor uid, aunque se aceptó último")
	assert_eq(_state.find_order(middle.uid).stage, Order.Stage.WAITING_DESIGN)


func test_modeling_runs_while_printing() -> void:
	var printing: Order = _accept("maceta")
	_sim.advance_game_seconds(960)
	_start_crafted_print(printing, 7200)
	var order: Order = _accept("llavero")
	assert_eq(order.stage, Order.Stage.DESIGNING, "No espera a la impresora")
	_sim.advance_game_seconds(240)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(printing.stage, Order.Stage.PRINTING)


func test_one_big_step_equals_many_small_steps() -> void:
	var small: GameState = GameState.new_game(_rules, 99)
	var big: GameState = GameState.new_game(_rules, 99)
	var small_sim: Simulation = Simulation.new(small, _rules)
	var big_sim: Simulation = Simulation.new(big, _rules)
	for sim: Simulation in [small_sim, big_sim]:
		var commands: GameCommands = GameCommands.new(sim)
		sim.advance_game_seconds(60 + 1620)
		commands.accept_offer(sim.state.offers[1].uid)
		commands.accept_offer(sim.state.offers[0].uid)
	for i: int in 7200:
		small_sim.advance_game_seconds(1)
	big_sim.advance_game_seconds(7200)
	assert_eq(big.designing_uid, -1)
	assert_eq(big.orders[1].stage, Order.Stage.READY_TO_PRINT)
	assert_eq(_json(small), _json(big))


func test_focus_shortens_what_is_left() -> void:
	var start: int = _state.game_seconds
	var order: Order = _accept("soporte_celular")
	_sim.advance_game_seconds(101)
	_sim.changes.clear()
	var orders_twin: int = _state.orders_rng.state
	var prints_twin: int = _state.prints_rng.state
	var result: CommandResult = _commands.focus_design(order.uid)
	assert_true(result.ok)
	assert_eq(order.design_ends_at, start + 101 + 310, "Faltaban 619 s: quedan ceil(619 × 0,5) = 310")
	assert_true(order.focused)
	assert_true(_sim.changes.computer)
	assert_has(_sim.changes.orders, order.uid)
	assert_eq(_state.orders_rng.state, orders_twin, "Concentrarse no usa el azar")
	assert_eq(_state.prints_rng.state, prints_twin)
	_sim.advance_game_seconds(309)
	assert_eq(order.stage, Order.Stage.DESIGNING)
	_sim.advance_game_seconds(1)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT, "El nuevo fin se procesa en su segundo exacto")


func test_focus_only_once_per_order() -> void:
	var order: Order = _accept("soporte_celular")
	assert_true(_commands.focus_design(order.uid).ok)
	var ends_at: int = order.design_ends_at
	_sim.changes.clear()
	var result: CommandResult = _commands.focus_design(order.uid)
	assert_false(result.ok)
	assert_eq(result.reason, "ERR_ALREADY_FOCUSED")
	assert_eq(order.design_ends_at, ends_at)
	assert_true(_sim.changes.is_empty())


func test_focus_needs_the_order_being_designed() -> void:
	var designing: Order = _accept("llavero")
	var queued: Order = _accept("soporte_celular")
	_sim.changes.clear()
	assert_eq(_commands.focus_design(queued.uid).reason, "ERR_NOT_DESIGNING")
	assert_false(queued.focused)
	assert_eq(_commands.focus_design(999).reason, "ERR_ORDER_GONE")
	assert_true(_sim.changes.is_empty())
	_sim.advance_game_seconds(240)
	assert_eq(_commands.focus_design(designing.uid).reason, "ERR_NOT_DESIGNING", "Ya está listo")
	assert_true(DesignFlow.check_focus(_state, queued.uid).ok, "El siguiente de la fila ya se está modelando")


func test_a_finished_design_says_it_is_not_being_designed() -> void:
	var order: Order = _accept("llavero")
	assert_true(_commands.focus_design(order.uid).ok)
	_sim.advance_game_seconds(order.design_ends_at - _state.game_seconds)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(_commands.focus_design(order.uid).reason, "ERR_NOT_DESIGNING", "Antes que ERR_ALREADY_FOCUSED")


func test_focus_never_ends_the_design_on_the_spot() -> void:
	var order: Order = _accept("soporte_celular")
	_sim.advance_game_seconds(719)
	assert_true(_commands.focus_design(order.uid).ok)
	assert_eq(order.design_ends_at, _state.game_seconds + 1, "Al menos 1 segundo de juego")


func test_cancelling_the_active_design_starts_the_next_now() -> void:
	var first: Order = _accept("llavero")
	var second: Order = _accept("soporte_celular")
	_sim.advance_game_seconds(100)
	_sim.changes.clear()
	assert_true(_commands.cancel_order(first.uid).ok)
	assert_null(_state.find_order(first.uid))
	assert_eq(_state.designing_uid, second.uid)
	assert_eq(second.stage, Order.Stage.DESIGNING)
	assert_eq(second.design_ends_at, _state.game_seconds + 720)
	assert_true(_sim.changes.computer)
	assert_has(_sim.changes.removed_orders, first.uid)
	_sim.advance_game_seconds(720)
	assert_eq(second.stage, Order.Stage.READY_TO_PRINT)


func test_cancelling_a_queued_order_keeps_the_design() -> void:
	var first: Order = _accept("llavero")
	var second: Order = _accept("soporte_celular")
	var ends_at: int = first.design_ends_at
	assert_true(_commands.cancel_order(second.uid).ok)
	assert_eq(_state.designing_uid, first.uid)
	assert_eq(first.design_ends_at, ends_at)


func test_cancelling_the_only_design_frees_the_computer() -> void:
	var order: Order = _accept("llavero")
	assert_true(_commands.cancel_order(order.uid).ok)
	assert_eq(_state.designing_uid, -1)
	_sim.advance_game_seconds(1000)
	assert_true(_state.orders.is_empty())
	assert_eq(_state.designing_uid, -1)


# --- Ayudantes -------------------------------------------------------------


func _add_offer(order_id: String) -> OrderOffer:
	var offer: OrderOffer = OrderOffer.new(_state.take_uid(), order_id, _state.game_seconds)
	_state.offers.append(offer)
	return offer


func _accept(order_id: String) -> Order:
	var result: CommandResult = _commands.accept_offer(_add_offer(order_id).uid)
	assert_true(result.ok, result.reason)
	return _state.find_order(result.uid)


## Deja el pedido imprimiéndose en la Cubo Uno, armado a mano (como si se
## hubiera tocado Imprimir), con una pieza que termina en `piece_seconds`.
func _start_crafted_print(order: Order, piece_seconds: int) -> void:
	var printer: OwnedPrinter = _state.printers[0]
	var spool: Spool = _state.spools[0]
	var grams: int = _rules.order_grams[order.order_id]
	spool.grams -= grams
	order.stage = Order.Stage.PRINTING
	order.printer_uid = printer.uid
	var job: PrintJob = PrintJob.new()
	job.order_uid = order.uid
	job.spool_uid = spool.uid
	job.mode_id = "normal"
	job.color_id = spool.color_id
	job.pieces_total = 1
	job.grams_per_piece = grams
	job.piece_seconds = piece_seconds
	job.piece_started_at = _state.game_seconds
	job.ends_at = _state.game_seconds + piece_seconds
	printer.job = job
	_sim.mark_dirty()


func _json(state: GameState) -> String:
	return JSON.stringify(SaveCodec.encode(state), "", true)
