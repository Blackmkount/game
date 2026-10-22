class_name OrderQueries
extends RefCounted
## Consultas de solo lectura sobre los pedidos, para la interfaz y para los
## motivos de error. Son cuentas con los enteros guardados en el estado y
## nunca lo cambian.

## Lo que muestra una impresora. IDLE_READY: está libre y hay un pedido con el
## modelo listo que puede imprimir ahora.
enum PrinterStatus { IDLE, IDLE_READY, PRINTING, DONE, FAILED }
## Lo próximo que conviene hacer en el taller, de lo más urgente a lo menos.
## NONE: no hay nada que hacer mientras se modela o se imprime.
enum NextStep { NONE, FAILED, REMOVE, PACK, DISPATCH, PRINT, MESSAGES, WAIT, NO_MAKEABLE }


static func printer_status(state: GameState, rules: SimRules, printer: OwnedPrinter) -> PrinterStatus:
	var job: PrintJob = printer.job
	if job != null:
		match job.status:
			PrintJob.Status.PRINTING:
				return PrinterStatus.PRINTING
			PrintJob.Status.DONE:
				return PrinterStatus.DONE
		return PrinterStatus.FAILED
	for order: Order in state.orders:
		if order.stage == Order.Stage.READY_TO_PRINT and PrintPlanner.recommend(state, rules, order, printer.uid).ok:
			return PrinterStatus.IDLE_READY
	return PrinterStatus.IDLE


## El primer paso que corresponde, en este orden: una falla, piezas por
## retirar, por embalar, por despachar, un modelo listo con una impresora que
## lo puede tomar, mensajes por responder (si caben más pedidos), esperar a lo
## que está en marcha, nada que se pueda hacer, o esperar mensajes.
static func next_step(state: GameState, rules: SimRules) -> NextStep:
	if _has_job_with(state, PrintJob.Status.FAILED):
		return NextStep.FAILED
	if _has_job_with(state, PrintJob.Status.DONE):
		return NextStep.REMOVE
	if count_stage(state, Order.Stage.TO_PACK) > 0:
		return NextStep.PACK
	if count_stage(state, Order.Stage.PACKED) > 0:
		return NextStep.DISPATCH
	for order: Order in state.orders:
		if order.stage == Order.Stage.READY_TO_PRINT and PrintPlanner.recommend(state, rules, order).ok:
			return NextStep.PRINT
	if not state.offers.is_empty() and state.orders.size() < rules.max_active_orders:
		return NextStep.MESSAGES
	if state.designing_uid >= 0 or _has_job_with(state, PrintJob.Status.PRINTING):
		return NextStep.NONE
	if not OrderBoard.has_makeable(state, rules):
		return NextStep.NO_MAKEABLE
	return NextStep.WAIT


## Número del botón Pedidos: mensajes sin responder, piezas por retirar, por
## embalar y por despachar, fallas por atender y, si hay alguna impresora
## libre, los modelos listos para imprimir.
static func pending_actions(state: GameState, rules: SimRules) -> int:
	var count: int = state.offers.size()
	for stage: Order.Stage in [Order.Stage.PRINTED, Order.Stage.TO_PACK, Order.Stage.PACKED]:
		count += count_stage(state, stage)
	for printer: OwnedPrinter in state.printers:
		if printer.job != null and printer.job.status == PrintJob.Status.FAILED:
			count += 1
	if _has_free_printer(state):
		count += count_stage(state, Order.Stage.READY_TO_PRINT)
	return count


## Paso del pedido entre los 6 del ciclo (1 es el mensaje).
static func step_index(order: Order) -> int:
	match order.stage:
		Order.Stage.WAITING_DESIGN, Order.Stage.DESIGNING:
			return 2
		Order.Stage.READY_TO_PRINT, Order.Stage.PRINTING:
			return 3
		Order.Stage.PRINTED:
			return 4
		Order.Stage.TO_PACK:
			return 5
	return 6


## Segundos de juego que faltan para terminar todas las piezas del trabajo.
## Es el tiempo nominal: nunca adelanta una falla que todavía no ocurre.
static func order_seconds_left(job: PrintJob, order: Order, now: int) -> int:
	var current_piece: int = maxi(0, job.piece_started_at + job.piece_seconds - now)
	return current_piece + (job.pieces_total - order.pieces_done - 1) * job.piece_seconds


## Segundos de juego que faltan para terminar de modelar; 0 si no se está
## modelando.
static func design_seconds_left(order: Order, now: int) -> int:
	return maxi(0, order.design_ends_at - now)


## Avance del modelado entre 0 y 1: 0 mientras espera en la fila y 1 cuando ya
## está listo.
static func design_progress(order: Order, rules: SimRules, now: int) -> float:
	if order.stage == Order.Stage.WAITING_DESIGN:
		return 0.0
	var total: int = rules.design_seconds[order.order_id]
	return clampf(1.0 - float(design_seconds_left(order, now)) / float(total), 0.0, 1.0)


## Segundos de juego hasta que el computador empieza a modelar el pedido: lo
## que le falta al modelado en curso más los pedidos que van antes en la fila.
## 0 si el pedido no está esperando.
static func queue_wait_seconds(state: GameState, rules: SimRules, order: Order, now: int) -> int:
	if order.stage != Order.Stage.WAITING_DESIGN:
		return 0
	var wait: int = 0
	for other: Order in state.orders:
		if other.stage == Order.Stage.DESIGNING:
			wait += design_seconds_left(other, now)
		elif other.stage == Order.Stage.WAITING_DESIGN and other.uid < order.uid:
			wait += rules.design_seconds[other.order_id]
	return wait


## Segundo de juego del plazo según el reloj de ahora, o -1 sin plazo. El
## plazo corre en live_seconds, así que se corre con el tiempo fuera del juego.
static func due_game_seconds(state: GameState, order: Order) -> int:
	if order.due_live < 0:
		return -1
	return state.game_seconds + order.due_live - state.live_seconds


static func is_late(state: GameState, order: Order) -> bool:
	return order.due_live >= 0 and state.live_seconds > order.due_live


## Lo que se cobra al despachar el pedido ahora, en centavos: la mitad (según
## late_delivery) si va atrasado.
static func payout_cents(state: GameState, rules: SimRules, order: Order) -> int:
	return roundi(rules.payment_cents[order.order_id] * (rules.late_payment_multiplier if is_late(state, order) else 1.0))


## La experiencia que da despachar el pedido ahora: menos (o nada) si va atrasado.
static func payout_xp(state: GameState, rules: SimRules, order: Order) -> int:
	return roundi(int(rules.orders[order.order_id]["xp"]) * (rules.late_xp_multiplier if is_late(state, order) else 1.0))


## Segundos de juego hasta el próximo mensaje, o -1 con el tablero en pausa.
static func seconds_to_next_offer(state: GameState) -> int:
	if state.next_offer_at < 0:
		return -1
	return maxi(0, state.next_offer_at - state.game_seconds)


## Se puede usar "Concentrarse": se está modelando, no se usó todavía y el
## balance lo tiene encendido.
static func focus_available(order: Order, rules: SimRules) -> bool:
	return order.stage == Order.Stage.DESIGNING and not order.focused and rules.focus_multiplier < 1.0


## Impresora que imprime o guarda las piezas del pedido, o null.
static func printer_for_order(state: GameState, order: Order) -> OwnedPrinter:
	if order.printer_uid < 0:
		return null
	return state.find_printer(order.printer_uid)


static func level(state: GameState, rules: SimRules) -> int:
	return rules.levels.level_for_xp(state.xp)


## Cuántos pedidos están en esa etapa.
static func count_stage(state: GameState, stage: Order.Stage) -> int:
	var count: int = 0
	for order: Order in state.orders:
		if order.stage == stage:
			count += 1
	return count


static func _has_job_with(state: GameState, status: PrintJob.Status) -> bool:
	for printer: OwnedPrinter in state.printers:
		if printer.job != null and printer.job.status == status:
			return true
	return false


static func _has_free_printer(state: GameState) -> bool:
	for printer: OwnedPrinter in state.printers:
		if printer.job == null:
			return true
	return false
