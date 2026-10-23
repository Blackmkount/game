extends GutTest
## Las escenas de DebugTools que miden el rendimiento (la prueba de
## presupuesto, las capturas 37, 38 y 43 y el panel de depuración): el
## taller lleno y sus trabajos en cada estado. Siempre iguales (sin azar).

const SEED: int = 1234

var _rules: SimRules


func before_all() -> void:
	_rules = Game.rules


func test_the_full_workshop_fills_every_free_slot_with_a_rack_of_printers() -> void:
	var state: GameState = GameState.new_game(_rules, SEED)
	var furniture_before: int = state.furniture.size()
	var printers_before: int = state.printers.size()
	var used: Array[int] = []
	for item: OwnedFurniture in state.furniture:
		used.append(item.slot)
	DebugTools.fill_workshop(state, _rules)
	var free: int = WorkshopRules.floor_slots_total(state, _rules) - used.size()
	var per_rack: int = int(_rules.furniture[DebugTools.WORKSHOP_RACK_ID]["printer_slots"])
	assert_eq(state.furniture.size(), furniture_before + free, "Una estantería por lugar libre")
	assert_eq(state.printers.size(), printers_before + free * per_rack, "Llenas de impresoras")
	assert_eq(state.printers.size(), 16, "Hoy: la del piso y 5 estanterías de 3")
	var slots: Array[int] = []
	var families: Dictionary[String, bool] = {}
	for item: OwnedFurniture in state.furniture.slice(furniture_before):
		assert_eq(item.furniture_id, DebugTools.WORKSHOP_RACK_ID)
		assert_false(item.slot in used, "En un lugar que estaba libre")
		assert_false(item.slot in slots, "Uno por lugar")
		slots.append(item.slot)
	for printer: OwnedPrinter in state.printers.slice(printers_before):
		assert_false(printer.is_on_floor(), "En su estantería")
		families[printer.printer_id] = true
	assert_eq(families.size(), (_rules.catalog.files["printers"] as Array).size(), "Todas las familias")
	var again: GameState = GameState.new_game(_rules, SEED)
	DebugTools.fill_workshop(again, _rules)
	assert_eq(SaveCodec.encode(again), SaveCodec.encode(state), "Siempre el mismo taller")


func test_the_jobs_cycle_through_every_state_with_different_colors() -> void:
	var state: GameState = GameState.new_game(_rules, SEED)
	DebugTools.fill_workshop(state, _rules)
	DebugTools.give_jobs(state, _rules)
	var colors: Dictionary[String, bool] = {}
	var failures: Array[String] = []
	for i: int in state.printers.size():
		var printer: OwnedPrinter = state.printers[i]
		var expected: int = DebugTools.WORKSHOP_JOBS[i % DebugTools.WORKSHOP_JOBS.size()]
		if expected < 0:
			assert_null(printer.job, "Impresora %d sin trabajo" % i)
			continue
		assert_not_null(printer.job, "Impresora %d con trabajo" % i)
		assert_eq(int(printer.job.status), expected, "Impresora %d en su estado" % i)
		var order: Order = state.find_order(printer.job.order_uid)
		assert_not_null(order, "Con su pedido")
		assert_eq(order.printer_uid, printer.uid)
		colors[printer.job.color_id] = true
		if expected == PrintJob.Status.PRINTING:
			assert_almost_eq(printer.job.progress_at(state.game_seconds), 0.5, 0.001, "La pieza va por la mitad")
		elif expected == PrintJob.Status.FAILED:
			failures.append(printer.job.failure_type)
	assert_gt(colors.size(), 4, "De colores distintos")
	assert_has(failures, FailureRules.SPAGHETTI, "Una falla con espagueti")
	assert_has(failures, FailureRules.WARPING, "Y otra con warping")
	assert_eq(DebugTools.WORKSHOP_LEVEL, 5, "El taller lleno se muestra en el nivel del taller")


## El taller lleno con trabajos de la captura 43 y del panel de depuración:
## en el nivel del taller, lleno y con sus trabajos, a la hora pedida.
func test_the_busy_workshop_is_the_full_workshop_at_its_level_with_jobs() -> void:
	var expected: GameState = GameState.new_game(_rules, SEED)
	DebugTools.fill_workshop(expected, _rules)
	expected.game_seconds = 22 * GameClock.SECONDS_PER_HOUR
	expected.xp = _rules.levels.thresholds[DebugTools.WORKSHOP_LEVEL - 1]
	DebugTools.give_jobs(expected, _rules)
	var state: GameState = DebugTools.busy_workshop(_rules, SEED, 22 * GameClock.SECONDS_PER_HOUR)
	assert_eq(OrderQueries.level(state, _rules), DebugTools.WORKSHOP_LEVEL, "En el nivel del taller")
	assert_eq(SaveCodec.encode(state), SaveCodec.encode(expected), "El taller lleno con sus trabajos, a esa hora")
	var start: GameState = GameState.new_game(_rules, SEED)
	assert_eq(DebugTools.busy_workshop(_rules, SEED).game_seconds, start.game_seconds, "Sin hora, la del comienzo")
