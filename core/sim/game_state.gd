class_name GameState
extends RefCounted
## Estado completo de una partida: solo datos. Las reglas que lo modifican
## viven en otras clases de core/sim.

## Constante técnica, no de balance: separa los dos flujos de azar para que,
## con la misma semilla, el de los fallos no repita los números del tablero.
const PRINTS_STREAM_SALT: int = 0x5851F42D4C957F2D
## Cuántos despachos recientes se recuerdan.
const RECENT_DELIVERIES_KEPT: int = 5

## El dinero se guarda en centavos para no acumular errores de redondeo.
var money_cents: int = 0
var xp: int = 0
## Segundos de juego desde el día 1 a las 00:00. Es un entero para que avanzar
## en un paso grande o en muchos pequeños dé exactamente lo mismo.
var game_seconds: int = 0
## Segundos de juego con la partida abierta. Solo avanza con
## advance(..., live = true): los plazos se congelan fuera del juego.
var live_seconds: int = 0
## Minutos de juego, solo de lectura: para GameClock, la fecha del HUD y lo que
## todavía cuenta en minutos.
var game_minutes: float:
	get:
		return float(game_seconds) / GameClock.SECONDS_PER_MINUTE
	set(_value):
		push_error("GameState.game_minutes es de solo lectura")
var space_id: String = ""
var spools: Array[Spool] = []
## Siempre en orden de uid.
var printers: Array[OwnedPrinter] = []
var furniture: Array[OwnedFurniture] = []
## Semilla de la partida; de ella salen los dos flujos de azar.
var rng_seed: int = 0
## Azar del tablero de pedidos.
var orders_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Azar de los fallos de impresión.
var prints_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Mensajes sin responder.
var offers: Array[OrderOffer] = []
## Segundo de juego en que llega el próximo mensaje; -1 = pausado (tablero lleno).
var next_offer_at: int = -1
## Pedidos fijos que llegan primero, en orden (config.order_board.starting_offers).
var scripted_offers: Array[String] = []
## Pedido del último mensaje, para no repetirlo enseguida.
var last_offer_order_id: String = ""
## Pedidos aceptados, siempre en orden de uid.
var orders: Array[Order] = []
## Pedido que se está modelando; -1 = computador libre.
var designing_uid: int = -1
## Todas las piezas empezadas en la partida (para las piezas de gracia).
var pieces_started: int = 0
var delivered_total: int = 0
## Pedidos despachados por id de pedido.
var delivered_by_order: Dictionary[String, int] = {}
## Últimos despachos, el más nuevo primero (máximo RECENT_DELIVERIES_KEPT).
var recent_deliveries: Array[Delivery] = []
## Próximo uid libre para impresoras, muebles, carretes, mensajes y pedidos.
var next_uid: int = 1


## Crea la partida inicial según config.starting_state.
static func new_game(rules: SimRules, p_seed: int) -> GameState:
	var start: Dictionary = rules.catalog.files["config"]["starting_state"]
	var state: GameState = GameState.new()
	state.rng_seed = p_seed
	state.orders_rng.seed = p_seed
	state.prints_rng.seed = p_seed ^ PRINTS_STREAM_SALT
	state.money_cents = roundi(float(start["money"]) * 100.0)
	state.xp = int(start["xp"])
	state.game_seconds = roundi(float(start["start_hour"]) * GameClock.SECONDS_PER_HOUR)
	state.space_id = start["space"]
	for furniture_id: String in start["furniture"]:
		state.furniture.append(OwnedFurniture.new(state.take_uid(), furniture_id, state.furniture.size()))
	for printer_id: String in start["printers"]:
		var place: int = state.free_printer_place(rules)
		state.printers.append(OwnedPrinter.new(state.take_uid(), printer_id, place))
	for spool: Dictionary in start["spools"]:
		state.spools.append(Spool.new(state.take_uid(), spool["material"], spool["color"], int(spool["grams"])))
	state.scripted_offers = rules.starting_offers.duplicate()
	state.next_offer_at = state.game_seconds + rules.first_offer_seconds
	return state


func take_uid() -> int:
	next_uid += 1
	return next_uid - 1


## Devuelve el uid de un mueble con lugar libre para una impresora, o
## OwnedPrinter.ON_FLOOR si no hay ninguno.
func free_printer_place(rules: SimRules) -> int:
	for item: OwnedFurniture in furniture:
		var slots: int = int(rules.furniture[item.furniture_id]["printer_slots"])
		var used: int = 0
		for printer: OwnedPrinter in printers:
			if printer.furniture_uid == item.uid:
				used += 1
		if used < slots:
			return item.uid
	return OwnedPrinter.ON_FLOOR


func total_grams() -> int:
	var total: int = 0
	for spool: Spool in spools:
		total += spool.grams
	return total


func find_order(uid: int) -> Order:
	for order: Order in orders:
		if order.uid == uid:
			return order
	return null


func find_offer(uid: int) -> OrderOffer:
	for offer: OrderOffer in offers:
		if offer.uid == uid:
			return offer
	return null


func find_printer(uid: int) -> OwnedPrinter:
	for printer: OwnedPrinter in printers:
		if printer.uid == uid:
			return printer
	return null


func find_spool(uid: int) -> Spool:
	for spool: Spool in spools:
		if spool.uid == uid:
			return spool
	return null
