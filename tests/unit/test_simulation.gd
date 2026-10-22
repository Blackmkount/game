extends GutTest
## Avance del tiempo: reloj de segundos de juego enteros, un avance grande da
## exactamente lo mismo que muchos pequeños, el camino rápido sin búsquedas, la
## salvaguarda de eventos, la velocidad con 40 impresoras y el tiempo de la
## primera venta.

## 8 horas reales: lo más que se avanzará de una vez (progreso fuera del juego).
const EIGHT_HOURS: float = 8.0 * 3600.0
## Tope de las esperas obligatorias de la primera venta, en segundos reales:
## la primera venta tiene que llegar antes de 2 minutos (GDD).
const FIRST_SALE_WAIT_REAL_SECONDS: int = 75
## Veces que se mide un mismo avance: vale la más rápida, para que una pausa
## del equipo de pruebas no cuente como lentitud del código.
const TIMING_RUNS: int = 3

var _rules: SimRules


## Simulación que cuenta cuántas veces busca el próximo evento.
class SpySimulation extends Simulation:
	var scans: int = 0

	func _init(p_state: GameState, p_rules: SimRules) -> void:
		super(p_state, p_rules)

	func _scan_next_event_time() -> int:
		scans += 1
		return super()


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())


# --- Reloj -----------------------------------------------------------------


func test_one_real_hour_is_one_game_day() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	Simulation.new(state, _rules).advance(3600.0)
	assert_eq(state.game_seconds - start, 86400)
	assert_eq(state.live_seconds, 86400)


func test_fractions_of_a_second_carry_over() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	var simulation: Simulation = Simulation.new(state, _rules)
	simulation.advance(1.0 / 64.0)
	assert_eq(state.game_seconds, start, "1/64 s real son 0,375 s de juego: todavía no hay un segundo entero")
	simulation.advance(1.0 / 64.0)
	simulation.advance(1.0 / 64.0)
	assert_eq(state.game_seconds, start + 1, "3/64 s real son 1,125 s de juego")
	for i: int in 61:
		simulation.advance(1.0 / 64.0)
	assert_eq(state.game_seconds, start + 24, "64 pasos de 1/64 s son 1 s real")


func test_zero_or_negative_time_does_nothing() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	var simulation: Simulation = Simulation.new(state, _rules)
	simulation.advance(0.0)
	simulation.advance(-50.0)
	simulation.advance_game_seconds(0)
	simulation.advance_game_seconds(-5)
	assert_eq(state.game_seconds, start)
	assert_eq(state.live_seconds, 0)


func test_time_away_moves_the_clock_but_not_the_deadlines() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	var simulation: Simulation = Simulation.new(state, _rules)
	simulation.advance(10.0, false)
	assert_eq(state.game_seconds, start + 240)
	assert_eq(state.live_seconds, 0, "Fuera del juego los plazos no corren")
	simulation.advance_game_seconds(60)
	assert_eq(state.live_seconds, 60)


# --- Un avance grande es igual a muchos pequeños ---------------------------


## El taller ocupado avanza 8 horas reales de tres maneras: de una vez, en
## pasos de 1 s y en pasos al azar de k/64 s. Las tres partidas guardadas
## tienen que ser idénticas, y en el camino tuvo que pasar de todo.
func test_one_big_step_equals_small_steps_in_three_ways() -> void:
	var doc: Dictionary = SaveCodec.encode(SimFixtures.busy_workshop(_rules).state)
	var once: Simulation = _clone(doc)
	var by_second: Simulation = _clone(doc)
	var by_fraction: Simulation = _clone(doc)
	var start: int = once.state.game_seconds

	once.advance(EIGHT_HOURS)
	for i: int in roundi(EIGHT_HOURS):
		by_second.advance(1.0)
	var steps: RandomNumberGenerator = RandomNumberGenerator.new()
	steps.seed = 64
	var sixty_fourths_left: int = roundi(EIGHT_HOURS) * 64
	while sixty_fourths_left > 0:
		var k: int = mini(steps.randi_range(1, 736), sixty_fourths_left)
		by_fraction.advance(k / 64.0)
		sixty_fourths_left -= k

	assert_eq(once.state.game_seconds, start + roundi(EIGHT_HOURS) * _rules.game_seconds_per_real_second)
	var expected: String = _json(once.state)
	assert_eq(_json(by_second.state), expected, "En pasos de 1 s")
	assert_eq(_json(by_fraction.state), expected, "En pasos al azar de k/64 s")
	# Pasó de todo. Si un cambio de semilla o de datos lo evita, esta prueba avisa.
	assert_false(once.changes.failures.is_empty(), "Alguna pieza falló")
	assert_has(_job_statuses(once.state), PrintJob.Status.DONE, "Algún trabajo terminó todas sus piezas")
	assert_true(once.changes.computer, "El computador terminó modelos")
	assert_eq(once.state.designing_uid, -1, "Se modeló toda la fila")
	assert_false(once.changes.arrived_offers.is_empty(), "Llegaron mensajes")


# --- Camino rápido ---------------------------------------------------------


func test_without_events_due_the_fast_path_does_not_search() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var simulation: SpySimulation = SpySimulation.new(state, _rules)
	simulation.advance_game_seconds(1)
	var scans: int = simulation.scans
	assert_gt(scans, 0, "Una partida nueva busca su primer evento")
	for i: int in _rules.first_offer_seconds - 2:
		simulation.advance_game_seconds(1)
	assert_eq(simulation.scans, scans, "Antes del primer mensaje no hay nada que buscar")
	simulation.advance_game_seconds(1)
	assert_eq(state.offers.size(), 1)
	assert_gt(simulation.scans, scans, "Al llegar al evento sí se busca")
	scans = simulation.scans
	simulation.advance_game_seconds(1)
	assert_eq(simulation.scans, scans)
	simulation.mark_dirty()
	simulation.advance_game_seconds(1)
	assert_gt(simulation.scans, scans, "Después de un comando se vuelve a buscar")


# --- Salvaguarda de eventos ------------------------------------------------


## Con los máximos que deja el validador, 8 horas reales nunca llegan a la
## salvaguarda: 40 impresoras con pedidos de 100 piezas, 20 pedidos por
## modelar y un mensaje por minuto de juego.
func test_data_maxima_stay_below_the_event_safety_limit() -> void:
	const PRINTERS: int = 40
	const MAX_PIECES: int = 100
	const MAX_ACTIVE_ORDERS: int = 20
	const MIN_OFFER_INTERVAL_SECONDS: int = GameClock.SECONDS_PER_MINUTE
	var eight_hours_game: int = roundi(EIGHT_HOURS) * _rules.game_seconds_per_real_second
	var events: int = PRINTERS * MAX_PIECES + MAX_ACTIVE_ORDERS + eight_hours_game / MIN_OFFER_INTERVAL_SECONDS + 1
	assert_eq(events, 15541)
	assert_lt(events, Simulation.MAX_EVENTS_PER_ADVANCE)


# --- Velocidad -------------------------------------------------------------


func test_eight_hours_with_forty_printers_take_under_20_ms() -> void:
	var finished: Array[Simulation] = []
	var elapsed: int = _fastest_eight_hours(SimFixtures.farm(_rules, 40), finished)
	gut.p("8 h con 40 impresoras (casco de 6 piezas): %d µs" % elapsed)
	assert_lt(elapsed, 20000, "Menos de 20 ms en la computadora de pruebas")
	assert_does_not_have(_job_statuses(finished[0].state), PrintJob.Status.PRINTING, "Todos los trabajos terminaron o fallaron")


## Prueba de carga, solo informativa: 40 trabajos de 100 piezas que no fallan.
func test_forty_hundred_piece_jobs_stay_under_100_ms() -> void:
	_rules.orders["llavero"] = _rules.orders["llavero"].duplicate(true)
	_rules.orders["llavero"]["pieces"] = 100
	_rules.grace_pieces = 1000000000
	var finished: Array[Simulation] = []
	var elapsed: int = _fastest_eight_hours(SimFixtures.farm(_rules, 40, "llavero"), finished)
	gut.p("8 h con 40 impresoras (llavero de 100 piezas): %d µs" % elapsed)
	assert_lt(elapsed, 100000)
	var state: GameState = finished[0].state
	for order: Order in state.orders:
		if order.order_id == "llavero" and order.stage == Order.Stage.PRINTED:
			assert_eq(order.pieces_done, 100)
	assert_does_not_have(_job_statuses(state), PrintJob.Status.PRINTING)


# --- Primera venta ---------------------------------------------------------


## La primera venta, jugada con comandos en el primer segundo posible: las
## esperas obligatorias son el primer mensaje, el modelado y la impresión
## recomendada, y caben en 75 s reales. La primera pieza nunca falla, así que
## se cumple siempre.
func test_first_sale_budget() -> void:
	var simulation: Simulation = SimFixtures.new_sim(_rules)
	var state: GameState = simulation.state
	var commands: GameCommands = GameCommands.new(simulation)
	var first_id: String = _rules.starting_offers[0]
	var start: int = state.game_seconds
	simulation.advance_game_seconds(_rules.first_offer_seconds)
	assert_eq(state.offers.size(), 1)
	var offer: OrderOffer = state.offers[0]
	assert_eq(offer.order_id, first_id)
	assert_true(commands.accept_offer(offer.uid).ok)
	var order: Order = state.find_order(offer.uid)
	simulation.advance_game_seconds(_rules.design_seconds[first_id])
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(state, _rules, order)
	assert_true(plan.ok)
	assert_true(plan.graced, "La primera pieza de la partida no puede fallar")
	assert_true(commands.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	simulation.advance_game_seconds(plan.total_seconds)
	assert_true(commands.remove_pieces(plan.printer_uid).ok)
	assert_true(commands.pack_order(order.uid).ok)
	var sale: CommandResult = commands.dispatch_order(order.uid)
	assert_true(sale.ok)
	assert_eq(sale.cents, _rules.payment_cents[first_id])
	var waited: int = state.game_seconds - start
	assert_eq(waited, _rules.first_offer_seconds + _rules.design_seconds[first_id] + plan.total_seconds)
	assert_lte(waited, FIRST_SALE_WAIT_REAL_SECONDS * _rules.game_seconds_per_real_second)


# --- Ayudantes -------------------------------------------------------------


## Avanza 8 horas reales TIMING_RUNS copias idénticas de la partida y
## devuelve el menor tiempo, en µs. Las copias terminadas quedan en
## `finished`, y tienen que haber terminado iguales.
func _fastest_eight_hours(simulation: Simulation, finished: Array[Simulation]) -> int:
	var doc: Dictionary = SaveCodec.encode(simulation.state)
	var fastest: int = 0
	for i: int in TIMING_RUNS:
		var copy: Simulation = _clone(doc)
		var started: int = Time.get_ticks_usec()
		copy.advance(EIGHT_HOURS)
		var elapsed: int = Time.get_ticks_usec() - started
		if i == 0 or elapsed < fastest:
			fastest = elapsed
		finished.append(copy)
	for copy: Simulation in finished:
		assert_eq(_json(copy.state), _json(finished[0].state), "Copias iguales terminan iguales")
	return fastest


## Una copia independiente de la partida, cargada desde lo guardado.
func _clone(doc: Dictionary) -> Simulation:
	var errors: Array[String] = []
	var state: GameState = SaveCodec.decode(doc.duplicate(true), _rules, errors)
	assert_not_null(state, "\n".join(PackedStringArray(errors)))
	return Simulation.new(state, _rules)


func _job_statuses(state: GameState) -> Array[PrintJob.Status]:
	var statuses: Array[PrintJob.Status] = []
	for printer: OwnedPrinter in state.printers:
		if printer.job != null:
			statuses.append(printer.job.status)
	return statuses


func _json(state: GameState) -> String:
	return JSON.stringify(SaveCodec.encode(state), "", true)
