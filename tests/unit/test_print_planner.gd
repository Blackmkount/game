extends GutTest
## Plan de impresión recomendado: qué impresora, carrete y modo, con sus
## números (tiempo, riesgo, material y ganancia), y la estimación de un
## mensaje todavía sin aceptar.

var _rules: SimRules
var _state: GameState


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_state = GameState.new_game(_rules, 1234)


# --- La recomendación ------------------------------------------------------


func test_first_keychain_plan() -> void:
	var order: Order = _ready_order("llavero")
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, order)
	assert_true(plan.ok)
	assert_null(plan.reason)
	assert_eq(plan.order_uid, order.uid)
	assert_eq(plan.printer_uid, 2, "La Cubo Uno")
	assert_eq(plan.spool_uid, 3, "El PLA blanco")
	assert_eq(plan.mode_id, "normal")
	assert_eq(plan.material_id, "pla")
	assert_eq(plan.color_id, "blanco")
	assert_eq(plan.quality, 2)
	assert_eq(plan.min_quality, 1)
	assert_eq(plan.pieces, 1)
	assert_eq(plan.piece_seconds, 1200)
	assert_eq(plan.total_seconds, 1200, "50 s reales")
	assert_almost_eq(plan.chance, 0.20, 0.0001)
	assert_true(plan.graced, "Las 3 primeras piezas no fallan")
	assert_eq(plan.grams_per_piece, 8)
	assert_eq(plan.grams_total, 8)
	assert_eq(plan.spool_grams, 1000)
	assert_eq(plan.cost_cents, 14)
	assert_eq(plan.payment_cents, 600)
	assert_eq(plan.profit_cents, 586)
	assert_eq(plan.xp, 5)


func test_grace_covers_only_the_first_pieces() -> void:
	var order: Order = _ready_order("llavero")
	_state.pieces_started = 2
	assert_true(PrintPlanner.recommend(_state, _rules, order).graced, "La tercera pieza todavía está en gracia")
	_state.pieces_started = 3
	assert_false(PrintPlanner.recommend(_state, _rules, order).graced)
	_state.pieces_started = 0
	_add_petg_printer()
	assert_false(PrintPlanner.recommend(_state, _rules, _ready_order("engranaje")).graced,
		"De 4 piezas, la cuarta ya puede fallar")


func test_gear_plan_on_a_rayo_x1() -> void:
	_add_petg_printer()
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("engranaje"))
	assert_true(plan.ok)
	assert_eq(plan.mode_id, "normal")
	assert_eq(plan.quality, 3)
	assert_eq(plan.pieces, 4)
	assert_eq(plan.piece_seconds, 2700)
	assert_eq(plan.total_seconds, 10800, "4 piezas, una tras otra: 7 min 30 s reales")
	assert_almost_eq(plan.chance, 0.069, 0.0001)
	assert_eq(plan.grams_total, 80)
	assert_eq(plan.cost_cents, 160)
	assert_eq(plan.profit_cents, 5440)


func test_only_the_pieces_left_are_planned() -> void:
	_add_petg_printer()
	var order: Order = _ready_order("engranaje")
	order.pieces_done = 2
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, order)
	assert_eq(plan.pieces, 2)
	assert_eq(plan.total_seconds, 5400)
	assert_eq(plan.grams_total, 40)
	assert_eq(plan.cost_cents, 80)


func test_normal_mode_wins_over_a_faster_draft() -> void:
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("llavero"))
	assert_eq(plan.mode_id, "normal", "El borrador es más rápido, pero normal va primero")


func test_flower_pot_is_never_draft() -> void:
	var order: Order = _ready_order("maceta")
	var draft: PrintPlan = PrintPlanner.evaluate(_state, _rules, order, _state.printers[0], _state.spools[0], "draft")
	assert_false(draft.ok)
	assert_eq(draft.reason.reason, "ERR_QUALITY")
	assert_eq(draft.reason.args, [1, 2])
	for printer_id: String in ["cubo_uno", "rayo_mini", "rayo_x1"]:
		_state.printers[0].printer_id = printer_id
		assert_eq(PrintPlanner.recommend(_state, _rules, order).mode_id, "normal", printer_id)


func test_fine_is_picked_when_normal_lacks_quality() -> void:
	var petg: Spool = _add_spool("petg", 1000)
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("carcasa"))
	assert_true(plan.ok)
	assert_eq(plan.printer_uid, 2, "La Cubo Uno da calidad 2 en normal y 3 en fino")
	assert_eq(plan.spool_uid, petg.uid)
	assert_eq(plan.mode_id, "fine")
	assert_eq(plan.quality, 3)
	assert_eq(plan.total_seconds, 2 * 23040, "2 piezas de 4 h × 1,6")


func test_the_faster_printer_wins() -> void:
	var rayo: OwnedPrinter = _add_petg_printer()
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("llavero"))
	assert_eq(plan.printer_uid, rayo.uid)
	assert_eq(plan.total_seconds, 600)


func test_with_equal_time_the_lower_risk_wins() -> void:
	var on_floor: OwnedPrinter = _state.printers[0]
	on_floor.printer_id = "rayo_x1"
	var on_table: OwnedPrinter = _add_petg_printer()
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("llavero"))
	assert_eq(plan.printer_uid, on_table.uid, "La del suelo tiene más riesgo")


func test_the_partial_spool_is_used_first() -> void:
	var partial: Spool = _add_spool("pla", 300)
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("llavero"))
	assert_eq(plan.spool_uid, partial.uid)
	assert_eq(plan.spool_grams, 300)


func test_the_client_material_order_comes_before_the_partial_spool() -> void:
	# Con el PETG igual de seguro que el PLA, decide el orden del cliente.
	var petg: Dictionary = _rules.materials["petg"].duplicate(true)
	petg["failure_multiplier"] = 1.0
	_rules.materials["petg"] = petg
	_add_spool("petg", 300)
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("soporte_celular"))
	assert_eq(plan.material_id, "pla", "El soporte pide PLA o PETG, en ese orden")


func test_empty_spools_are_not_tried_while_others_have_material() -> void:
	_state.spools[0].grams = 0
	var petg: Spool = _add_spool("petg", 1000)
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("llavero"))
	assert_false(plan.ok)
	assert_eq(plan.spool_uid, petg.uid, "El PLA vacío no se prueba")
	assert_eq(plan.reason.reason, "ERR_MATERIAL_NOT_ACCEPTED")


func test_a_busy_workshop_says_when_the_printer_is_free() -> void:
	var busy: Order = _ready_order("llavero")
	_state.printers[0].job = _job_for(busy, 1200)
	busy.stage = Order.Stage.PRINTING
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("maceta"))
	assert_false(plan.ok)
	assert_eq(plan.reason.reason, "ERR_PRINTER_BUSY")
	assert_eq(plan.reason.args, ["PRINTER_CUBO_UNO", {"seconds": 1200}])


func test_only_the_chosen_printer_is_tried() -> void:
	var rayo: OwnedPrinter = _add_petg_printer()
	var order: Order = _ready_order("llavero")
	assert_eq(PrintPlanner.recommend(_state, _rules, order, 2).printer_uid, 2, "Aunque la Rayo X1 sea más rápida")
	assert_eq(PrintPlanner.recommend(_state, _rules, order, rayo.uid).printer_uid, rayo.uid)
	var gone: PrintPlan = PrintPlanner.recommend(_state, _rules, order, 999)
	assert_false(gone.ok)
	assert_eq(gone.reason.reason, "ERR_PRINTER_GONE")


func test_without_a_valid_plan_the_first_reason_is_given() -> void:
	_state.spools[0].material_id = "petg"
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("llavero"))
	assert_false(plan.ok)
	assert_eq(plan.reason.reason, "ERR_MATERIAL_NOT_ACCEPTED")
	assert_eq(plan.reason.args, ["MATERIAL_PETG"])
	assert_eq(plan.mode_id, "normal", "La primera combinación probada")


func test_with_every_spool_empty_the_reason_says_how_much_is_missing() -> void:
	_state.spools[0].grams = 0
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, _ready_order("llavero"))
	assert_eq(plan.reason.reason, "ERR_NOT_ENOUGH_MATERIAL")
	assert_eq(plan.reason.args, [{"grams": 0}, {"grams": 8}])
	_state.spools.clear()
	assert_eq(PrintPlanner.recommend(_state, _rules, _state.orders[0]).reason.reason, "ERR_SPOOL_GONE")


func test_an_order_still_in_design_cannot_be_planned() -> void:
	var order: Order = _ready_order("llavero")
	order.stage = Order.Stage.DESIGNING
	assert_eq(PrintPlanner.recommend(_state, _rules, order).reason.reason, "ERR_NOT_MODELED")
	assert_eq(PrintPlanner.recommend(_state, _rules, null).reason.reason, "ERR_ORDER_GONE")


func test_an_invalid_plan_still_has_its_numbers() -> void:
	var order: Order = _ready_order("maceta")
	var plan: PrintPlan = PrintPlanner.evaluate(_state, _rules, order, _state.printers[0], _state.spools[0], "draft")
	assert_false(plan.ok)
	assert_eq(plan.order_uid, order.uid)
	assert_eq(plan.printer_uid, 2)
	assert_eq(plan.spool_uid, 3)
	assert_eq(plan.quality, 1)
	assert_eq(plan.min_quality, 2)
	assert_eq(plan.piece_seconds, 4320, "120 min × 0,6")
	var no_spool: PrintPlan = PrintPlanner.evaluate(_state, _rules, order, _state.printers[0], null, "normal")
	assert_eq(no_spool.reason.reason, "ERR_SPOOL_GONE")
	assert_eq(no_spool.spool_uid, -1)
	assert_eq(no_spool.piece_seconds, 0, "Sin carrete no hay números")


func test_plan_and_print_command_give_the_same_reason() -> void:
	var commands: GameCommands = GameCommands.new(Simulation.new(_state, _rules))
	var cubo: OwnedPrinter = _state.printers[0]
	var pla: Spool = _state.spools[0]
	var empty: Spool = _add_spool("pla", 0)
	var resin: Spool = _add_spool("resina", 1000)
	var mini: OwnedPrinter = _add_printer("rayo_mini")
	var busy: OwnedPrinter = _add_printer("rayo_x1")
	var done: OwnedPrinter = _add_printer("rayo_x1")
	var failed: OwnedPrinter = _add_printer("rayo_x1")
	var printing: Order = _order_on(busy, PrintJob.Status.PRINTING)
	_order_on(done, PrintJob.Status.DONE)
	_order_on(failed, PrintJob.Status.FAILED)
	var waiting: Order = _ready_order("llavero")
	waiting.stage = Order.Stage.WAITING_DESIGN
	var designing: Order = _ready_order("llavero")
	designing.stage = Order.Stage.DESIGNING
	var keychain: Order = _ready_order("llavero")
	# Cada fila: pedido, impresora, carrete, modo y el motivo esperado.
	var setups: Array[Array] = [
		[999, cubo.uid, pla.uid, "normal", "ERR_ORDER_GONE"],
		[waiting.uid, cubo.uid, pla.uid, "normal", "ERR_NOT_MODELED"],
		[designing.uid, cubo.uid, pla.uid, "normal", "ERR_NOT_MODELED"],
		[printing.uid, cubo.uid, pla.uid, "normal", "ERR_ALREADY_PRINTING"],
		[keychain.uid, 999, pla.uid, "normal", "ERR_PRINTER_GONE"],
		[keychain.uid, done.uid, pla.uid, "normal", "ERR_PRINTER_DONE"],
		[keychain.uid, failed.uid, pla.uid, "normal", "ERR_PRINTER_FAILED"],
		[keychain.uid, busy.uid, pla.uid, "normal", "ERR_PRINTER_BUSY"],
		[_ready_order("organizador").uid, mini.uid, pla.uid, "normal", "ERR_TOO_BIG"],
		[_ready_order("letrero").uid, cubo.uid, pla.uid, "normal", "ERR_NOT_MULTICOLOR"],
		[keychain.uid, cubo.uid, 999, "normal", "ERR_SPOOL_GONE"],
		[keychain.uid, cubo.uid, resin.uid, "normal", "ERR_MATERIAL_NOT_ACCEPTED"],
		[_ready_order("miniatura").uid, cubo.uid, resin.uid, "normal", "ERR_PRINTER_MATERIAL"],
		[keychain.uid, cubo.uid, pla.uid, "turbo", "ERR_MODE_UNKNOWN"],
		[_ready_order("maceta").uid, cubo.uid, pla.uid, "draft", "ERR_QUALITY"],
		[keychain.uid, cubo.uid, empty.uid, "normal", "ERR_NOT_ENOUGH_MATERIAL"],
	]
	var before: String = JSON.stringify(SaveCodec.encode(_state), "", true)
	var prints_state: int = _state.prints_rng.state
	for setup: Array in setups:
		var expected: String = setup[4]
		var plan: PrintPlan = PrintPlanner.evaluate(_state, _rules, _state.find_order(setup[0]),
				_state.find_printer(setup[1]), _state.find_spool(setup[2]), setup[3])
		var result: CommandResult = commands.start_print(setup[0], setup[1], setup[2], setup[3])
		assert_false(plan.ok, expected)
		assert_eq(plan.reason.reason, expected)
		assert_false(result.ok, expected)
		assert_eq(result.reason, expected)
		assert_eq(result.args, plan.reason.args, "Mismos datos del motivo en %s" % expected)
	assert_eq(JSON.stringify(SaveCodec.encode(_state), "", true), before, "Un comando que falla no cambia nada")
	assert_eq(_state.prints_rng.state, prints_state, "Ni usa el azar")
	assert_true(commands.sim.changes.is_empty())
	var valid: PrintPlan = PrintPlanner.evaluate(_state, _rules, keychain, cubo, pla, "normal")
	assert_true(valid.ok)
	assert_true(commands.start_print(keychain.uid, cubo.uid, pla.uid, "normal").ok,
		"Lo que el plan da por válido se puede imprimir")


func test_planning_changes_nothing() -> void:
	var order: Order = _ready_order("llavero")
	var twin: RandomNumberGenerator = RandomNumberGenerator.new()
	twin.seed = _state.prints_rng.seed
	twin.state = _state.prints_rng.state
	var before: String = JSON.stringify(SaveCodec.encode(_state), "", true)
	PrintPlanner.recommend(_state, _rules, order)
	PrintPlanner.estimate_for_offer(_state, _rules, "maceta")
	assert_eq(JSON.stringify(SaveCodec.encode(_state), "", true), before)
	assert_eq(_state.prints_rng.state, twin.state, "Planear no usa el azar")


# --- La estimación de un mensaje -------------------------------------------


func test_offer_estimate_for_the_keychain() -> void:
	var plan: PrintPlan = PrintPlanner.estimate_for_offer(_state, _rules, "llavero")
	assert_true(plan.ok)
	assert_eq(plan.order_uid, -1, "Todavía no es un pedido")
	assert_eq(plan.printer_uid, 2)
	assert_eq(plan.spool_uid, 3)
	assert_eq(plan.mode_id, "normal")
	assert_eq(plan.total_seconds, 1200)
	assert_eq(plan.profit_cents, 586)


func test_offer_estimate_ignores_busy_printers() -> void:
	var busy: Order = _ready_order("maceta")
	busy.stage = Order.Stage.PRINTING
	_state.printers[0].job = _job_for(busy, 7200)
	var plan: PrintPlan = PrintPlanner.estimate_for_offer(_state, _rules, "llavero")
	assert_true(plan.ok)
	assert_eq(plan.total_seconds, 1200)


func test_offer_estimate_plans_every_piece() -> void:
	_add_petg_printer()
	var plan: PrintPlan = PrintPlanner.estimate_for_offer(_state, _rules, "engranaje")
	assert_eq(plan.pieces, 4)
	assert_eq(plan.total_seconds, 10800)
	assert_eq(plan.profit_cents, 5440)


func test_offer_estimate_without_material() -> void:
	_state.spools[0].grams = 50
	var plan: PrintPlan = PrintPlanner.estimate_for_offer(_state, _rules, "maceta")
	assert_false(plan.ok)
	assert_eq(plan.reason.reason, "ERR_NOT_ENOUGH_MATERIAL")
	assert_eq(plan.reason.args, [{"grams": 50}, {"grams": 80}])


# --- Ayudantes -------------------------------------------------------------


func _ready_order(order_id: String) -> Order:
	var order: Order = Order.new(_state.take_uid(), order_id, _state.game_seconds)
	order.stage = Order.Stage.READY_TO_PRINT
	_state.orders.append(order)
	return order


func _add_spool(material_id: String, grams: int) -> Spool:
	var spool: Spool = Spool.new(_state.take_uid(), material_id, "negro", grams)
	_state.spools.append(spool)
	return spool


## Una Rayo X1 en una mesa de trabajo y un carrete de PETG negro de 1 kg.
func _add_petg_printer() -> OwnedPrinter:
	var table: OwnedFurniture = OwnedFurniture.new(_state.take_uid(), "mesa_trabajo", _state.furniture.size())
	_state.furniture.append(table)
	var rayo: OwnedPrinter = OwnedPrinter.new(_state.take_uid(), "rayo_x1", table.uid)
	_state.printers.append(rayo)
	_add_spool("petg", 1000)
	return rayo


func _add_printer(printer_id: String) -> OwnedPrinter:
	var printer: OwnedPrinter = OwnedPrinter.new(_state.take_uid(), printer_id)
	_state.printers.append(printer)
	return printer


## Un llavero en la impresora, con su trabajo en ese estado.
func _order_on(printer: OwnedPrinter, status: PrintJob.Status) -> Order:
	var order: Order = _ready_order("llavero")
	order.stage = Order.Stage.PRINTED if status == PrintJob.Status.DONE else Order.Stage.PRINTING
	order.printer_uid = printer.uid
	printer.job = _job_for(order, 1200)
	printer.job.status = status
	return order


func _job_for(order: Order, piece_seconds: int) -> PrintJob:
	var job: PrintJob = PrintJob.new()
	job.order_uid = order.uid
	job.spool_uid = _state.spools[0].uid
	job.mode_id = "normal"
	job.color_id = _state.spools[0].color_id
	job.pieces_total = int(_rules.orders[order.order_id]["pieces"])
	job.grams_per_piece = _rules.order_grams[order.order_id]
	job.piece_seconds = piece_seconds
	job.piece_started_at = _state.game_seconds
	job.ends_at = _state.game_seconds + piece_seconds
	return job
