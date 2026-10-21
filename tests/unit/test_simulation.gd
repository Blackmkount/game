extends GutTest
## Avance del tiempo: 1 hora real = 1 día de juego, y el resultado no depende
## del tamaño de los pasos.

var _catalog: DataCatalog


func before_each() -> void:
	_catalog = DataCatalog.load_from()


func test_one_real_hour_is_one_game_day() -> void:
	var state: GameState = GameState.new_game(_catalog, 1)
	var start: float = state.game_minutes
	Simulation.new(state, _catalog).advance(3600.0)
	assert_almost_eq(state.game_minutes - start, 1440.0, 0.0001)


func test_big_step_equals_many_small_steps() -> void:
	var big: GameState = GameState.new_game(_catalog, 1)
	var small: GameState = GameState.new_game(_catalog, 1)
	Simulation.new(big, _catalog).advance(8.0 * 3600.0)
	var simulation: Simulation = Simulation.new(small, _catalog)
	for i: int in 28800:
		simulation.advance(1.0)
	assert_almost_eq(small.game_minutes, big.game_minutes, 0.001)


func test_zero_or_negative_time_does_nothing() -> void:
	var state: GameState = GameState.new_game(_catalog, 1)
	var start: float = state.game_minutes
	var simulation: Simulation = Simulation.new(state, _catalog)
	simulation.advance(0.0)
	simulation.advance(-50.0)
	assert_eq(state.game_minutes, start)
