class_name PrinterSheet
extends RefCounted
## Panel inferior de una impresora, según lo que está haciendo
## (OrderQueries.printer_status):
## - libre y sin nada para imprimir: sus datos, como siempre;
## - libre con un modelo listo: el plan para imprimirlo (tiempo, calidad,
##   riesgo, material y ganancia), con los modos, carretes y pedidos para
##   elegir, y el botón Imprimir;
## - imprimiendo: el pedido, la pieza y cuánto falta, con su barra;
## - con las piezas listas: el botón Retirar;
## - con una pieza fallada: qué se perdió, qué se guarda y Limpiar o Limpiar y
##   reintentar.
##
## Solo lee la partida. Los botones avisan un id de acción (print, retry,
## clean, remove, go_pack, orders...) y las opciones "mode_<id>",
## "spool_<uid>" y "order_<uid>"; OrderLoopController los corre.

## Fila de avance del trabajo (se cambia en el lugar con tick).
const JOB_ROW: String = "job"


## Arma el panel, o null si la impresora ya no está. `choice` es lo elegido en
## el plan (y el modo para reintentar); `error_text`, por qué no se pudo lo
## último que se intentó.
static func build(printer_uid: int, choice: PrintChoice, error_text: String = "") -> BottomSheet:
	var state: GameState = Game.state
	var rules: SimRules = Game.rules
	var printer: OwnedPrinter = state.find_printer(printer_uid)
	if printer == null:
		return null
	choice.printer_uid = printer_uid
	var sheet: BottomSheet = null
	match OrderQueries.printer_status(state, rules, printer):
		OrderQueries.PrinterStatus.IDLE_READY:
			sheet = _plan(state, rules, printer, choice)
		OrderQueries.PrinterStatus.PRINTING:
			sheet = _printing(state, rules, printer)
		OrderQueries.PrinterStatus.DONE:
			sheet = _done(state, rules, printer)
		OrderQueries.PrinterStatus.FAILED:
			sheet = _failed(state, rules, printer, choice)
	if sheet == null:
		sheet = _idle(state, rules, printer)
	if not error_text.is_empty():
		sheet.add_error(error_text)
	return sheet


## Cambia en el lugar cuánto falta y la barra del trabajo (una vez por segundo
## real), sin volver a armar el panel.
static func tick(sheet: BottomSheet, printer_uid: int, now: int) -> void:
	var printer: OwnedPrinter = Game.state.find_printer(printer_uid)
	if printer == null or printer.job == null or printer.job.status != PrintJob.Status.PRINTING:
		return
	var order: Order = Game.state.find_order(printer.job.order_uid)
	if order != null:
		sheet.set_progress(JOB_ROW, _ready_in(printer.job, order, now), _job_ratio(printer.job, order, now))


## Modo para reintentar la pieza que falló: el elegido en el panel, o el del
## trabajo.
static func retry_mode(rules: SimRules, printer: OwnedPrinter, choice: PrintChoice) -> String:
	if rules.modes.has(choice.mode_id) or printer == null or printer.job == null:
		return choice.mode_id
	return printer.job.mode_id


## Libre y sin nada para imprimir: los datos de la impresora.
static func _idle(state: GameState, rules: SimRules, printer: OwnedPrinter) -> BottomSheet:
	var definition: Dictionary = rules.printers[printer.printer_id]
	var sheet: BottomSheet = _sheet(state, rules, printer, _t(definition["name_key"]))
	sheet.add_line("star", _t("SHEET_PRINTER_IDLE"), UiPalette.XP_FILL)
	sheet.add_line("printer", UiFormat.tr_format("SHOP_PRINTER_STATS", [UiFormat.decimal(float(definition["speed"])), int(definition["max_quality"]), definition["volume"]]))
	var reliability: float = WorkshopRules.printer_reliability(state, rules, printer)
	sheet.add_line("check", UiFormat.tr_format("SHEET_PRINTER_RELIABILITY", [roundi(reliability * 100.0)]))
	var accessories: Array[String] = []
	for accessory_id: String in definition["built_in_accessories"] + printer.accessories:
		accessories.append(_t(rules.accessories[accessory_id]["name_key"]))
	if accessories.is_empty():
		sheet.add_line("wrench", _t("SHEET_PRINTER_NO_ACCESSORIES"), UiPalette.TEXT_MUTED)
	else:
		sheet.add_line("wrench", UiFormat.tr_format("SHEET_PRINTER_ACCESSORIES", [", ".join(accessories)]))
	if printer.is_on_floor():
		var penalty: int = roundi(WorkshopRules.floor_reliability_penalty(rules) * 100.0)
		sheet.add_tip(UiFormat.tr_format("SHEET_PRINTER_FLOOR_TIP", [penalty]))
		sheet.add_action("shop_furniture", _t("SHEET_BUY_TABLE"), true)
	sheet.add_action("orders", _t("SHEET_SEE_ORDERS"), not printer.is_on_floor())
	return sheet


## Libre con un modelo listo: el plan de impresión de lo elegido.
static func _plan(state: GameState, rules: SimRules, printer: OwnedPrinter, choice: PrintChoice) -> BottomSheet:
	var plan: PrintPlan = choice.normalize(state, rules)
	if plan == null:
		return null
	var order: Order = state.find_order(plan.order_uid)
	var rate: int = rules.game_seconds_per_real_second
	var sheet: BottomSheet = _sheet(state, rules, printer, UiFormat.tr_format("PLAN_TITLE", [_order_name(rules, order)]))
	var real: String = UiFormat.real_duration(plan.total_seconds, rate)
	var game: String = UiFormat.game_duration(plan.total_seconds)
	if plan.pieces > 1:
		sheet.add_line("calendar", UiFormat.tr_format("PLAN_TIME_PIECES", [plan.pieces, real, game]))
	else:
		sheet.add_line("calendar", UiFormat.tr_format("PLAN_TIME", [real, game]))
	sheet.add_line("star", _risk_text(plan.quality, plan.min_quality, plan.chance, plan.graced, plan.pieces))
	sheet.add_line("spool", UiFormat.tr_format("PLAN_MATERIAL", [
		UiFormat.grams(plan.grams_total), _material_text(rules, plan.material_id, plan.color_id), UiFormat.grams(plan.spool_grams),
	]))
	sheet.add_line("coin", UiFormat.tr_format("PLAN_MONEY", [UiFormat.money(plan.cost_cents), UiFormat.money(plan.profit_cents)]))
	sheet.add_chips("mode", _mode_chips(rules, printer, plan.min_quality, plan.mode_id))
	var spools: Array[Spool] = choice.usable_spools(state, rules, plan.mode_id)
	if spools.size() > 1:
		var options: Array[Dictionary] = []
		for spool: Spool in spools:
			var text: String = UiFormat.tr_format("CHIP_SPOOL", [_material_text(rules, spool.material_id, spool.color_id), UiFormat.grams(spool.grams)])
			options.append(_chip(str(spool.uid), text, spool.uid == plan.spool_uid, true))
		sheet.add_chips("spool", options)
	var orders: Array[Order] = choice.printable_orders(state, rules)
	if orders.size() > 1:
		var options: Array[Dictionary] = []
		for other: Order in orders:
			options.append(_chip(str(other.uid), _order_name(rules, other), other.uid == plan.order_uid, true))
		sheet.add_chips("order", options)
	if OrderQueries.count_stage(state, Order.Stage.TO_PACK) > 0:
		sheet.add_action("go_pack", _t("ACTION_GO_PACK"))
	sheet.add_action("print", _t("ACTION_PRINT"), true, plan.ok, UiFormat.reason(plan.reason, rate))
	return sheet


## Imprimiendo: el pedido, la pieza y cuánto falta para todo el pedido.
static func _printing(state: GameState, rules: SimRules, printer: OwnedPrinter) -> BottomSheet:
	var job: PrintJob = printer.job
	var order: Order = state.find_order(job.order_uid)
	if order == null:
		return null
	var sheet: BottomSheet = _sheet(state, rules, printer, _t(rules.printers[printer.printer_id]["name_key"]))
	sheet.add_line("printer", UiFormat.tr_format("PRINTING_LINE", [_order_name(rules, order)]))
	if job.pieces_total > 1:
		sheet.add_line("tasks", UiFormat.tr_format("PRINTING_PIECE", [order.pieces_done + 1, job.pieces_total]))
	var now: int = state.game_seconds
	sheet.add_progress(JOB_ROW, "calendar", _ready_in(job, order, now), _job_ratio(job, order, now))
	var spool: Spool = state.find_spool(job.spool_uid)
	var material: String = _material_text(rules, spool.material_id if spool != null else "", job.color_id)
	var quality: int = PrintRules.quality(rules, printer.printer_id, job.mode_id)
	sheet.add_line("spool", UiFormat.tr_format("PRINTING_SETTINGS", [material, _t(rules.modes[job.mode_id]["name_key"]), quality]))
	sheet.add_action("orders", _t("SHEET_SEE_ORDERS"))
	return sheet


## Las piezas están listas en la cama: hay que retirarlas.
static func _done(state: GameState, rules: SimRules, printer: OwnedPrinter) -> BottomSheet:
	var job: PrintJob = printer.job
	var order: Order = state.find_order(job.order_uid)
	if order == null:
		return null
	var sheet: BottomSheet = _sheet(state, rules, printer, _t(rules.printers[printer.printer_id]["name_key"]))
	var pieces: String = UiFormat.tr_format("ORDERS_PIECE" if job.pieces_total == 1 else "ORDERS_PIECES", [job.pieces_total])
	sheet.add_line("check", UiFormat.tr_format("DONE_LINE", [_order_name(rules, order), pieces]), UiPalette.XP_FILL)
	var remove: String = _t("ACTION_REMOVE") if job.pieces_total == 1 else UiFormat.tr_format("ACTION_REMOVE_N", [job.pieces_total])
	sheet.add_action("remove", remove, true)
	return sheet


## Falló una pieza: qué se perdió, qué se guarda y cómo seguir.
static func _failed(state: GameState, rules: SimRules, printer: OwnedPrinter, choice: PrintChoice) -> BottomSheet:
	var job: PrintJob = printer.job
	var order: Order = state.find_order(job.order_uid)
	if order == null:
		return null
	var failure: String = _t("FAILURE_" + job.failure_type.to_upper())
	var sheet: BottomSheet = _sheet(state, rules, printer, UiFormat.tr_format("FAILED_TITLE", [failure, job.fail_percent()]))
	var spool: Spool = state.find_spool(job.spool_uid)
	var material: String = _material_text(rules, spool.material_id if spool != null else "", job.color_id)
	sheet.add_line("warning", UiFormat.tr_format("FAILED_LOST", [UiFormat.grams(job.lost_grams), material]), UiPalette.BADGE)
	sheet.add_line("check", UiFormat.tr_format("FAILED_KEPT", [order.pieces_done, job.pieces_total]))
	var mode_id: String = retry_mode(rules, printer, choice)
	var min_quality: int = int(rules.orders[order.order_id]["min_quality"])
	if spool != null:
		var pieces: int = job.pieces_total - order.pieces_done
		var chances: Vector2 = FailureRules.chances(state, rules, printer, spool.material_id, mode_id)
		var graced: bool = state.pieces_started + pieces <= rules.grace_pieces
		sheet.add_line("star", _risk_text(PrintRules.quality(rules, printer.printer_id, mode_id), min_quality, chances.x + chances.y, graced, pieces))
	sheet.add_tip(_t("FAILED_TIP_" + job.failure_type.to_upper()))
	sheet.add_chips("mode", _mode_chips(rules, printer, min_quality, mode_id))
	sheet.add_action("clean", _t("ACTION_CLEAN"))
	var retry: CommandResult = PrintFlow.check_retry(state, rules, printer.uid, mode_id)
	sheet.add_action("retry", _t("ACTION_RETRY"), true, retry.ok, UiFormat.reason(retry, rules.game_seconds_per_real_second))
	return sheet


## Panel con la vista de la impresora, el título y dónde está.
static func _sheet(state: GameState, rules: SimRules, printer: OwnedPrinter, title: String) -> BottomSheet:
	var place: String = _t("SHEET_PRINTER_ON_FLOOR")
	if not printer.is_on_floor():
		for furniture: OwnedFurniture in state.furniture:
			if furniture.uid == printer.furniture_uid:
				place = UiFormat.tr_format("SHEET_PRINTER_ON_FURNITURE", [_t(rules.furniture[furniture.furniture_id]["name_key"])])
	return BottomSheet.new(Previews.printer(printer.printer_id), title, place)


## "Calidad 2 (pide 1) · Riesgo de fallo 20%", por pieza si son varias, o 0%
## mientras dura la calibración de Don Ernesto.
static func _risk_text(quality: int, min_quality: int, chance: float, graced: bool, pieces: int) -> String:
	if graced:
		return UiFormat.tr_format("PLAN_QUALITY_GRACE", [quality, min_quality])
	var key: String = "PLAN_QUALITY_RISK_PIECES" if pieces > 1 else "PLAN_QUALITY_RISK"
	return UiFormat.tr_format(key, [quality, min_quality, roundi(chance * 100.0)])


## Un botón por modo, en el orden de data/config.json. Los que no alcanzan la
## calidad que pide el pedido no se pueden elegir y dicen por qué.
static func _mode_chips(rules: SimRules, printer: OwnedPrinter, min_quality: int, selected: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for mode_id: String in rules.modes:
		var mode_name: String = _t(rules.modes[mode_id]["name_key"])
		var quality: int = PrintRules.quality(rules, printer.printer_id, mode_id)
		var enabled: bool = quality >= min_quality
		var text: String = mode_name if enabled else UiFormat.tr_format("CHIP_MODE_LOW_QUALITY", [mode_name, quality])
		options.append(_chip(mode_id, text, mode_id == selected, enabled))
	return options


static func _chip(id: String, text: String, selected: bool, enabled: bool) -> Dictionary:
	return {"id": id, "text": text, "selected": selected, "enabled": enabled}


## "Lista en 3 min 45 s": todas las piezas que faltan (nominal).
static func _ready_in(job: PrintJob, order: Order, now: int) -> String:
	var left: int = OrderQueries.order_seconds_left(job, order, now)
	return UiFormat.tr_format("PRINTING_READY_IN", [UiFormat.real_duration(left, Game.rules.game_seconds_per_real_second)])


## Avance de todo el pedido, de 0 a 1 (nominal).
static func _job_ratio(job: PrintJob, order: Order, now: int) -> float:
	return clampf((order.pieces_done + job.progress_at(now)) / float(job.pieces_total), 0.0, 1.0)


## "PLA Blanco": el material y su color.
static func _material_text(rules: SimRules, material_id: String, color_id: String) -> String:
	var material: String = _t(rules.materials[material_id]["name_key"]) if rules.materials.has(material_id) else ""
	if not rules.colors.has(color_id):
		return material
	return UiFormat.tr_format("MATERIAL_COLOR", [material, _t(rules.colors[color_id]["name_key"])])


static func _order_name(rules: SimRules, order: Order) -> String:
	return _t(rules.orders[order.order_id]["name_key"])


## tr() no se puede usar en funciones estáticas.
static func _t(key: String) -> String:
	return TranslationServer.translate(key)
