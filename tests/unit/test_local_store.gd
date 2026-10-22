extends GutTest
## Ferretería del barrio: un carrete de PLA o PETG al instante, 50% más caro
## que la tienda. Revisa en orden que lo venda, el dinero y el almacenamiento;
## si no se puede, no cambia nada, y nunca usa el azar.

var _rules: SimRules
var _sim: Simulation
var _state: GameState
var _commands: GameCommands


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_sim = SimFixtures.new_sim(_rules)
	_state = _sim.state
	_commands = GameCommands.new(_sim)


func test_prices_are_the_shop_price_plus_half() -> void:
	assert_eq(_rules.local_store_cents, {"pla": 2700, "petg": 3000} as Dictionary[String, int], "$18 y $20 de la tienda, por 1,5")
	assert_eq(_rules.local_store_grams, 1000)
	assert_eq(_rules.local_store_color, "blanco")
	assert_almost_eq(_rules.local_store_price_multiplier, 1.5, 0.0001)


func test_a_smaller_spool_costs_less() -> void:
	var catalog: DataCatalog = DataCatalog.load_from()
	catalog.files["config"]["local_store"]["grams"] = 500
	var rules: SimRules = SimRules.from_catalog(catalog)
	assert_eq(rules.local_store_cents["pla"], 1350, "El mismo precio por gramo: medio kilo, medio precio")


func test_buying_pays_and_adds_a_new_spool() -> void:
	var uid: int = _state.next_uid
	var twins: Array[RandomNumberGenerator] = _twins()
	_sim.changes.clear()
	var result: CommandResult = _commands.buy_local_material("petg")
	assert_true(result.ok, result.reason)
	assert_eq(_state.money_cents, 25000 - 3000, "$250 - $30")
	assert_eq(_state.spools.size(), 2)
	var spool: Spool = _state.spools[1]
	assert_eq(spool.uid, uid, "Un uid nuevo")
	assert_eq(result.uid, uid)
	assert_eq(spool.material_id, "petg")
	assert_eq(spool.color_id, "blanco")
	assert_eq(spool.grams, 1000)
	assert_eq(_state.spools[0].grams, 1000, "El carrete de antes no cambia")
	assert_true(_sim.changes.spools)
	assert_true(_sim.changes.money)
	_assert_no_draws(twins)


func test_only_what_the_store_sells() -> void:
	_assert_refused_without_changes(_commands.buy_local_material.bind("tpu"), "ERR_NOT_IN_LOCAL_STORE")
	_assert_refused_without_changes(_commands.buy_local_material.bind("no_existe"), "ERR_NOT_IN_LOCAL_STORE")
	_state.money_cents = 0
	_assert_refused_without_changes(_commands.buy_local_material.bind("tpu"), "ERR_NOT_IN_LOCAL_STORE", "Lo que no vende va antes que el dinero")


func test_money_must_cover_the_price() -> void:
	_state.money_cents = 2699
	_assert_refused_without_changes(_commands.buy_local_material.bind("pla"), "ERR_NO_MONEY")
	assert_eq(_commands.buy_local_material("pla").args, [{"cents": 2700}], "Dice cuánto cuesta")
	_state.money_cents = 2700
	assert_true(_commands.buy_local_material("pla").ok, "Con lo justo alcanza")
	assert_eq(_state.money_cents, 0)


func test_the_spool_must_fit_in_storage() -> void:
	# 4 kg de espacio con 1 kg de PLA al empezar: caben 3 carretes más.
	for i: int in 3:
		assert_true(_commands.buy_local_material("pla").ok, "Carrete %d" % (i + 1))
	assert_eq(_state.total_grams(), 4000)
	_assert_refused_without_changes(_commands.buy_local_material.bind("petg"), "ERR_NO_STORAGE")
	assert_eq(_commands.buy_local_material("petg").args, [{"grams": 4000}], "Dice cuánto guarda el espacio")
	_state.money_cents = 0
	_assert_refused_without_changes(_commands.buy_local_material.bind("petg"), "ERR_NO_MONEY", "El dinero va antes que el espacio")
	# El material usado deja lugar.
	_state.money_cents = 25000
	_state.spools[0].grams = 0
	assert_true(_commands.buy_local_material("petg").ok)


func test_material_set_aside_for_a_print_still_takes_room() -> void:
	# 3.050 g guardados; una maceta aparta 80 g del carrete al empezar.
	_state.spools[0].grams = 50
	for i: int in 3:
		SimFixtures.add_spool(_state, "pla", 1000)
	var order: Order = SimFixtures.accept(_sim, "maceta")
	SimFixtures.finish_designs(_sim)
	SimFixtures.start_print(_sim, order, _state.printers[0], _state.spools[1])
	assert_eq(_state.total_grams(), 2970, "Los 80 g apartados ya no están en el carrete")
	assert_eq(WorkshopRules.reserved_grams(_state), 80)
	_assert_refused_without_changes(_commands.buy_local_material.bind("pla"), "ERR_NO_STORAGE", "Lo apartado sigue ocupando lugar")
	# Si la pieza falla, lo que no se imprimió vuelve al carrete y sigue cabiendo.
	DebugTools.force_fail(_sim, _state.printers[0].uid, FailureRules.SPAGHETTI, 0.1)
	_sim.advance(60.0)
	assert_eq(_state.printers[0].job.status, PrintJob.Status.FAILED)
	assert_lte(_state.total_grams() + WorkshopRules.reserved_grams(_state), WorkshopRules.storage_capacity_grams(_state, _rules))


func test_a_shelf_makes_room() -> void:
	_state.spools[0].grams = 4000
	assert_eq(LocalStore.check_buy(_state, _rules, "pla").reason, "ERR_NO_STORAGE")
	_state.furniture.append(OwnedFurniture.new(_state.take_uid(), "repisa_filamento", _state.furniture.size()))
	assert_true(LocalStore.check_buy(_state, _rules, "pla").ok, "La repisa guarda 6 kg más")


func test_check_matches_the_command() -> void:
	_state.money_cents = 2800
	for material_id: String in ["pla", "petg", "tpu"]:
		var check: CommandResult = LocalStore.check_buy(_state, _rules, material_id)
		var before: int = _state.money_cents
		var result: CommandResult = _commands.buy_local_material(material_id)
		assert_eq(result.ok, check.ok, material_id)
		assert_eq(result.reason, check.reason, material_id)
		assert_eq(result.args, check.args, material_id)
		if result.ok:
			_state.money_cents = before


func test_buying_material_brings_back_orders_that_can_be_made() -> void:
	_state.spools[0].grams = 0
	assert_false(OrderBoard.has_makeable(_state, _rules), "Sin material nadie pide nada")
	assert_true(_commands.buy_local_material("pla").ok)
	assert_true(OrderBoard.has_makeable(_state, _rules))
	# La perilla (nivel 2) solo se hace en PETG.
	_state.xp = 100
	assert_false(OrderBoard.is_makeable(_state, _rules, "perilla"))
	assert_true(_commands.buy_local_material("petg").ok)
	assert_true(OrderBoard.is_makeable(_state, _rules, "perilla"))


func test_the_new_spool_is_saved() -> void:
	assert_true(_commands.buy_local_material("petg").ok)
	var errors: Array[String] = []
	var loaded: GameState = SaveCodec.decode(SaveCodec.encode(_state), _rules, errors)
	assert_eq(errors, [] as Array[String])
	assert_eq(loaded.spools.size(), 2)
	assert_eq(loaded.spools[1].material_id, "petg")
	assert_eq(loaded.money_cents, 22000)
	assert_eq(_json_of(loaded), _json())


# --- Ayudantes -------------------------------------------------------------


## El comando falla con ese motivo y no cambia nada: ni el estado, ni el
## azar, ni los cambios anotados.
func _assert_refused_without_changes(command: Callable, reason: String, text: String = "") -> void:
	var before: String = _json()
	var twins: Array[RandomNumberGenerator] = _twins()
	_sim.changes.clear()
	var result: CommandResult = command.call()
	assert_false(result.ok, text)
	assert_eq(result.reason, reason, text)
	assert_eq(_json(), before, text)
	assert_true(_sim.changes.is_empty(), text)
	_assert_no_draws(twins)


## Copias de los dos flujos de azar, para ver después que no se usaron.
func _twins() -> Array[RandomNumberGenerator]:
	var twins: Array[RandomNumberGenerator] = []
	for rng: RandomNumberGenerator in [_state.orders_rng, _state.prints_rng]:
		var twin: RandomNumberGenerator = RandomNumberGenerator.new()
		twin.seed = rng.seed
		twin.state = rng.state
		twins.append(twin)
	return twins


func _assert_no_draws(twins: Array[RandomNumberGenerator]) -> void:
	assert_eq(_state.orders_rng.state, twins[0].state, "No usa el azar del tablero")
	assert_eq(_state.prints_rng.state, twins[1].state, "No usa el azar de los fallos")


func _json() -> String:
	return _json_of(_state)


func _json_of(state: GameState) -> String:
	return JSON.stringify(SaveCodec.encode(state), "", true)
