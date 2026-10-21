extends GutTest
## Calendario del juego: días, horas y minutos a partir de minutos de juego.


func test_start_of_first_day() -> void:
	assert_eq(GameClock.day(0.0), 1)
	assert_eq(GameClock.hour(0.0), 0)
	assert_eq(GameClock.minute(0.0), 0)


func test_morning_of_first_day() -> void:
	var minutes: float = 8 * 60 + 30
	assert_eq(GameClock.day(minutes), 1)
	assert_eq(GameClock.hour(minutes), 8)
	assert_eq(GameClock.minute(minutes), 30)


func test_next_day_starts_at_midnight() -> void:
	assert_eq(GameClock.day(1439.9), 1)
	assert_eq(GameClock.day(1440.0), 2)
	assert_eq(GameClock.hour(1440.0 + 61.0), 1)
	assert_eq(GameClock.minute(1440.0 + 61.0), 1)
