class_name GameClock
extends RefCounted
## Calendario del juego. El tiempo se guarda como minutos de juego desde el
## día 1 a las 00:00.

const MINUTES_PER_DAY: int = 1440
const MINUTES_PER_HOUR: int = 60


static func day(game_minutes: float) -> int:
	return int(floor(game_minutes / MINUTES_PER_DAY)) + 1


static func hour(game_minutes: float) -> int:
	return int(floor(fposmod(game_minutes, MINUTES_PER_DAY) / MINUTES_PER_HOUR))


static func minute(game_minutes: float) -> int:
	return int(floor(fposmod(game_minutes, MINUTES_PER_HOUR)))
