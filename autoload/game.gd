extends Node
## Punto de entrada de la presentación hacia la simulación (autoload "Game").
##
## - Carga y valida los datos de balance de data/.
## - Es dueño de la partida (GameState): al abrir el juego la carga con
##   SaveManager o empieza una nueva, y la avanza con el tiempo real.
## - Expone los comandos del jugador (accept_offer, start_print,
##   dispatch_order...), uno a uno con los de GameCommands. La interfaz nunca
##   modifica el estado directamente: siempre pasa por aquí y recibe un
##   CommandResult con el éxito o el motivo del error.
## - Después de cada comando y de cada avance avisa de los cambios con las
##   señales del autoload Events (_flush_changes) y pide guardar.

## Un cuadro largo (pestaña escondida, app que vuelve de segundo plano) no
## avanza más que esto: el juego se pausa en lugar de saltar. Constante técnica.
const MAX_FRAME_REAL_SECONDS: float = 1.0
## Motivo de los comandos cuando no hay partida (los datos no se pudieron cargar).
const ERR_NO_GAME: String = "ERR_NO_GAME"

var catalog: DataCatalog
var rules: SimRules
## Es rules.levels; se mantiene para la interfaz que ya la usa.
var levels: LevelTable
var state: GameState
var sim: Simulation
var commands: GameCommands
## Se está probando una escena del panel de depuración (start_trial): nada
## se guarda hasta que se vuelva a abrir el juego.
var trial: bool = false

## Último minuto de juego y último segundo real avisados; -1 = avisar en el
## próximo avance (partida recién empezada o cargada).
var _last_minute: int = -1
var _last_tick: int = -1


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
	var loaded: GameState = SaveManager.load_state(rules)
	_start(loaded if loaded != null else GameState.new_game(rules, randi()))


func _process(delta: float) -> void:
	advance(minf(delta, MAX_FRAME_REAL_SECONDS))


## Empieza una partida nueva con esa semilla. No guarda: quien la pide decide
## (Ajustes guarda enseguida; las pruebas corren con el guardado apagado).
func reset_game(p_seed: int) -> void:
	if rules == null:
		return
	_start(GameState.new_game(rules, p_seed))


## Panel de depuración: juega con `p_state` (el taller lleno, otra hora)
## sin tocar la partida del jugador: primero guarda la de verdad y después
## apaga el guardado hasta que se vuelva a abrir el juego.
func start_trial(p_state: GameState) -> void:
	if not trial:
		SaveManager.save_now()
	trial = true
	SaveManager.enabled = false
	_start(p_state)


## Avanza la partida `real_seconds` segundos reales. _process lo llama con el
## tiempo del cuadro limitado; las pruebas y las capturas, sin límite.
func advance(real_seconds: float) -> void:
	if sim == null:
		return
	sim.advance(real_seconds)
	_flush_changes()
	var minute: int = floori(state.game_minutes)
	if minute != _last_minute:
		_last_minute = minute
		Events.time_changed.emit(state.game_minutes)
	var tick: int = floori(float(state.game_seconds) / rules.game_seconds_per_real_second)
	if tick != _last_tick:
		_last_tick = tick
		Events.clock_ticked.emit(state.game_seconds)


func level() -> int:
	return OrderQueries.level(state, rules)


# --- Comandos del jugador (ver GameCommands) ----------------------------------


func accept_offer(offer_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.accept_offer(offer_uid))


func reject_offer(offer_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.reject_offer(offer_uid))


func focus_design(order_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.focus_design(order_uid))


func start_print(order_uid: int, printer_uid: int, spool_uid: int, mode_id: String) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.start_print(order_uid, printer_uid, spool_uid, mode_id))


func retry_piece(printer_uid: int, mode_id: String) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.retry_piece(printer_uid, mode_id))


func clean_printer(printer_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.clean_printer(printer_uid))


func remove_pieces(printer_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.remove_pieces(printer_uid))


func pack_order(order_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.pack_order(order_uid))


func dispatch_order(order_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.dispatch_order(order_uid))


func cancel_order(order_uid: int) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.cancel_order(order_uid))


func buy_local_material(material_id: String) -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _finish(commands.buy_local_material(material_id))


## Embala todos los pedidos con las piezas retiradas. `count` dice cuántos.
func pack_all() -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _run_on_stage(Order.Stage.TO_PACK, commands.pack_order, "ERR_NOTHING_TO_PACK")


## Despacha todos los pedidos embalados. `cents`, `xp` y `count` son la suma.
func dispatch_all() -> CommandResult:
	if state == null:
		return CommandResult.fail(ERR_NO_GAME)
	return _run_on_stage(Order.Stage.PACKED, commands.dispatch_order, "ERR_NOTHING_TO_DISPATCH")


# --- Interno ------------------------------------------------------------------


func _start(p_state: GameState) -> void:
	state = p_state
	sim = Simulation.new(state, rules)
	commands = GameCommands.new(sim)
	# Si al cargar se descartó el pedido que se modelaba (su id ya no existe en
	# data/), la fila del computador sigue con el próximo. Con algo modelándose
	# no hace nada.
	DesignFlow.start_next(sim, state.game_seconds)
	_last_minute = -1
	_last_tick = -1
	Events.game_loaded.emit()


## Termina un comando: avisa lo que cambió y, si se pudo, pide guardar.
func _finish(result: CommandResult) -> CommandResult:
	_flush_changes()
	if result.ok:
		SaveManager.request_save()
	return result


## Corre `command` con cada pedido que está en la etapa `stage`, en orden de
## uid, sobre una copia de la lista (cada comando la cambia), y suma lo cobrado,
## la experiencia y cuántos se pudieron. Sin ninguno, falla con `none_reason`.
func _run_on_stage(stage: Order.Stage, command: Callable, none_reason: String) -> CommandResult:
	var uids: Array[int] = []
	for order: Order in state.orders:
		if order.stage == stage:
			uids.append(order.uid)
	if uids.is_empty():
		return CommandResult.fail(none_reason)
	var total: CommandResult = CommandResult.success()
	for uid: int in uids:
		var result: CommandResult = command.call(uid)
		if result.ok:
			total.cents += result.cents
			total.xp += result.xp
			total.count += 1
	return _finish(total)


## Convierte lo que cambió (sim.changes) en señales de Events, en este orden
## fijo, y pide guardar. El acumulador se reemplaza antes de avisar: si quien
## escucha usa un comando, sus cambios se avisan después y no se pierden.
func _flush_changes() -> void:
	var changes: SimChanges = sim.changes
	if changes.is_empty():
		return
	sim.changes = SimChanges.new()
	for uid: int in changes.printers:
		Events.printer_changed.emit(uid)
	for uid: int in changes.failures:
		var printer: OwnedPrinter = state.find_printer(uid)
		if printer != null and printer.job != null:
			Events.print_failed.emit(uid, printer.job.failure_type)
	if changes.computer:
		Events.computer_changed.emit()
	for uid: int in changes.orders:
		if not changes.removed_orders.has(uid):
			Events.order_changed.emit(uid)
	for uid: int in changes.removed_orders:
		Events.order_removed.emit(uid)
	if changes.offers:
		Events.offers_changed.emit()
	for uid: int in changes.arrived_offers:
		Events.offer_arrived.emit(uid)
	if changes.spools:
		Events.spools_changed.emit()
	if changes.money:
		Events.money_changed.emit(state.money_cents)
	if changes.xp:
		Events.xp_changed.emit(state.xp)
	for delivery: Delivery in changes.deliveries:
		Events.order_delivered.emit(delivery.order_uid, delivery.order_id, delivery.cents, delivery.xp, delivery.late)
	if changes.level_up > 0:
		Events.level_up.emit(changes.level_up)
	SaveManager.request_save()
