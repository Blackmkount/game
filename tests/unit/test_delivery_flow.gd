extends GutTest
## Del pedido impreso a la puerta: retirar las piezas, embalar y despachar
## (cobro, plazo, experiencia, nivel y agradecimiento), y cancelar en cada
## etapa. Ninguno de estos comandos usa el azar.

var _rules: SimRules
var _sim: Simulation
var _state: GameState
var _commands: GameCommands


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	# Estas pruebas no son de fallas: las piezas salen bien salvo que se fuerce.
	_rules.grace_pieces = 1000
	_sim = SimFixtures.new_sim(_rules)
	_state = _sim.state
	_commands = GameCommands.new(_sim)
	SimFixtures.quiet_board(_state)


# --- Retirar ---------------------------------------------------------------


func test_remove_sends_the_pieces_to_packing_and_frees_the_printer() -> void:
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTED)
	var cubo: OwnedPrinter = _state.printers[0]
	var grams: int = _state.spools[0].grams
	var twins: Array[RandomNumberGenerator] = _twins()
	_sim.changes.clear()
	var result: CommandResult = _commands.remove_pieces(cubo.uid)
	assert_true(result.ok, result.reason)
	assert_eq(order.stage, Order.Stage.TO_PACK)
	assert_eq(order.color_id, "blanco", "Las piezas tienen el color del carrete")
	assert_eq(order.printer_uid, -1)
	assert_eq(order.pieces_done, 1)
	assert_null(cubo.job, "La impresora queda libre")
	assert_eq(_state.spools[0].grams, grams, "Retirar no devuelve material")
	assert_has(_sim.changes.printers, cubo.uid)
	assert_has(_sim.changes.orders, order.uid)
	assert_false(_sim.changes.spools)
	_assert_no_draws(twins)


func test_finished_pieces_keep_the_printer_until_they_are_removed() -> void:
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTED)
	var cubo: OwnedPrinter = _state.printers[0]
	var next: Order = SimFixtures.order_at(_sim, "maceta", Order.Stage.READY_TO_PRINT)
	var pla: Spool = _state.spools[0]
	assert_eq(_commands.start_print(next.uid, cubo.uid, pla.uid, "normal").reason, "ERR_PRINTER_DONE")
	assert_true(_commands.remove_pieces(cubo.uid).ok)
	assert_eq(order.stage, Order.Stage.TO_PACK)
	assert_true(_commands.start_print(next.uid, cubo.uid, pla.uid, "normal").ok, "Ya se puede imprimir otro pedido")
	assert_eq(cubo.job.order_uid, next.uid)


func test_remove_needs_finished_pieces() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	assert_eq(_commands.remove_pieces(999).reason, "ERR_PRINTER_GONE")
	assert_eq(_commands.remove_pieces(cubo.uid).reason, "ERR_NOTHING_TO_REMOVE", "Impresora libre")
	SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTING)
	_assert_refused_without_changes(_commands.remove_pieces.bind(cubo.uid), "ERR_NOTHING_TO_REMOVE", "Todavía imprime")
	DebugTools.force_fail(_sim, cubo.uid, FailureRules.SPAGHETTI)
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	assert_eq(cubo.job.status, PrintJob.Status.FAILED)
	_assert_refused_without_changes(_commands.remove_pieces.bind(cubo.uid), "ERR_NOTHING_TO_REMOVE", "Falló")


# --- Embalar ---------------------------------------------------------------


func test_pack_closes_the_box() -> void:
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.TO_PACK)
	var twins: Array[RandomNumberGenerator] = _twins()
	_sim.changes.clear()
	assert_true(_commands.pack_order(order.uid).ok)
	assert_eq(order.stage, Order.Stage.PACKED)
	assert_has(_sim.changes.orders, order.uid)
	_assert_no_draws(twins)


func test_pack_needs_pieces_waiting_to_be_packed() -> void:
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.TO_PACK)
	var designing: Order = SimFixtures.accept(_sim, "maceta")
	_assert_refused_without_changes(_commands.pack_order.bind(999), "ERR_ORDER_GONE")
	_assert_refused_without_changes(_commands.pack_order.bind(designing.uid), "ERR_NOTHING_TO_PACK", "Se está modelando")
	assert_true(_commands.pack_order(order.uid).ok)
	_assert_refused_without_changes(_commands.pack_order.bind(order.uid), "ERR_NOTHING_TO_PACK", "Ya está embalado")


# --- Despachar -------------------------------------------------------------


func test_dispatch_pays_and_counts_the_delivery() -> void:
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	var money: int = _state.money_cents
	var twins: Array[RandomNumberGenerator] = _twins()
	_sim.changes.clear()
	var result: CommandResult = _commands.dispatch_order(order.uid)
	assert_true(result.ok, result.reason)
	assert_eq(result.cents, 600)
	assert_eq(result.xp, 5)
	assert_eq(_state.money_cents, money + 600)
	assert_eq(_state.xp, 5)
	assert_null(_state.find_order(order.uid), "El pedido se fue por la puerta")
	assert_eq(_state.delivered_total, 1)
	assert_eq(_state.delivered_by_order.size(), 1)
	assert_eq(_state.delivered_by_order["llavero"], 1)
	assert_eq(_state.recent_deliveries.size(), 1)
	var delivery: Delivery = _state.recent_deliveries[0]
	assert_eq(delivery.order_uid, order.uid)
	assert_eq(delivery.order_id, "llavero")
	assert_eq(delivery.cents, 600)
	assert_eq(delivery.xp, 5)
	assert_false(delivery.late)
	assert_eq(delivery.delivered_at, _state.game_seconds)
	assert_true(_sim.changes.money)
	assert_true(_sim.changes.xp)
	assert_eq(_sim.changes.deliveries, [delivery] as Array[Delivery])
	assert_has(_sim.changes.removed_orders, order.uid)
	assert_eq(_sim.changes.level_up, 0, "5 XP no alcanzan para el nivel 2")
	_assert_no_draws(twins)


func test_dispatch_needs_a_packed_order() -> void:
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.TO_PACK)
	_assert_refused_without_changes(_commands.dispatch_order.bind(999), "ERR_ORDER_GONE")
	_assert_refused_without_changes(_commands.dispatch_order.bind(order.uid), "ERR_NOTHING_TO_DISPATCH", "Falta embalar")
	assert_true(_commands.pack_order(order.uid).ok)
	assert_true(_commands.dispatch_order(order.uid).ok)
	_assert_refused_without_changes(_commands.dispatch_order.bind(order.uid), "ERR_ORDER_GONE", "Ya se despachó")


func test_late_dispatch_pays_half_and_no_xp_but_still_counts() -> void:
	SimFixtures.add_spool(_state, "petg", 1000)
	var order: Order = SimFixtures.order_at(_sim, "perilla", Order.Stage.PACKED)
	assert_gt(order.due_live, 0, "La perilla tiene plazo")
	_sim.advance_game_seconds(order.due_live - _state.live_seconds + 1)
	var money: int = _state.money_cents
	_sim.changes.clear()
	var result: CommandResult = _commands.dispatch_order(order.uid)
	assert_eq(result.cents, 900, "La mitad de $18")
	assert_eq(result.xp, 0)
	assert_eq(_state.money_cents, money + 900)
	assert_eq(_state.xp, 0)
	assert_true(_state.recent_deliveries[0].late)
	assert_eq(_state.delivered_total, 1, "Igual cuenta como entregado")
	assert_eq(_state.delivered_by_order["perilla"], 1)
	assert_false(_sim.changes.xp, "La experiencia no cambió")


func test_the_deadline_runs_only_while_playing() -> void:
	SimFixtures.add_spool(_state, "petg", 1000)
	var order: Order = SimFixtures.order_at(_sim, "perilla", Order.Stage.PACKED)
	_sim.advance_game_seconds(order.due_live - _state.live_seconds)
	_sim.advance_game_seconds(10 * GameClock.SECONDS_PER_DAY, false)
	assert_eq(_state.live_seconds, order.due_live, "Justo en el plazo, y el tiempo fuera del juego no cuenta")
	var result: CommandResult = _commands.dispatch_order(order.uid)
	assert_eq(result.cents, 1800, "A tiempo: el pago completo")
	assert_eq(result.xp, 15)
	assert_false(_state.recent_deliveries[0].late)


func test_recent_deliveries_keep_the_last_five_newest_first() -> void:
	var uids: Array[int] = []
	for i: int in 6:
		var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
		assert_true(_commands.dispatch_order(order.uid).ok)
		uids.append(order.uid)
	assert_eq(_state.delivered_total, 6)
	assert_eq(_state.delivered_by_order["llavero"], 6)
	var kept: Array[int] = []
	for delivery: Delivery in _state.recent_deliveries:
		kept.append(delivery.order_uid)
	uids.reverse()
	assert_eq(kept, uids.slice(0, GameState.RECENT_DELIVERIES_KEPT), "Los 5 últimos, el más nuevo primero")


func test_thanks_text_alternates_with_the_order_uid() -> void:
	var keys: Array = _rules.clients["amigos"]["thanks_keys"]
	var first: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	var second: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	assert_eq(second.uid, first.uid + 1)
	assert_true(_commands.dispatch_order(first.uid).ok)
	assert_true(_commands.dispatch_order(second.uid).ok)
	assert_eq(_state.recent_deliveries[1].thanks_key, keys[first.uid % keys.size()])
	assert_eq(_state.recent_deliveries[0].thanks_key, keys[second.uid % keys.size()])
	assert_ne(_state.recent_deliveries[0].thanks_key, _state.recent_deliveries[1].thanks_key)


func test_reaching_100_xp_levels_up() -> void:
	_state.xp = 95
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	_sim.changes.clear()
	assert_true(_commands.dispatch_order(order.uid).ok)
	assert_eq(_state.xp, 100)
	assert_eq(_sim.changes.level_up, 2)
	assert_eq(OrderQueries.level(_state, _rules), 2)


# --- Cancelar --------------------------------------------------------------


func test_cancel_before_printing_only_removes_the_order() -> void:
	var designing: Order = SimFixtures.accept(_sim, "llavero")
	var waiting: Order = SimFixtures.accept(_sim, "maceta")
	var last: Order = SimFixtures.accept(_sim, "soporte_celular")
	var grams: int = _state.total_grams()
	var twins: Array[RandomNumberGenerator] = _twins()

	_sim.changes.clear()
	assert_true(_commands.cancel_order(waiting.uid).ok, "En la fila del computador")
	assert_eq(_sim.changes.removed_orders, [waiting.uid] as Array[int])
	assert_eq(_state.designing_uid, designing.uid, "El modelado en curso sigue")

	_sim.advance_game_seconds(100)
	_sim.changes.clear()
	assert_true(_commands.cancel_order(designing.uid).ok, "Modelándose")
	assert_eq(_state.designing_uid, last.uid, "El siguiente de la fila empieza ahora")
	assert_eq(last.stage, Order.Stage.DESIGNING)
	assert_eq(last.design_ends_at, _state.game_seconds + _rules.design_seconds["soporte_celular"])
	assert_true(_sim.changes.computer)

	SimFixtures.finish_designs(_sim)
	assert_eq(last.stage, Order.Stage.READY_TO_PRINT)
	assert_true(_commands.cancel_order(last.uid).ok, "Con el modelo listo")
	assert_true(_state.orders.is_empty())
	assert_eq(_state.designing_uid, -1)
	assert_eq(_state.total_grams(), grams, "Sin imprimir no se pierde material")
	_assert_no_draws(twins)


func test_cancel_on_a_printer_returns_the_unstarted_material_and_frees_it() -> void:
	var petg: Spool = SimFixtures.add_spool(_state, "petg", 1000)
	var cubo: OwnedPrinter = _state.printers[0]
	# Perilla: 2 piezas de 15 g de PETG en la Cubo Uno.
	var printing: Order = SimFixtures.order_at(_sim, "perilla", Order.Stage.PRINTING)
	assert_eq(petg.grams, 970, "Se apartaron las 2 piezas")
	_sim.changes.clear()
	assert_true(_commands.cancel_order(printing.uid).ok)
	assert_eq(petg.grams, 985, "La pieza en curso se pierde; la otra vuelve")
	assert_null(cubo.job)
	assert_has(_sim.changes.printers, cubo.uid)
	assert_true(_sim.changes.spools)

	var failed: Order = SimFixtures.order_at(_sim, "perilla", Order.Stage.PRINTING)
	DebugTools.force_fail(_sim, cubo.uid, FailureRules.WARPING, 0.2)
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	var lost: int = cubo.job.lost_grams
	assert_eq(petg.grams, 985 - 30 + 15 - lost, "Volvió lo que no gastó la pieza que falló")
	assert_true(_commands.cancel_order(failed.uid).ok)
	assert_eq(petg.grams, 985 - lost, "Y ahora la pieza sin empezar")
	assert_null(cubo.job)

	var printed: Order = SimFixtures.order_at(_sim, "perilla", Order.Stage.PRINTED)
	var grams: int = petg.grams
	assert_true(_commands.cancel_order(printed.uid).ok)
	assert_eq(petg.grams, grams, "Las piezas terminadas se descartan")
	assert_null(cubo.job, "La impresora queda libre")
	assert_true(_state.orders.is_empty())


func test_cancel_after_removing_the_pieces() -> void:
	var to_pack: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.TO_PACK)
	var packed: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	var grams: int = _state.total_grams()
	var money: int = _state.money_cents
	assert_true(_commands.cancel_order(to_pack.uid).ok)
	assert_true(_commands.cancel_order(packed.uid).ok)
	assert_true(_state.orders.is_empty())
	assert_eq(_state.total_grams(), grams)
	assert_eq(_state.money_cents, money, "Cancelar no cuesta dinero")
	assert_eq(_state.delivered_total, 0)
	_assert_refused_without_changes(_commands.cancel_order.bind(packed.uid), "ERR_ORDER_GONE")


# --- Ayudantes -------------------------------------------------------------


## El comando falla con ese motivo y no cambia nada: ni el estado, ni el
## azar, ni los cambios anotados.
func _assert_refused_without_changes(command: Callable, reason: String, text: String = "") -> void:
	var before: String = _json()
	var twins: Array[RandomNumberGenerator] = _twins()
	_sim.changes.clear()
	var result: CommandResult = command.call()
	assert_false(result.ok, text)
	assert_eq(result.reason, reason, text)
	assert_eq(_json(), before, text)
	assert_true(_sim.changes.is_empty(), text)
	_assert_no_draws(twins)


## Copias de los dos flujos de azar, para ver después que no se usaron.
func _twins() -> Array[RandomNumberGenerator]:
	var twins: Array[RandomNumberGenerator] = []
	for rng: RandomNumberGenerator in [_state.orders_rng, _state.prints_rng]:
		var twin: RandomNumberGenerator = RandomNumberGenerator.new()
		twin.seed = rng.seed
		twin.state = rng.state
		twins.append(twin)
	return twins


func _assert_no_draws(twins: Array[RandomNumberGenerator]) -> void:
	assert_eq(_state.orders_rng.state, twins[0].state, "No usa el azar del tablero")
	assert_eq(_state.prints_rng.state, twins[1].state, "No usa el azar de los fallos")


func _json() -> String:
	return JSON.stringify(SaveCodec.encode(_state), "", true)
