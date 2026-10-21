extends Node
## Punto de entrada de la presentación hacia la simulación (autoload "Game").
##
## - Carga y valida los datos de balance de data/.
## - Es dueño de la partida (GameState) y la avanza con el tiempo real.
## - Más adelante expone los comandos del jugador (accept_order, start_print,
##   buy_item...). La interfaz nunca modifica el estado directamente: siempre
##   pasa por aquí.
## - Avisa de los cambios a través de las señales del autoload Events.

## Un cuadro largo (pestaña escondida, app que vuelve de segundo plano) no
## avanza más que esto: el juego se pausa en lugar de saltar. Constante técnica.
const MAX_FRAME_REAL_SECONDS: float = 1.0

var catalog: DataCatalog
var rules: SimRules
## Es rules.levels; se mantiene para la interfaz que ya la usa.
var levels: LevelTable
var state: GameState
var sim: Simulation

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
	rules = SimRules.from_catalog(catalog)
	levels = rules.levels
	state = GameState.new_game(rules, randi())
	sim = Simulation.new(state, rules)


func _process(delta: float) -> void:
	advance(minf(delta, MAX_FRAME_REAL_SECONDS))


## Avanza la partida `real_seconds` segundos reales. _process lo llama con el
## tiempo del cuadro limitado; las pruebas y las capturas, sin límite.
func advance(real_seconds: float) -> void:
	if sim == null:
		return
	sim.advance(real_seconds)
	var minute: int = floori(state.game_minutes)
	if minute != _last_minute:
		_last_minute = minute
		Events.time_changed.emit(state.game_minutes)


func level() -> int:
	return levels.level_for_xp(state.xp)
