extends GutTest
## Guardar y cargar la partida (SaveCodec): exacto, sin float, con el azar
## intacto, y sin caerse nunca con un guardado roto.

var _rules: SimRules


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())


func test_round_trip_through_json_is_exact() -> void:
	var state: GameState = _busy_state()
	var saved: String = _json(SaveCodec.encode(state))
	var loaded: GameState = _decode_ok(JSON.parse_string(saved))
	assert_eq(_json(SaveCodec.encode(loaded)), saved)
	assert_eq(loaded.designing_uid, state.designing_uid, "designing_uid se recalcula desde el pedido que se modela")


func test_round_trip_in_memory_is_exact() -> void:
	var doc: Dictionary = SaveCodec.encode(_busy_state())
	assert_eq(_json(SaveCodec.encode(_decode_ok(doc))), _json(doc))


func test_every_job_status_survives() -> void:
	var state: GameState = _busy_state()
	var cubo: OwnedPrinter = state.printers[0]
	var order: Order = state.find_order(cubo.job.order_uid)
	cubo.job.ends_at = state.game_seconds + 100
	for status: PrintJob.Status in PrintJob.Status.values():
		cubo.job.status = status
		order.stage = Order.Stage.PRINTED if status == PrintJob.Status.DONE else Order.Stage.PRINTING
		var loaded: GameState = _reload(state)
		assert_eq(loaded.printers[0].job.status, status)
		assert_eq(loaded.find_order(order.uid).stage, order.stage)


func test_both_random_streams_continue_after_loading() -> void:
	var state: GameState = _busy_state()
	var loaded: GameState = _reload(state)
	for i: int in 10:
		assert_eq(loaded.orders_rng.randf(), state.orders_rng.randf())
		assert_eq(loaded.prints_rng.randf(), state.prints_rng.randf())


func test_64_bit_values_survive_as_text() -> void:
	var big_seed: int = (1 << 60) + 7
	var big_state: int = (1 << 62) + 12345
	var state: GameState = GameState.new_game(_rules, big_seed)
	state.orders_rng.state = big_state
	state.prints_rng.state = -big_state
	var doc: Dictionary = SaveCodec.encode(state)
	assert_typeof(doc["rng_seed"], TYPE_STRING)
	assert_typeof(doc["orders_rng_state"], TYPE_STRING)
	assert_typeof(doc["prints_rng_state"], TYPE_STRING)
	var loaded: GameState = _reload(state)
	assert_eq(loaded.rng_seed, big_seed)
	assert_eq(loaded.orders_rng.state, big_state)
	assert_eq(loaded.prints_rng.state, -big_state)
	assert_eq(loaded.orders_rng.randi(), state.orders_rng.randi())
	assert_eq(loaded.prints_rng.randi(), state.prints_rng.randi())


func test_saved_data_has_no_floats() -> void:
	var found: Array[String] = []
	_find_forbidden_types(SaveCodec.encode(_busy_state()), "state", found)
	assert_eq(found, [] as Array[String], "Solo int, String, bool, Array, Dictionary y null")


func test_printers_and_orders_load_in_uid_order() -> void:
	var state: GameState = _busy_state()
	var doc: Dictionary = SaveCodec.encode(state)
	(doc["printers"] as Array).reverse()
	(doc["orders"] as Array).reverse()
	var loaded: GameState = _decode_ok(doc)
	assert_eq(_json(SaveCodec.encode(loaded)), _json(SaveCodec.encode(state)))


func test_unknown_order_ids_are_dropped() -> void:
	var state: GameState = _busy_state()
	var doc: Dictionary = SaveCodec.encode(state)
	doc["offers"][0]["order_id"] = "no_existe"
	doc["orders"][0]["order_id"] = "no_existe"
	doc["scripted_offers"] = ["no_existe", "llavero"]
	doc["last_offer_order_id"] = "no_existe"
	doc["delivered_by_order"]["no_existe"] = 2
	doc["recent_deliveries"][0]["order_id"] = "no_existe"
	var loaded: GameState = _decode_ok(doc)
	assert_eq(loaded.offers.size(), state.offers.size() - 1)
	assert_eq(loaded.orders.size(), state.orders.size() - 1)
	assert_null(loaded.find_order(state.orders[0].uid))
	assert_eq(loaded.scripted_offers, ["llavero"] as Array[String])
	assert_eq(loaded.last_offer_order_id, "")
	assert_false(loaded.delivered_by_order.has("no_existe"))
	assert_eq(loaded.recent_deliveries.size(), state.recent_deliveries.size() - 1)


## Si al cargar se descartan todos los mensajes de un tablero lleno (sus
## pedidos ya no existen en data/), el tablero no queda en pausa para siempre:
## sin mensajes no hay nada que aceptar o rechazar para reanudarlo.
func test_a_paused_board_with_free_slots_starts_again() -> void:
	var state: GameState = GameState.new_game(_rules, 1234)
	Simulation.new(state, _rules).advance_game_seconds(_rules.first_offer_seconds + _rules.starting_gap_seconds + _rules.offer_interval_seconds)
	assert_eq(state.offers.size(), _rules.board_slots)
	assert_eq(state.next_offer_at, -1)
	assert_eq(_reload(state).next_offer_at, -1, "Con el tablero lleno sigue en pausa")
	var doc: Dictionary = SaveCodec.encode(state)
	for offer: Dictionary in doc["offers"]:
		offer["order_id"] = "no_existe"
	var loaded: GameState = _decode_ok(doc)
	assert_true(loaded.offers.is_empty())
	assert_eq(loaded.next_offer_at, state.game_seconds + _rules.offer_interval_seconds, "El próximo mensaje se espera desde ahora")


func test_job_without_its_order_is_dropped() -> void:
	var state: GameState = _busy_state()
	var rayo: OwnedPrinter = state.printers[1]
	var doc: Dictionary = SaveCodec.encode(state)
	for order: Dictionary in doc["orders"]:
		if int(order["uid"]) == rayo.job.order_uid:
			order["order_id"] = "no_existe"
	var loaded: GameState = _decode_ok(doc)
	assert_null(loaded.find_printer(rayo.uid).job, "La impresora queda libre")


func test_order_without_its_job_goes_back_to_ready_to_print() -> void:
	var state: GameState = _busy_state()
	var rayo: OwnedPrinter = state.printers[1]
	var order_uid: int = rayo.job.order_uid
	var doc: Dictionary = SaveCodec.encode(state)
	doc["printers"][1]["job"] = null
	var loaded: GameState = _decode_ok(doc)
	var order: Order = loaded.find_order(order_uid)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)
	assert_eq(order.printer_uid, -1)
	assert_eq(order.pieces_done, 1, "Las piezas hechas se conservan")


func test_job_without_its_spool_is_dropped() -> void:
	var state: GameState = _busy_state()
	var rayo: OwnedPrinter = state.printers[1]
	var order_uid: int = rayo.job.order_uid
	var doc: Dictionary = SaveCodec.encode(state)
	doc["printers"][1]["job"]["spool_uid"] = 999
	var loaded: GameState = _decode_ok(doc)
	assert_null(loaded.find_printer(rayo.uid).job)
	assert_eq(loaded.find_order(order_uid).stage, Order.Stage.READY_TO_PRINT)


## Un trabajo cuyo pedido dice estar en otra impresora no es de esta: se
## descarta y el pedido vuelve a esperar una impresora.
func test_job_of_an_order_on_another_printer_is_dropped() -> void:
	var state: GameState = _busy_state()
	var cubo: OwnedPrinter = state.printers[0]
	var rayo: OwnedPrinter = state.printers[1]
	var order_uid: int = rayo.job.order_uid
	var doc: Dictionary = SaveCodec.encode(state)
	for order: Dictionary in doc["orders"]:
		if int(order["uid"]) == order_uid:
			order["printer_uid"] = cubo.uid
	var loaded: GameState = _decode_ok(doc)
	assert_null(loaded.find_printer(rayo.uid).job)
	assert_eq(loaded.find_order(order_uid).stage, Order.Stage.READY_TO_PRINT)
	assert_eq(loaded.find_order(order_uid).printer_uid, -1)
	assert_eq(loaded.find_printer(cubo.uid).job.order_uid, cubo.job.order_uid, "El trabajo de la otra impresora sigue")


func test_two_orders_designing_is_invalid() -> void:
	var doc: Dictionary = SaveCodec.encode(_busy_state())
	doc["orders"][0]["stage"] = "designing"
	doc["orders"][0]["design_ends_at"] = doc["game_seconds"] + 10
	_assert_invalid(doc, "más de un pedido modelándose")


func test_events_in_the_past_are_invalid() -> void:
	var state: GameState = _busy_state()
	var doc: Dictionary = SaveCodec.encode(state)
	doc["next_offer_at"] = state.game_seconds - 1
	_assert_invalid(doc, "próximo mensaje")
	doc = SaveCodec.encode(state)
	doc["printers"][1]["job"]["ends_at"] = state.game_seconds - 1
	_assert_invalid(doc, "termina en el pasado")
	doc = SaveCodec.encode(state)
	doc["orders"][1]["design_ends_at"] = state.game_seconds - 1
	_assert_invalid(doc, "el modelado del pedido %d termina en el pasado" % state.designing_uid)


func test_uids_must_be_unique_and_below_next_uid() -> void:
	var state: GameState = _busy_state()
	var doc: Dictionary = SaveCodec.encode(state)
	doc["spools"][1]["uid"] = state.spools[0].uid
	_assert_invalid(doc, "repetido")
	doc = SaveCodec.encode(state)
	doc["next_uid"] = state.spools[1].uid
	_assert_invalid(doc, "fuera de rango")


func test_unknown_workshop_ids_are_invalid() -> void:
	var doc: Dictionary = SaveCodec.encode(_busy_state())
	doc["spools"][0]["material_id"] = "oro"
	_assert_invalid(doc, "oro")
	doc = SaveCodec.encode(_busy_state())
	doc["spools"][1]["color_id"] = "dorado"
	_assert_invalid(doc, "dorado")
	doc = SaveCodec.encode(_busy_state())
	doc["printers"][1]["furniture_uid"] = 999
	_assert_invalid(doc, "mueble que no existe")


func test_newer_or_broken_versions_are_refused() -> void:
	var state: Dictionary = SaveCodec.encode(_busy_state())
	assert_eq(SaveCodec.migrate({"version": 2, "save_seq": 1, "state": state}), {})
	assert_eq(SaveCodec.migrate({"version": "uno", "state": state}), {})
	assert_eq(SaveCodec.migrate({"state": state}), {})
	var current: Dictionary = {"version": 1.0, "save_seq": 3.0, "state": state}
	assert_eq(SaveCodec.migrate(current), current, "La versión 1 se carga tal cual")


func test_garbage_gives_null_and_a_reason() -> void:
	_assert_invalid({}, "money_cents")
	_assert_invalid({"money_cents": "mucho"}, "money_cents")
	var doc: Dictionary = SaveCodec.encode(_busy_state())
	doc["printers"] = "ninguna"
	_assert_invalid(doc, "printers")
	doc = SaveCodec.encode(_busy_state())
	doc["orders"][0]["stage"] = "volando"
	_assert_invalid(doc, "stage")
	doc = SaveCodec.encode(_busy_state())
	doc["game_seconds"] = 1.5
	_assert_invalid(doc, "game_seconds")
	doc = SaveCodec.encode(_busy_state())
	doc["rng_seed"] = 1234
	_assert_invalid(doc, "rng_seed")
	doc = SaveCodec.encode(_busy_state())
	doc["orders_rng_state"] = "99999999999999999999"
	_assert_invalid(doc, "orders_rng_state")
	doc = SaveCodec.encode(_busy_state())
	doc["printers"][0]["job"] = "a medias"
	_assert_invalid(doc, "job")


## El taller ocupado avanza 8 horas reales dos veces: sin guardar nunca, y
## guardando y cargando cada media hora real, con piezas a mitad de imprimir y
## fallas ya decididas. Las dos partidas terminan iguales.
func test_continuing_after_save_and_load_equals_not_saving() -> void:
	var played: Simulation = SimFixtures.busy_workshop(_rules)
	var reloaded: GameState = _reload(played.state)
	var events: SimChanges = SimChanges.new()
	for i: int in 16:
		played.advance(1800.0)
		var relay: Simulation = Simulation.new(reloaded, _rules)
		relay.advance(1800.0)
		events.failures.append_array(relay.changes.failures)
		events.computer = events.computer or relay.changes.computer
		events.arrived_offers.append_array(relay.changes.arrived_offers)
		reloaded = _reload(reloaded)
	assert_eq(_json(SaveCodec.encode(reloaded)), _json(SaveCodec.encode(played.state)))
	# Pasó de todo después de cargar. Si un cambio de semilla o de datos lo evita, esta prueba avisa.
	assert_false(events.failures.is_empty(), "Alguna pieza falló")
	assert_true(events.computer, "El computador terminó modelos")
	assert_false(events.arrived_offers.is_empty(), "Llegaron mensajes")


## Cada variable de cada objeto de la partida vuelve igual al cargar. Un campo
## nuevo que se olvide en encode() y decode() a la vez no cambia la ida y
## vuelta por JSON, pero sí hace fallar esta prueba.
func test_every_field_survives_loading() -> void:
	var state: GameState = _busy_state()
	state.scripted_offers.append("maceta")
	var differences: Array[String] = []
	_compare_fields(state, _reload(state), "state", differences)
	assert_eq(differences, [] as Array[String])


## Partida a mitad del ciclo armada a mano: un mensaje, un pedido en cada
## etapa, dos impresoras con trabajo, dos carretes y despachos recientes.
func _busy_state() -> GameState:
	var state: GameState = GameState.new_game(_rules, 1234)
	var now: int = state.game_seconds + 5000
	state.game_seconds = now
	state.live_seconds = 4000
	state.money_cents = 31234
	state.xp = 40
	for i: int in 3:
		state.orders_rng.randf()
		state.prints_rng.randf()
	var table: OwnedFurniture = OwnedFurniture.new(state.take_uid(), "mesa_trabajo", 1)
	state.furniture.append(table)
	var rayo: OwnedPrinter = OwnedPrinter.new(state.take_uid(), "rayo_x1", table.uid)
	rayo.accessories.append("camera")
	state.printers.append(rayo)
	var petg: Spool = Spool.new(state.take_uid(), "petg", "negro", 420)
	state.spools.append(petg)
	state.spools[0].grams = 976
	state.offers.append(OrderOffer.new(state.take_uid(), "maceta", now - 100))
	state.next_offer_at = now + 600
	state.scripted_offers.clear()
	state.last_offer_order_id = "maceta"

	_add_order(state, "soporte_celular", Order.Stage.WAITING_DESIGN)
	var designing: Order = _add_order(state, "llavero", Order.Stage.DESIGNING)
	designing.design_ends_at = now + 120
	designing.focused = true
	state.designing_uid = designing.uid
	_add_order(state, "maceta", Order.Stage.READY_TO_PRINT)
	var printing: Order = _add_order(state, "engranaje", Order.Stage.PRINTING)
	printing.pieces_done = 1
	printing.printer_uid = rayo.uid
	rayo.job = _job(printing.uid, petg, "normal", 4, 20, 2700, now - 100)
	rayo.job.ends_at = now + 900
	rayo.job.fails = true
	rayo.job.failure_type = "warping"
	rayo.job.lost_grams = 8
	var printed: Order = _add_order(state, "llavero", Order.Stage.PRINTED)
	printed.pieces_done = 1
	printed.printer_uid = state.printers[0].uid
	state.printers[0].job = _job(printed.uid, state.spools[0], "fine", 1, 8, 1920, now - 2000)
	state.printers[0].job.status = PrintJob.Status.DONE
	var to_pack: Order = _add_order(state, "llavero", Order.Stage.TO_PACK)
	to_pack.color_id = "blanco"
	var packed: Order = _add_order(state, "perilla", Order.Stage.PACKED)
	packed.color_id = "negro"
	packed.due_live = 3000

	state.pieces_started = 6
	state.delivered_total = 3
	state.delivered_by_order["llavero"] = 3
	state.recent_deliveries.append(Delivery.new(state.take_uid(), "llavero", 600, 5, false, "THANKS_AMIGOS_2", now - 300))
	state.recent_deliveries.append(Delivery.new(state.take_uid(), "llavero", 300, 0, true, "THANKS_AMIGOS_1", now - 900))
	return state


func _add_order(state: GameState, order_id: String, stage: Order.Stage) -> Order:
	var order: Order = Order.new(state.take_uid(), order_id, state.game_seconds - 1000)
	order.stage = stage
	state.orders.append(order)
	return order


func _job(order_uid: int, spool: Spool, mode_id: String, pieces: int, grams: int, piece_seconds: int, started_at: int) -> PrintJob:
	var job: PrintJob = PrintJob.new()
	job.order_uid = order_uid
	job.spool_uid = spool.uid
	job.mode_id = mode_id
	job.color_id = spool.color_id
	job.pieces_total = pieces
	job.grams_per_piece = grams
	job.piece_seconds = piece_seconds
	job.piece_started_at = started_at
	job.ends_at = started_at + piece_seconds
	return job


## Guarda como JSON y vuelve a cargar, como lo hará SaveManager.
func _reload(state: GameState) -> GameState:
	return _decode_ok(JSON.parse_string(_json(SaveCodec.encode(state))))


func _decode_ok(doc: Dictionary) -> GameState:
	var errors: Array[String] = []
	var state: GameState = SaveCodec.decode(doc, _rules, errors)
	assert_not_null(state, "No cargó: " + "\n".join(PackedStringArray(errors)))
	return state


func _assert_invalid(doc: Dictionary, expected_text: String) -> void:
	var errors: Array[String] = []
	assert_null(SaveCodec.decode(doc, _rules, errors), "Debía rechazarse: " + expected_text)
	var joined: String = "\n".join(PackedStringArray(errors))
	assert_string_contains(joined, expected_text)


func _json(doc: Dictionary) -> String:
	return JSON.stringify(doc, "", true)


## Compara dos partidas variable por variable (las de los scripts), entrando
## en los objetos y las listas. Anota en `differences` la ruta de lo distinto.
func _compare_fields(expected: Variant, actual: Variant, path: String, differences: Array[String]) -> void:
	if expected is RandomNumberGenerator:
		var expected_rng: RandomNumberGenerator = expected
		var actual_rng: RandomNumberGenerator = actual
		if expected_rng.seed != actual_rng.seed or expected_rng.state != actual_rng.state:
			differences.append(path)
	elif expected is Object:
		if not actual is Object:
			differences.append(path)
			return
		for property: Dictionary in (expected as Object).get_property_list():
			if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var name: String = property["name"]
				_compare_fields((expected as Object).get(name), (actual as Object).get(name), path + "." + name, differences)
	elif expected is Array:
		if not actual is Array or (expected as Array).size() != (actual as Array).size():
			differences.append(path)
			return
		for i: int in (expected as Array).size():
			_compare_fields(expected[i], actual[i], "%s[%d]" % [path, i], differences)
	elif typeof(expected) != typeof(actual) or expected != actual:
		differences.append(path)


func _find_forbidden_types(value: Variant, path: String, found: Array[String]) -> void:
	match typeof(value):
		TYPE_DICTIONARY:
			var dictionary: Dictionary = value
			for key: Variant in dictionary:
				if not key is String:
					found.append("%s: clave %s" % [path, type_string(typeof(key))])
				_find_forbidden_types(dictionary[key], "%s.%s" % [path, key], found)
		TYPE_ARRAY:
			var array: Array = value
			for i: int in array.size():
				_find_forbidden_types(array[i], "%s[%d]" % [path, i], found)
		TYPE_INT, TYPE_STRING, TYPE_BOOL, TYPE_NIL:
			pass
		_:
			found.append("%s: %s" % [path, type_string(typeof(value))])
