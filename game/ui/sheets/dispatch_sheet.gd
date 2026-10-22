class_name DispatchSheet
extends RefCounted
## Panel inferior del rincón de despacho: los pedidos por embalar (las piezas
## que se retiraron de la impresora) y los embalados listos para salir, con
## cómo se entregan, lo que se cobra y si van atrasados.
##
## Solo lee la partida. Los botones avisan "pack" (embalar todo), "dispatch"
## (despachar todo lo embalado) u "orders"; OrderLoopController los corre.


static func build(error_text: String = "") -> BottomSheet:
	var state: GameState = Game.state
	var rules: SimRules = Game.rules
	var sheet: BottomSheet = BottomSheet.new(Previews.icon("truck"), _t("DISPATCH_TITLE"), _t("DISPATCH_DESC"))
	if not error_text.is_empty():
		sheet.add_error(error_text)
	var to_pack: int = 0
	var packed: int = 0
	for order: Order in state.orders:
		var definition: Dictionary = rules.orders[order.order_id]
		var order_name: String = _t(definition["name_key"])
		var late: bool = OrderQueries.is_late(state, order)
		if order.stage == Order.Stage.TO_PACK:
			to_pack += 1
			sheet.add_line("box", UiFormat.tr_format("DISPATCH_TO_PACK", [order_name]))
		elif order.stage == Order.Stage.PACKED:
			packed += 1
			# Lo que se cobra de verdad: atrasado es menos.
			var cents: String = UiFormat.money(OrderQueries.payout_cents(state, rules, order))
			var delivery: String = _t(rules.clients[definition["client"]]["delivery_key"])
			sheet.add_line("truck", UiFormat.tr_format("DISPATCH_PACKED", [order_name, delivery, cents, OrderQueries.payout_xp(state, rules, order)]))
		else:
			continue
		if late:
			sheet.add_line("warning", UiFormat.tr_format("DISPATCH_LATE", [order_name]), UiPalette.BADGE)
	if to_pack > 0:
		sheet.add_action("pack", _t("ACTION_PACK"), true)
		if packed > 0:
			sheet.add_action("dispatch", UiFormat.tr_format("ACTION_DISPATCH_N", [packed]))
	elif packed > 0:
		var text: String = _t("ACTION_DISPATCH") if packed == 1 else UiFormat.tr_format("ACTION_DISPATCH_N", [packed])
		sheet.add_action("dispatch", text, true)
	else:
		sheet.add_line("box", _t("DISPATCH_EMPTY"), UiPalette.TEXT_MUTED)
		sheet.add_action("orders", _t("SHEET_SEE_ORDERS"), true)
	return sheet


## Cuántos pedidos del rincón (por embalar o embalados) van atrasados. El
## plazo vence con el reloj, sin ninguna señal: OrderLoopController lo revisa
## una vez por segundo y rearma el panel si cambió.
static func late_count(state: GameState) -> int:
	var count: int = 0
	for order: Order in state.orders:
		if (order.stage == Order.Stage.TO_PACK or order.stage == Order.Stage.PACKED) and OrderQueries.is_late(state, order):
			count += 1
	return count


## tr() no se puede usar en funciones estáticas.
static func _t(key: String) -> String:
	return TranslationServer.translate(key)
