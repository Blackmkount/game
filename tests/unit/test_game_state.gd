extends GutTest
## Partida nueva según config.starting_state (GDD 6.3).

var _catalog: DataCatalog
var _state: GameState


func before_each() -> void:
	_catalog = DataCatalog.load_from()
	_state = GameState.new_game(_catalog, 1234)


func test_starts_with_250_dollars_and_no_experience() -> void:
	assert_eq(_state.money_cents, 25000)
	assert_eq(_state.xp, 0)
	assert_eq(_state.rng_seed, 1234)


func test_starts_on_day_one_at_eight() -> void:
	assert_eq(GameClock.day(_state.game_minutes), 1)
	assert_eq(GameClock.hour(_state.game_minutes), 8)


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


func test_ids_are_unique() -> void:
	assert_ne(_state.furniture[0].uid, _state.printers[0].uid)
