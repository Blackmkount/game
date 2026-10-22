extends GutTest
## Impresión en el ciclo: Imprimir aparta el material y empieza la primera
## pieza, las piezas siguen solas en su segundo exacto, una falla detiene el
## trabajo, y se puede reintentar o limpiar. Los gramos nunca aparecen ni
## desaparecen.

var _rules: SimRules
var _state: GameState
var _sim: Simulation
var _commands: GameCommands


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_state = GameState.new_game(_rules, 1234)
	_sim = Simulation.new(_state, _rules)
	_commands = GameCommands.new(_sim)
	# Tablero en pausa: estas pruebas no aceptan mensajes; los pedidos se arman
	# a mano con el modelo listo.
	_state.scripted_offers.clear()
	_state.next_offer_at = -1


# --- Imprimir y piezas que siguen solas ------------------------------------


func test_keychain_is_ready_in_twenty_game_minutes() -> void:
	var order: Order = _ready_order("llavero")
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, order)
	var start: int = _state.game_seconds
	var result: CommandResult = _commands.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id)
	assert_true(result.ok, result.reason)
	var job: PrintJob = _state.printers[0].job
	assert_eq(_state.spools[0].grams, 992, "Se apartan los 8 g")
	assert_false(job.fails, "Las primeras piezas de la partida no fallan")
	assert_eq(job.ends_at, start + 1200)
	_sim.advance_game_seconds(1199)
	assert_eq(job.status, PrintJob.Status.PRINTING)
	_sim.advance_game_seconds(1)
	assert_eq(job.status, PrintJob.Status.DONE)
	assert_eq(order.stage, Order.Stage.PRINTED)
	assert_eq(order.pieces_done, 1)
	assert_eq(_state.spools[0].grams, 992, "Terminar una pieza no toca el carrete")


func test_start_print_reserves_the_pieces_left_and_builds_the_job() -> void:
	var rayo: OwnedPrinter = _add_rayo_x1()
	var petg: Spool = _add_spool("petg", 1000)
	var order: Order = _ready_order("engranaje")
	var start: int = _state.game_seconds
	_sim.changes.clear()
	_start(order, rayo, petg, "normal")
	assert_eq(petg.grams, 920, "Las 4 piezas de 20 g se apartan de una vez")
	assert_eq(order.stage, Order.Stage.PRINTING)
	assert_eq(order.printer_uid, rayo.uid)
	var job: PrintJob = rayo.job
	assert_eq(job.order_uid, order.uid)
	assert_eq(job.spool_uid, petg.uid)
	assert_eq(job.mode_id, "normal")
	assert_eq(job.color_id, "negro", "El color del carrete")
	assert_eq(job.pieces_total, 4)
	assert_eq(job.grams_per_piece, 20)
	assert_eq(job.piece_seconds, 2700)
	assert_eq(job.piece_started_at, start)
	assert_eq(job.ends_at, start + 2700)
	assert_eq(job.status, PrintJob.Status.PRINTING)
	assert_eq(_state.pieces_started, 1)
	assert_has(_sim.changes.printers, rayo.uid)
	assert_has(_sim.changes.orders, order.uid)
	assert_true(_sim.changes.spools)


func test_pieces_continue_on_their_own() -> void:
	_rules.grace_pieces = 1000
	var rayo: OwnedPrinter = _add_rayo_x1()
	var petg: Spool = _add_spool("petg", 1000)
	var order: Order = _ready_order("engranaje")
	var start: int = _state.game_seconds
	_start(order, rayo, petg, "normal")
	_sim.advance_game_seconds(2699)
	assert_eq(order.pieces_done, 0)
	_sim.advance_game_seconds(1)
	assert_eq(order.pieces_done, 1)
	assert_eq(rayo.job.status, PrintJob.Status.PRINTING)
	assert_eq(rayo.job.piece_started_at, start + 2700, "La siguiente empieza en el segundo exacto")
	assert_eq(rayo.job.ends_at, start + 5400)
	assert_eq(petg.grams, 920, "El material ya estaba apartado")
	_sim.advance_game_seconds(3 * 2700)
	assert_eq(order.pieces_done, 4)
	assert_eq(rayo.job.status, PrintJob.Status.DONE)
	assert_eq(order.stage, Order.Stage.PRINTED)
	assert_eq(_state.pieces_started, 4)


func test_every_piece_uses_two_random_numbers() -> void:
	_rules.grace_pieces = 1000
	var rayo: OwnedPrinter = _add_rayo_x1()
	var petg: Spool = _add_spool("petg", 1000)
	var order: Order = _ready_order("engranaje")
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	var orders_state: int = _state.orders_rng.state
	_start(order, rayo, petg, "normal")
	_draw(twin, 2)
	assert_eq(_state.prints_rng.state, twin.state, "Imprimir: 2 números para la primera pieza")
	_sim.advance_game_seconds(2700)
	_draw(twin, 2)
	assert_eq(_state.prints_rng.state, twin.state, "La segunda pieza: 2 más")
	_sim.advance_game_seconds(3 * 2700)
	_draw(twin, 4)
	assert_eq(_state.prints_rng.state, twin.state, "4 piezas, 8 números; terminar no usa el azar")
	assert_eq(_state.orders_rng.state, orders_state, "Imprimir no toca el azar del tablero")


func test_finished_pieces_keep_the_printer_busy() -> void:
	var order: Order = _ready_order("llavero")
	var cubo: OwnedPrinter = _state.printers[0]
	_start(order, cubo, _state.spools[0], "normal")
	_sim.advance_game_seconds(1200)
	var other: Order = _ready_order("maceta")
	var result: CommandResult = _commands.start_print(other.uid, cubo.uid, _state.spools[0].uid, "normal")
	assert_eq(result.reason, "ERR_PRINTER_DONE")
	assert_eq(result.args, ["PRINTER_CUBO_UNO"])
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	_sim.advance_game_seconds(GameClock.SECONDS_PER_DAY)
	assert_eq(cubo.job.status, PrintJob.Status.DONE, "Las piezas esperan a que se retiren")
	assert_eq(order.stage, Order.Stage.PRINTED)
	assert_eq(other.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(_state.prints_rng.state, twin.state)


# --- Fallas ----------------------------------------------------------------


func test_a_failed_piece_stops_the_job_and_returns_what_was_not_used() -> void:
	var setup: Dictionary = _gear_failing_on_piece_three()
	var rayo: OwnedPrinter = setup["printer"]
	var petg: Spool = setup["spool"]
	var order: Order = setup["order"]
	var piece_start: int = rayo.job.piece_started_at
	assert_eq(rayo.job.ends_at, piece_start + 945, "Espagueti al 35% de 2.700 s")
	assert_eq(rayo.job.lost_grams, 7, "35% de 20 g, hacia arriba")
	_sim.changes.clear()
	_sim.advance_game_seconds(944)
	assert_eq(rayo.job.status, PrintJob.Status.PRINTING)
	assert_eq(petg.grams, 920)
	_sim.advance_game_seconds(1)
	assert_eq(rayo.job.status, PrintJob.Status.FAILED)
	assert_eq(rayo.job.fail_percent(), 35)
	assert_eq(petg.grams, 933, "Vuelven los 13 g que no se usaron")
	assert_eq(order.pieces_done, 2, "Las piezas terminadas se guardan")
	assert_eq(order.stage, Order.Stage.PRINTING)
	assert_eq(_sim.changes.failures.size(), 1)
	assert_has(_sim.changes.failures, rayo.uid)
	assert_true(_sim.changes.spools)
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	_sim.advance_game_seconds(GameClock.SECONDS_PER_DAY)
	assert_eq(rayo.job.status, PrintJob.Status.FAILED, "Una falla espera al jugador")
	assert_eq(rayo.job.piece_started_at, piece_start)
	assert_eq(rayo.job.ends_at, piece_start + 945)
	assert_eq(order.pieces_done, 2)
	assert_eq(petg.grams, 933)
	assert_eq(_state.prints_rng.state, twin.state, "El trabajo detenido ya no tiene eventos")


func test_only_the_first_pieces_of_the_game_are_graced() -> void:
	# PETG que siempre falla: solo la gracia (3 piezas) lo salva.
	var petg_def: Dictionary = _rules.materials["petg"].duplicate(true)
	petg_def["failure_multiplier"] = 100.0
	_rules.materials["petg"] = petg_def
	_rules.max_chance = 1.0
	var rayo: OwnedPrinter = _add_rayo_x1()
	var order: Order = _ready_order("engranaje")
	_start(order, rayo, _add_spool("petg", 1000), "normal")
	_sim.advance_game_seconds(3 * 2700)
	assert_eq(order.pieces_done, 3, "Las 3 primeras piezas no fallan")
	assert_true(rayo.job.fails, "La cuarta ya puede fallar")
	_sim.advance_game_seconds(2700)
	assert_eq(rayo.job.status, PrintJob.Status.FAILED)
	assert_eq(_state.pieces_started, 4)


func test_force_fail_needs_a_piece_in_progress_and_uses_no_random_numbers() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	assert_false(DebugTools.force_fail(_sim, cubo.uid, FailureRules.SPAGHETTI), "Impresora libre")
	assert_false(DebugTools.force_fail(_sim, 999, FailureRules.SPAGHETTI))
	_start(_ready_order("llavero"), cubo, _state.spools[0], "normal")
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	assert_false(DebugTools.force_fail(_sim, cubo.uid, "derretido"), "Tipo de fallo desconocido")
	assert_false(cubo.job.fails)
	_sim.advance_game_seconds(1000)
	assert_true(DebugTools.force_fail(_sim, cubo.uid, FailureRules.WARPING))
	assert_eq(cubo.job.failure_type, FailureRules.WARPING)
	assert_eq(cubo.job.ends_at, _state.game_seconds + 1, "El 35% ya pasó: falla en el próximo segundo")
	assert_eq(cubo.job.fail_percent(), 83, "Se detiene donde iba: 1.001 de 1.200 s")
	assert_eq(cubo.job.lost_grams, 7, "Se pierde lo impreso hasta ahí: 83% de 8 g, hacia arriba")
	assert_eq(_state.prints_rng.state, twin.state)
	_sim.advance_game_seconds(1)
	assert_eq(cubo.job.status, PrintJob.Status.FAILED)


func test_retry_prints_the_failed_piece_again_with_the_new_mode() -> void:
	var setup: Dictionary = _gear_failing_on_piece_three()
	var rayo: OwnedPrinter = setup["printer"]
	var petg: Spool = setup["spool"]
	var order: Order = setup["order"]
	_sim.advance_game_seconds(945)
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	var started: int = _state.pieces_started
	var now: int = _state.game_seconds
	_sim.changes.clear()
	var result: CommandResult = _commands.retry_piece(rayo.uid, "fine")
	assert_true(result.ok, result.reason)
	assert_eq(petg.grams, 913, "Se vuelven a apartar los 20 g de la pieza")
	assert_eq(rayo.job.status, PrintJob.Status.PRINTING)
	assert_eq(rayo.job.mode_id, "fine")
	assert_eq(rayo.job.piece_seconds, 4320, "2.700 s × 1,6 del modo fino")
	assert_eq(rayo.job.piece_started_at, now)
	assert_eq(rayo.job.ends_at, now + 4320)
	assert_eq(order.pieces_done, 2, "Las piezas terminadas se conservan")
	assert_eq(_state.pieces_started, started + 1)
	_draw(twin, 2)
	assert_eq(_state.prints_rng.state, twin.state, "2 números nuevos para la pieza")
	assert_has(_sim.changes.printers, rayo.uid)
	assert_true(_sim.changes.spools)
	_sim.advance_game_seconds(2 * 4320)
	assert_eq(order.pieces_done, 4, "La pieza 4 también sale en fino")
	assert_eq(rayo.job.status, PrintJob.Status.DONE)
	assert_eq(petg.grams, 913)


func test_retry_without_material_changes_nothing() -> void:
	var setup: Dictionary = _gear_failing_on_piece_three()
	var rayo: OwnedPrinter = setup["printer"]
	var petg: Spool = setup["spool"]
	_sim.advance_game_seconds(945)
	petg.grams = 5
	var before: String = _json()
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	_sim.changes.clear()
	var result: CommandResult = _commands.retry_piece(rayo.uid, "normal")
	assert_eq(result.reason, "ERR_NOT_ENOUGH_MATERIAL")
	assert_eq(result.args, [{"grams": 5}, {"grams": 20}], "Quedan 5 g y hacen falta 20 g")
	assert_eq(_json(), before)
	assert_eq(_state.prints_rng.state, twin.state, "No usa el azar")
	assert_true(_sim.changes.is_empty())


func test_retry_and_clean_need_a_failed_piece() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	var setup: Dictionary = _gear_failing_on_piece_three()
	var rayo: OwnedPrinter = setup["printer"]
	var before: String = _json()
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	assert_eq(_commands.retry_piece(999, "normal").reason, "ERR_PRINTER_GONE")
	assert_eq(_commands.clean_printer(999).reason, "ERR_PRINTER_GONE")
	assert_eq(_commands.retry_piece(cubo.uid, "normal").reason, "ERR_NOT_FAILED", "Impresora libre")
	assert_eq(_commands.clean_printer(cubo.uid).reason, "ERR_NOT_FAILED")
	assert_eq(_commands.retry_piece(rayo.uid, "normal").reason, "ERR_NOT_FAILED", "Todavía imprime")
	assert_eq(_commands.clean_printer(rayo.uid).reason, "ERR_NOT_FAILED")
	assert_eq(_json(), before)
	_sim.advance_game_seconds(945)
	before = _json()
	twin = _twin(_state.prints_rng)
	assert_eq(_commands.retry_piece(rayo.uid, "turbo").reason, "ERR_MODE_UNKNOWN")
	var result: CommandResult = _commands.retry_piece(rayo.uid, "draft")
	assert_eq(result.reason, "ERR_QUALITY")
	assert_eq(result.args, [2, 3], "El engranaje pide calidad 3")
	assert_eq(_json(), before)
	assert_eq(_state.prints_rng.state, twin.state)


func test_clean_returns_the_unstarted_material_and_keeps_finished_pieces() -> void:
	var setup: Dictionary = _gear_failing_on_piece_three()
	var rayo: OwnedPrinter = setup["printer"]
	var petg: Spool = setup["spool"]
	var order: Order = setup["order"]
	_sim.advance_game_seconds(945)
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	_sim.changes.clear()
	assert_true(_commands.clean_printer(rayo.uid).ok)
	assert_eq(petg.grams, 953, "Vuelven los 20 g de la pieza 4, sin empezar")
	assert_null(rayo.job)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(order.printer_uid, -1)
	assert_eq(order.pieces_done, 2)
	assert_eq(_state.prints_rng.state, twin.state, "Limpiar no usa el azar")
	assert_has(_sim.changes.printers, rayo.uid)
	assert_has(_sim.changes.orders, order.uid)
	assert_true(_sim.changes.spools)
	# Se puede elegir otra impresora: la Cubo Uno solo llega a calidad 3 en fino.
	var cubo: OwnedPrinter = _state.printers[0]
	_start(order, cubo, petg, "fine")
	assert_eq(petg.grams, 913, "Solo se apartan las 2 piezas que faltan")
	assert_eq(cubo.job.piece_seconds, 8640)
	_sim.advance_game_seconds(2 * 8640)
	assert_eq(order.pieces_done, 4)
	assert_eq(order.stage, Order.Stage.PRINTED)


func test_grams_are_conserved() -> void:
	_rules.grace_pieces = 1000
	var rayo: OwnedPrinter = _add_rayo_x1()
	var petg: Spool = _add_spool("petg", 1000)
	var cubo: OwnedPrinter = _state.printers[0]
	var pla: Spool = _state.spools[0]
	var gear: Order = _ready_order("engranaje")
	var keychain: Order = _ready_order("llavero")
	var pot: Order = _ready_order("maceta")
	var lost: int = 0
	var total: int = _grams_everywhere(lost)
	_start(gear, rayo, petg, "normal")
	assert_eq(_grams_everywhere(lost), total, "Imprimir")
	_sim.advance_game_seconds(2700)
	assert_eq(_grams_everywhere(lost), total, "Pieza terminada")
	DebugTools.force_fail(_sim, rayo.uid, FailureRules.SPAGHETTI)
	_sim.advance_game_seconds(945)
	lost += rayo.job.lost_grams
	assert_eq(_grams_everywhere(lost), total, "Falla")
	assert_true(_commands.retry_piece(rayo.uid, "normal").ok)
	assert_eq(_grams_everywhere(lost), total, "Reintentar")
	DebugTools.force_fail(_sim, rayo.uid, FailureRules.WARPING, 0.2)
	_sim.advance_game_seconds(540)
	lost += rayo.job.lost_grams
	assert_eq(_grams_everywhere(lost), total, "Segunda falla")
	assert_true(_commands.clean_printer(rayo.uid).ok)
	assert_eq(_grams_everywhere(lost), total, "Limpiar")
	_start(gear, rayo, petg, "normal")
	assert_eq(_grams_everywhere(lost), total, "Imprimir otra vez")
	_sim.advance_game_seconds(1000)
	lost += _lost_on_cancel(gear)
	assert_true(_commands.cancel_order(gear.uid).ok)
	assert_eq(_grams_everywhere(lost), total, "Cancelar mientras imprime")
	_start(keychain, cubo, pla, "normal")
	DebugTools.force_fail(_sim, cubo.uid, FailureRules.SPAGHETTI)
	_sim.advance_game_seconds(420)
	lost += cubo.job.lost_grams
	lost += _lost_on_cancel(keychain)
	assert_true(_commands.cancel_order(keychain.uid).ok)
	assert_eq(_grams_everywhere(lost), total, "Cancelar después de una falla")
	_start(pot, cubo, pla, "normal")
	_sim.advance_game_seconds(7200)
	assert_eq(cubo.job.status, PrintJob.Status.DONE)
	lost += _lost_on_cancel(pot)
	assert_true(_commands.cancel_order(pot.uid).ok)
	assert_eq(_grams_everywhere(lost), total, "Cancelar con las piezas listas")
	assert_true(_state.orders.is_empty())
	assert_eq(_state.total_grams() + lost, total, "Sin pedidos, todo está en los carretes o perdido")


func test_one_big_step_equals_many_small_steps_while_printing() -> void:
	_rules.grace_pieces = 0
	var small: Simulation = _two_printer_workshop()
	var big: Simulation = _two_printer_workshop()
	for i: int in 10900:
		small.advance_game_seconds(1)
	big.advance_game_seconds(10900)
	assert_eq(big.state.printers[2].job.status, PrintJob.Status.FAILED, "La perilla forzada falló")
	assert_gt(big.state.pieces_started, 2, "Hubo piezas que siguieron solas")
	assert_eq(_json_of(small.state), _json_of(big.state))


# --- Ayudantes -------------------------------------------------------------


func _ready_order(order_id: String) -> Order:
	var order: Order = Order.new(_state.take_uid(), order_id, _state.game_seconds)
	order.stage = Order.Stage.READY_TO_PRINT
	_state.orders.append(order)
	return order


func _add_spool(material_id: String, grams: int) -> Spool:
	var spool: Spool = Spool.new(_state.take_uid(), material_id, "negro", grams)
	_state.spools.append(spool)
	return spool


## Una Rayo X1 sobre una mesa de trabajo.
func _add_rayo_x1() -> OwnedPrinter:
	var table: OwnedFurniture = OwnedFurniture.new(_state.take_uid(), "mesa_trabajo", _state.furniture.size())
	_state.furniture.append(table)
	var rayo: OwnedPrinter = OwnedPrinter.new(_state.take_uid(), "rayo_x1", table.uid)
	_state.printers.append(rayo)
	return rayo


func _start(order: Order, printer: OwnedPrinter, spool: Spool, mode_id: String) -> void:
	var result: CommandResult = _commands.start_print(order.uid, printer.uid, spool.uid, mode_id)
	assert_true(result.ok, result.reason)


## Un engranaje (4 × 20 g de PETG) en una Rayo X1 con las piezas 1 y 2 listas
## y la 3 en curso, forzada a fallar por espagueti al 35%.
func _gear_failing_on_piece_three() -> Dictionary:
	_rules.grace_pieces = 1000
	var rayo: OwnedPrinter = _add_rayo_x1()
	var petg: Spool = _add_spool("petg", 1000)
	var order: Order = _ready_order("engranaje")
	_start(order, rayo, petg, "normal")
	_sim.advance_game_seconds(2 * 2700)
	assert_eq(order.pieces_done, 2)
	assert_true(DebugTools.force_fail(_sim, rayo.uid, FailureRules.SPAGHETTI))
	return {"printer": rayo, "spool": petg, "order": order}


## Dos Rayo X1 con PETG: un engranaje y una perilla cuya primera pieza se
## fuerza a fallar. Mismo estado de partida cada vez.
func _two_printer_workshop() -> Simulation:
	_state = GameState.new_game(_rules, 77)
	_state.scripted_offers.clear()
	_state.next_offer_at = -1
	var sim: Simulation = Simulation.new(_state, _rules)
	_commands = GameCommands.new(sim)
	var gear_printer: OwnedPrinter = _add_rayo_x1()
	var knob_printer: OwnedPrinter = _add_rayo_x1()
	var petg: Spool = _add_spool("petg", 1000)
	_start(_ready_order("engranaje"), gear_printer, petg, "normal")
	_start(_ready_order("perilla"), knob_printer, petg, "normal")
	DebugTools.force_fail(sim, knob_printer.uid, FailureRules.WARPING, 0.5)
	return sim


## Gramos en los carretes, en las piezas terminadas, apartados en los trabajos
## para las piezas que faltan, y los perdidos que lleva la prueba.
func _grams_everywhere(lost: int) -> int:
	var total: int = _state.total_grams() + lost
	for order: Order in _state.orders:
		total += order.pieces_done * _rules.order_grams[order.order_id]
	for printer: OwnedPrinter in _state.printers:
		var job: PrintJob = printer.job
		if job == null:
			continue
		var unfinished: int = job.pieces_total - _state.find_order(job.order_uid).pieces_done
		match job.status:
			PrintJob.Status.PRINTING:
				total += unfinished * job.grams_per_piece
			PrintJob.Status.FAILED:
				total += (unfinished - 1) * job.grams_per_piece
	return total


## Lo que se pierde al cancelar: las piezas terminadas y la pieza en curso (lo
## perdido de una pieza que falló ya se contó al fallar).
func _lost_on_cancel(order: Order) -> int:
	var grams: int = order.pieces_done * _rules.order_grams[order.order_id]
	var printer: OwnedPrinter = _state.find_printer(order.printer_uid)
	if printer.job.status == PrintJob.Status.PRINTING:
		grams += printer.job.grams_per_piece
	return grams


func _twin(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	var twin: RandomNumberGenerator = RandomNumberGenerator.new()
	twin.seed = rng.seed
	twin.state = rng.state
	return twin


func _draw(rng: RandomNumberGenerator, count: int) -> void:
	for i: int in count:
		rng.randf()


func _json() -> String:
	return _json_of(_state)


func _json_of(state: GameState) -> String:
	return JSON.stringify(SaveCodec.encode(state), "", true)
