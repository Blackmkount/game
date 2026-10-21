extends GutTest
## SimRules convierte una sola vez los números de data/*.json en enteros:
## segundos de juego, gramos y centavos.

var _rules: SimRules


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())


func test_one_real_second_is_24_game_seconds() -> void:
	assert_eq(_rules.game_seconds_per_real_second, 24)


func test_board_times_in_game_seconds() -> void:
	assert_eq(_rules.offer_interval_seconds, 3600, "Un mensaje nuevo cada 60 minutos de juego")
	assert_eq(_rules.first_offer_seconds, 60, "El primer mensaje llega al minuto de juego")
	assert_eq(_rules.starting_gap_seconds, 1620, "El segundo mensaje llega 27 minutos de juego después")
	assert_eq(_rules.board_slots, 3)
	assert_eq(_rules.max_active_orders, 3)
	assert_eq(_rules.starting_offers, ["llavero"] as Array[String])


func test_design_and_deadline_in_game_seconds() -> void:
	assert_eq(_rules.design_seconds["llavero"], 240)
	assert_eq(_rules.deadline_seconds["perilla"], 259200, "3 días de plazo")
	assert_eq(_rules.deadline_seconds["llavero"], 0, "0 = sin plazo")
	assert_eq(_rules.prep_seconds_per_piece, 0)


func test_order_grams_and_payment() -> void:
	assert_eq(_rules.order_grams["llavero"], 8)
	assert_eq(_rules.payment_cents["llavero"], 600)


func test_grams_round_up() -> void:
	var catalog: DataCatalog = DataCatalog.load_from()
	catalog.files["orders"][0]["grams_per_piece"] = 7.2
	assert_eq(SimRules.from_catalog(catalog).order_grams[catalog.files["orders"][0]["id"]], 8)


func test_failure_rules() -> void:
	assert_true(_rules.stop_ranges.has("spaghetti"))
	assert_true(_rules.stop_ranges.has("warping"))
	assert_almost_eq(_rules.stop_ranges["spaghetti"].x, 0.10, 0.0001)
	assert_almost_eq(_rules.stop_ranges["spaghetti"].y, 0.60, 0.0001)
	assert_almost_eq(_rules.max_chance, 0.9, 0.0001)
	assert_eq(_rules.grace_pieces, 3)


func test_lookups_by_id_and_file_order() -> void:
	assert_eq(_rules.printers["cubo_uno"]["name_key"], "PRINTER_CUBO_UNO")
	assert_eq(_rules.modes["fine"]["quality_delta"], 1.0)
	assert_eq(_rules.colors["blanco"]["hex"], "f2efe6")
	assert_eq(_rules.order_list[0], "llavero")
	assert_eq(_rules.order_list.size(), _rules.orders.size())
	assert_eq(_rules.best_quality_delta, 1)
	assert_eq(_rules.levels.level_for_xp(100), 2)
