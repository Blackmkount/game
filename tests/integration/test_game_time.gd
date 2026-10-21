extends GutTest
## El autoload Game avanza la partida con el tiempo real, y un cuadro largo
## (pestaña escondida, app que vuelve de segundo plano) pausa en lugar de saltar.


func test_long_frame_advances_at_most_one_real_second() -> void:
	var before: int = Game.state.game_seconds
	Game._process(30.0)
	assert_eq(Game.state.game_seconds - before, Game.rules.game_seconds_per_real_second)


func test_advance_is_not_limited() -> void:
	var before: int = Game.state.game_seconds
	Game.advance(30.0)
	assert_eq(Game.state.game_seconds - before, 30 * Game.rules.game_seconds_per_real_second)


func test_levels_come_from_the_rules() -> void:
	assert_same(Game.levels, Game.rules.levels)
