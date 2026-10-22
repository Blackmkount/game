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


## Retira las piezas terminadas de la impresora: el pedido pasa a embalarse y
## la impresora queda libre.
func remove_pieces(printer_uid: int) -> CommandResult:
	var printer: OwnedPrinter = sim.state.find_printer(printer_uid)
	if printer == null:
		return CommandResult.fail("ERR_PRINTER_GONE")
	if printer.job == null or printer.job.status != PrintJob.Status.DONE:
		return CommandResult.fail("ERR_NOTHING_TO_REMOVE")
	DeliveryFlow.remove(sim, printer)
	sim.mark_dirty()
	return CommandResult.success()


## Embala un pedido con las piezas ya retiradas.
func pack_order(order_uid: int) -> CommandResult:
	var order: Order = sim.state.find_order(order_uid)
	var result: CommandResult = _check_stage(order, Order.Stage.TO_PACK, "ERR_NOTHING_TO_PACK")
	if not result.ok:
		return result
	DeliveryFlow.pack(sim, order)
	sim.mark_dirty()
	return result


## Despacha un pedido embalado: se cobra y se gana experiencia (menos si se
## pasó del plazo). `cents` y `xp` del resultado dicen cuánto.
func dispatch_order(order_uid: int) -> CommandResult:
	var order: Order = sim.state.find_order(order_uid)
	var result: CommandResult = _check_stage(order, Order.Stage.PACKED, "ERR_NOTHING_TO_DISPATCH")
	if not result.ok:
		return result
	var delivery: Delivery = DeliveryFlow.dispatch(sim, order, sim.state.game_seconds)
	result.cents = delivery.cents
	result.xp = delivery.xp
	sim.mark_dirty()
	return result


## Cancela un pedido en cualquier etapa, sin castigo: solo se pierde el
## material que ya se usó.
func cancel_order(order_uid: int) -> CommandResult:
	var order: Order = sim.state.find_order(order_uid)
	if order == null:
		return CommandResult.fail("ERR_ORDER_GONE")
	DeliveryFlow.cancel(sim, order, sim.state.game_seconds)
	sim.mark_dirty()
	return CommandResult.success()


## Ferretería: compra un carrete de ese material al instante, más caro que la
## tienda. `uid` del resultado es el del carrete nuevo.
func buy_local_material(material_id: String) -> CommandResult:
	var result: CommandResult = LocalStore.check_buy(sim.state, sim.rules, material_id)
	if not result.ok:
		return result
	result.uid = LocalStore.buy(sim, material_id).uid
	sim.mark_dirty()
	return result


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


## El pedido existe y está en la etapa `stage`; si no, falla con `reason_key`.
static func _check_stage(order: Order, stage: Order.Stage, reason_key: String) -> CommandResult:
	if order == null:
		return CommandResult.fail("ERR_ORDER_GONE")
	if order.stage != stage:
		return CommandResult.fail(reason_key)
	return CommandResult.success()
