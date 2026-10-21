extends GutTest
## Tablero de pedidos (GDD 5.2): cuándo llegan los mensajes, cuáles pueden
## llegar, y aceptar, rechazar o cancelar.

const LEVEL_ONE: Array[String] = ["llavero", "soporte_celular", "maceta"]

var _rules: SimRules
var _state: GameState
var _sim: Simulation
var _commands: GameCommands


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_new_game(1234)


# --- Cuándo llegan ---------------------------------------------------------


func test_scripted_keychain_arrives_after_one_minute_with_one_draw() -> void:
	var twin: RandomNumberGenerator = _twin(_state.orders_rng)
	var prints_state: int = _state.prints_rng.state
	_sim.advance_game_seconds(59)
	assert_true(_state.offers.is_empty())
	assert_eq(_state.orders_rng.state, twin.state, "Antes del mensaje no se usa el azar")
	_sim.advance_game_seconds(1)
	assert_eq(_state.offers.size(), 1)
	var offer: OrderOffer = _state.offers[0]
	assert_eq(offer.order_id, "llavero")
	assert_eq(offer.uid, 4, "Después del mueble, la impresora y el carrete")
	assert_eq(offer.arrived_at, 28860)
	twin.randf()
	assert_eq(_state.orders_rng.state, twin.state, "Exactamente un número del azar del tablero")
	assert_eq(_state.prints_rng.state, prints_state, "El tablero no toca el azar de los fallos")
	assert_true(_state.scripted_offers.is_empty())
	assert_eq(_state.last_offer_order_id, "llavero")
	assert_true(_sim.changes.offers)
	assert_eq(_sim.changes.arrived_offers, [4] as Array[int])


func test_next_offers_come_after_the_starting_gap_then_every_hour() -> void:
	_sim.advance_game_seconds(60)
	assert_eq(_state.next_offer_at, 28860 + 1620)
	_sim.advance_game_seconds(1619)
	assert_eq(_state.offers.size(), 1)
	_sim.advance_game_seconds(1)
	assert_eq(_state.offers.size(), 2)
	assert_eq(_state.offers[1].arrived_at, 30480)
	assert_eq(_state.next_offer_at, 30480 + 3600)
	assert_true(_commands.reject_offer(_state.offers[0].uid).ok)
	assert_eq(_state.next_offer_at, 30480 + 3600, "Con lugar libre, responder no cambia la espera")
	_sim.advance_game_seconds(3600)
	assert_eq(_state.offers.size(), 2)
	assert_eq(_state.offers[1].arrived_at, 34080)
	assert_eq(_state.next_offer_at, 34080 + 3600)


func test_full_board_pauses_and_reject_resumes_from_now() -> void:
	_fill_board()
	_sim.advance_game_seconds(10000)
	assert_eq(_state.offers.size(), 3, "Los mensajes no vencen y no llegan más")
	assert_true(_commands.reject_offer(_state.offers[1].uid).ok)
	assert_eq(_state.offers.size(), 2)
	assert_eq(_state.next_offer_at, _state.game_seconds + 3600)


func test_full_board_pauses_and_accept_resumes_from_now() -> void:
	_fill_board()
	_sim.advance_game_seconds(500)
	assert_true(_commands.accept_offer(_state.offers[0].uid).ok)
	assert_eq(_state.next_offer_at, _state.game_seconds + 3600)
	var waited: int = _state.next_offer_at - _state.game_seconds
	_sim.advance_game_seconds(waited - 1)
	assert_eq(_state.offers.size(), 2)
	_sim.advance_game_seconds(1)
	assert_eq(_state.offers.size(), 3, "Aceptar marca la simulación para buscar el nuevo evento")


# --- Cuáles pueden llegar --------------------------------------------------


func test_only_orders_of_the_player_level_arrive() -> void:
	var level_one: Array[String] = _unique(_offer_ids(200))
	level_one.sort()
	assert_eq(level_one, ["llavero", "maceta", "soporte_celular"] as Array[String])
	_state.xp = 100
	var level_two: Array[String] = _unique(_offer_ids(200))
	level_two.sort()
	assert_eq(level_two, ["figura", "llavero", "maceta", "organizador", "soporte_celular"] as Array[String],
		"Nivel 2 sin PETG: la perilla no llega")


func test_perilla_needs_a_petg_spool() -> void:
	_state.xp = 100
	assert_does_not_have(_offer_ids(200), "perilla")
	_state.spools.append(Spool.new(_state.take_uid(), "petg", "negro", 1000))
	assert_has(_offer_ids(200), "perilla")


func test_helmet_needs_grams_for_all_its_pieces() -> void:
	_state.xp = 300
	assert_false(OrderBoard.is_makeable(_state, _rules, "casco_cosplay"), "6 × 220 g no caben en 1.000 g")
	assert_does_not_have(_offer_ids(200), "casco_cosplay")
	_state.spools[0].grams = 1320
	assert_true(OrderBoard.is_makeable(_state, _rules, "casco_cosplay"))
	assert_has(_offer_ids(200), "casco_cosplay")


func test_sign_needs_a_multicolor_printer() -> void:
	_state.xp = 300
	assert_does_not_have(_offer_ids(200), "letrero")
	_state.printers.append(OwnedPrinter.new(_state.take_uid(), "prisma_mc"))
	assert_has(_offer_ids(200), "letrero")


func test_makeability_checks_size_quality_and_material() -> void:
	assert_true(OrderBoard.is_makeable(_state, _rules, "llavero"))
	_state.spools[0].grams = 7
	assert_false(OrderBoard.is_makeable(_state, _rules, "llavero"), "Hacen falta 8 g")
	_state.spools[0].grams = 1000
	assert_false(OrderBoard.is_makeable(_state, _rules, "funda_flexible"), "No hay TPU")
	assert_false(OrderBoard.is_makeable(_state, _rules, "miniatura"), "Calidad 5 en resina")
	_state.printers[0].printer_id = "rayo_mini"
	assert_false(OrderBoard.is_makeable(_state, _rules, "organizador"), "La Rayo Mini es tamaño S")
	_state.printers.clear()
	assert_false(OrderBoard.is_makeable(_state, _rules, "llavero"), "Sin impresoras no se puede")


func test_a_busy_printer_still_counts() -> void:
	_state.printers[0].job = PrintJob.new()
	assert_true(OrderBoard.is_makeable(_state, _rules, "llavero"))


func test_without_candidates_nothing_arrives_but_one_draw_is_made() -> void:
	_state.spools[0].grams = 0
	_state.scripted_offers.clear()
	assert_false(OrderBoard.has_makeable(_state, _rules))
	var twin: RandomNumberGenerator = _twin(_state.orders_rng)
	var next_uid: int = _state.next_uid
	_sim.advance_game_seconds(60)
	assert_true(_state.offers.is_empty())
	assert_eq(_state.next_uid, next_uid)
	twin.randf()
	assert_eq(_state.orders_rng.state, twin.state)
	assert_eq(_state.next_offer_at, 28860 + 3600, "El reloj del tablero sigue")
	assert_false(_sim.changes.offers)


func test_no_duplicates_on_the_board_while_there_are_alternatives() -> void:
	for game_seed: int in 30:
		_new_game(game_seed)
		_fill_board()
		var ids: Array[String] = []
		for offer: OrderOffer in _state.offers:
			ids.append(offer.order_id)
		ids.sort()
		assert_eq(ids, ["llavero", "maceta", "soporte_celular"] as Array[String], "Semilla %d" % game_seed)


func test_the_only_makeable_order_can_repeat() -> void:
	_state.spools[0].grams = 10
	_sim.advance_game_seconds(60 + 1620)
	assert_eq(_state.offers.size(), 2)
	assert_eq(_state.offers[1].order_id, "llavero", "Solo alcanza para un llavero: se repite")


func test_the_last_order_is_never_offered_again_right_away() -> void:
	var ids: Array[String] = _offer_ids(200)
	for i: int in range(1, ids.size()):
		assert_ne(ids[i], ids[i - 1], "Mensaje %d" % i)


func test_same_seed_gives_the_same_offers() -> void:
	var first: Array[String] = _offer_sequence(77)
	assert_eq(_offer_sequence(77), first)
	assert_ne(_offer_sequence(78), first, "Otra semilla, otros mensajes")


# --- Aceptar, rechazar y cancelar ------------------------------------------


func test_accepted_order_keeps_the_offer_uid() -> void:
	var offer: OrderOffer = _add_offer("maceta")
	var result: CommandResult = _commands.accept_offer(offer.uid)
	assert_true(result.ok)
	assert_eq(result.uid, offer.uid)
	assert_true(_state.offers.is_empty())
	assert_eq(_state.orders.size(), 1)
	var order: Order = _state.orders[0]
	assert_eq(order.uid, offer.uid)
	assert_eq(order.order_id, "maceta")
	assert_eq(order.accepted_at, _state.game_seconds)
	assert_eq(order.due_live, -1, "La maceta no tiene plazo")
	assert_true(_sim.changes.offers)
	assert_has(_sim.changes.orders, offer.uid)


func test_deadline_counts_in_live_seconds() -> void:
	_state.spools.append(Spool.new(_state.take_uid(), "petg", "negro", 1000))
	_state.live_seconds = 5000
	var offer: OrderOffer = _add_offer("perilla")
	assert_true(_commands.accept_offer(offer.uid).ok)
	assert_eq(_state.find_order(offer.uid).due_live, 5000 + 259200, "3 días de juego")


func test_orders_stay_in_uid_order() -> void:
	var older: OrderOffer = _add_offer("llavero")
	var newer: OrderOffer = _add_offer("maceta")
	assert_true(_commands.accept_offer(newer.uid).ok)
	assert_true(_commands.accept_offer(older.uid).ok)
	assert_eq(_state.orders[0].uid, older.uid)
	assert_eq(_state.orders[1].uid, newer.uid)


func test_fourth_order_is_refused() -> void:
	for i: int in 3:
		assert_true(_commands.accept_offer(_add_offer("llavero").uid).ok)
	var fourth: OrderOffer = _add_offer("llavero")
	_sim.changes.clear()
	var result: CommandResult = _commands.accept_offer(fourth.uid)
	assert_false(result.ok)
	assert_eq(result.reason, "ERR_TOO_MANY_ORDERS")
	assert_eq(result.args, [3])
	assert_eq(_state.orders.size(), 3)
	assert_eq(_state.offers.size(), 1, "Un comando que falla no cambia nada")
	assert_true(_sim.changes.is_empty())


func test_offer_without_material_is_refused() -> void:
	var offer: OrderOffer = _add_offer("maceta")
	_state.spools[0].grams = 79
	var result: CommandResult = _commands.accept_offer(offer.uid)
	assert_false(result.ok)
	assert_eq(result.reason, "ERR_NO_MATERIAL_FOR_ORDER")
	assert_eq(_state.offers.size(), 1)
	assert_true(_state.orders.is_empty())
	assert_true(_sim.changes.is_empty())
	_state.spools[0].grams = 80
	assert_true(_commands.accept_offer(offer.uid).ok)


func test_missing_offer_is_refused() -> void:
	var offer: OrderOffer = _add_offer("llavero")
	assert_eq(_commands.accept_offer(999).reason, "ERR_OFFER_GONE")
	assert_true(_commands.reject_offer(offer.uid).ok)
	assert_true(_state.offers.is_empty())
	assert_eq(_commands.reject_offer(offer.uid).reason, "ERR_OFFER_GONE")
	assert_eq(_commands.accept_offer(offer.uid).reason, "ERR_OFFER_GONE")


func test_commands_never_use_the_random_streams() -> void:
	var orders_twin: RandomNumberGenerator = _twin(_state.orders_rng)
	var prints_twin: RandomNumberGenerator = _twin(_state.prints_rng)
	var kept: OrderOffer = _add_offer("llavero")
	_commands.reject_offer(_add_offer("maceta").uid)
	_commands.accept_offer(kept.uid)
	_commands.cancel_order(kept.uid)
	assert_eq(_state.orders_rng.state, orders_twin.state)
	assert_eq(_state.prints_rng.state, prints_twin.state)


func test_cancel_removes_the_order() -> void:
	var offer: OrderOffer = _add_offer("maceta")
	_commands.accept_offer(offer.uid)
	_sim.changes.clear()
	var result: CommandResult = _commands.cancel_order(offer.uid)
	assert_true(result.ok)
	assert_true(_state.orders.is_empty())
	assert_eq(_sim.changes.removed_orders, [offer.uid] as Array[int])
	assert_eq(_commands.cancel_order(offer.uid).reason, "ERR_ORDER_GONE")


func test_cancel_while_printing_returns_the_unstarted_material() -> void:
	var order: Order = _printing_order(PrintJob.Status.PRINTING)
	assert_eq(_state.spools[0].grams, 2000 - 4 * 220, "Se apartaron las 4 piezas que faltaban")
	assert_true(_commands.cancel_order(order.uid).ok)
	assert_eq(_state.spools[0].grams, 2000 - 220, "La pieza en curso se pierde; las 3 sin empezar vuelven")
	assert_null(_state.printers[0].job)
	assert_true(_sim.changes.spools)
	assert_has(_sim.changes.printers, _state.printers[0].uid)


func test_cancel_after_a_failure_returns_the_unstarted_material() -> void:
	var order: Order = _printing_order(PrintJob.Status.FAILED)
	var job: PrintJob = _state.printers[0].job
	_state.spools[0].grams += job.grams_per_piece - job.lost_grams
	assert_true(_commands.cancel_order(order.uid).ok)
	assert_eq(_state.spools[0].grams, 2000 - job.lost_grams, "Solo se pierde lo que gastó la pieza que falló")
	assert_null(_state.printers[0].job)


func test_cancel_with_finished_pieces_frees_the_printer() -> void:
	var order: Order = _printing_order(PrintJob.Status.DONE)
	order.stage = Order.Stage.PRINTED
	order.pieces_done = 6
	var grams: int = _state.spools[0].grams
	assert_true(_commands.cancel_order(order.uid).ok)
	assert_eq(_state.spools[0].grams, grams, "Las piezas terminadas se descartan")
	assert_null(_state.printers[0].job)


# --- Ayudantes -------------------------------------------------------------


func _new_game(game_seed: int) -> void:
	_state = GameState.new_game(_rules, game_seed)
	_sim = Simulation.new(_state, _rules)
	_commands = GameCommands.new(_sim)


## Avanza hasta que llegan los 3 primeros mensajes y el tablero se pausa.
func _fill_board() -> void:
	_sim.advance_game_seconds(60 + 1620 + 3600)
	assert_eq(_state.offers.size(), 3)
	assert_eq(_state.next_offer_at, -1, "Tablero lleno: en pausa")


## Avanza el tablero `count` mensajes, vaciándolo después de cada uno para que
## nunca se llene. Devuelve los pedidos en orden de llegada.
func _offer_ids(count: int) -> Array[String]:
	var ids: Array[String] = []
	for i: int in count:
		_state.offers.clear()
		_sim.advance_game_seconds(_state.next_offer_at - _state.game_seconds)
		for offer: OrderOffer in _state.offers:
			ids.append(offer.order_id)
	return ids


func _offer_sequence(game_seed: int) -> Array[String]:
	_new_game(game_seed)
	return _offer_ids(30)


func _add_offer(order_id: String) -> OrderOffer:
	var offer: OrderOffer = OrderOffer.new(_state.take_uid(), order_id, _state.game_seconds)
	_state.offers.append(offer)
	return offer


## Un casco de 6 piezas de 220 g en la Cubo Uno, con 2 piezas hechas y la
## tercera en curso. Al empezar se apartaron los gramos de las 4 que faltaban.
func _printing_order(status: PrintJob.Status) -> Order:
	var printer: OwnedPrinter = _state.printers[0]
	var spool: Spool = _state.spools[0]
	spool.grams = 2000 - 4 * 220
	var order: Order = Order.new(_state.take_uid(), "casco_cosplay", _state.game_seconds)
	order.stage = Order.Stage.PRINTING
	order.pieces_done = 2
	order.printer_uid = printer.uid
	_state.orders.append(order)
	var job: PrintJob = PrintJob.new()
	job.order_uid = order.uid
	job.spool_uid = spool.uid
	job.mode_id = "normal"
	job.color_id = spool.color_id
	job.pieces_total = 6
	job.grams_per_piece = 220
	job.piece_seconds = 19800
	job.piece_started_at = _state.game_seconds
	job.ends_at = _state.game_seconds + 6930
	job.fails = true
	job.failure_type = "spaghetti"
	job.lost_grams = 77
	job.status = status
	printer.job = job
	return order


func _twin(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	var twin: RandomNumberGenerator = RandomNumberGenerator.new()
	twin.seed = rng.seed
	twin.state = rng.state
	return twin


func _unique(ids: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for id: String in ids:
		if not result.has(id):
			result.append(id)
	return result
