class_name Simulation
extends RefCounted
## Avanza una partida con el tiempo. Es el mismo avance para el juego en vivo,
## para el progreso fuera del juego y para el simulador de balance.
##
## El reloj cuenta segundos de juego enteros. advance() convierte el tiempo
## real y guarda la fracción de segundo que sobra en _carry, que no se guarda
## en la partida. Los eventos se procesan en su segundo exacto y en orden de
## tiempo. Por ahora hay uno: el mensaje nuevo del tablero; el fin de modelado
## y el fin de pieza se agregan en los pasos siguientes del ciclo de pedidos.

## Salvaguarda técnica para que un avance nunca quede dando vueltas sin fin.
const MAX_EVENTS_PER_ADVANCE: int = 100000
## "No hay eventos pendientes": el mayor entero posible.
const NO_EVENT: int = 9223372036854775807

var state: GameState
var rules: SimRules
## Lo que cambió desde el último aviso; Game lo vacía al emitir las señales.
var changes: SimChanges = SimChanges.new()

## Fracción de segundo de juego que sobró del último avance. NO se guarda.
var _carry: float = 0.0
## true cuando un comando cambió el estado y hay que volver a buscar eventos.
var _dirty: bool = true
var _next_event_time: int = NO_EVENT


func _init(p_state: GameState, p_rules: SimRules) -> void:
	state = p_state
	rules = p_rules


## Avanza `real_seconds` segundos reales. Con live = false (progreso fuera del
## juego) los plazos no corren.
func advance(real_seconds: float, live: bool = true) -> void:
	if real_seconds <= 0.0:
		return
	_carry += real_seconds * float(rules.game_seconds_per_real_second)
	var whole: int = floori(_carry)
	_carry -= float(whole)
	if whole > 0:
		advance_game_seconds(whole, live)


## Avanza `seconds` segundos de juego, procesando cada evento en su segundo
## exacto.
func advance_game_seconds(seconds: int, live: bool = true) -> void:
	if seconds <= 0:
		return
	var target: int = state.game_seconds + seconds
	if not _dirty and target < _next_event_time:
		# Camino rápido de casi todos los cuadros: no hay eventos en el medio.
		_move_to(target, live)
		return
	var processed: int = 0
	while true:
		var t: int = _scan_next_event_time()
		if t > target:
			break
		if processed >= MAX_EVENTS_PER_ADVANCE:
			push_error("Simulation: demasiados eventos en un avance")
			_next_event_time = t
			_dirty = false
			# El reloj queda en el último evento procesado: nunca se salta eventos.
			return
		_move_to(maxi(t, state.game_seconds), live)
		_process_events_at(state.game_seconds)
		processed += 1
	_move_to(target, live)
	_next_event_time = _scan_next_event_time()
	_dirty = false


## Un comando cambió el estado: el próximo avance vuelve a buscar eventos.
func mark_dirty() -> void:
	_dirty = true


func _move_to(t: int, live: bool) -> void:
	if live:
		state.live_seconds += t - state.game_seconds
	state.game_seconds = t


## Segundo de juego del próximo evento pendiente, o NO_EVENT.
func _scan_next_event_time() -> int:
	var next: int = NO_EVENT
	if state.next_offer_at >= 0:
		next = mini(next, state.next_offer_at)
	return next


## Procesa los eventos del segundo `t` en orden fijo: impresoras, computador y
## tablero. Por ahora solo el tablero.
func _process_events_at(t: int) -> void:
	if state.next_offer_at == t:
		OrderBoard.on_refill(self, t)
