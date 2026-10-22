extends GutTest
## El autoload Game: los comandos del jugador, embalar y despachar todo, los
## avisos de Events después de cada comando y de cada avance (en un orden
## fijo), los avisos del reloj y la partida nueva.

const SEED: int = 1234
## uid que no existe en la partida, para avisos armados a mano.
const GONE_UID: int = 9000

## Nombres de las señales de Events en el orden en que llegaron.
var _heard: Array[String] = []
var _listeners: Dictionary[String, Callable] = {}
var _previous_processing: bool
var _rejects: Array[CommandResult] = []


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	_heard.clear()
	_rejects.clear()
	for info: Dictionary in (Events.get_script() as Script).get_script_signal_list():
		var signal_name: String = info["name"]
		# Se descartan los argumentos de la señal y queda solo su nombre.
		var listener: Callable = _hear.bind(signal_name)
		var arg_count: int = (info["args"] as Array).size()
		if arg_count > 0:
			listener = listener.unbind(arg_count)
		Events.connect(signal_name, listener)
		_listeners[signal_name] = listener
	watch_signals(Events)


func after_each() -> void:
	for signal_name: String in _listeners:
		Events.disconnect(signal_name, _listeners[signal_name])
	_listeners.clear()
	if Events.offer_arrived.is_connected(_reject_arrived):
		Events.offer_arrived.disconnect(_reject_arrived)
	Game.set_process(_previous_processing)


func test_a_whole_order_through_the_game_commands() -> void:
	Game.advance(3.0)
	var offer: OrderOffer = Game.state.offers[0]
	assert_signal_emitted_with_parameters(Events, "offer_arrived", [offer.uid])
	var order: Order = _accept(offer.uid)
	assert_true(Game.sim.changes.is_empty(), "Game avisa apenas termina el comando")
	assert_signal_emitted(Events, "computer_changed")
	assert_signal_emitted_with_parameters(Events, "order_changed", [order.uid])
	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	assert_true(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	assert_signal_emitted(Events, "spools_changed")
	assert_signal_emitted_with_parameters(Events, "printer_changed", [plan.printer_uid])
	_advance_until(func() -> bool: return order.stage == Order.Stage.PRINTED)
	assert_true(Game.remove_pieces(plan.printer_uid).ok)
	assert_eq(order.stage, Order.Stage.TO_PACK)
	assert_true(Game.pack_order(order.uid).ok)
	assert_eq(order.stage, Order.Stage.PACKED)
	var money: int = Game.state.money_cents
	var dispatched: CommandResult = Game.dispatch_order(order.uid)
	assert_true(dispatched.ok, dispatched.reason)
	var cents: int = Game.rules.payment_cents["llavero"]
	var xp: int = int(Game.rules.orders["llavero"]["xp"])
	assert_eq(dispatched.cents, cents)
	assert_eq(dispatched.xp, xp)
	assert_eq(Game.state.money_cents, money + cents)
	assert_signal_emitted_with_parameters(Events, "order_delivered", [order.uid, "llavero", cents, xp, false])
	assert_signal_emitted_with_parameters(Events, "money_changed", [money + cents])
	assert_signal_emitted_with_parameters(Events, "xp_changed", [xp])
	assert_signal_emitted_with_parameters(Events, "order_removed", [order.uid])
	assert_null(Game.state.find_order(order.uid))


func test_reject_focus_and_cancel_through_game() -> void:
	Game.advance(3.0)
	var rejected: OrderOffer = Game.state.offers[0]
	assert_true(Game.reject_offer(rejected.uid).ok)
	assert_null(Game.state.find_offer(rejected.uid))
	assert_signal_emitted(Events, "offers_changed")
	var order: Order = _accept(_add_offer("llavero"))
	assert_true(Game.focus_design(order.uid).ok)
	assert_true(order.focused)
	assert_true(Game.cancel_order(order.uid).ok)
	assert_null(Game.state.find_order(order.uid))
	assert_signal_emitted_with_parameters(Events, "order_removed", [order.uid])
	assert_eq(Game.state.designing_uid, -1, "El computador queda libre")


func test_a_failed_piece_is_retried_or_cleaned_through_game() -> void:
	Game.advance(3.0)
	var order: Order = _accept(Game.state.offers[0].uid)
	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	var printer: OwnedPrinter = Game.state.find_printer(plan.printer_uid)
	assert_true(Game.start_print(order.uid, printer.uid, plan.spool_uid, plan.mode_id).ok)
	_fail_current_piece(printer)
	assert_signal_emitted_with_parameters(Events, "print_failed", [printer.uid, FailureRules.SPAGHETTI])
	var retried: CommandResult = Game.retry_piece(printer.uid, "fine")
	assert_true(retried.ok, retried.reason)
	assert_eq(printer.job.status, PrintJob.Status.PRINTING)
	assert_eq(printer.job.mode_id, "fine")
	_fail_current_piece(printer)
	assert_true(Game.clean_printer(printer.uid).ok)
	assert_null(printer.job)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)


func test_pack_all_and_dispatch_all_add_up_every_order() -> void:
	assert_eq(Game.pack_all().reason, "ERR_NOTHING_TO_PACK")
	assert_eq(Game.dispatch_all().reason, "ERR_NOTHING_TO_DISPATCH")
	Game.advance(3.0)
	var first: Order = _to_pack(Game.state.offers[0].uid)
	var second: Order = _to_pack(_add_offer("llavero"))
	assert_eq(Game.dispatch_all().reason, "ERR_NOTHING_TO_DISPATCH", "Todavía no hay nada embalado")
	var packed: CommandResult = Game.pack_all()
	assert_true(packed.ok, packed.reason)
	assert_eq(packed.count, 2)
	assert_eq(first.stage, Order.Stage.PACKED)
	assert_eq(second.stage, Order.Stage.PACKED)
	assert_eq(Game.pack_all().reason, "ERR_NOTHING_TO_PACK")
	var money: int = Game.state.money_cents
	var dispatched: CommandResult = Game.dispatch_all()
	assert_true(dispatched.ok, dispatched.reason)
	assert_eq(dispatched.count, 2)
	assert_eq(dispatched.cents, 2 * Game.rules.payment_cents["llavero"])
	assert_eq(dispatched.xp, 2 * int(Game.rules.orders["llavero"]["xp"]))
	assert_eq(Game.state.money_cents, money + dispatched.cents)
	assert_eq(Game.state.delivered_total, 2)
	assert_eq(_heard.count("order_delivered"), 2)
	assert_eq(Game.dispatch_all().reason, "ERR_NOTHING_TO_DISPATCH")


func test_signals_come_out_after_each_change_in_a_fixed_order() -> void:
	Game.advance(3.0)
	var order: Order = _accept(Game.state.offers[0].uid)
	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	assert_true(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	assert_true(DebugTools.force_fail(Game.sim, plan.printer_uid, FailureRules.SPAGHETTI))
	var job: PrintJob = Game.state.find_printer(plan.printer_uid).job
	# Hasta justo antes de la falla, en segundos reales enteros.
	var rate: int = Game.rules.game_seconds_per_real_second
	Game.advance(float(floori(float(job.ends_at - Game.state.game_seconds - 1) / rate)))
	assert_eq(job.status, PrintJob.Status.PRINTING)
	assert_true(Game.sim.changes.is_empty())
	# Más cambios en el mismo aviso que la falla, para ver el orden completo.
	var changes: SimChanges = Game.sim.changes
	changes.computer = true
	changes.add_order(order.uid)
	changes.add_order(GONE_UID)
	changes.add_removed(GONE_UID)
	changes.offers = true
	changes.arrived_offers.append(GONE_UID + 1)
	changes.money = true
	changes.xp = true
	changes.deliveries.append(Delivery.new(GONE_UID, "llavero", 0, 0, false, "", Game.state.game_seconds))
	changes.level_up = 2
	_heard.clear()
	Game.advance(1.0)
	assert_eq(job.status, PrintJob.Status.FAILED)
	var flushed: Array = _heard.filter(func(name: String) -> bool: return name != "time_changed" and name != "clock_ticked")
	assert_eq(flushed, [
		"printer_changed", "print_failed", "computer_changed", "order_changed", "order_removed", "offers_changed",
		"offer_arrived", "spools_changed", "money_changed", "xp_changed", "order_delivered", "level_up",
	])
	assert_gt(_heard.find("clock_ticked"), _heard.find("level_up"), "El reloj avisa después de los cambios")
	assert_signal_emitted_with_parameters(Events, "print_failed", [plan.printer_uid, FailureRules.SPAGHETTI])
	assert_eq(get_signal_parameters(Events, "order_changed"), [order.uid], "Un pedido que ya no está solo avisa que se fue")
	assert_true(Game.sim.changes.is_empty())


func test_buying_at_the_local_store_through_game() -> void:
	var money: int = Game.state.money_cents
	var result: CommandResult = Game.buy_local_material("pla")
	assert_true(result.ok, result.reason)
	assert_eq(Game.state.find_spool(result.uid).material_id, "pla")
	assert_true(Game.sim.changes.is_empty(), "Game avisa apenas termina el comando")
	assert_eq(_heard, ["spools_changed", "money_changed"] as Array[String])
	assert_signal_emitted_with_parameters(Events, "money_changed", [money - 2700])


func test_a_listener_that_uses_a_command_loses_no_signal() -> void:
	Events.offer_arrived.connect(_reject_arrived, CONNECT_ONE_SHOT)
	Game.advance(3.0)
	assert_eq(_rejects.size(), 1)
	assert_true(_rejects[0].ok, _rejects[0].reason)
	assert_eq(Game.state.offers.size(), 0)
	assert_eq(_heard.count("offer_arrived"), 1, "Ningún aviso se repite")
	assert_eq(_heard.count("offers_changed"), 2, "Llegó y se rechazó")
	assert_true(Game.sim.changes.is_empty())


func test_a_failed_command_says_why_and_changes_nothing() -> void:
	Game.advance(3.0)
	var before: String = _sorted_json(Game.state)
	_heard.clear()
	var printer_uid: int = Game.state.printers[0].uid
	var spool_uid: int = Game.state.spools[0].uid
	var expected: Dictionary[String, CommandResult] = {
		"ERR_OFFER_GONE accept": Game.accept_offer(GONE_UID),
		"ERR_OFFER_GONE reject": Game.reject_offer(GONE_UID),
		"ERR_ORDER_GONE focus": Game.focus_design(GONE_UID),
		"ERR_ORDER_GONE print": Game.start_print(GONE_UID, printer_uid, spool_uid, "normal"),
		"ERR_NOT_FAILED retry": Game.retry_piece(printer_uid, "normal"),
		"ERR_NOT_FAILED clean": Game.clean_printer(printer_uid),
		"ERR_NOTHING_TO_REMOVE remove": Game.remove_pieces(printer_uid),
		"ERR_ORDER_GONE pack": Game.pack_order(GONE_UID),
		"ERR_ORDER_GONE dispatch": Game.dispatch_order(GONE_UID),
		"ERR_ORDER_GONE cancel": Game.cancel_order(GONE_UID),
		"ERR_NOT_IN_LOCAL_STORE buy": Game.buy_local_material("tpu"),
	}
	for key: String in expected:
		assert_false(expected[key].ok, key)
		assert_eq(expected[key].reason, key.get_slice(" ", 0), key)
	assert_eq(_heard.size(), 0, "Nada que avisar")
	assert_eq(_sorted_json(Game.state), before)


func test_commands_without_a_game_fail_with_a_reason() -> void:
	var saved: GameState = Game.state
	Game.state = null
	var commands: Array[Callable] = [
		Game.accept_offer.bind(1), Game.reject_offer.bind(1), Game.focus_design.bind(1),
		Game.start_print.bind(1, 2, 3, "normal"), Game.retry_piece.bind(2, "normal"), Game.clean_printer.bind(2),
		Game.remove_pieces.bind(2), Game.pack_order.bind(1), Game.dispatch_order.bind(1),
		Game.cancel_order.bind(1), Game.pack_all, Game.dispatch_all, Game.buy_local_material.bind("pla"),
	]
	var reasons: Array[String] = []
	for command: Callable in commands:
		var result: CommandResult = command.call()
		reasons.append(result.reason)
	Game.state = saved
	for reason: String in reasons:
		assert_eq(reason, "ERR_NO_GAME")
	assert_eq(reasons.size(), 13)


func test_reset_game_starts_a_new_game_and_says_so() -> void:
	Game.advance(3.0)
	_accept(Game.state.offers[0].uid)
	Game.reset_game(SEED)
	assert_signal_emitted(Events, "game_loaded")
	assert_eq(_sorted_json(Game.state), _sorted_json(GameState.new_game(Game.rules, SEED)))
	assert_same(Game.sim.state, Game.state)
	assert_same(Game.commands.sim, Game.sim)
	Game.advance(3.0)
	assert_true(Game.accept_offer(Game.state.offers[0].uid).ok, "Los comandos usan la partida nueva")


func test_the_clock_ticks_once_per_real_second_and_the_time_once_per_game_minute() -> void:
	# La partida nueva empieza en un minuto y un segundo real justos.
	var minute: int = floori(Game.state.game_minutes)
	Game.advance(1.0)
	assert_eq(_heard.count("clock_ticked"), 1)
	assert_eq(_heard.count("time_changed"), 1, "La primera vez después de empezar")
	assert_signal_emitted_with_parameters(Events, "clock_ticked", [Game.state.game_seconds])
	Game.advance(0.5)
	assert_eq(_heard.count("clock_ticked"), 1, "Medio segundo real no es un tic")
	Game.advance(0.5)
	assert_eq(_heard.count("clock_ticked"), 2)
	assert_eq(_heard.count("time_changed"), 1, "Sigue el mismo minuto de juego")
	_advance_until(func() -> bool: return floori(Game.state.game_minutes) > minute)
	assert_eq(_heard.count("time_changed"), 2)
	var ticks: int = _heard.count("clock_ticked")
	Game.advance(30.0)
	assert_eq(_heard.count("clock_ticked"), ticks + 1, "Un avance largo avisa una sola vez")


func test_level_uses_the_shared_rule() -> void:
	Game.state.xp = 1000
	assert_eq(Game.level(), OrderQueries.level(Game.state, Game.rules))
	assert_gt(Game.level(), 1)


# --- Ayudas ---------------------------------------------------------------------


func _hear(signal_name: String) -> void:
	_heard.append(signal_name)


func _reject_arrived(offer_uid: int) -> void:
	_rejects.append(Game.reject_offer(offer_uid))


func _accept(offer_uid: int) -> Order:
	var result: CommandResult = Game.accept_offer(offer_uid)
	assert_true(result.ok, result.reason)
	return Game.state.find_order(result.uid)


## Llega a mano un mensaje con ese pedido; devuelve su uid.
func _add_offer(order_id: String) -> int:
	var offer: OrderOffer = OrderOffer.new(Game.state.take_uid(), order_id, Game.state.game_seconds)
	Game.state.offers.append(offer)
	return offer.uid


## Acepta el mensaje y lleva el pedido con comandos de Game hasta embalar:
## modelado, impreso con el plan recomendado y retirado.
func _to_pack(offer_uid: int) -> Order:
	var order: Order = _accept(offer_uid)
	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	assert_true(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	_advance_until(func() -> bool: return order.stage == Order.Stage.PRINTED)
	assert_true(Game.remove_pieces(plan.printer_uid).ok)
	assert_eq(order.stage, Order.Stage.TO_PACK)
	return order


## La pieza en curso de esa impresora falla (a propósito) y se avanza hasta
## que se ve la falla.
func _fail_current_piece(printer: OwnedPrinter) -> void:
	assert_true(DebugTools.force_fail(Game.sim, printer.uid, FailureRules.SPAGHETTI))
	var job: PrintJob = printer.job
	_advance_until(func() -> bool: return job.status == PrintJob.Status.FAILED)


## Avanza de a un segundo real hasta que se cumpla `condition`, con un límite
## para no quedar esperando para siempre.
func _advance_until(condition: Callable, max_real_seconds: int = 120) -> void:
	for i: int in max_real_seconds:
		if condition.call():
			return
		Game.advance(1.0)
	assert_true(condition.call(), "No llegó a tiempo")


func _sorted_json(state: GameState) -> String:
	return JSON.stringify(SaveCodec.encode(state), "", true)
