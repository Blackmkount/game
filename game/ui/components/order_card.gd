class_name OrderCard
extends PanelContainer
## Tarjeta de un pedido en curso: en qué paso va (StepTracker), qué está
## pasando y cuánto falta, el plazo y el botón del paso siguiente, que cambia
## con la etapa (ver _next_action).
##
## "Cancelar pedido" pide un segundo toque. La cuenta la lleva OrdersScreen,
## para que no se pierda si la tarjeta se vuelve a armar entre los dos toques.
##
## tick() cambia en el lugar las cuentas regresivas, la barra, el plazo y la
## nota del botón, una vez por segundo real. Lo demás se vuelve a armar cuando
## cambia el pedido.

## Botón del paso siguiente: "focus", "print", "see_printer", "remove",
## "pack" o "dispatch", con el uid del pedido.
signal card_action(verb: String, uid: int)
## Se tocó "Cancelar pedido" (el primero o el segundo toque).
signal cancel_tapped(uid: int)

const ICON_SIZE: float = 56.0
const BUTTON_HEIGHT: float = 88.0
const BAR_HEIGHT: float = 16.0
## El botón para cancelar se ve chico (sin fondo), pero se toca en 88 px.
const CANCEL_HEIGHT: float = 88.0
const CANCEL_FONT_SIZE: int = 19

var uid: int

var _order: Order
var _confirming: bool
var _status: Label
var _bar: ProgressBar
var _deadline: Label
var _note: Label
var _cancel: Button


## `confirming`: el primer toque de "Cancelar pedido" ya se hizo.
func _init(order: Order, confirming: bool = false) -> void:
	_order = order
	uid = order.uid
	_confirming = confirming
	name = "Order_%d" % order.uid
	theme_type_variation = "CardPanel"
	# Deja pasar el arrastre a la lista, para poder desplazarla desde la tarjeta.
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	var state: GameState = Game.state
	var rules: SimRules = Game.rules
	var step: int = OrderQueries.step_index(_order)
	var column: VBoxContainer = UiKit.vbox(10)
	add_child(column)
	column.add_child(_header(rules, step))
	var tracker: StepTracker = StepTracker.new(step)
	tracker.name = "Steps_%d" % uid
	column.add_child(tracker)
	var failed: bool = _job_status() == PrintJob.Status.FAILED
	_status = UiKit.label("", "BoldLabel" if failed else "", true)
	_status.name = "Status"
	if failed:
		_status.add_theme_color_override("font_color", UiPalette.BADGE)
	column.add_child(_status)
	if _order.stage == Order.Stage.DESIGNING or (_order.stage == Order.Stage.PRINTING and not failed):
		_bar = ProgressBar.new()
		_bar.name = "Progress"
		_bar.show_percentage = false
		_bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
		_bar.min_value = 0.0
		_bar.max_value = 1.0
		_bar.step = 0.0
		_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_bar)
	if _order.due_live >= 0:
		_deadline = UiKit.label("", "SmallLabel", true)
		_deadline.name = "Deadline"
		column.add_child(_deadline)
	_add_actions(column, _next_action(state, rules))
	tick(state.game_seconds)


## Cambia en el lugar lo que depende del reloj.
func tick(now: int) -> void:
	_status.text = _status_text(now)
	if _bar != null:
		_bar.value = _progress(now)
	if _deadline != null:
		var late: bool = OrderQueries.is_late(Game.state, _order)
		if late:
			_deadline.text = tr("ORDERS_LATE")
		else:
			_deadline.text = UiFormat.tr_format("ORDERS_DEADLINE", [UiFormat.due_date(OrderQueries.due_game_seconds(Game.state, _order))])
		_deadline.add_theme_color_override("font_color", UiPalette.BADGE if late else UiPalette.TEXT_MUTED)
	if _note != null:
		_note.text = _note_text(now)


## Muestra "Cancelar pedido" o, después del primer toque, "¿Seguro? Toca otra vez".
func set_confirming(confirming: bool) -> void:
	_confirming = confirming
	_cancel.text = tr("ORDERS_CANCEL_CONFIRM" if confirming else "ORDERS_CANCEL")
	var color: Color = UiPalette.BADGE if confirming else UiPalette.TEXT_MUTED
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		_cancel.add_theme_color_override(color_name, color)


## Icono del paso actual, nombre del pedido y cliente.
func _header(rules: SimRules, step: int) -> Control:
	var definition: Dictionary = rules.orders[_order.order_id]
	var row: HBoxContainer = UiKit.hbox(12)
	var tile: PanelContainer = UiKit.icon_tile(StepTracker.icon_for(step), ICON_SIZE, UiPalette.ACCENT)
	tile.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(tile)
	var names: VBoxContainer = UiKit.vbox(2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(names)
	names.add_child(UiKit.label(tr(definition["name_key"]), "BoldLabel", true))
	names.add_child(UiKit.label(tr(rules.clients[definition["client"]]["name_key"]), "SmallLabel", true))
	return row


## Qué está pasando con el pedido, con su cuenta regresiva si corresponde.
func _status_text(now: int) -> String:
	var rate: int = Game.rules.game_seconds_per_real_second
	match _order.stage:
		Order.Stage.WAITING_DESIGN:
			var wait: int = OrderQueries.queue_wait_seconds(Game.state, Game.rules, _order, now)
			return UiFormat.tr_format("STAGE_WAITING_DESIGN", [UiFormat.real_duration(wait, rate)])
		Order.Stage.DESIGNING:
			return UiFormat.tr_format("STAGE_DESIGNING", [UiFormat.real_duration(OrderQueries.design_seconds_left(_order, now), rate)])
		Order.Stage.READY_TO_PRINT:
			return tr("STAGE_READY")
		Order.Stage.PRINTING:
			return _printing_text(now, rate)
		Order.Stage.PRINTED:
			return UiFormat.tr_format("STAGE_PRINTED", [_printer_name()])
		Order.Stage.TO_PACK:
			return tr("STAGE_TO_PACK")
	return tr("STAGE_PACKED")


func _printing_text(now: int, rate: int) -> String:
	var printer: OwnedPrinter = OrderQueries.printer_for_order(Game.state, _order)
	if printer == null or printer.job == null:
		return ""
	var job: PrintJob = printer.job
	var piece: int = _order.pieces_done + 1
	if job.status == PrintJob.Status.FAILED:
		return UiFormat.tr_format("STAGE_FAILED", [piece, job.pieces_total, _printer_name()])
	var left: String = UiFormat.real_duration(OrderQueries.order_seconds_left(job, _order, now), rate)
	if job.pieces_total > 1:
		return UiFormat.tr_format("STAGE_PRINTING_PIECES", [piece, job.pieces_total, _printer_name(), left])
	return UiFormat.tr_format("STAGE_PRINTING", [_printer_name(), left])


## Avance de la barra: el modelado, o todas las piezas del pedido (nominal).
func _progress(now: int) -> float:
	if _order.stage == Order.Stage.DESIGNING:
		return OrderQueries.design_progress(_order, Game.rules, now)
	var printer: OwnedPrinter = OrderQueries.printer_for_order(Game.state, _order)
	if printer == null or printer.job == null:
		return 0.0
	var job: PrintJob = printer.job
	return clampf((_order.pieces_done + job.progress_at(now)) / float(job.pieces_total), 0.0, 1.0)


## Botón del paso siguiente según la etapa: {"verb", "text", "enabled"}, o
## vacío si no hay nada que tocar (se modela sin poder concentrarse, o se
## imprime).
func _next_action(state: GameState, rules: SimRules) -> Dictionary:
	match _order.stage:
		Order.Stage.WAITING_DESIGN:
			return {"verb": "", "text": tr("ACTION_QUEUED"), "enabled": false}
		Order.Stage.DESIGNING:
			if OrderQueries.focus_available(_order, rules):
				return {"verb": "focus", "text": tr("ACTION_FOCUS"), "enabled": true}
		Order.Stage.READY_TO_PRINT:
			var plan: PrintPlan = PrintPlanner.recommend(state, rules, _order)
			return {"verb": "print", "text": tr("ACTION_PRINT"), "enabled": plan.ok}
		Order.Stage.PRINTING:
			if _job_status() == PrintJob.Status.FAILED:
				return {"verb": "see_printer", "text": tr("ACTION_SEE_PRINTER"), "enabled": true}
		Order.Stage.PRINTED:
			var pieces: int = int(rules.orders[_order.order_id]["pieces"])
			var text: String = tr("ACTION_REMOVE") if pieces == 1 else UiFormat.tr_format("ACTION_REMOVE_N", [pieces])
			return {"verb": "remove", "text": text, "enabled": true}
		Order.Stage.TO_PACK:
			return {"verb": "pack", "text": tr("ACTION_PACK"), "enabled": true}
		Order.Stage.PACKED:
			return {"verb": "dispatch", "text": tr("ACTION_DISPATCH"), "enabled": true}
	return {}


## Por qué el botón está deshabilitado: cuándo empieza a modelarse o por qué
## no se puede imprimir todavía.
func _note_text(now: int) -> String:
	var rate: int = Game.rules.game_seconds_per_real_second
	if _order.stage == Order.Stage.WAITING_DESIGN:
		var wait: int = OrderQueries.queue_wait_seconds(Game.state, Game.rules, _order, now)
		return UiFormat.tr_format("NOTE_STARTS_IN", [UiFormat.real_duration(wait, rate)])
	return UiFormat.reason(PrintPlanner.recommend(Game.state, Game.rules, _order).reason, rate)


## "Cancelar pedido" (chico, a la izquierda) y el botón del paso siguiente.
func _add_actions(column: VBoxContainer, next: Dictionary) -> void:
	var row: HBoxContainer = UiKit.hbox(10)
	row.name = "Actions"
	column.add_child(row)
	_cancel = Button.new()
	_cancel.name = "Cancel_%d" % uid
	_cancel.flat = true
	_cancel.focus_mode = Control.FOCUS_NONE
	_cancel.custom_minimum_size = Vector2(0, CANCEL_HEIGHT)
	_cancel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_cancel.add_theme_font_size_override("font_size", CANCEL_FONT_SIZE)
	_cancel.pressed.connect(func() -> void: cancel_tapped.emit(uid))
	row.add_child(_cancel)
	set_confirming(_confirming)
	if next.is_empty():
		return
	var verb: String = next["verb"]
	var button: Button = Button.new()
	button.name = "Next_%d" % uid
	button.text = next["text"]
	button.theme_type_variation = "PrimaryButton"
	button.disabled = not next["enabled"]
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: card_action.emit(verb, uid))
	row.add_child(button)
	if button.disabled:
		_note = UiKit.label("", "MutedLabel", true)
		_note.name = "NextNote_%d" % uid
		column.add_child(_note)


func _job_status() -> int:
	var printer: OwnedPrinter = OrderQueries.printer_for_order(Game.state, _order)
	if _order.stage != Order.Stage.PRINTING or printer == null or printer.job == null:
		return -1
	return printer.job.status


func _printer_name() -> String:
	var printer: OwnedPrinter = OrderQueries.printer_for_order(Game.state, _order)
	if printer == null:
		return ""
	return tr(Game.rules.printers[printer.printer_id]["name_key"])
