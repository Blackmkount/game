extends GutTest
## Formatos de números de la interfaz en español y en inglés.

var _previous_locale: String


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)


func test_money_in_spanish() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.money(25000), "$250")
	assert_eq(UiFormat.money(258000), "$2.580")
	assert_eq(UiFormat.money(750), "$7,50")
	assert_eq(UiFormat.money(-1200), "-$12")


func test_money_in_english() -> void:
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.money(258000), "$2,580")
	assert_eq(UiFormat.money(750), "$7.50")


func test_durations() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.duration(20.0), "20 min")
	assert_eq(UiFormat.duration(90.0), "1 h 30 min")
	assert_eq(UiFormat.duration(300.0), "5 h")


func test_date() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.date(8 * 60.0), "Día 1 · 08:00")
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.date(1440.0 + 75.0), "Day 2 · 01:15")


func test_real_durations_round_up_to_the_second() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.real_duration(1200, 24), "50 s")
	assert_eq(UiFormat.real_duration(2400, 24), "1 min 40 s")
	assert_eq(UiFormat.real_duration(7200, 24), "5 min")
	assert_eq(UiFormat.real_duration(10800, 24), "7 min 30 s", "Lo que tarda el engranaje")
	assert_eq(UiFormat.real_duration(14400, 24), "10 min")
	assert_eq(UiFormat.real_duration(118800, 24), "1 h 23 min", "4.950 s: los minutos también suben")
	assert_eq(UiFormat.real_duration(1, 24), "1 s", "Lo que falta nunca se muestra como 0")
	assert_eq(UiFormat.real_duration(0, 24), "0 s")


func test_real_duration_in_english() -> void:
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.real_duration(2400, 24), "1 min 40 s")
	assert_eq(UiFormat.real_duration(86400 * 2, 24), "2 h")


func test_game_duration_and_due_date() -> void:
	TranslationServer.set_locale("es")
	assert_eq(UiFormat.game_duration(1200), "20 min")
	assert_eq(UiFormat.game_duration(10800), "3 h")
	assert_eq(UiFormat.due_date(28800 + 2 * 86400 + 90), "Día 3 · 08:01")


func test_reason_translates_texts_and_formats_amounts() -> void:
	TranslationServer.set_locale("es")
	var busy: CommandResult = CommandResult.fail("ERR_PRINTER_BUSY", ["PRINTER_CUBO_UNO", CommandResult.seconds_arg(2400)])
	assert_eq(UiFormat.reason(busy, 24), "La Cubo Uno está ocupada: se libera en 1 min 40 s.")
	var grams: CommandResult = CommandResult.fail("ERR_NOT_ENOUGH_MATERIAL", [CommandResult.grams_arg(5), CommandResult.grams_arg(1320)])
	assert_eq(UiFormat.reason(grams, 24), "No alcanza el material: quedan 5 g y hacen falta 1.320 g.")
	var money: CommandResult = CommandResult.fail("ERR_NO_MONEY", [CommandResult.cents_arg(1550)])
	assert_eq(UiFormat.reason(money, 24), "Te falta dinero: cuesta $15,50.")
	var quality: CommandResult = CommandResult.fail("ERR_QUALITY", [2, 3])
	assert_eq(UiFormat.reason(quality, 24), "No alcanza la calidad: da 2 y pide 3.")
	var too_big: CommandResult = CommandResult.fail("ERR_TOO_BIG", ["PRINTER_CUBO_UNO", "S"])
	assert_eq(UiFormat.reason(too_big, 24), "No cabe: la Cubo Uno es tamaño S.", "El tamaño no es una clave y queda igual")


func test_reason_without_args_and_success() -> void:
	TranslationServer.set_locale("en")
	assert_eq(UiFormat.reason(CommandResult.fail("ERR_NOTHING_TO_PACK"), 24), "Nothing to pack.")
	assert_eq(UiFormat.reason(CommandResult.success(), 24), "")
	assert_eq(UiFormat.reason(null, 24), "")


func test_reason_of_a_busy_printer_from_the_rules() -> void:
	TranslationServer.set_locale("es")
	var rules: SimRules = SimRules.from_catalog(DataCatalog.load_from())
	var sim: Simulation = SimFixtures.new_sim(rules)
	SimFixtures.quiet_board(sim.state)
	var order: Order = SimFixtures.accept(sim, "llavero")
	SimFixtures.finish_designs(sim)
	var printer: OwnedPrinter = sim.state.printers[0]
	SimFixtures.start_print(sim, order, printer, sim.state.spools[0])
	var result: CommandResult = PrintRules.check_printer_free(sim.state, rules, printer)
	assert_eq(UiFormat.reason(result, rules.game_seconds_per_real_second), "La Cubo Uno está ocupada: se libera en 50 s.")
