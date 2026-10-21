class_name GameCommands
extends RefCounted
## Comandos del jugador sobre la partida. El autoload Game los envuelve uno a
## uno con el mismo nombre.
##
## Cada comando revisa primero, en un orden fijo (el primer problema gana), y
## solo si todo está bien cambia el estado. Un comando que falla no cambia nada
## y no usa el azar. Todos ocurren en el segundo actual del reloj
## (state.game_seconds), anotan lo que cambió en sim.changes y avisan a la
## simulación (mark_dirty) para que vuelva a buscar el próximo evento.

var sim: Simulation


func _init(p_sim: Simulation) -> void:
	sim = p_sim


## Acepta un mensaje: se vuelve un pedido con el mismo uid y, si el computador
## está libre, se empieza a modelar. Si el tablero estaba lleno, se vuelve a
## esperar el próximo mensaje.
func accept_offer(offer_uid: int) -> CommandResult:
	var state: GameState = sim.state
	var result: CommandResult = OrderBoard.check_accept(state, sim.rules, offer_uid)
	if not result.ok:
		return result
	var t: int = state.game_seconds
	var offer: OrderOffer = state.find_offer(offer_uid)
	state.offers.erase(offer)
	var order: Order = Order.new(offer.uid, offer.order_id, t)
	var deadline: int = sim.rules.deadline_seconds[offer.order_id]
	if deadline > 0:
		order.due_live = state.live_seconds + deadline
	_insert_order(order)
	DesignFlow.start_next(sim, t)
	OrderBoard.resume_if_paused(state, sim.rules, t)
	sim.changes.offers = true
	sim.changes.add_order(order.uid)
	sim.mark_dirty()
	result.uid = order.uid
	return result


## Rechaza un mensaje, sin castigo.
func reject_offer(offer_uid: int) -> CommandResult:
	var state: GameState = sim.state
	var offer: OrderOffer = state.find_offer(offer_uid)
	if offer == null:
		return CommandResult.fail("ERR_OFFER_GONE")
	state.offers.erase(offer)
	OrderBoard.resume_if_paused(state, sim.rules, state.game_seconds)
	sim.changes.offers = true
	sim.mark_dirty()
	return CommandResult.success()


## "Concentrarse" en el pedido que se está modelando (una vez por pedido).
func focus_design(order_uid: int) -> CommandResult:
	var state: GameState = sim.state
	var result: CommandResult = DesignFlow.check_focus(state, order_uid)
	if not result.ok:
		return result
	DesignFlow.focus(sim, state.find_order(order_uid), state.game_seconds)
	sim.mark_dirty()
	return result


## Imprime el pedido con esa impresora, carrete y modo. Revisa con
## PrintRules.check, igual que el plan que ve el jugador, así el motivo de un
## error es el mismo. Aparta el material y empieza la primera pieza.
func start_print(order_uid: int, printer_uid: int, spool_uid: int, mode_id: String) -> CommandResult:
	var state: GameState = sim.state
	var order: Order = state.find_order(order_uid)
	var printer: OwnedPrinter = state.find_printer(printer_uid)
	var spool: Spool = state.find_spool(spool_uid)
	var result: CommandResult = PrintRules.check(state, sim.rules, order, printer, spool, mode_id)
	if not result.ok:
		return result
	PrintFlow.start_job(sim, order, printer, spool, mode_id, state.game_seconds)
	sim.mark_dirty()
	return result


## "Limpiar y reintentar": vuelve a imprimir la pieza que falló, con el modo
## elegido y el mismo carrete. Todo se revisa antes de usar el azar.
func retry_piece(printer_uid: int, mode_id: String) -> CommandResult:
	var state: GameState = sim.state
	var result: CommandResult = PrintFlow.check_retry(state, sim.rules, printer_uid, mode_id)
	if not result.ok:
		return result
	PrintFlow.retry(sim, state.find_printer(printer_uid), mode_id, state.game_seconds)
	sim.mark_dirty()
	return result


## "Limpiar": libera la impresora que falló; el pedido conserva sus piezas
## terminadas y vuelve a esperar una impresora.
func clean_printer(printer_uid: int) -> CommandResult:
	var state: GameState = sim.state
	var result: CommandResult = PrintFlow.check_failed(state, printer_uid)
	if not result.ok:
		return result
	PrintFlow.clean(sim, state.find_printer(printer_uid))
	sim.mark_dirty()
	return result


## Cancela un pedido en cualquier etapa, sin castigo: solo se pierde el
## material que ya se usó. Si se estaba modelando, el computador sigue con el
## siguiente de la fila.
func cancel_order(order_uid: int) -> CommandResult:
	var state: GameState = sim.state
	var order: Order = state.find_order(order_uid)
	if order == null:
		return CommandResult.fail("ERR_ORDER_GONE")
	state.orders.erase(order)
	if order.printer_uid >= 0:
		_release_printer(order)
	if order.stage == Order.Stage.DESIGNING:
		state.designing_uid = -1
		sim.changes.computer = true
		DesignFlow.start_next(sim, state.game_seconds)
	sim.changes.add_removed(order.uid)
	sim.mark_dirty()
	return CommandResult.success()


## Agrega el pedido manteniendo state.orders en orden de uid: se puede aceptar
## un mensaje viejo después de uno nuevo.
func _insert_order(order: Order) -> void:
	var orders: Array[Order] = sim.state.orders
	var index: int = orders.size()
	for i: int in orders.size():
		if orders[i].uid > order.uid:
			index = i
			break
	orders.insert(index, order)


## Libera la impresora de un pedido cancelado. La pieza en curso (o la que
## falló) se pierde; el material apartado para las piezas sin empezar vuelve
## al carrete. Las piezas terminadas se descartan.
func _release_printer(order: Order) -> void:
	var printer: OwnedPrinter = sim.state.find_printer(order.printer_uid)
	if printer == null or printer.job == null:
		return
	PrintFlow.release(sim, printer, order)
