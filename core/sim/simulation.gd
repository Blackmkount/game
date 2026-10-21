class_name Simulation
extends RefCounted
## Avanza una partida con el tiempo. Es el mismo avance para el juego en vivo,
## para el progreso fuera del juego y para el simulador de balance.
##
## Por ahora solo mueve el reloj. Las impresiones, los envíos y los pedidos
## se agregan en las siguientes tareas de la Fase 1.

var state: GameState
var _game_seconds_per_real_second: float


func _init(p_state: GameState, catalog: DataCatalog) -> void:
	state = p_state
	_game_seconds_per_real_second = float(catalog.files["config"]["time"]["game_seconds_per_real_second"])


## Avanza la partida `real_seconds` segundos reales.
func advance(real_seconds: float) -> void:
	if real_seconds <= 0.0:
		return
	state.game_minutes += real_seconds * _game_seconds_per_real_second / 60.0
