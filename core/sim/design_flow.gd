class_name DesignFlow
extends RefCounted
## Modelado en el computador. Empieza solo al aceptar un pedido, se modela un
## pedido a la vez, en fila por orden de uid, y corre en paralelo con las
## impresoras. "Concentrarse" (una vez por pedido) acorta lo que falta.


## Si el computador está libre, empieza a modelar el pedido en espera de menor
## uid, desde el segundo `t`.
static func start_next(sim: Simulation, t: int) -> void:
	var state: GameState = sim.state
	if state.designing_uid != -1:
		return
	for order: Order in state.orders:
		if order.stage == Order.Stage.WAITING_DESIGN:
			order.stage = Order.Stage.DESIGNING
			order.design_ends_at = t + sim.rules.design_seconds[order.order_id]
			state.designing_uid = order.uid
			sim.changes.computer = true
			sim.changes.add_order(order.uid)
			return


## Evento del computador en el segundo `t`: el modelo está listo para imprimir
## y empieza el siguiente de la fila en el mismo segundo.
static func on_design_end(sim: Simulation, order: Order, t: int) -> void:
	order.stage = Order.Stage.READY_TO_PRINT
	order.design_ends_at = -1
	sim.state.designing_uid = -1
	sim.changes.computer = true
	sim.changes.add_order(order.uid)
	start_next(sim, t)


## Revisa si se puede usar "Concentrarse" en el pedido. El primer problema gana.
static func check_focus(state: GameState, order_uid: int) -> CommandResult:
	var order: Order = state.find_order(order_uid)
	if order == null:
		return CommandResult.fail("ERR_ORDER_GONE")
	if order.stage != Order.Stage.DESIGNING:
		return CommandResult.fail("ERR_NOT_DESIGNING")
	if order.focused:
		return CommandResult.fail("ERR_ALREADY_FOCUSED")
	return CommandResult.success()


## "Concentrarse": lo que falta del modelado se multiplica por
## focus_multiplier (redondeado hacia arriba, nunca menos de 1 segundo).
static func focus(sim: Simulation, order: Order, now: int) -> void:
	var left: int = order.design_ends_at - now
	order.design_ends_at = now + maxi(1, ceili(left * sim.rules.focus_multiplier))
	order.focused = true
	sim.changes.computer = true
	sim.changes.add_order(order.uid)
