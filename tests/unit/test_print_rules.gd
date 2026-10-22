extends GutTest
## Reglas de una impresión: tiempo por pieza, calidad, costo del material y la
## revisión única para imprimir, con sus motivos en orden fijo.

var _rules: SimRules
var _state: GameState


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_state = GameState.new_game(_rules, 1234)


# --- Tiempo, calidad y costo -----------------------------------------------


func test_keychain_piece_time_depends_on_the_mode() -> void:
	assert_eq(PrintRules.piece_seconds(_rules, "llavero", "cubo_uno", "pla", "normal"), 1200, "20 minutos de juego")
	assert_eq(PrintRules.piece_seconds(_rules, "llavero", "cubo_uno", "pla", "fine"), 1920)
	assert_eq(PrintRules.piece_seconds(_rules, "llavero", "cubo_uno", "pla", "draft"), 720)


func test_printer_speed_divides_the_time() -> void:
	assert_eq(PrintRules.piece_seconds(_rules, "engranaje", "rayo_x1", "petg", "normal"), 2700, "90 min a velocidad 2")
	assert_eq(PrintRules.piece_seconds(_rules, "funda_flexible", "rayo_mini", "tpu", "normal"), 4320,
		"90 min × 1,6 del TPU a velocidad 2")


func test_prep_time_is_added_per_piece_and_not_divided_by_speed() -> void:
	_rules.prep_seconds_per_piece = 300
	assert_eq(PrintRules.piece_seconds(_rules, "llavero", "cubo_uno", "pla", "normal"), 1500)
	assert_eq(PrintRules.piece_seconds(_rules, "engranaje", "rayo_x1", "petg", "normal"), 3000)


func test_piece_time_is_never_zero() -> void:
	var llavero: Dictionary = _rules.orders["llavero"].duplicate(true)
	llavero["minutes_per_piece"] = 0.001
	_rules.orders["llavero"] = llavero
	assert_eq(PrintRules.piece_seconds(_rules, "llavero", "cubo_uno", "pla", "draft"), 1)


func test_quality_stays_inside_the_scale() -> void:
	assert_eq(PrintRules.quality(_rules, "cubo_uno", "normal"), 2)
	assert_eq(PrintRules.quality(_rules, "cubo_uno", "fine"), 3)
	assert_eq(PrintRules.quality(_rules, "cubo_uno", "draft"), 1)
	assert_eq(PrintRules.quality(_rules, "gota_r1", "fine"), 5, "Calidad 5 más fino sigue siendo 5")
	var cubo: Dictionary = _rules.printers["cubo_uno"].duplicate(true)
	cubo["max_quality"] = 1
	_rules.printers["cubo_uno"] = cubo
	assert_eq(PrintRules.quality(_rules, "cubo_uno", "draft"), 1, "Nunca menos de 1")


func test_material_cost_in_cents() -> void:
	assert_eq(PrintRules.cost_cents(_rules, "pla", 8), 14, "8 g de PLA a $18 el kilo")
	assert_eq(PrintRules.cost_cents(_rules, "petg", 4 * 20), 160, "Las 4 piezas del engranaje")
	assert_eq(PrintRules.cost_cents(_rules, "pla", 0), 0)


func test_pieces_left_skips_the_finished_ones() -> void:
	var order: Order = _ready_order("engranaje")
	assert_eq(PrintRules.pieces_left(_rules, order), 4)
	order.pieces_done = 3
	assert_eq(PrintRules.pieces_left(_rules, order), 1)


# --- La revisión para imprimir ---------------------------------------------


func test_a_valid_setup_passes() -> void:
	var order: Order = _ready_order("llavero")
	_assert_check(order, _state.printers[0], _state.spools[0], "normal", "")


func test_check_reasons_come_in_the_fixed_order() -> void:
	# Un letrero (M, multicolor) que también acepta TPU y pide calidad 4: cada
	# paso arregla un solo problema y todos los que siguen están presentes.
	var letrero: Dictionary = _rules.orders["letrero"].duplicate(true)
	letrero["materials"] = ["pla", "tpu"]
	letrero["min_quality"] = 4
	_rules.orders["letrero"] = letrero
	var order: Order = Order.new(_state.take_uid(), "letrero", _state.game_seconds)
	var printer: OwnedPrinter = OwnedPrinter.new(_state.take_uid(), "rayo_mini")
	var spool: Spool = Spool.new(_state.take_uid(), "resina", "gris", 0)
	_assert_check(null, null, null, "turbo", "ERR_ORDER_GONE")
	order.stage = Order.Stage.WAITING_DESIGN
	_assert_check(order, null, null, "turbo", "ERR_NOT_MODELED")
	order.stage = Order.Stage.DESIGNING
	_assert_check(order, null, null, "turbo", "ERR_NOT_MODELED")
	for stage: Order.Stage in [Order.Stage.PRINTING, Order.Stage.PRINTED, Order.Stage.TO_PACK, Order.Stage.PACKED]:
		order.stage = stage
		_assert_check(order, null, null, "turbo", "ERR_ALREADY_PRINTING")
	order.stage = Order.Stage.READY_TO_PRINT
	_assert_check(order, null, null, "turbo", "ERR_PRINTER_GONE")
	printer.job = _job_for(_ready_order("llavero"), 1200)
	printer.job.status = PrintJob.Status.DONE
	_assert_check(order, printer, null, "turbo", "ERR_PRINTER_DONE", ["PRINTER_RAYO_MINI"])
	printer.job.status = PrintJob.Status.FAILED
	_assert_check(order, printer, null, "turbo", "ERR_PRINTER_FAILED", ["PRINTER_RAYO_MINI"])
	printer.job.status = PrintJob.Status.PRINTING
	_assert_check(order, printer, null, "turbo", "ERR_PRINTER_BUSY", ["PRINTER_RAYO_MINI", {"seconds": 1200}])
	printer.job = null
	_assert_check(order, printer, null, "turbo", "ERR_TOO_BIG", ["PRINTER_RAYO_MINI", "S"])
	printer.printer_id = "cubo_uno"
	_assert_check(order, printer, null, "turbo", "ERR_NOT_MULTICOLOR")
	printer.printer_id = "prisma_mc"
	_assert_check(order, printer, null, "turbo", "ERR_SPOOL_GONE")
	_assert_check(order, printer, spool, "turbo", "ERR_MATERIAL_NOT_ACCEPTED", ["MATERIAL_RESINA"])
	spool.material_id = "tpu"
	_assert_check(order, printer, spool, "turbo", "ERR_PRINTER_MATERIAL", ["PRINTER_PRISMA_MC", "MATERIAL_TPU"])
	spool.material_id = "pla"
	_assert_check(order, printer, spool, "turbo", "ERR_MODE_UNKNOWN")
	_assert_check(order, printer, spool, "normal", "ERR_QUALITY", [3, 4])
	_assert_check(order, printer, spool, "fine", "ERR_NOT_ENOUGH_MATERIAL", [{"grams": 0}, {"grams": 140}])
	spool.grams = 140
	_assert_check(order, printer, spool, "fine", "")


func test_busy_printer_says_when_all_its_pieces_are_done() -> void:
	var casco: Order = _ready_order("casco_cosplay")
	casco.stage = Order.Stage.PRINTING
	casco.pieces_done = 2
	var printer: OwnedPrinter = _state.printers[0]
	printer.job = _job_for(casco, 19800)
	_state.game_seconds += 1000
	_assert_check(_ready_order("llavero"), printer, _state.spools[0], "normal", "ERR_PRINTER_BUSY",
		["PRINTER_CUBO_UNO", {"seconds": 18800 + 3 * 19800}])


func test_order_too_big_for_the_printer() -> void:
	_state.printers[0].printer_id = "rayo_mini"
	_assert_check(_ready_order("organizador"), _state.printers[0], _state.spools[0], "normal", "ERR_TOO_BIG",
		["PRINTER_RAYO_MINI", "S"])
	var previous_locale: String = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	assert_eq(tr("ERR_TOO_BIG") % [tr("PRINTER_RAYO_MINI"), "S"], "No cabe: la Rayo Mini es tamaño S.")
	TranslationServer.set_locale(previous_locale)


func test_quality_reason_gives_both_numbers() -> void:
	_assert_check(_ready_order("maceta"), _state.printers[0], _state.spools[0], "draft", "ERR_QUALITY", [1, 2])


func test_material_is_checked_only_for_the_pieces_left() -> void:
	_state.printers[0].printer_id = "rayo_x1"
	var spool: Spool = Spool.new(_state.take_uid(), "petg", "negro", 39)
	var order: Order = _ready_order("engranaje")
	order.pieces_done = 2
	_assert_check(order, _state.printers[0], spool, "normal", "ERR_NOT_ENOUGH_MATERIAL",
		[{"grams": 39}, {"grams": 40}])
	spool.grams = 40
	_assert_check(order, _state.printers[0], spool, "normal", "")


func test_setup_check_ignores_the_order_and_the_printer_state() -> void:
	var printer: OwnedPrinter = _state.printers[0]
	printer.job = _job_for(_ready_order("llavero"), 1200)
	var result: CommandResult = PrintRules.check_setup(_rules, "llavero", printer.printer_id, _state.spools[0], "normal", 1)
	assert_true(result.ok, "Con la impresora ocupada la combinación sirve igual")
	result = PrintRules.check_setup(_rules, "llavero", printer.printer_id, _state.spools[0], "normal", 126)
	assert_eq(result.reason, "ERR_NOT_ENOUGH_MATERIAL", "126 × 8 g no caben en 1.000 g")


# --- Ayudantes -------------------------------------------------------------


func _ready_order(order_id: String) -> Order:
	var order: Order = Order.new(_state.take_uid(), order_id, _state.game_seconds)
	order.stage = Order.Stage.READY_TO_PRINT
	_state.orders.append(order)
	return order


## Trabajo de una pieza por vez para el pedido, empezado ahora.
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


## Revisa y compara el motivo y sus datos; reason "" = se puede imprimir.
func _assert_check(order: Order, printer: OwnedPrinter, spool: Spool, mode_id: String, reason: String, args: Array = []) -> void:
	var result: CommandResult = PrintRules.check(_state, _rules, order, printer, spool, mode_id)
	assert_eq(result.ok, reason == "", "ok con motivo esperado '%s'" % reason)
	assert_eq(result.reason, reason)
	assert_eq(result.args, args, "Datos del motivo %s" % reason)
