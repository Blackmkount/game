class_name DeskSheet
extends RefCounted
## Panel inferior de la mesa del computador, donde se modelan los pedidos: qué
## se modela y cuánto falta (con su barra), qué espera en la fila, el consejo
## de concentrarse y qué modelos están listos para imprimir.
##
## Solo lee la partida. Los botones avisan "focus" (concentrarse en el modelo
## en curso), "print_ready" (abrir la impresora para el primer modelo listo)
## u "orders"; OrderLoopController los corre.

## El mueble donde se modela.
const FURNITURE_ID: String = "mesa_computador"
## Fila de avance del modelado (se cambia en el lugar con tick).
const DESIGN_ROW: String = "design"


## Arma el panel, o null si el mueble ya no está.
static func build(furniture_uid: int, error_text: String = "") -> BottomSheet:
	var state: GameState = Game.state
	var rules: SimRules = Game.rules
	var furniture: OwnedFurniture = null
	for item: OwnedFurniture in state.furniture:
		if item.uid == furniture_uid:
			furniture = item
	if furniture == null:
		return null
	var name_key: String = rules.furniture[furniture.furniture_id]["name_key"]
	var sheet: BottomSheet = BottomSheet.new(Previews.furniture(furniture.furniture_id), _t(name_key), _t(name_key + "_DESC"))
	if not error_text.is_empty():
		sheet.add_error(error_text)
	var now: int = state.game_seconds
	var designing: Order = state.find_order(state.designing_uid)
	if designing != null:
		var kind: String = _t("DESIGN_KIND_" + String(rules.orders[designing.order_id]["design_kind"]).to_upper())
		sheet.add_line("design", UiFormat.tr_format("DESK_DESIGNING", [_order_name(rules, designing), kind]))
		sheet.add_progress(DESIGN_ROW, "calendar", _ready_in(designing, now), OrderQueries.design_progress(designing, rules, now))
	var queued: Array[String] = _names(rules, state, Order.Stage.WAITING_DESIGN)
	if not queued.is_empty():
		sheet.add_line("tasks", UiFormat.tr_format("DESK_QUEUE", [", ".join(queued)]))
	var focus: bool = designing != null and OrderQueries.focus_available(designing, rules)
	if focus:
		sheet.add_tip(UiFormat.tr_format("DESK_FOCUS_TIP", [roundi((1.0 - rules.focus_multiplier) * 100.0)]))
	elif designing != null and designing.focused:
		sheet.add_line("star", _t("DESK_FOCUSED"), UiPalette.GOLD)
	var ready: Array[String] = _names(rules, state, Order.Stage.READY_TO_PRINT)
	if not ready.is_empty():
		sheet.add_line("check", UiFormat.tr_format("DESK_READY", [", ".join(ready)]), UiPalette.XP_FILL)
	if designing == null:
		sheet.add_line("design", _t("SHEET_COMPUTER_IDLE"), UiPalette.TEXT_MUTED)
	if focus:
		sheet.add_action("orders", _t("SHEET_SEE_ORDERS"))
		sheet.add_action("focus", _t("ACTION_FOCUS"), true)
	elif not ready.is_empty():
		sheet.add_action("orders", _t("SHEET_SEE_ORDERS"))
		var plan: PrintPlan = PrintPlanner.recommend(state, rules, first_ready(state))
		sheet.add_action("print_ready", _t("ACTION_PRINT"), true, plan.ok, UiFormat.reason(plan.reason, rules.game_seconds_per_real_second))
	else:
		sheet.add_action("orders", _t("SHEET_SEE_ORDERS"), true)
	return sheet


## Cambia en el lugar cuánto falta y la barra del modelado (una vez por
## segundo real), sin volver a armar el panel.
static func tick(sheet: BottomSheet, now: int) -> void:
	var designing: Order = Game.state.find_order(Game.state.designing_uid)
	if designing != null:
		sheet.set_progress(DESIGN_ROW, _ready_in(designing, now), OrderQueries.design_progress(designing, Game.rules, now))


## El primer pedido (menor uid) con el modelo listo para imprimir, o null.
static func first_ready(state: GameState) -> Order:
	for order: Order in state.orders:
		if order.stage == Order.Stage.READY_TO_PRINT:
			return order
	return null


static func _ready_in(order: Order, now: int) -> String:
	var left: String = UiFormat.real_duration(OrderQueries.design_seconds_left(order, now), Game.rules.game_seconds_per_real_second)
	return UiFormat.tr_format("DESK_READY_IN", [left])


## Nombres de los pedidos en esa etapa, en orden de uid.
static func _names(rules: SimRules, state: GameState, stage: Order.Stage) -> Array[String]:
	var names: Array[String] = []
	for order: Order in state.orders:
		if order.stage == stage:
			names.append(_order_name(rules, order))
	return names


static func _order_name(rules: SimRules, order: Order) -> String:
	return _t(rules.orders[order.order_id]["name_key"])


## tr() no se puede usar en funciones estáticas.
static func _t(key: String) -> String:
	return TranslationServer.translate(key)
