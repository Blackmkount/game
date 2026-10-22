class_name PrintChoice
extends RefCounted
## Lo que el jugador eligió en el panel de una impresora: qué pedido, con qué
## carrete y en qué modo. Es solo de la interfaz (no se guarda en la partida).
## Lo que no eligió, o lo que ya no sirve, toma lo recomendado
## (PrintPlanner.recommend).

var printer_uid: int = -1
## -1 = el primer pedido con el modelo listo que esta impresora puede tomar.
var order_uid: int = -1
## -1 = el carrete recomendado.
var spool_uid: int = -1
## "" = el modo recomendado.
var mode_id: String = ""


func _init(p_printer_uid: int = -1, p_order_uid: int = -1) -> void:
	printer_uid = p_printer_uid
	order_uid = p_order_uid


## Plan con lo elegido. Si el pedido ya no está listo para imprimir (o esta
## impresora no lo puede tomar), toma otro que sí; si el carrete ya no está, se
## vació o no sirve, o el modo no existe o no alcanza la calidad, usa lo
## recomendado. Corrige la elección para que diga lo que muestra el plan. Sin
## ningún pedido listo devuelve null.
func normalize(state: GameState, rules: SimRules) -> PrintPlan:
	var order: Order = state.find_order(order_uid)
	if order == null or not printable_orders(state, rules).has(order):
		order = _fallback_order(state, rules)
		spool_uid = -1
	if order == null:
		order_uid = -1
		return null
	order_uid = order.uid
	var best: PrintPlan = PrintPlanner.recommend(state, rules, order, printer_uid)
	if not best.ok:
		spool_uid = best.spool_uid
		mode_id = best.mode_id
		return best
	var printer: OwnedPrinter = state.find_printer(printer_uid)
	# El carrete y el modo se revisan por separado: con la impresora libre, que
	# uno sirva no depende del otro.
	if not PrintPlanner.evaluate(state, rules, order, printer, state.find_spool(spool_uid), best.mode_id).ok:
		spool_uid = best.spool_uid
	if not PrintPlanner.evaluate(state, rules, order, printer, state.find_spool(best.spool_uid), mode_id).ok:
		mode_id = best.mode_id
	return PrintPlanner.evaluate(state, rules, order, printer, state.find_spool(spool_uid), mode_id)


## Pedidos con el modelo listo que esta impresora puede imprimir ahora, en
## orden de uid.
func printable_orders(state: GameState, rules: SimRules) -> Array[Order]:
	var printable: Array[Order] = []
	for order: Order in state.orders:
		if order.stage == Order.Stage.READY_TO_PRINT and PrintPlanner.recommend(state, rules, order, printer_uid).ok:
			printable.append(order)
	return printable


## Carretes con los que se puede imprimir el pedido elegido en esta impresora,
## en orden de uid. Llamar después de normalize.
func usable_spools(state: GameState, rules: SimRules, mode: String) -> Array[Spool]:
	var usable: Array[Spool] = []
	var order: Order = state.find_order(order_uid)
	var printer: OwnedPrinter = state.find_printer(printer_uid)
	for spool: Spool in state.spools:
		if spool.grams > 0 and PrintPlanner.evaluate(state, rules, order, printer, spool, mode).ok:
			usable.append(spool)
	return usable


## El primer pedido listo que esta impresora puede tomar; si ninguno, el
## primero listo (su plan dirá por qué no).
func _fallback_order(state: GameState, rules: SimRules) -> Order:
	var printable: Array[Order] = printable_orders(state, rules)
	if not printable.is_empty():
		return printable[0]
	for order: Order in state.orders:
		if order.stage == Order.Stage.READY_TO_PRINT:
			return order
	return null
