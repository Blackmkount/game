extends GutTest
## Guardar y cargar la partida: el sobre con versión y número de guardado, el
## archivo temporal que se renombra, el más nuevo de los dos gana, el dañado se
## aparta como .bad, una versión más nueva no se toca, y las pruebas nunca
## tocan la partida del jugador.
##
## Usa un archivo propio y enciende el guardado solo durante cada prueba.

const SEED: int = 1234
const TEST_PATH: String = "user://test_save_manager.json"

var _previous_path: String
var _previous_enabled: bool
var _previous_processing: bool
var _autosave: Timer
var _autosave_was_running: bool


func before_each() -> void:
	_previous_path = SaveManager.path
	_previous_enabled = SaveManager.enabled
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	SaveManager.path = TEST_PATH
	SaveManager.enabled = true
	# El guardado cada pocos segundos no debe caer en medio de una prueba.
	_autosave = SaveManager.get_node("AutosaveTimer")
	_autosave_was_running = not _autosave.is_stopped()
	_autosave.stop()
	_remove_files()


func after_each() -> void:
	_remove_files()
	SaveManager.path = _previous_path
	SaveManager.enabled = _previous_enabled
	_autosave.start()
	Game.set_process(_previous_processing)


func test_tests_never_touch_the_players_save() -> void:
	assert_true("-s" in OS.get_cmdline_args(), "GUT corre con -s")
	assert_false(_previous_enabled, "Con -s el guardado empieza apagado")
	assert_eq(_previous_path, SaveManager.DEFAULT_PATH)
	SaveManager.enabled = false
	assert_false(SaveManager.save_now())
	assert_false(FileAccess.file_exists(TEST_PATH))
	SaveManager.enabled = true
	assert_true(SaveManager.save_now())
	SaveManager.enabled = false
	assert_null(SaveManager.load_state(Game.rules), "Apagado tampoco carga")


func test_a_command_saves_through_the_temporary_file_once_per_frame() -> void:
	assert_true(SaveManager.save_now())
	var first_seq: int = _read_envelope(TEST_PATH)["save_seq"]
	# Un temporal viejo que sobró: el guardado lo reemplaza y lo renombra.
	_write_text(_tmp_path(), "{basura")
	Game.advance(3.0)
	var offer: OrderOffer = Game.state.offers[0]
	assert_true(Game.accept_offer(offer.uid).ok)
	assert_eq(_read_envelope(TEST_PATH)["save_seq"], first_seq, "Se guarda al final del cuadro")
	await wait_process_frames(1)
	assert_false(FileAccess.file_exists(_tmp_path()), "El temporal se renombró")
	var envelope: Dictionary = _read_envelope(TEST_PATH)
	assert_eq(envelope["version"], SaveCodec.CURRENT_VERSION)
	assert_eq(envelope["save_seq"], first_seq + 1, "El avance y el comando del mismo cuadro guardan una vez")
	assert_gt(envelope["saved_unix"], 0)
	var whole_unix: RegEx = RegEx.create_from_string("\"saved_unix\":[0-9]+[,}]")
	assert_not_null(whole_unix.search(FileAccess.get_file_as_string(TEST_PATH)), "La hora se guarda como entero")
	var errors: Array[String] = []
	var saved: GameState = SaveCodec.decode(envelope["state"], Game.rules, errors)
	assert_eq(errors, [] as Array[String])
	assert_eq(_sorted_json(saved), _sorted_json(Game.state))
	assert_eq(Game.state.find_order(offer.uid).stage, Order.Stage.DESIGNING)


func test_a_failed_command_does_not_save() -> void:
	assert_eq(Game.accept_offer(999).reason, "ERR_OFFER_GONE")
	await wait_process_frames(1)
	assert_false(FileAccess.file_exists(TEST_PATH))


func test_losing_focus_pausing_or_closing_saves() -> void:
	for what: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_WM_CLOSE_REQUEST]:
		_remove_files()
		SaveManager.notification(what)
		assert_true(FileAccess.file_exists(TEST_PATH), "Aviso %d" % what)


func test_saving_on_its_own_every_few_seconds() -> void:
	assert_true(_autosave_was_running)
	assert_false(_autosave.one_shot)
	assert_almost_eq(_autosave.wait_time, SaveManager.AUTOSAVE_SECONDS, 0.001)
	_autosave.timeout.emit()
	assert_true(FileAccess.file_exists(TEST_PATH))


func test_reset_and_load_restore_the_same_game() -> void:
	_play_until_mid_print()
	assert_true(SaveManager.save_now())
	var saved: String = _sorted_json(Game.state)
	Game.reset_game(SEED + 1)
	assert_ne(_sorted_json(Game.state), saved)
	var loaded: GameState = SaveManager.load_state(Game.rules)
	assert_not_null(loaded)
	assert_eq(_sorted_json(loaded), saved)


func test_nothing_saved_loads_nothing() -> void:
	assert_null(SaveManager.load_state(Game.rules))
	assert_true(SaveManager.enabled)


func test_the_newest_of_main_and_temporary_wins() -> void:
	_write_save(TEST_PATH, 5, _state_with_money(100))
	_write_save(_tmp_path(), 6, _state_with_money(200))
	assert_eq(SaveManager.load_state(Game.rules).money_cents, 200, "El temporal quedó sin renombrar")
	_write_save(_tmp_path(), 4, _state_with_money(300))
	assert_eq(SaveManager.load_state(Game.rules).money_cents, 100, "Un temporal viejo no gana")


func test_saving_after_loading_continues_the_count() -> void:
	_write_save(TEST_PATH, 5, _state_with_money(100))
	_write_save(_tmp_path(), 6, _state_with_money(200))
	assert_not_null(SaveManager.load_state(Game.rules))
	assert_true(SaveManager.save_now())
	assert_eq(_read_envelope(TEST_PATH)["save_seq"], 7)


func test_a_broken_main_is_set_aside_and_the_temporary_is_used() -> void:
	_write_text(TEST_PATH, "{basura")
	_write_save(_tmp_path(), 3, _state_with_money(200))
	var loaded: GameState = SaveManager.load_state(Game.rules)
	assert_not_null(loaded)
	assert_eq(loaded.money_cents, 200)
	assert_false(FileAccess.file_exists(TEST_PATH))
	assert_eq(FileAccess.get_file_as_string(_bad_path()), "{basura", "Se guarda aparte, sin cambios")


func test_a_broken_temporary_is_deleted_and_the_main_is_used() -> void:
	_write_save(TEST_PATH, 3, _state_with_money(100))
	_write_text(_tmp_path(), "[1, 2]")
	assert_eq(SaveManager.load_state(Game.rules).money_cents, 100)
	assert_false(FileAccess.file_exists(_tmp_path()))
	assert_false(FileAccess.file_exists(_bad_path()))


func test_an_unreadable_game_counts_as_broken() -> void:
	var envelope: Dictionary = _envelope(3, _state_with_money(100))
	(envelope["state"] as Dictionary).erase("money_cents")
	_write_text(TEST_PATH, JSON.stringify(envelope))
	assert_null(SaveManager.load_state(Game.rules))
	assert_true(FileAccess.file_exists(_bad_path()))
	assert_true(SaveManager.enabled, "Un guardado dañado no apaga el guardado")


func test_a_save_from_a_newer_version_is_refused_and_kept() -> void:
	var envelope: Dictionary = _envelope(9, _state_with_money(100))
	envelope["version"] = SaveCodec.CURRENT_VERSION + 1
	var text: String = JSON.stringify(envelope)
	_write_text(TEST_PATH, text)
	assert_null(SaveManager.load_state(Game.rules))
	assert_push_warning("versión más nueva")
	assert_false(SaveManager.enabled, "No se guarda encima por el resto de la sesión")
	assert_false(SaveManager.save_now())
	SaveManager.request_save()
	await wait_process_frames(1)
	assert_eq(FileAccess.get_file_as_string(TEST_PATH), text, "El archivo queda sin tocar")
	assert_false(FileAccess.file_exists(_tmp_path()))
	assert_false(FileAccess.file_exists(_bad_path()))


func test_a_newer_temporary_also_refuses_loading() -> void:
	_write_save(TEST_PATH, 3, _state_with_money(100))
	var envelope: Dictionary = _envelope(4, _state_with_money(200))
	envelope["version"] = SaveCodec.CURRENT_VERSION + 1
	_write_text(_tmp_path(), JSON.stringify(envelope))
	assert_null(SaveManager.load_state(Game.rules))
	assert_false(SaveManager.enabled)
	assert_true(FileAccess.file_exists(_tmp_path()))


func test_a_dropped_design_lets_the_queue_go_on_when_the_game_starts() -> void:
	Game.advance(3.0)
	var first: Order = _accept(Game.state.offers[0].uid)
	var second: Order = _accept(_add_offer("llavero"))
	assert_eq(first.stage, Order.Stage.DESIGNING)
	assert_eq(second.stage, Order.Stage.WAITING_DESIGN)
	var doc: Dictionary = SaveCodec.encode(Game.state)
	# Una versión nueva de data/ ya no tiene el pedido que se modelaba.
	for entry: Dictionary in doc["orders"]:
		if entry["uid"] == first.uid:
			entry["order_id"] = "pedido_que_ya_no_existe"
	_write_text(TEST_PATH, JSON.stringify(_envelope(1, doc)))
	var loaded: GameState = SaveManager.load_state(Game.rules)
	assert_eq(loaded.orders.size(), 1)
	assert_eq(loaded.designing_uid, -1)
	Game._start(loaded)
	var waiting: Order = Game.state.find_order(second.uid)
	assert_eq(waiting.stage, Order.Stage.DESIGNING, "Empieza a modelarse al cargar")
	assert_eq(waiting.design_ends_at, loaded.game_seconds + Game.rules.design_seconds["llavero"])
	assert_eq(Game.state.designing_uid, second.uid)


# --- Ayudas ---------------------------------------------------------------------


## Llavero aceptado, modelado y a mitad de su impresión.
func _play_until_mid_print() -> void:
	Game.advance(3.0)
	var order: Order = _accept(Game.state.offers[0].uid)
	Game.advance(10.0)
	assert_eq(order.stage, Order.Stage.READY_TO_PRINT)
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	assert_true(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	Game.advance(20.0)
	assert_eq(order.stage, Order.Stage.PRINTING)


func _accept(offer_uid: int) -> Order:
	var result: CommandResult = Game.accept_offer(offer_uid)
	assert_true(result.ok, result.reason)
	return Game.state.find_order(result.uid)


## Llega a mano un mensaje con ese pedido; devuelve su uid.
func _add_offer(order_id: String) -> int:
	var offer: OrderOffer = OrderOffer.new(Game.state.take_uid(), order_id, Game.state.game_seconds)
	Game.state.offers.append(offer)
	return offer.uid


func _state_with_money(cents: int) -> Dictionary:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	state.money_cents = cents
	return SaveCodec.encode(state)


func _envelope(save_seq: int, state_doc: Dictionary) -> Dictionary:
	return {"version": SaveCodec.CURRENT_VERSION, "save_seq": save_seq, "saved_unix": 1700000000, "state": state_doc}


func _write_save(file_path: String, save_seq: int, state_doc: Dictionary) -> void:
	_write_text(file_path, JSON.stringify(_envelope(save_seq, state_doc)))


func _write_text(file_path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _read_envelope(file_path: String) -> Dictionary:
	var json: JSON = JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(file_path)), OK, file_path)
	var doc: Dictionary = json.data
	# JSON entrega los números como float: los enteros se comparan como int.
	for key: String in ["version", "save_seq", "saved_unix"]:
		var value: float = doc[key]
		if value == floorf(value):
			doc[key] = int(value)
	return doc


func _sorted_json(state: GameState) -> String:
	return JSON.stringify(SaveCodec.encode(state), "", true)


func _tmp_path() -> String:
	return TEST_PATH + SaveManager.TMP_SUFFIX


func _bad_path() -> String:
	return TEST_PATH + SaveManager.BAD_SUFFIX


func _remove_files() -> void:
	for file_path: String in [TEST_PATH, _tmp_path(), _bad_path()]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
