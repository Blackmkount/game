extends GutTest
## Partida nueva según config.starting_state (GDD 6.3).

var _rules: SimRules
var _state: GameState


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_state = GameState.new_game(_rules, 1234)


func test_starts_with_250_dollars_and_no_experience() -> void:
	assert_eq(_state.money_cents, 25000)
	assert_eq(_state.xp, 0)
	assert_eq(_state.rng_seed, 1234)


func test_starts_on_day_one_at_eight() -> void:
	assert_eq(_state.game_seconds, 28800)
	assert_eq(_state.live_seconds, 0)
	assert_eq(_state.game_minutes, 480.0)
	assert_eq(GameClock.day(_state.game_minutes), 1)
	assert_eq(GameClock.hour(_state.game_minutes), 8)
	assert_eq(GameClock.minute(_state.game_minutes), 0)


func test_game_minutes_is_read_only() -> void:
	_state.game_minutes = 5.0
	assert_push_error("solo lectura")
	assert_eq(_state.game_seconds, 28800)


func test_starts_with_one_kilo_of_white_pla() -> void:
	assert_eq(_state.spools.size(), 1)
	assert_eq(_state.spools[0].material_id, "pla")
	assert_eq(_state.spools[0].color_id, "blanco")
	assert_eq(_state.spools[0].grams, 1000)
	assert_eq(_state.total_grams(), 1000)


func test_starts_with_table_and_old_computer() -> void:
	assert_eq(_state.furniture.size(), 1)
	assert_eq(_state.furniture[0].furniture_id, "mesa_computador")
	assert_eq(_state.furniture[0].slot, 0)


func test_printer_starts_on_the_floor() -> void:
	assert_eq(_state.printers.size(), 1)
	assert_eq(_state.printers[0].printer_id, "cubo_uno")
	assert_true(_state.printers[0].is_on_floor(), "La mesa del computador no tiene lugar para impresoras")


func test_uids_go_furniture_then_printer_then_spool() -> void:
	assert_eq(_state.furniture[0].uid, 1)
	assert_eq(_state.printers[0].uid, 2)
	assert_eq(_state.spools[0].uid, 3)
	assert_eq(_state.take_uid(), 4)


func test_first_message_is_scripted() -> void:
	assert_eq(_state.scripted_offers, ["llavero"] as Array[String])
	assert_eq(_state.next_offer_at, 28860, "El llavero llega al primer minuto de juego")


func test_scripted_offers_are_a_copy() -> void:
	_state.scripted_offers.clear()
	assert_eq(_rules.starting_offers, ["llavero"] as Array[String])


func test_both_random_streams_are_seeded_and_differ() -> void:
	var twin: GameState = GameState.new_game(_rules, 1234)
	assert_eq(_state.orders_rng.seed, 1234)
	assert_eq(_state.prints_rng.seed, 1234 ^ GameState.PRINTS_STREAM_SALT)
	var orders_draw: float = _state.orders_rng.randf()
	var prints_draw: float = _state.prints_rng.randf()
	assert_ne(orders_draw, prints_draw)
	assert_eq(twin.orders_rng.randf(), orders_draw, "Misma semilla, mismos números")
	assert_eq(twin.prints_rng.randf(), prints_draw)
