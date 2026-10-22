class_name SaveCodec
extends RefCounted
## Convierte una partida (GameState) en un diccionario para guardarlo como
## JSON, y de vuelta.
##
## - El diccionario solo tiene int, String, bool, Array, Dictionary y null:
##   nada de float, para que guardar y cargar sea exacto. Los enum van como su
##   nombre en minúsculas ("designing", "printing").
## - La semilla y el estado de los dos flujos de azar son enteros de 64 bits y
##   van como texto: JSON los leería como float y perdería precisión.
## - decode() nunca se cae. Si algo está roto devuelve null y anota el motivo
##   en errors. Los mensajes y pedidos cuyo id ya no existe en data/ se
##   descartan, y lo que quedó sin su pedido o su carrete se arregla
##   (ver _repair).

const CURRENT_VERSION: int = 1


## Lleva un guardado completo (el sobre con "version") a CURRENT_VERSION.
## Devuelve {} si la versión no es válida o es más nueva que la de este juego:
## esa partida no se puede cargar.
static func migrate(doc: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var version: int = SaveReader.new(errors).integer(doc, "version")
	if not errors.is_empty() or version < 1 or version > CURRENT_VERSION:
		return {}
	return doc


static func encode(state: GameState) -> Dictionary:
	var furniture: Array = []
	for item: OwnedFurniture in state.furniture:
		furniture.append({"uid": item.uid, "furniture_id": item.furniture_id, "slot": item.slot})
	var spools: Array = []
	for spool: Spool in state.spools:
		spools.append({"uid": spool.uid, "material_id": spool.material_id, "color_id": spool.color_id, "grams": spool.grams})
	var printers: Array = []
	for printer: OwnedPrinter in state.printers:
		var job: Variant = null
		if printer.job != null:
			job = _encode_job(printer.job)
		printers.append({
			"uid": printer.uid,
			"printer_id": printer.printer_id,
			"furniture_uid": printer.furniture_uid,
			"accessories": printer.accessories.duplicate(),
			"job": job,
		})
	var offers: Array = []
	for offer: OrderOffer in state.offers:
		offers.append({"uid": offer.uid, "order_id": offer.order_id, "arrived_at": offer.arrived_at})
	var orders: Array = []
	for order: Order in state.orders:
		orders.append(_encode_order(order))
	var deliveries: Array = []
	for delivery: Delivery in state.recent_deliveries:
		deliveries.append(_encode_delivery(delivery))
	return {
		"money_cents": state.money_cents,
		"xp": state.xp,
		"game_seconds": state.game_seconds,
		"live_seconds": state.live_seconds,
		"space_id": state.space_id,
		"rng_seed": str(state.rng_seed),
		"orders_rng_state": str(state.orders_rng.state),
		"prints_rng_state": str(state.prints_rng.state),
		"furniture": furniture,
		"spools": spools,
		"printers": printers,
		"offers": offers,
		"next_offer_at": state.next_offer_at,
		"scripted_offers": state.scripted_offers.duplicate(),
		"last_offer_order_id": state.last_offer_order_id,
		"orders": orders,
		"pieces_started": state.pieces_started,
		"delivered_total": state.delivered_total,
		"delivered_by_order": state.delivered_by_order.duplicate(),
		"recent_deliveries": deliveries,
		"next_uid": state.next_uid,
	}


## Arma la partida desde lo que devolvió encode() (o el mismo diccionario
## leído de JSON). Devuelve null si está rota, con los motivos en errors.
static func decode(doc: Dictionary, rules: SimRules, errors: Array[String]) -> GameState:
	var before: int = errors.size()
	var read: SaveReader = SaveReader.new(errors)
	var state: GameState = GameState.new()
	state.money_cents = read.integer(doc, "money_cents")
	state.xp = read.integer(doc, "xp")
	state.game_seconds = read.integer(doc, "game_seconds")
	state.live_seconds = read.integer(doc, "live_seconds")
	state.space_id = read.known_id(doc, "space_id", rules.spaces)
	# Primero la semilla y después el estado: fijar la semilla reinicia el estado.
	state.rng_seed = read.big_integer(doc, "rng_seed")
	state.orders_rng.seed = state.rng_seed
	state.orders_rng.state = read.big_integer(doc, "orders_rng_state")
	state.prints_rng.seed = state.rng_seed ^ GameState.PRINTS_STREAM_SALT
	state.prints_rng.state = read.big_integer(doc, "prints_rng_state")
	for entry: Dictionary in read.entries(doc, "furniture"):
		state.furniture.append(OwnedFurniture.new(read.integer(entry, "uid"), read.known_id(entry, "furniture_id", rules.furniture), read.integer(entry, "slot")))
	for entry: Dictionary in read.entries(doc, "spools"):
		state.spools.append(Spool.new(read.integer(entry, "uid"), read.known_id(entry, "material_id", rules.materials), read.known_id(entry, "color_id", rules.colors), read.integer(entry, "grams")))
	for entry: Dictionary in read.entries(doc, "printers"):
		state.printers.append(_decode_printer(read, entry, rules))
	for entry: Dictionary in read.entries(doc, "offers"):
		var offer: OrderOffer = OrderOffer.new(read.integer(entry, "uid"), read.text(entry, "order_id"), read.integer(entry, "arrived_at"))
		if rules.orders.has(offer.order_id):
			state.offers.append(offer)
	state.next_offer_at = read.integer(doc, "next_offer_at")
	for order_id: String in read.texts(doc, "scripted_offers"):
		if rules.orders.has(order_id):
			state.scripted_offers.append(order_id)
	state.last_offer_order_id = read.text(doc, "last_offer_order_id")
	if not rules.orders.has(state.last_offer_order_id):
		state.last_offer_order_id = ""
	for entry: Dictionary in read.entries(doc, "orders"):
		var order: Order = _decode_order(read, entry, rules)
		if rules.orders.has(order.order_id):
			state.orders.append(order)
	state.pieces_started = read.integer(doc, "pieces_started")
	state.delivered_total = read.integer(doc, "delivered_total")
	var delivered: Dictionary = read.dictionary(doc, "delivered_by_order")
	for order_id: Variant in delivered:
		if order_id is String and rules.orders.has(order_id):
			state.delivered_by_order[order_id] = read.integer(delivered, order_id)
	for entry: Dictionary in read.entries(doc, "recent_deliveries"):
		var delivery: Delivery = _decode_delivery(read, entry)
		if rules.orders.has(delivery.order_id):
			state.recent_deliveries.append(delivery)
	state.next_uid = read.integer(doc, "next_uid")
	if errors.size() > before:
		return null
	state.printers.sort_custom(func(a: OwnedPrinter, b: OwnedPrinter) -> bool: return a.uid < b.uid)
	state.orders.sort_custom(func(a: Order, b: Order) -> bool: return a.uid < b.uid)
	_repair(state, rules)
	_check(state, errors)
	return null if errors.size() > before else state


static func _encode_job(job: PrintJob) -> Dictionary:
	return {
		"order_uid": job.order_uid,
		"spool_uid": job.spool_uid,
		"mode_id": job.mode_id,
		"color_id": job.color_id,
		"pieces_total": job.pieces_total,
		"grams_per_piece": job.grams_per_piece,
		"piece_seconds": job.piece_seconds,
		"piece_started_at": job.piece_started_at,
		"ends_at": job.ends_at,
		"fails": job.fails,
		"failure_type": job.failure_type,
		"lost_grams": job.lost_grams,
		"status": _enum_name(PrintJob.Status, job.status),
	}


static func _encode_order(order: Order) -> Dictionary:
	return {
		"uid": order.uid,
		"order_id": order.order_id,
		"stage": _enum_name(Order.Stage, order.stage),
		"accepted_at": order.accepted_at,
		"due_live": order.due_live,
		"design_ends_at": order.design_ends_at,
		"focused": order.focused,
		"pieces_done": order.pieces_done,
		"printer_uid": order.printer_uid,
		"color_id": order.color_id,
	}


static func _encode_delivery(delivery: Delivery) -> Dictionary:
	return {
		"order_uid": delivery.order_uid,
		"order_id": delivery.order_id,
		"cents": delivery.cents,
		"xp": delivery.xp,
		"late": delivery.late,
		"thanks_key": delivery.thanks_key,
		"delivered_at": delivery.delivered_at,
	}


static func _decode_printer(read: SaveReader, entry: Dictionary, rules: SimRules) -> OwnedPrinter:
	var printer: OwnedPrinter = OwnedPrinter.new(read.integer(entry, "uid"), read.known_id(entry, "printer_id", rules.printers), read.integer(entry, "furniture_uid"))
	for accessory_id: String in read.texts(entry, "accessories"):
		if not rules.accessories.has(accessory_id):
			read.errors.append("'accessories' tiene un id desconocido: '%s'" % accessory_id)
		printer.accessories.append(accessory_id)
	var job: Variant = entry.get("job")
	if job is Dictionary:
		printer.job = _decode_job(read, job)
	elif job != null:
		read.errors.append("'job' debe ser un objeto o null")
	return printer


static func _decode_job(read: SaveReader, entry: Dictionary) -> PrintJob:
	var job: PrintJob = PrintJob.new()
	job.order_uid = read.integer(entry, "order_uid")
	job.spool_uid = read.integer(entry, "spool_uid")
	job.mode_id = read.text(entry, "mode_id")
	job.color_id = read.text(entry, "color_id")
	job.pieces_total = read.integer(entry, "pieces_total")
	job.grams_per_piece = read.integer(entry, "grams_per_piece")
	job.piece_seconds = read.integer(entry, "piece_seconds")
	job.piece_started_at = read.integer(entry, "piece_started_at")
	job.ends_at = read.integer(entry, "ends_at")
	job.fails = read.flag(entry, "fails")
	job.failure_type = read.text(entry, "failure_type")
	job.lost_grams = read.integer(entry, "lost_grams")
	job.status = read.enum_value(entry, "status", PrintJob.Status) as PrintJob.Status
	return job


static func _decode_order(read: SaveReader, entry: Dictionary, rules: SimRules) -> Order:
	var order: Order = Order.new(read.integer(entry, "uid"), read.text(entry, "order_id"), read.integer(entry, "accepted_at"))
	order.stage = read.enum_value(entry, "stage", Order.Stage) as Order.Stage
	order.due_live = read.integer(entry, "due_live")
	order.design_ends_at = read.integer(entry, "design_ends_at")
	order.focused = read.flag(entry, "focused")
	order.pieces_done = read.integer(entry, "pieces_done")
	order.printer_uid = read.integer(entry, "printer_uid")
	order.color_id = read.text(entry, "color_id")
	if not rules.colors.has(order.color_id):
		order.color_id = ""
	return order


static func _decode_delivery(read: SaveReader, entry: Dictionary) -> Delivery:
	return Delivery.new(read.integer(entry, "order_uid"), read.text(entry, "order_id"), read.integer(entry, "cents"),
		read.integer(entry, "xp"), read.flag(entry, "late"), read.text(entry, "thanks_key"), read.integer(entry, "delivered_at"))


## Arregla referencias rotas sin perder la partida. Un trabajo cuyo pedido,
## carrete, modo, color o tipo de fallo ya no existe, o que no corresponde a
## la etapa de su pedido, se descarta (la impresora queda libre). Un pedido
## "imprimiendo" o "impreso" sin su trabajo vuelve a "listo para imprimir".
## Un tablero en pausa al que se le descartaron mensajes vuelve a esperar el
## próximo: sin mensajes no habría nada que responder para reanudarlo.
static func _repair(state: GameState, rules: SimRules) -> void:
	OrderBoard.resume_if_paused(state, rules, state.game_seconds)
	for printer: OwnedPrinter in state.printers:
		if printer.job != null and not _job_fits(state, rules, printer):
			printer.job = null
	for order: Order in state.orders:
		var on_printer: bool = order.stage == Order.Stage.PRINTING or order.stage == Order.Stage.PRINTED
		if on_printer and _job_of(state, order) == null:
			order.stage = Order.Stage.READY_TO_PRINT
			on_printer = false
		if not on_printer:
			order.printer_uid = -1


static func _job_fits(state: GameState, rules: SimRules, printer: OwnedPrinter) -> bool:
	var job: PrintJob = printer.job
	var order: Order = state.find_order(job.order_uid)
	if order == null or order.printer_uid != printer.uid or state.find_spool(job.spool_uid) == null:
		return false
	if not rules.modes.has(job.mode_id) or not rules.colors.has(job.color_id):
		return false
	if job.failure_type != "" and not rules.stop_ranges.has(job.failure_type):
		return false
	var expected: Order.Stage = Order.Stage.PRINTED if job.status == PrintJob.Status.DONE else Order.Stage.PRINTING
	return order.stage == expected


static func _job_of(state: GameState, order: Order) -> PrintJob:
	var printer: OwnedPrinter = state.find_printer(order.printer_uid)
	if printer == null or printer.job == null or printer.job.order_uid != order.uid:
		return null
	return printer.job


## Revisa lo que no se puede arreglar: uids repetidos o fuera de rango, más de
## un pedido modelándose y eventos pendientes en el pasado (el avance no
## podría procesarlos). Calcula designing_uid.
static func _check(state: GameState, errors: Array[String]) -> void:
	_check_uids(state, errors)
	for printer: OwnedPrinter in state.printers:
		if printer.furniture_uid != OwnedPrinter.ON_FLOOR and not _has_furniture(state, printer.furniture_uid):
			errors.append("la impresora %d está sobre un mueble que no existe" % printer.uid)
		var job: PrintJob = printer.job
		if job == null:
			continue
		if job.piece_seconds < 1 or job.pieces_total < 1:
			errors.append("el trabajo de la impresora %d no tiene piezas o tiempo" % printer.uid)
		elif job.status == PrintJob.Status.PRINTING and job.ends_at < state.game_seconds:
			errors.append("el trabajo de la impresora %d termina en el pasado" % printer.uid)
	for order: Order in state.orders:
		if order.stage != Order.Stage.DESIGNING:
			continue
		if state.designing_uid != -1:
			errors.append("hay más de un pedido modelándose")
		elif order.design_ends_at < state.game_seconds:
			errors.append("el modelado del pedido %d termina en el pasado" % order.uid)
		state.designing_uid = order.uid
	if state.next_offer_at != -1 and state.next_offer_at < state.game_seconds:
		errors.append("el próximo mensaje llega en el pasado")


static func _check_uids(state: GameState, errors: Array[String]) -> void:
	var uids: Array[int] = []
	for item: OwnedFurniture in state.furniture:
		uids.append(item.uid)
	for printer: OwnedPrinter in state.printers:
		uids.append(printer.uid)
	for spool: Spool in state.spools:
		uids.append(spool.uid)
	for offer: OrderOffer in state.offers:
		uids.append(offer.uid)
	for order: Order in state.orders:
		uids.append(order.uid)
	var seen: Dictionary[int, bool] = {}
	for uid: int in uids:
		if uid < 1 or uid >= state.next_uid:
			errors.append("el uid %d está fuera de rango (next_uid %d)" % [uid, state.next_uid])
		elif seen.has(uid):
			errors.append("el uid %d está repetido" % uid)
		seen[uid] = true


static func _has_furniture(state: GameState, uid: int) -> bool:
	for item: OwnedFurniture in state.furniture:
		if item.uid == uid:
			return true
	return false


static func _enum_name(names: Dictionary, value: int) -> String:
	return (names.find_key(value) as String).to_lower()
