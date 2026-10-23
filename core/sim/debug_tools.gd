class_name DebugTools
extends RefCounted
## Herramientas para las pruebas, las capturas y el panel de depuración:
## fuerzan situaciones que el azar solo da a veces. Nunca usan el azar.

## El taller lleno (fill_workshop): una estantería metálica en cada lugar
## libre del piso.
const WORKSHOP_RACK_ID: String = "estanteria_metalica"
## El nivel del taller lleno en las capturas y el panel de depuración: el de
## la decoración del taller, con la tira LED.
const WORKSHOP_LEVEL: int = 5
## Los trabajos del taller lleno (give_jobs), uno por impresora y en este
## orden: imprimiendo, lista, con una falla (espagueti o warping, alternados)
## y sin trabajo (-1). La pieza que se imprime va por la mitad: cada pieza
## dura el doble de WORKSHOP_HALF_PIECE_SECONDS. No son números de balance:
## solo arman la escena que se mide.
const WORKSHOP_JOBS: Array[int] = [PrintJob.Status.PRINTING, PrintJob.Status.DONE, PrintJob.Status.FAILED, -1]
const WORKSHOP_FAILURES: Array[String] = [FailureRules.SPAGHETTI, FailureRules.WARPING]
const WORKSHOP_HALF_PIECE_SECONDS: int = 1800


## El taller más cargado que se puede armar hoy, el peor caso para medir el
## rendimiento (la prueba de presupuesto, las capturas 37, 38 y 43 y el
## panel de depuración): a `state` (una partida nueva) le agrega una
## estantería metálica en cada lugar libre del piso de su espacio, con una
## impresora en cada uno de sus lugares, recorriendo en orden todas las
## familias del catálogo.
static func fill_workshop(state: GameState, rules: SimRules) -> void:
	var families: Array[String] = []
	for printer: Dictionary in rules.catalog.files["printers"]:
		families.append(String(printer["id"]))
	var used: Array[int] = []
	for item: OwnedFurniture in state.furniture:
		used.append(item.slot)
	var per_rack: int = int(rules.furniture[WORKSHOP_RACK_ID]["printer_slots"])
	var next: int = 0
	for slot: int in WorkshopRules.floor_slots_total(state, rules):
		if slot in used:
			continue
		var rack: OwnedFurniture = OwnedFurniture.new(state.take_uid(), WORKSHOP_RACK_ID, slot)
		state.furniture.append(rack)
		for i: int in per_rack:
			state.printers.append(OwnedPrinter.new(state.take_uid(), families[next % families.size()], rack.uid))
			next += 1


## Pone a trabajar las impresoras de `state` según WORKSHOP_JOBS, cada una
## con un pedido y un color distintos, como en una partida guardada.
static func give_jobs(state: GameState, rules: SimRules) -> void:
	var order_ids: Array[String] = rules.order_list
	var color_ids: Array[String] = []
	for color_id: String in rules.colors:
		color_ids.append(color_id)
	var now: int = state.game_seconds
	var failures: int = 0
	for i: int in state.printers.size():
		var status: int = WORKSHOP_JOBS[i % WORKSHOP_JOBS.size()]
		if status < 0:
			continue
		var printer: OwnedPrinter = state.printers[i]
		var order: Order = Order.new(state.take_uid(), order_ids[i % order_ids.size()], now)
		order.stage = Order.Stage.PRINTING
		order.printer_uid = printer.uid
		state.orders.append(order)
		var job: PrintJob = PrintJob.new()
		job.order_uid = order.uid
		job.spool_uid = state.spools[0].uid
		job.color_id = color_ids[i % color_ids.size()]
		job.pieces_total = 1
		job.piece_seconds = WORKSHOP_HALF_PIECE_SECONDS * 2
		job.piece_started_at = now - WORKSHOP_HALF_PIECE_SECONDS
		job.ends_at = now + WORKSHOP_HALF_PIECE_SECONDS
		job.status = status as PrintJob.Status
		if status == PrintJob.Status.DONE:
			order.stage = Order.Stage.PRINTED
			order.pieces_done = 1
		elif status == PrintJob.Status.FAILED:
			job.fails = true
			job.failure_type = WORKSHOP_FAILURES[failures % WORKSHOP_FAILURES.size()]
			job.ends_at = now
			failures += 1
		printer.job = job


## Hace que la pieza en curso de la impresora falle con `failure_type` al
## llegar a `stop` de su avance, o en el próximo segundo si ese punto ya pasó.
## Se pierde lo impreso hasta donde se detiene, como en una falla de verdad.
## Devuelve false, sin cambiar nada, si la impresora no está imprimiendo o el
## tipo de fallo no existe.
static func force_fail(sim: Simulation, printer_uid: int, failure_type: String, stop: float = 0.35) -> bool:
	var printer: OwnedPrinter = sim.state.find_printer(printer_uid)
	if printer == null or printer.job == null or printer.job.status != PrintJob.Status.PRINTING:
		return false
	if not sim.rules.stop_ranges.has(failure_type):
		return false
	var job: PrintJob = printer.job
	var stop_seconds: int = clampi(roundi(job.piece_seconds * stop), 1, job.piece_seconds)
	job.fails = true
	job.failure_type = failure_type
	job.ends_at = maxi(sim.state.game_seconds + 1, job.piece_started_at + stop_seconds)
	var stopped_at: float = float(job.ends_at - job.piece_started_at) / float(job.piece_seconds)
	job.lost_grams = clampi(ceili(job.grams_per_piece * stopped_at), 1, job.grams_per_piece)
	sim.mark_dirty()
	return true
