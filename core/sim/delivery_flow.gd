class_name DeliveryFlow
extends RefCounted
## Del pedido impreso a la puerta: retirar las piezas de la impresora,
## embalarlas en el rincón de despacho y despacharlas. Al despachar se cobra,
## se gana experiencia y se revisa el plazo. También cancelar un pedido en
## cualquier etapa, sin castigo: solo se pierde el material ya usado.


## Retira todas las piezas terminadas de la impresora, ya revisado: el pedido
## pasa a embalarse con el color del carrete y la impresora queda libre.
static func remove(sim: Simulation, printer: OwnedPrinter) -> void:
	var order: Order = sim.state.find_order(printer.job.order_uid)
	order.color_id = printer.job.color_id
	PrintFlow.release(sim, printer, order)
	order.stage = Order.Stage.TO_PACK
	order.printer_uid = -1
	sim.changes.add_order(order.uid)


static func pack(sim: Simulation, order: Order) -> void:
	order.stage = Order.Stage.PACKED
	sim.changes.add_order(order.uid)


## Despacha el pedido embalado en el segundo `t`, ya revisado. Si se pasó del
## plazo, se cobra menos y se gana menos experiencia, pero cuenta igual como
## entregado. Devuelve el registro del despacho.
static func dispatch(sim: Simulation, order: Order, t: int) -> Delivery:
	var state: GameState = sim.state
	var rules: SimRules = sim.rules
	var definition: Dictionary = rules.orders[order.order_id]
	var late: bool = OrderQueries.is_late(state, order)
	var cents: int = OrderQueries.payout_cents(state, rules, order)
	var xp: int = OrderQueries.payout_xp(state, rules, order)
	var level_before: int = OrderQueries.level(state, rules)
	state.money_cents += cents
	state.xp += xp
	var level_after: int = OrderQueries.level(state, rules)
	if level_after > level_before:
		sim.changes.level_up = level_after
	state.delivered_total += 1
	state.delivered_by_order[order.order_id] = state.delivered_by_order.get(order.order_id, 0) + 1
	var thanks_keys: Array = rules.clients[definition["client"]]["thanks_keys"]
	var delivery: Delivery = Delivery.new(order.uid, order.order_id, cents, xp, late,
			thanks_keys[order.uid % thanks_keys.size()], t)
	state.recent_deliveries.push_front(delivery)
	if state.recent_deliveries.size() > GameState.RECENT_DELIVERIES_KEPT:
		state.recent_deliveries.resize(GameState.RECENT_DELIVERIES_KEPT)
	state.orders.erase(order)
	if cents != 0:
		sim.changes.money = true
	if xp != 0:
		sim.changes.xp = true
	sim.changes.deliveries.append(delivery)
	sim.changes.add_removed(order.uid)
	return delivery


## Cancela el pedido en el segundo `t`. Si se estaba modelando, el computador
## sigue con el siguiente de la fila. Si tenía una impresora, la libera: la
## pieza en curso (o la que falló) se pierde, el material apartado para las
## piezas sin empezar vuelve al carrete y las piezas terminadas se descartan.
static func cancel(sim: Simulation, order: Order, t: int) -> void:
	var state: GameState = sim.state
	state.orders.erase(order)
	var printer: OwnedPrinter = OrderQueries.printer_for_order(state, order)
	if printer != null and printer.job != null:
		PrintFlow.release(sim, printer, order)
	if order.stage == Order.Stage.DESIGNING:
		state.designing_uid = -1
		sim.changes.computer = true
		DesignFlow.start_next(sim, t)
	sim.changes.add_removed(order.uid)
