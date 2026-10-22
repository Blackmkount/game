extends GutTest
## Lo elegido en el panel de una impresora (PrintChoice): se respeta mientras
## sirve y, si ya no sirve, vuelve a lo recomendado.

var _rules: SimRules
var _sim: Simulation
var _state: GameState
var _commands: GameCommands
var _cubo: OwnedPrinter
var _pla: Spool


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	# Las piezas salen bien salvo que se fuerce una falla.
	_rules.grace_pieces = 1000
	_sim = SimFixtures.new_sim(_rules)
	_state = _sim.state
	_commands = GameCommands.new(_sim)
	SimFixtures.quiet_board(_state)
	_cubo = _state.printers[0]
	_pla = _state.spools[0]


func test_a_new_choice_takes_the_recommendation() -> void:
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	var choice: PrintChoice = PrintChoice.new(_cubo.uid)
	var before: String = _encoded()
	var plan: PrintPlan = choice.normalize(_state, _rules)
	assert_true(plan.ok)
	assert_eq([plan.order_uid, plan.printer_uid, plan.spool_uid, plan.mode_id], [order.uid, _cubo.uid, _pla.uid, "normal"])
	assert_eq([choice.order_uid, choice.spool_uid, choice.mode_id], [order.uid, _pla.uid, "normal"], "La elección dice lo que muestra el plan")
	assert_eq(_encoded(), before, "Elegir no cambia la partida")


func test_choices_that_still_work_are_kept() -> void:
	SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	var black: Spool = SimFixtures.add_spool(_state, "pla", 500)
	var choice: PrintChoice = PrintChoice.new(_cubo.uid)
	choice.spool_uid = black.uid
	choice.mode_id = "fine"
	var plan: PrintPlan = choice.normalize(_state, _rules)
	assert_true(plan.ok)
	assert_eq(plan.spool_uid, black.uid)
	assert_eq(plan.mode_id, "fine")
	assert_eq(plan.total_seconds, 1920, "El plan es el del modo fino")


func test_a_spool_that_is_gone_empty_or_wrong_falls_back() -> void:
	SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	var black: Spool = SimFixtures.add_spool(_state, "pla", 500)
	var petg: Spool = SimFixtures.add_spool(_state, "petg", 1000)
	var choice: PrintChoice = PrintChoice.new(_cubo.uid)
	choice.mode_id = "fine"
	choice.spool_uid = black.uid
	black.grams = 0
	assert_eq(choice.normalize(_state, _rules).spool_uid, _pla.uid, "Vacío")
	assert_eq(choice.spool_uid, _pla.uid)
	choice.spool_uid = 9000
	assert_eq(choice.normalize(_state, _rules).spool_uid, _pla.uid, "Ya no está")
	choice.spool_uid = petg.uid
	assert_eq(choice.normalize(_state, _rules).spool_uid, _pla.uid, "El llavero se pide en PLA")
	assert_eq(choice.mode_id, "fine", "El modo, que sirve, se queda")


func test_an_unknown_or_too_low_mode_falls_back() -> void:
	SimFixtures.order_at(_sim, "maceta", Order.Stage.READY_TO_PRINT)
	var choice: PrintChoice = PrintChoice.new(_cubo.uid)
	choice.mode_id = "turbo"
	assert_eq(choice.normalize(_state, _rules).mode_id, "normal", "No existe")
	choice.mode_id = "draft"
	var plan: PrintPlan = choice.normalize(_state, _rules)
	assert_eq(plan.mode_id, "normal", "Borrador da calidad 1 y la maceta pide 2")
	assert_true(plan.ok)
	choice.mode_id = "fine"
	assert_eq(choice.normalize(_state, _rules).mode_id, "fine")


func test_an_order_that_left_ready_to_print_falls_back() -> void:
	var keychain: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	var planter: Order = SimFixtures.order_at(_sim, "maceta", Order.Stage.READY_TO_PRINT)
	var choice: PrintChoice = PrintChoice.new(_cubo.uid, keychain.uid)
	choice.mode_id = "fine"
	assert_eq(choice.normalize(_state, _rules).order_uid, keychain.uid)
	assert_true(_commands.cancel_order(keychain.uid).ok)
	var plan: PrintPlan = choice.normalize(_state, _rules)
	assert_eq(plan.order_uid, planter.uid, "El otro modelo listo")
	assert_eq(choice.order_uid, planter.uid)
	assert_true(plan.ok)
	assert_true(_commands.start_print(planter.uid, _cubo.uid, _pla.uid, "normal").ok)
	assert_null(choice.normalize(_state, _rules), "No queda nada listo para imprimir")
	assert_eq(choice.order_uid, -1)


func test_an_order_this_printer_cannot_take_gives_way_to_one_it_can() -> void:
	_pla.grams = 3000
	var table: OwnedFurniture = OwnedFurniture.new(_state.take_uid(), "mesa_auxiliar", 1)
	_state.furniture.append(table)
	var small: OwnedPrinter = OwnedPrinter.new(_state.take_uid(), "rayo_mini", table.uid)
	_state.printers.append(small)
	var helmet: Order = SimFixtures.order_at(_sim, "casco_cosplay", Order.Stage.READY_TO_PRINT)
	var choice: PrintChoice = PrintChoice.new(small.uid, helmet.uid)
	var plan: PrintPlan = choice.normalize(_state, _rules)
	assert_false(plan.ok, "Solo está el casco, que no cabe")
	assert_eq(plan.reason.reason, "ERR_TOO_BIG")
	var keychain: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	assert_eq(choice.printable_orders(_state, _rules), [keychain] as Array[Order])
	plan = choice.normalize(_state, _rules)
	assert_true(plan.ok)
	assert_eq(plan.order_uid, keychain.uid, "Toma el que sí cabe")
	assert_eq(plan.printer_uid, small.uid)


func test_usable_spools_are_the_ones_that_can_print_the_order() -> void:
	SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	var black: Spool = SimFixtures.add_spool(_state, "pla", 500)
	SimFixtures.add_spool(_state, "petg", 1000)
	var tiny: Spool = SimFixtures.add_spool(_state, "pla", 5)
	var choice: PrintChoice = PrintChoice.new(_cubo.uid)
	choice.normalize(_state, _rules)
	assert_eq(choice.usable_spools(_state, _rules, "normal"), [_pla, black] as Array[Spool], "Sin PETG ni el de 5 g")
	assert_true(tiny.grams < _rules.order_grams["llavero"])


func _encoded() -> String:
	return JSON.stringify(SaveCodec.encode(_state), "", true)
