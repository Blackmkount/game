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
	(_files["clients"] as Array).append({"id": "amigos", "name_key": "CLIENT_AMIGOS"})
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
