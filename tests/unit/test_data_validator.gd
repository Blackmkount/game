extends GutTest
## Comprueba que DataValidator detecta datos rotos. Cada prueba parte de una
## copia de los datos reales y les mete un solo error.

const TranslationKeys: GDScript = preload("res://tests/helpers/translation_keys.gd")

var _files: Dictionary[String, Variant]
var _keys: Array[String]


func before_each() -> void:
	_files = DataCatalog.load_from().files.duplicate(true)
	_keys = TranslationKeys.read()


func test_real_data_has_no_errors() -> void:
	assert_eq(_errors(), [] as Array[String])


func test_detects_missing_field() -> void:
	_find("printers", "cubo_uno").erase("price")
	_assert_error_mentions("falta el campo 'price'")


func test_detects_wrong_type() -> void:
	_find("orders", "llavero")["pieces"] = "una"
	_assert_error_mentions("'pieces' debe ser de tipo int")


func test_detects_unknown_material_in_order() -> void:
	_find("orders", "llavero")["materials"] = ["madera"]
	_assert_error_mentions("'madera' no existe en materials.json")


func test_detects_duplicate_id() -> void:
	(_files["clients"] as Array).append(_find("clients", "amigos").duplicate(true))
	_assert_error_mentions("'amigos' está repetido")


func test_detects_missing_translation() -> void:
	_find("materials", "pla")["name_key"] = "MATERIAL_INVENTADO"
	_assert_error_mentions("MATERIAL_INVENTADO")


func test_detects_order_that_no_printer_can_make() -> void:
	var order: Dictionary = _find("orders", "llavero")
	order["materials"] = ["resina"]
	order["multicolor"] = true
	_assert_error_mentions("ninguna impresora puede imprimirlo")


func test_detects_material_of_another_technology() -> void:
	(_find("printers", "cubo_uno")["materials"] as Array).append("resina")
	_assert_error_mentions("otra tecnología")


func test_detects_levels_not_increasing() -> void:
	_files["levels"]["xp_thresholds"] = [0, 100, 50]
	_assert_error_mentions("debe ser mayor")


func test_detects_bad_shipping_range() -> void:
	_find("materials", "pla")["shipping_days"] = [5, 3]
	_assert_error_mentions("'shipping_days' debe ser de tipo days")


func test_detects_starting_printers_without_place() -> void:
	_files["config"]["floor_printing"]["max_printers"] = 0
	_assert_error_mentions("no caben en los muebles iniciales ni en el suelo")


func test_detects_unknown_objective_target() -> void:
	_files["objectives"][0]["target"] = "pedido_inventado"
	_assert_error_mentions("'pedido_inventado' no existe en orders.json")


func test_detects_unknown_spool_color() -> void:
	_files["config"]["starting_state"]["spools"][0]["color"] = "fucsia"
	_assert_error_mentions("el color 'fucsia' no existe")


func test_detects_missing_description() -> void:
	_keys.erase("FURNITURE_MESA_AUXILIAR_DESC")
	_assert_error_mentions("FURNITURE_MESA_AUXILIAR_DESC")


func test_detects_missing_file() -> void:
	_files.erase("orders")
	_assert_error_mentions("orders: el archivo debe ser una lista")


# --- Ciclo de pedidos: diseño, tablero y fallos ----------------------------

func test_detects_design_minutes_out_of_range() -> void:
	_find("orders", "llavero")["design_minutes"] = 0
	_assert_error_mentions("orders.llavero.design_minutes: 0.0 está fuera del rango")


func test_detects_unknown_design_kind() -> void:
	_find("orders", "llavero")["design_kind"] = "magia"
	_assert_error_mentions("tipo de diseño desconocido 'magia'")


func test_detects_missing_ask_text() -> void:
	_keys.erase("ORDER_LLAVERO_ASK")
	_assert_error_mentions("ORDER_LLAVERO_ASK")


func test_detects_missing_delivery_text() -> void:
	_keys.erase("DELIVERY_PICKUP")
	_assert_error_mentions("DELIVERY_PICKUP")


func test_detects_client_without_thanks() -> void:
	_find("clients", "amigos")["thanks_keys"] = []
	_assert_error_mentions("clients.amigos: necesita al menos un agradecimiento")


func test_detects_missing_thanks_text() -> void:
	_keys.erase("THANKS_AMIGOS_2")
	_assert_error_mentions("THANKS_AMIGOS_2")


func test_detects_max_active_orders_out_of_range() -> void:
	_files["config"]["order_board"]["max_active_orders"] = 0
	_assert_error_mentions("config.order_board.max_active_orders: 0.0 está fuera del rango")


func test_detects_first_offer_time_out_of_range() -> void:
	_files["config"]["order_board"]["first_offer_after_game_minutes"] = 0
	_assert_error_mentions("config.order_board.first_offer_after_game_minutes: 0.0 está fuera del rango")


func test_detects_starting_offer_gap_out_of_range() -> void:
	_files["config"]["order_board"]["starting_offer_gap_game_minutes"] = 0
	_assert_error_mentions("config.order_board.starting_offer_gap_game_minutes: 0.0 está fuera del rango")


func test_detects_unknown_starting_offer() -> void:
	_files["config"]["order_board"]["starting_offers"] = ["no_existe"]
	_assert_error_mentions("'no_existe' no existe en orders.json")


func test_detects_bad_starting_offers_list() -> void:
	_files["config"]["order_board"]["starting_offers"] = ["llavero", "llavero", "figura", "maceta"]
	_assert_error_mentions("'llavero' está repetido")
	_assert_error_mentions("hay más pedidos iniciales que lugares en el tablero")
	_assert_error_mentions("'figura' es de nivel 2 y debe ser de nivel 1")


func test_detects_starting_offer_not_makeable_at_start() -> void:
	# La perilla solo acepta PETG y al empezar solo hay un carrete de PLA.
	_files["config"]["order_board"]["starting_offers"] = ["perilla"]
	_assert_error_mentions("'perilla' no se puede hacer con las impresoras y el material iniciales")


func test_detects_starting_offer_without_enough_grams() -> void:
	_files["config"]["starting_state"]["spools"][0]["grams"] = 5
	_assert_error_mentions("'llavero' no se puede hacer con las impresoras y el material iniciales")


func test_detects_focus_multiplier_out_of_range() -> void:
	_files["config"]["design"]["focus_multiplier"] = 1.5
	_assert_error_mentions("config.design.focus_multiplier: 1.5 está fuera del rango")


func test_detects_prep_minutes_out_of_range() -> void:
	_files["config"]["printing"]["prep_minutes_per_piece"] = -1
	_assert_error_mentions("config.printing.prep_minutes_per_piece: -1.0 está fuera del rango")


func test_detects_max_chance_out_of_range() -> void:
	_files["config"]["failures"]["max_chance"] = 0
	_assert_error_mentions("config.failures.max_chance: 0.0 está fuera del rango")


func test_detects_grace_pieces_out_of_range() -> void:
	_files["config"]["failures"]["grace_pieces"] = -1
	_assert_error_mentions("config.failures.grace_pieces: -1.0 está fuera del rango")


func test_detects_missing_failure_type_weight() -> void:
	_files["config"]["failures"]["random_type_weights"] = {"spaghetti": 1}
	_assert_error_mentions("random_type_weights: falta el tipo de fallo 'warping'")


func test_detects_reversed_stop_progress_range() -> void:
	_files["config"]["failures"]["stop_progress"]["warping"] = [0.5, 0.2]
	_assert_error_mentions("'stop_progress' debe ser de tipo ranges")


func test_detects_bad_stop_progress_types_and_limits() -> void:
	_files["config"]["failures"]["stop_progress"] = {"spaghetti": [0.0, 0.6], "lluvia": [0.1, 0.2]}
	_assert_error_mentions("stop_progress: falta el tipo de fallo 'warping'")
	_assert_error_mentions("stop_progress: tipo de fallo desconocido 'lluvia'")
	_assert_error_mentions("config.failures.stop_progress.spaghetti: 0.0 está fuera del rango")


func test_detects_fractional_game_seconds_per_real_second() -> void:
	_files["config"]["time"]["game_seconds_per_real_second"] = 24.5
	_assert_error_mentions("'game_seconds_per_real_second' debe ser de tipo int")


func test_detects_unknown_local_store_color() -> void:
	_files["config"]["local_store"]["color"] = "violeta"
	_assert_error_mentions("el color 'violeta' no existe")


func _errors() -> Array[String]:
	return DataValidator.validate(_files, _keys)


func _assert_error_mentions(text: String) -> void:
	var errors: Array[String] = _errors()
	var found: bool = errors.any(func(error: String) -> bool: return error.contains(text))
	assert_true(found, "Se esperaba un error que mencione '%s'. Errores: %s" % [text, errors])


func _find(list_name: String, id: String) -> Dictionary:
	for entry: Dictionary in _files[list_name]:
		if entry["id"] == id:
			return entry
	return {}
