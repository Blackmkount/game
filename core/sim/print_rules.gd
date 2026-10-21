class_name PrintRules
extends RefCounted
## Reglas de una impresión: tiempo por pieza, calidad, costo del material y la
## revisión única para imprimir un pedido.
##
## La misma revisión (check) la usan el comando Imprimir y el plan que ve el
## jugador, así la interfaz muestra exactamente el motivo con que fallaría el
## comando. Va en un orden fijo y el primer problema gana: primero el pedido,
## después la impresora y al final la combinación de pedido, impresora,
## carrete y modo.


## Segundos de juego de una pieza. La velocidad de la impresora divide el
## tiempo; la preparación por pieza se suma aparte y no depende de la velocidad.
static func piece_seconds(rules: SimRules, order_id: String, printer_id: String, material_id: String, mode_id: String) -> int:
	var seconds: float = float(rules.orders[order_id]["minutes_per_piece"]) * float(GameClock.SECONDS_PER_MINUTE) \
			* float(rules.modes[mode_id]["time_multiplier"]) * float(rules.materials[material_id]["time_multiplier"]) \
			/ float(rules.printers[printer_id]["speed"])
	return maxi(1, roundi(seconds)) + rules.prep_seconds_per_piece


## Calidad que da la impresora con ese modo, dentro de la escala de calidad.
static func quality(rules: SimRules, printer_id: String, mode_id: String) -> int:
	var raw: int = int(rules.printers[printer_id]["max_quality"]) + int(rules.modes[mode_id]["quality_delta"])
	return clampi(raw, DataValidator.MIN_QUALITY, DataValidator.MAX_QUALITY)


## Lo que cuestan `grams` gramos del material, en centavos, al precio de la tienda.
static func cost_cents(rules: SimRules, material_id: String, grams: int) -> int:
	var material: Dictionary = rules.materials[material_id]
	return roundi(grams * float(material["price"]) * 100.0 / float(material["unit_grams"]))


## Piezas del pedido que faltan imprimir (las terminadas viven en el pedido).
static func pieces_left(rules: SimRules, order: Order) -> int:
	return int(rules.orders[order.order_id]["pieces"]) - order.pieces_done


## Revisión completa para imprimir el pedido con esa impresora, carrete y
## modo. El pedido, la impresora y el carrete pueden ser null (ya no están).
static func check(state: GameState, rules: SimRules, order: Order, printer: OwnedPrinter, spool: Spool, mode_id: String) -> CommandResult:
	var result: CommandResult = check_order_ready(order)
	if result.ok:
		result = check_printer_free(state, rules, printer)
	if result.ok:
		result = check_setup(rules, order.order_id, printer.printer_id, spool, mode_id, pieces_left(rules, order))
	return result


## El pedido existe y tiene el modelo listo, sin estar ya en una impresora.
static func check_order_ready(order: Order) -> CommandResult:
	if order == null:
		return CommandResult.fail("ERR_ORDER_GONE")
	match order.stage:
		Order.Stage.WAITING_DESIGN, Order.Stage.DESIGNING:
			return CommandResult.fail("ERR_NOT_MODELED")
		Order.Stage.READY_TO_PRINT:
			return CommandResult.success()
	return CommandResult.fail("ERR_ALREADY_PRINTING")


## La impresora existe y no tiene trabajo: ni piezas por retirar, ni una falla
## por limpiar, ni una impresión en curso.
static func check_printer_free(state: GameState, rules: SimRules, printer: OwnedPrinter) -> CommandResult:
	if printer == null:
		return CommandResult.fail("ERR_PRINTER_GONE")
	var job: PrintJob = printer.job
	if job == null:
		return CommandResult.success()
	var name_key: String = rules.printers[printer.printer_id]["name_key"]
	match job.status:
		PrintJob.Status.DONE:
			return CommandResult.fail("ERR_PRINTER_DONE", [name_key])
		PrintJob.Status.FAILED:
			return CommandResult.fail("ERR_PRINTER_FAILED", [name_key])
	var left: int = OrderQueries.order_seconds_left(job, state.find_order(job.order_uid), state.game_seconds)
	return CommandResult.fail("ERR_PRINTER_BUSY", [name_key, CommandResult.seconds_arg(left)])


## La combinación sirve para `pieces` piezas del pedido: tamaño, multicolor,
## carrete, material que aceptan el cliente y la impresora, modo, calidad y
## gramos. No mira si la impresora está ocupada.
static func check_setup(rules: SimRules, order_id: String, printer_id: String, spool: Spool, mode_id: String, pieces: int) -> CommandResult:
	var order: Dictionary = rules.orders[order_id]
	var printer: Dictionary = rules.printers[printer_id]
	var printer_key: String = printer["name_key"]
	var volume: String = printer["volume"]
	if DataValidator.VOLUMES.find(volume) < DataValidator.VOLUMES.find(order["size"]):
		return CommandResult.fail("ERR_TOO_BIG", [printer_key, volume])
	if order["multicolor"] and not printer["multicolor"]:
		return CommandResult.fail("ERR_NOT_MULTICOLOR")
	if spool == null:
		return CommandResult.fail("ERR_SPOOL_GONE")
	var material_key: String = rules.materials[spool.material_id]["name_key"]
	if spool.material_id not in order["materials"]:
		return CommandResult.fail("ERR_MATERIAL_NOT_ACCEPTED", [material_key])
	if spool.material_id not in printer["materials"]:
		return CommandResult.fail("ERR_PRINTER_MATERIAL", [printer_key, material_key])
	if not rules.modes.has(mode_id):
		return CommandResult.fail("ERR_MODE_UNKNOWN")
	var given_quality: int = quality(rules, printer_id, mode_id)
	var min_quality: int = int(order["min_quality"])
	if given_quality < min_quality:
		return CommandResult.fail("ERR_QUALITY", [given_quality, min_quality])
	var needed_grams: int = pieces * rules.order_grams[order_id]
	if spool.grams < needed_grams:
		return CommandResult.fail("ERR_NOT_ENOUGH_MATERIAL",
				[CommandResult.grams_arg(spool.grams), CommandResult.grams_arg(needed_grams)])
	return CommandResult.success()
