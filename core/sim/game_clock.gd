class_name GameClock
extends RefCounted
## Calendario del juego. La partida cuenta segundos de juego enteros desde el
## día 1 a las 00:00 (GameState.game_seconds); estas funciones reciben minutos
## de juego (GameState.game_minutes).

const MINUTES_PER_DAY: int = 1440
const MINUTES_PER_HOUR: int = 60
const SECONDS_PER_MINUTE: int = 60
const SECONDS_PER_HOUR: int = 3600
const SECONDS_PER_DAY: int = 86400


static func day(game_minutes: float) -> int:
	return int(floor(game_minutes / MINUTES_PER_DAY)) + 1


static func hour(game_minutes: float) -> int:
	return int(floor(fposmod(game_minutes, MINUTES_PER_DAY) / MINUTES_PER_HOUR))


static func minute(game_minutes: float) -> int:
	return int(floor(fposmod(game_minutes, MINUTES_PER_HOUR)))
