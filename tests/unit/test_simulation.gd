extends GutTest
## Avance del tiempo con un reloj de segundos de juego enteros: 1 hora real =
## 1 día de juego, y el resultado no depende del tamaño de los pasos.

var _rules: SimRules


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())


func test_one_real_hour_is_one_game_day() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	Simulation.new(state, _rules).advance(3600.0)
	assert_eq(state.game_seconds - start, 86400)
	assert_eq(state.live_seconds, 86400)


func test_big_step_equals_many_small_steps() -> void:
	var big: GameState = GameState.new_game(_rules, 1)
	var small: GameState = GameState.new_game(_rules, 1)
	Simulation.new(big, _rules).advance(8.0 * 3600.0)
	var simulation: Simulation = Simulation.new(small, _rules)
	for i: int in 28800:
		simulation.advance(1.0)
	assert_eq(small.game_seconds, big.game_seconds)
	assert_eq(small.live_seconds, big.live_seconds)


func test_fractions_of_a_second_carry_over() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	var simulation: Simulation = Simulation.new(state, _rules)
	simulation.advance(1.0 / 64.0)
	assert_eq(state.game_seconds, start, "1/64 s real son 0,375 s de juego: todavía no hay un segundo entero")
	simulation.advance(1.0 / 64.0)
	simulation.advance(1.0 / 64.0)
	assert_eq(state.game_seconds, start + 1, "3/64 s real son 1,125 s de juego")
	for i: int in 61:
		simulation.advance(1.0 / 64.0)
	assert_eq(state.game_seconds, start + 24, "64 pasos de 1/64 s son 1 s real")


func test_zero_or_negative_time_does_nothing() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	var simulation: Simulation = Simulation.new(state, _rules)
	simulation.advance(0.0)
	simulation.advance(-50.0)
	simulation.advance_game_seconds(0)
	simulation.advance_game_seconds(-5)
	assert_eq(state.game_seconds, start)
	assert_eq(state.live_seconds, 0)


func test_time_away_moves_the_clock_but_not_the_deadlines() -> void:
	var state: GameState = GameState.new_game(_rules, 1)
	var start: int = state.game_seconds
	var simulation: Simulation = Simulation.new(state, _rules)
	simulation.advance(10.0, false)
	assert_eq(state.game_seconds, start + 240)
	assert_eq(state.live_seconds, 0, "Fuera del juego los plazos no corren")
	simulation.advance_game_seconds(60)
	assert_eq(state.live_seconds, 60)
