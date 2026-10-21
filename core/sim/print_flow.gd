class_name PrintFlow
extends RefCounted
## Impresión de un pedido en una impresora. Las piezas salen una tras otra sin
## tocar nada, y al empezar cada pieza ya se decide si va a fallar y en qué
## punto (FailureRules), así el avance del tiempo solo compara enteros.
##
## El material se aparta al tocar Imprimir: salen del carrete los gramos de
## todas las piezas que faltan, así ninguna pieza se queda esperando material.
## Si una pieza falla, vuelve al carrete lo que no se gastó de esa pieza. Al
## limpiar o cancelar vuelve lo apartado para las piezas sin empezar.


## Empieza a imprimir el pedido en el segundo `t`. La combinación ya se revisó
## con PrintRules.check: aparta el material, arma el trabajo con el color del
## carrete y empieza la primera pieza que falta.
static func start_job(sim: Simulation, order: Order, printer: OwnedPrinter, spool: Spool, mode_id: String, t: int) -> void:
	var rules: SimRules = sim.rules
	var job: PrintJob = PrintJob.new()
	job.order_uid = order.uid
	job.spool_uid = spool.uid
	job.mode_id = mode_id
	job.color_id = spool.color_id
	job.pieces_total = int(rules.orders[order.order_id]["pieces"])
	job.grams_per_piece = rules.order_grams[order.order_id]
	job.piece_seconds = PrintRules.piece_seconds(rules, order.order_id, printer.printer_id, spool.material_id, mode_id)
	spool.grams -= PrintRules.pieces_left(rules, order) * job.grams_per_piece
	printer.job = job
	order.stage = Order.Stage.PRINTING
	order.printer_uid = printer.uid
	sim.changes.spools = true
	sim.changes.add_printer(printer.uid)
	sim.changes.add_order(order.uid)
	start_piece(sim, printer, t)


## Empieza la pieza siguiente del trabajo en el segundo `t` y decide ya si va a
## fallar. Las primeras piezas de la partida (grace_pieces) nunca fallan, pero
## igual usan sus dos números del azar.
static func start_piece(sim: Simulation, printer: OwnedPrinter, t: int) -> void:
	var state: GameState = sim.state
	var job: PrintJob = printer.job
	var graced: bool = state.pieces_started < sim.rules.grace_pieces
	state.pieces_started += 1
	var material_id: String = state.find_spool(job.spool_uid).material_id
	var piece_chances: Vector2 = FailureRules.chances(state, sim.rules, printer, material_id, job.mode_id)
	FailureRules.roll_into(job, state.prints_rng, piece_chances, graced, sim.rules, t)


## Evento de la impresora en el segundo `t`: termina (o falla) la pieza en
## curso. Si falla, el trabajo se detiene y vuelve al carrete lo que no se
## gastó de esa pieza. Si sale bien y quedan piezas, la siguiente empieza en el
## mismo segundo; si era la última, las piezas esperan en la impresora hasta
## que se retiren.
static func on_piece_end(sim: Simulation, printer: OwnedPrinter, t: int) -> void:
	var job: PrintJob = printer.job
	var order: Order = sim.state.find_order(job.order_uid)
	sim.changes.add_printer(printer.uid)
	sim.changes.add_order(order.uid)
	if job.fails:
		job.status = PrintJob.Status.FAILED
		sim.state.find_spool(job.spool_uid).grams += job.grams_per_piece - job.lost_grams
		sim.changes.spools = true
		sim.changes.failures.append(printer.uid)
		return
	order.pieces_done += 1
	if order.pieces_done < job.pieces_total:
		start_piece(sim, printer, t)
	else:
		job.status = PrintJob.Status.DONE
		order.stage = Order.Stage.PRINTED


## La impresora existe y tiene una pieza que falló (para limpiar o reintentar).
static func check_failed(state: GameState, printer_uid: int) -> CommandResult:
	var printer: OwnedPrinter = state.find_printer(printer_uid)
	if printer == null:
		return CommandResult.fail("ERR_PRINTER_GONE")
	if printer.job == null or printer.job.status != PrintJob.Status.FAILED:
		return CommandResult.fail("ERR_NOT_FAILED")
	return CommandResult.success()


## Revisa si se puede reintentar la pieza que falló con ese modo: con el
## carrete del trabajo y para una sola pieza, la que falló. El primer problema
## gana.
static func check_retry(state: GameState, rules: SimRules, printer_uid: int, mode_id: String) -> CommandResult:
	var result: CommandResult = check_failed(state, printer_uid)
	if not result.ok:
		return result
	var printer: OwnedPrinter = state.find_printer(printer_uid)
	var job: PrintJob = printer.job
	var order_id: String = state.find_order(job.order_uid).order_id
	return PrintRules.check_setup(rules, order_id, printer.printer_id, state.find_spool(job.spool_uid), mode_id, 1)


## "Limpiar y reintentar" en el segundo `t`, ya revisado con check_retry:
## vuelve a apartar el material de la pieza que falló y la empieza de nuevo con
## el modo elegido, que sigue para las piezas que faltan. Las piezas
## terminadas se conservan.
static func retry(sim: Simulation, printer: OwnedPrinter, mode_id: String, t: int) -> void:
	var job: PrintJob = printer.job
	var order: Order = sim.state.find_order(job.order_uid)
	var spool: Spool = sim.state.find_spool(job.spool_uid)
	spool.grams -= job.grams_per_piece
	job.mode_id = mode_id
	job.piece_seconds = PrintRules.piece_seconds(sim.rules, order.order_id, printer.printer_id, spool.material_id, mode_id)
	job.status = PrintJob.Status.PRINTING
	sim.changes.spools = true
	sim.changes.add_printer(printer.uid)
	sim.changes.add_order(order.uid)
	start_piece(sim, printer, t)


## "Limpiar", ya revisado con check_failed: la impresora queda libre y el
## pedido vuelve a tener el modelo listo para imprimir, con sus piezas
## terminadas. Se puede elegir otra impresora o carrete.
static func clean(sim: Simulation, printer: OwnedPrinter) -> void:
	var order: Order = sim.state.find_order(printer.job.order_uid)
	release(sim, printer, order)
	order.stage = Order.Stage.READY_TO_PRINT
	order.printer_uid = -1
	sim.changes.add_order(order.uid)


## Saca el trabajo de la impresora. Si no terminó, vuelve al carrete el
## material apartado para las piezas sin empezar; la pieza en curso (o la que
## falló) no vuelve. No toca las piezas terminadas ni la etapa del pedido.
static func release(sim: Simulation, printer: OwnedPrinter, order: Order) -> void:
	var job: PrintJob = printer.job
	if job.status != PrintJob.Status.DONE:
		sim.state.find_spool(job.spool_uid).grams += (job.pieces_total - order.pieces_done - 1) * job.grams_per_piece
		sim.changes.spools = true
	printer.job = null
	sim.changes.add_printer(printer.uid)
