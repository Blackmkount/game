class_name StatusPresenter
extends Node
## Lo que muestran las burbujas de estado sobre los objetos del ciclo de
## pedidos (cada impresora, la mesa del computador y el rincón de despacho) y
## la burbuja de cercanía. Es hijo de WorldControls, que lo crea al armarse.
##
## - El contenido (icono, color, texto, latido) cambia solo con las señales de
##   Events y con el reloj (Events.clock_ticked, una vez por segundo real).
## - Las posiciones se ponen en cada cuadro (place_bubbles), solo con valores:
##   sin crear nada.
## - bubble_icon dice qué muestra la burbuja de cercanía del objeto resaltado
##   (QuickActions). Lo que hace se decide al tocarla
##   (OrderLoopController.run_quick), con la partida de ese momento.
##
## Una burbuja no se ve si su objeto no tiene nada que contar, si es el que
## tiene el panel abierto, si la burbuja de cercanía lo reemplaza o si queda
## fuera de la pantalla.

## Distancia entre el objeto y la punta de abajo de la burbuja.
const LIFT: float = 8.0

## Icono de la burbuja de cercanía del objeto resaltado.
var bubble_icon: String = ""

var _controls: WorldControls
var _items: Array[WorldInteractable] = []
## Índice de la burbuja de cada objeto en hud.status_bubbles.
var _indices: Array[int] = []
## El objeto tiene algo que mostrar.
var _active: Array[bool] = []
## Su texto cambia con el reloj (cuenta regresiva).
var _ticking: Array[bool] = []
var _highlighted: WorldInteractable = null
var _refresh_queued: bool = false


func _init(controls: WorldControls) -> void:
	_controls = controls


func _ready() -> void:
	if Game.state == null:
		return
	for item: WorldInteractable in _controls.room.interactables:
		var desk: bool = item.kind == WorldInteractable.Kind.FURNITURE and QuickActions.is_computer_desk(Game.state, item.ref)
		if item.kind == WorldInteractable.Kind.PRINTER or item.kind == WorldInteractable.Kind.DISPATCH or desk:
			_items.append(item)
			_indices.append(_controls.hud.status_bubbles.add(item))
			_active.append(false)
			_ticking.append(false)
	Events.printer_changed.connect(_queue_refresh.unbind(1))
	Events.computer_changed.connect(_queue_refresh)
	Events.order_changed.connect(_queue_refresh.unbind(1))
	Events.order_removed.connect(_queue_refresh.unbind(1))
	Events.spools_changed.connect(_queue_refresh)
	Events.game_loaded.connect(_queue_refresh)
	Events.clock_ticked.connect(_on_clock_ticked)
	_refresh()


## El personaje se acercó a otro objeto (o a ninguno).
func on_highlight_changed(item: WorldInteractable) -> void:
	_highlighted = item
	_update_quick()


## La burbuja de estado de `item`, o null si ese objeto no tiene.
func bubble_for(item: WorldInteractable) -> StatusBubble:
	var i: int = _items.find(item)
	return _controls.hud.status_bubbles.bubble(_indices[i]) if i >= 0 else null


## Pone cada burbuja sobre su objeto y decide si se ve. Se llama en cada
## cuadro, después de mover la cámara.
func place_bubbles() -> void:
	var bubbles: StatusBubbles = _controls.hud.status_bubbles
	var screen: Rect2 = Rect2(Vector2.ZERO, _controls.hud.get_viewport_rect().size)
	for i: int in _items.size():
		var item: WorldInteractable = _items[i]
		var shown: bool = _active[i] and item != _controls.sheet_item \
				and not (item == _controls.highlighted and _controls.sheet_item == null)
		if shown:
			var anchor: Vector2 = _controls.world_to_ui(item.top_center())
			shown = screen.has_point(anchor)
			if shown:
				var size: Vector2 = bubbles.bubble(_indices[i]).size
				var top_left: Vector2 = anchor - Vector2(size.x / 2.0, size.y + LIFT)
				bubbles.place(_indices[i], _controls.hud.keep_in_world(Rect2(top_left, size)))
		bubbles.set_visible_for(_indices[i], shown)


## Se recalcula al final del cuadro: los avisos de un mismo cambio se juntan.
func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh.call_deferred()


func _refresh() -> void:
	_refresh_queued = false
	if Game.state == null:
		return
	for i: int in _items.size():
		_update(i)
	_update_quick()


func _on_clock_ticked(_game_seconds: int) -> void:
	for i: int in _items.size():
		if _ticking[i]:
			_update(i)


func _update_quick() -> void:
	if _highlighted == null or Game.state == null:
		bubble_icon = ""
		return
	bubble_icon = QuickActions.for_item(Game.state, Game.rules, _highlighted)["icon"]


## Lo que muestra la burbuja del objeto `i` según la partida de ahora.
func _update(i: int) -> void:
	var item: WorldInteractable = _items[i]
	var state: GameState = Game.state
	var rules: SimRules = Game.rules
	var rate: int = rules.game_seconds_per_real_second
	var now: int = state.game_seconds
	var bubble: StatusBubble = _controls.hud.status_bubbles.bubble(_indices[i])
	_active[i] = true
	_ticking[i] = false
	match item.kind:
		WorldInteractable.Kind.PRINTER:
			var printer: OwnedPrinter = state.find_printer(item.ref)
			var status: int = OrderQueries.printer_status(state, rules, printer) if printer != null else OrderQueries.PrinterStatus.IDLE
			match status:
				OrderQueries.PrinterStatus.PRINTING:
					_ticking[i] = true
					bubble.set_state("printer", _printing_text(state, printer.job, now, rate), UiPalette.ACCENT, false)
				OrderQueries.PrinterStatus.DONE:
					var pieces: int = printer.job.pieces_total
					bubble.set_state("check", str(pieces) if pieces > 1 else "", UiPalette.XP_FILL, true)
				OrderQueries.PrinterStatus.FAILED:
					bubble.set_state("warning", "", UiPalette.BADGE, true)
				OrderQueries.PrinterStatus.IDLE_READY:
					bubble.set_state("printer", "", UiPalette.ACCENT, true)
				_:
					_active[i] = false
		WorldInteractable.Kind.FURNITURE:
			var designing: Order = state.find_order(state.designing_uid)
			_active[i] = designing != null
			_ticking[i] = _active[i]
			if designing != null:
				bubble.set_state("design", UiFormat.real_duration(OrderQueries.design_seconds_left(designing, now), rate), UiPalette.ACCENT, false)
		WorldInteractable.Kind.DISPATCH:
			var to_pack: int = OrderQueries.count_stage(state, Order.Stage.TO_PACK)
			var packed: int = OrderQueries.count_stage(state, Order.Stage.PACKED)
			_active[i] = to_pack + packed > 0
			if _active[i]:
				bubble.set_state("box" if to_pack > 0 else "truck", str(to_pack + packed), UiPalette.GOLD, false)


## "50 s", o "2/4 · 4 min" con varias piezas: cuánto falta para todo el pedido.
func _printing_text(state: GameState, job: PrintJob, now: int, rate: int) -> String:
	var order: Order = state.find_order(job.order_uid)
	if order == null:
		return ""
	var left: String = UiFormat.real_duration(OrderQueries.order_seconds_left(job, order, now), rate)
	if job.pieces_total > 1:
		return UiFormat.tr_format("STATUS_PIECES", [order.pieces_done, job.pieces_total, left])
	return left
