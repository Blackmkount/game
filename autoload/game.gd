extends Node
## Punto de entrada de la presentación hacia la simulación (autoload "Game").
##
## - Carga y valida los datos de balance de data/.
## - Es dueño de la partida (GameState) y la avanza con el tiempo real.
## - Más adelante expone los comandos del jugador (accept_order, start_print,
##   buy_item...). La interfaz nunca modifica el estado directamente: siempre
##   pasa por aquí.
## - Avisa de los cambios a través de las señales del autoload Events.

var catalog: DataCatalog
var levels: LevelTable
var state: GameState

var _simulation: Simulation
var _last_minute: int = -1


func _ready() -> void:
	catalog = DataCatalog.load_from()
	var errors: Array[String] = catalog.errors.duplicate()
	if errors.is_empty():
		errors.append_array(DataValidator.validate(catalog.files, []))
	if not errors.is_empty():
		for error: String in errors:
			push_error("Datos de balance: " + error)
		set_process(false)
		return
	levels = LevelTable.from_catalog(catalog)
	state = GameState.new_game(catalog, randi())
	_simulation = Simulation.new(state, catalog)


func _process(delta: float) -> void:
	_simulation.advance(delta)
	var minute: int = int(state.game_minutes)
	if minute != _last_minute:
		_last_minute = minute
		Events.time_changed.emit(state.game_minutes)


func level() -> int:
	return levels.level_for_xp(state.xp)
