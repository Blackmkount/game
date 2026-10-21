class_name DataValidator
extends RefCounted
## Revisa que los datos de balance (data/*.json) estén completos y sean
## coherentes: campos obligatorios, tipos, rangos y referencias entre archivos.
##
## Uso: DataValidator.validate(catalog.files, claves_de_traduccion) devuelve
## la lista de problemas encontrados, vacía si todo está bien.

const VOLUMES: Array[String] = ["S", "M", "L"]
const TECHNOLOGIES: Array[String] = ["fdm", "resin"]
const PRINT_MODES: Array[String] = ["draft", "normal", "fine"]
const FAILURE_TYPES: Array[String] = ["spaghetti", "warping"]
## Cómo se consigue el modelo 3D de un pedido (cambia cuánto tarda modelarlo).
const DESIGN_KINDS: Array[String] = ["template", "custom", "measure", "client_file"]
## Tipos de objetivo y el archivo al que apunta su "target" ("" = ninguno).
const OBJECTIVE_TARGETS: Dictionary[String, String] = {
	"deliver_orders": "orders",
	"own_furniture": "furniture",
	"own_printers": "printers",
	"own_space": "spaces",
	"install_accessory": "accessories",
	"buy_material": "materials",
	"reach_level": "",
}
## Listas cuyos elementos necesitan además una descripción "<name_key>_DESC".
const DESCRIBED_LISTS: Array[String] = ["accessories", "furniture"]
const MIN_QUALITY: int = 1
const MAX_QUALITY: int = 5

## Campos obligatorios de los archivos con forma de lista. Tipos: "string",
## "text" (puede estar vacío), "number", "int", "bool", "ids" (lista de
## identificadores) y "days" (rango [mínimo, máximo] de días de envío).
const LIST_SCHEMAS: Dictionary[String, Dictionary] = {
	"materials": {
		"id": "string", "name_key": "string", "technology": "string", "price": "number",
		"unit_grams": "int", "failure_multiplier": "number", "time_multiplier": "number",
		"unlock_level": "int", "shipping_days": "days",
	},
	"printers": {
		"id": "string", "name_key": "string", "technology": "string", "price": "number",
		"speed": "number", "max_quality": "int", "volume": "string", "materials": "ids",
		"multicolor": "bool", "enclosed": "bool", "reliability": "number",
		"built_in_accessories": "ids", "unlock_level": "int", "shipping_days": "days",
	},
	"accessories": {
		"id": "string", "name_key": "string", "technology": "string", "price": "number",
		"unlock_level": "int", "shipping_days": "days", "warping_multiplier": "number",
		"pauses_on_runout": "bool", "spaghetti_pause_progress": "number",
	},
	"furniture": {
		"id": "string", "name_key": "string", "purchasable": "bool", "price": "number",
		"unlock_level": "int", "shipping_days": "days", "floor_slots": "int",
		"printer_slots": "int", "storage_grams": "int", "reliability_bonus": "number",
		"max_owned": "int",
	},
	"spaces": {
		"id": "string", "name_key": "string", "price": "number", "unlock_level": "int",
		"floor_slots": "int",
	},
	"clients": {"id": "string", "name_key": "string", "delivery_key": "string", "thanks_keys": "ids"},
	"orders": {
		"id": "string", "name_key": "string", "client": "string", "size": "string",
		"min_quality": "int", "materials": "ids", "multicolor": "bool", "pieces": "int",
		"grams_per_piece": "number", "minutes_per_piece": "number", "payment": "number",
		"xp": "int", "min_level": "int", "deadline_days": "number",
		"design_kind": "string", "design_minutes": "number", "ask_key": "string",
	},
	"objectives": {
		"id": "string", "name_key": "string", "type": "string", "target": "text",
		"count": "int", "reward_money": "number", "reward_xp": "int",
	},
}
## Secciones de config.json. Tipos extra: "list" (lista de objetos),
## "weights" (nombre -> peso) y "ranges" (nombre -> [mínimo, máximo]).
## Los segundos de juego por segundo real deben ser enteros: el reloj de la
## simulación cuenta segundos enteros.
const CONFIG_SCHEMAS: Dictionary[String, Dictionary] = {
	"starting_state": {
		"money": "number", "xp": "int", "start_hour": "number", "space": "string",
		"printers": "ids", "furniture": "ids", "spools": "list",
	},
	"time": {"game_seconds_per_real_second": "int", "offline_limit_real_hours": "number"},
	"order_board": {
		"slots": "int", "new_order_every_game_minutes": "number", "max_active_orders": "int",
		"starting_offers": "ids", "first_offer_after_game_minutes": "number",
		"starting_offer_gap_game_minutes": "number",
	},
	"design": {"focus_multiplier": "number"},
	"printing": {"prep_minutes_per_piece": "number"},
	"late_delivery": {"payment_multiplier": "number", "xp_multiplier": "number"},
	"storage": {"base_capacity_grams": "int"},
	"floor_printing": {"max_printers": "int", "reliability_penalty": "number"},
	"shipping": {"express_days": "int", "express_fee": "number"},
	"local_store": {"materials": "ids", "price_multiplier": "number", "color": "string", "grams": "int"},
	"rescue": {"material": "string", "color": "string", "grams": "int"},
	"failures": {
		"random_type_weights": "weights", "enclosed_warping_multiplier": "number",
		"max_chance": "number", "grace_pieces": "int", "stop_progress": "ranges",
	},
}
const PRINT_MODE_SCHEMA: Dictionary = {
	"id": "string", "name_key": "string", "quality_delta": "int",
	"time_multiplier": "number", "failure_multiplier": "number",
}
const COLOR_SCHEMA: Dictionary = {"id": "string", "name_key": "string", "hex": "string"}
const SPOOL_SCHEMA: Dictionary = {"material": "string", "color": "string", "grams": "int"}

var _files: Dictionary[String, Variant]
var _translation_keys: Array[String]
var _errors: Array[String] = []
## Entradas válidas de cada lista, por id: {"printers": {"cubo_uno": {...}}}.
var _by_id: Dictionary[String, Dictionary] = {}
var _max_level: int = 1
var _color_ids: Array[String] = []
## Mayor mejora de calidad que da un modo de impresión ("fino").
var _best_quality_delta: int = 0


static func validate(files: Dictionary[String, Variant], translation_keys: Array[String]) -> Array[String]:
	var validator: DataValidator = DataValidator.new()
	validator._files = files
	validator._translation_keys = translation_keys
	validator._run()
	return validator._errors


func _run() -> void:
	_check_levels()
	for list_name: String in LIST_SCHEMAS:
		_check_list(list_name)
	_best_quality_delta = _read_best_quality_delta()
	_check_materials()
	_check_printers()
	_check_accessories()
	_check_furniture()
	_check_spaces()
	_check_clients()
	_check_orders()
	_check_objectives()
	_check_config()


func _error(message: String) -> void:
	_errors.append(message)


# --- Estructura general ---------------------------------------------------

func _check_levels() -> void:
	var levels: Variant = _files.get("levels")
	if not levels is Dictionary or not _matches(levels.get("xp_thresholds"), "ids_numbers"):
		_error("levels: falta 'xp_thresholds' como lista de números")
		return
	var thresholds: Array = levels["xp_thresholds"]
	if thresholds.is_empty() or thresholds[0] != 0:
		_error("levels: el nivel 1 debe empezar con 0 de experiencia")
	for i: int in range(1, thresholds.size()):
		if thresholds[i] <= thresholds[i - 1]:
			_error("levels: la experiencia del nivel %d debe ser mayor que la del nivel %d" % [i + 1, i])
	_max_level = maxi(thresholds.size(), 1)


func _check_list(list_name: String) -> void:
	_by_id[list_name] = {}
	var entries: Variant = _files.get(list_name)
	if not entries is Array:
		_error("%s: el archivo debe ser una lista" % list_name)
		return
	for index: int in (entries as Array).size():
		var entry: Variant = entries[index]
		var context: String = "%s[%d]" % [list_name, index]
		if not entry is Dictionary:
			_error("%s: cada elemento debe ser un objeto" % context)
			continue
		if not _check_fields(context, entry, LIST_SCHEMAS[list_name]):
			continue
		var id: String = entry["id"]
		if _by_id[list_name].has(id):
			_error("%s: el id '%s' está repetido" % [list_name, id])
			continue
		_check_translation(list_name + "." + id, entry["name_key"])
		if list_name in DESCRIBED_LISTS:
			_check_translation(list_name + "." + id, entry["name_key"] + "_DESC")
		_by_id[list_name][id] = entry


## Revisa que existan los campos del esquema con el tipo correcto.
## Devuelve false si falta alguno o tiene otro tipo.
func _check_fields(context: String, entry: Dictionary, schema: Dictionary) -> bool:
	var ok: bool = true
	for field: String in schema:
		if not entry.has(field):
			_error("%s: falta el campo '%s'" % [context, field])
			ok = false
		elif not _matches(entry[field], schema[field]):
			_error("%s: el campo '%s' debe ser de tipo %s" % [context, field, schema[field]])
			ok = false
	return ok


func _matches(value: Variant, type: String) -> bool:
	match type:
		"string":
			return value is String and not (value as String).is_empty()
		"text":
			return value is String
		"list":
			return value is Array and (value as Array).all(func(item: Variant) -> bool: return item is Dictionary)
		"number":
			return value is float or value is int
		"int":
			return (value is float or value is int) and is_equal_approx(fmod(float(value), 1.0), 0.0)
		"bool":
			return value is bool
		"ids":
			return value is Array and (value as Array).all(func(item: Variant) -> bool: return item is String)
		"ids_numbers":
			return value is Array and (value as Array).all(func(item: Variant) -> bool: return item is float or item is int)
		"days":
			return _is_ordered_pair(value, "int") and value[0] >= 0
		"weights":
			if not value is Dictionary:
				return false
			for key: Variant in value:
				if not key is String or not _matches(value[key], "number") or value[key] < 0:
					return false
			return true
		"ranges":
			if not value is Dictionary:
				return false
			for key: Variant in value:
				if not key is String or not _is_ordered_pair(value[key], "number"):
					return false
			return true
	return false


## Lista [a, b] de dos valores del tipo indicado con a <= b.
func _is_ordered_pair(value: Variant, item_type: String) -> bool:
	return value is Array and (value as Array).size() == 2 \
		and _matches(value[0], item_type) and _matches(value[1], item_type) \
		and value[0] <= value[1]


func _check_translation(context: String, key: String) -> void:
	if not _translation_keys.is_empty() and key not in _translation_keys:
		_error("%s: la clave de texto '%s' no está en translations.csv" % [context, key])


func _check_ref(context: String, list_name: String, id: String) -> void:
	if not _by_id[list_name].has(id):
		_error("%s: '%s' no existe en %s.json" % [context, id, list_name])


func _check_range(context: String, value: float, min_value: float, max_value: float) -> void:
	if value < min_value or value > max_value:
		_error("%s: %s está fuera del rango [%s, %s]" % [context, value, min_value, max_value])


## Revisa nivel de desbloqueo, precio y envío de algo que se vende en la tienda.
func _check_shop_item(context: String, entry: Dictionary, purchasable: bool = true) -> void:
	_check_range(context + ".unlock_level", entry["unlock_level"], 1, _max_level)
	_check_range(context + ".price", entry["price"], 0, INF)
	if purchasable and entry["shipping_days"][0] < 1:
		_error("%s: lo que se compra en la tienda tarda al menos 1 día en llegar" % context)


# --- Archivos con forma de lista ------------------------------------------

func _check_materials() -> void:
	for id: String in _by_id["materials"]:
		var material: Dictionary = _by_id["materials"][id]
		var context: String = "materials." + id
		_check_shop_item(context, material)
		if material["technology"] not in TECHNOLOGIES:
			_error("%s: tecnología desconocida '%s'" % [context, material["technology"]])
		_check_range(context + ".unit_grams", material["unit_grams"], 1, INF)
		_check_range(context + ".failure_multiplier", material["failure_multiplier"], 0.01, 10)
		_check_range(context + ".time_multiplier", material["time_multiplier"], 0.01, 10)


func _check_printers() -> void:
	for id: String in _by_id["printers"]:
		var printer: Dictionary = _by_id["printers"][id]
		var context: String = "printers." + id
		_check_shop_item(context, printer)
		_check_range(context + ".speed", printer["speed"], 0.01, 100)
		_check_range(context + ".max_quality", printer["max_quality"], MIN_QUALITY, MAX_QUALITY)
		_check_range(context + ".reliability", printer["reliability"], 0.01, 1)
		if printer["volume"] not in VOLUMES:
			_error("%s: volumen desconocido '%s'" % [context, printer["volume"]])
		if printer["technology"] not in TECHNOLOGIES:
			_error("%s: tecnología desconocida '%s'" % [context, printer["technology"]])
		if (printer["materials"] as Array).is_empty():
			_error("%s: debe aceptar al menos un material" % context)
		for material_id: String in printer["materials"]:
			_check_ref(context, "materials", material_id)
			var material: Dictionary = _by_id["materials"].get(material_id, {})
			if not material.is_empty() and material["technology"] != printer["technology"]:
				_error("%s: no puede usar '%s' porque es de otra tecnología" % [context, material_id])
		for accessory_id: String in printer["built_in_accessories"]:
			_check_ref(context, "accessories", accessory_id)


func _check_accessories() -> void:
	for id: String in _by_id["accessories"]:
		var accessory: Dictionary = _by_id["accessories"][id]
		var context: String = "accessories." + id
		_check_shop_item(context, accessory)
		if accessory["technology"] not in TECHNOLOGIES:
			_error("%s: tecnología desconocida '%s'" % [context, accessory["technology"]])
		_check_range(context + ".warping_multiplier", accessory["warping_multiplier"], 0, 1)
		_check_range(context + ".spaghetti_pause_progress", accessory["spaghetti_pause_progress"], 0, 0.99)


func _check_furniture() -> void:
	for id: String in _by_id["furniture"]:
		var furniture: Dictionary = _by_id["furniture"][id]
		var context: String = "furniture." + id
		_check_shop_item(context, furniture, furniture["purchasable"])
		_check_range(context + ".floor_slots", furniture["floor_slots"], 1, 100)
		_check_range(context + ".printer_slots", furniture["printer_slots"], 0, 100)
		_check_range(context + ".storage_grams", furniture["storage_grams"], 0, INF)
		_check_range(context + ".reliability_bonus", furniture["reliability_bonus"], 0, 0.2)
		_check_range(context + ".max_owned", furniture["max_owned"], 0, 100)


func _check_spaces() -> void:
	for id: String in _by_id["spaces"]:
		var space: Dictionary = _by_id["spaces"][id]
		var context: String = "spaces." + id
		_check_range(context + ".unlock_level", space["unlock_level"], 1, _max_level)
		_check_range(context + ".price", space["price"], 0, INF)
		_check_range(context + ".floor_slots", space["floor_slots"], 1, 1000)


func _check_clients() -> void:
	for id: String in _by_id["clients"]:
		var client: Dictionary = _by_id["clients"][id]
		var context: String = "clients." + id
		_check_translation(context, client["delivery_key"])
		if (client["thanks_keys"] as Array).is_empty():
			_error("%s: necesita al menos un agradecimiento en 'thanks_keys'" % context)
		for key: String in client["thanks_keys"]:
			_check_translation(context, key)


func _check_orders() -> void:
	for id: String in _by_id["orders"]:
		var order: Dictionary = _by_id["orders"][id]
		var context: String = "orders." + id
		_check_ref(context, "clients", order["client"])
		_check_translation(context, order["ask_key"])
		if order["design_kind"] not in DESIGN_KINDS:
			_error("%s: tipo de diseño desconocido '%s'" % [context, order["design_kind"]])
		_check_range(context + ".design_minutes", order["design_minutes"], 0.5, 1440)
		if order["size"] not in VOLUMES:
			_error("%s: tamaño desconocido '%s'" % [context, order["size"]])
		_check_range(context + ".min_quality", order["min_quality"], MIN_QUALITY, MAX_QUALITY)
		_check_range(context + ".min_level", order["min_level"], 1, _max_level)
		_check_range(context + ".pieces", order["pieces"], 1, 100)
		_check_range(context + ".grams_per_piece", order["grams_per_piece"], 0.1, INF)
		_check_range(context + ".minutes_per_piece", order["minutes_per_piece"], 0.1, INF)
		_check_range(context + ".payment", order["payment"], 0.01, INF)
		_check_range(context + ".xp", order["xp"], 0, INF)
		_check_range(context + ".deadline_days", order["deadline_days"], 0, INF)
		if (order["materials"] as Array).is_empty():
			_error("%s: debe aceptar al menos un material" % context)
		for material_id: String in order["materials"]:
			_check_ref(context, "materials", material_id)
		if order["size"] in VOLUMES and not _some_printer_can_make(order):
			_error("%s: ninguna impresora puede imprimirlo (tamaño, calidad, material o multicolor)" % context)


func _read_best_quality_delta() -> int:
	var best_quality_delta: int = 0
	var config: Variant = _files.get("config", {})
	var modes: Variant = (config as Dictionary).get("print_modes", []) if config is Dictionary else []
	if modes is Array:
		for mode: Variant in modes:
			if mode is Dictionary and _matches(mode.get("quality_delta"), "int"):
				best_quality_delta = maxi(best_quality_delta, int(mode["quality_delta"]))
	return best_quality_delta


func _some_printer_can_make(order: Dictionary) -> bool:
	for printer: Dictionary in _by_id["printers"].values():
		if _printer_can_make(printer, order):
			return true
	return false


## La impresora puede hacer el pedido: tamaño, calidad (con el mejor modo),
## algún material en común y multicolor si hace falta.
func _printer_can_make(printer: Dictionary, order: Dictionary) -> bool:
	var fits: bool = VOLUMES.find(printer["volume"]) >= VOLUMES.find(order["size"])
	var quality: int = mini(int(printer["max_quality"]) + _best_quality_delta, MAX_QUALITY)
	var shares_material: bool = (order["materials"] as Array).any(
		func(material_id: String) -> bool: return material_id in printer["materials"])
	var color_ok: bool = printer["multicolor"] or not order["multicolor"]
	return fits and quality >= order["min_quality"] and shares_material and color_ok


func _check_objectives() -> void:
	for id: String in _by_id["objectives"]:
		var objective: Dictionary = _by_id["objectives"][id]
		var context: String = "objectives." + id
		var type: String = objective["type"]
		var target: String = objective["target"]
		_check_range(context + ".count", objective["count"], 1, 1000)
		_check_range(context + ".reward_money", objective["reward_money"], 0, INF)
		_check_range(context + ".reward_xp", objective["reward_xp"], 0, INF)
		if not OBJECTIVE_TARGETS.has(type):
			_error("%s: tipo de objetivo desconocido '%s'" % [context, type])
		elif type == "reach_level":
			_check_range(context + ".count", objective["count"], 2, _max_level)
		elif not target.is_empty():
			_check_ref(context, OBJECTIVE_TARGETS[type], target)
		elif type in ["own_space", "buy_material", "install_accessory"]:
			_error("%s: este tipo de objetivo necesita un 'target'" % context)


# --- config.json ----------------------------------------------------------

func _check_config() -> void:
	var config: Variant = _files.get("config")
	if not config is Dictionary:
		_error("config: el archivo debe ser un objeto")
		return
	var sections_ok: bool = true
	for section: String in CONFIG_SCHEMAS:
		var value: Variant = config.get(section)
		if not value is Dictionary:
			_error("config: falta la sección '%s'" % section)
			sections_ok = false
		elif not _check_fields("config." + section, value, CONFIG_SCHEMAS[section]):
			sections_ok = false
	_check_print_modes(config.get("print_modes"))
	_check_colors(config.get("filament_colors"))
	if sections_ok:
		_check_config_values(config)


func _check_print_modes(modes: Variant) -> void:
	if not modes is Array:
		_error("config: falta la lista 'print_modes'")
		return
	var ids: Array[String] = []
	for mode: Variant in modes:
		if mode is Dictionary and _check_fields("config.print_modes", mode, PRINT_MODE_SCHEMA):
			ids.append(mode["id"])
			_check_translation("config.print_modes." + str(mode["id"]), mode["name_key"])
			_check_range("config.print_modes.time_multiplier", mode["time_multiplier"], 0.01, 10)
			_check_range("config.print_modes.failure_multiplier", mode["failure_multiplier"], 0.01, 10)
	ids.sort()
	var expected: Array[String] = PRINT_MODES.duplicate()
	expected.sort()
	if ids != expected:
		_error("config.print_modes: debe tener exactamente los modos %s" % [PRINT_MODES])


func _check_colors(colors: Variant) -> void:
	if not colors is Array or (colors as Array).is_empty():
		_error("config: falta la lista 'filament_colors'")
		return
	for color: Variant in colors:
		if not color is Dictionary or not _check_fields("config.filament_colors", color, COLOR_SCHEMA):
			continue
		var context: String = "config.filament_colors." + str(color["id"])
		if color["id"] in _color_ids:
			_error("%s: el id está repetido" % context)
		_color_ids.append(color["id"])
		_check_translation(context, color["name_key"])
		if not Color.html_is_valid(color["hex"]):
			_error("%s: '%s' no es un color válido" % [context, color["hex"]])


func _check_color_ref(context: String, color_id: String) -> void:
	if color_id not in _color_ids:
		_error("%s: el color '%s' no existe en config.filament_colors" % [context, color_id])


func _check_config_values(config: Dictionary) -> void:
	var start: Dictionary = config["starting_state"]
	_check_range("config.starting_state.money", start["money"], 0, INF)
	_check_range("config.starting_state.xp", start["xp"], 0, INF)
	_check_range("config.starting_state.start_hour", start["start_hour"], 0, 23)
	_check_ref("config.starting_state.space", "spaces", start["space"])
	for printer_id: String in start["printers"]:
		_check_ref("config.starting_state.printers", "printers", printer_id)
	for furniture_id: String in start["furniture"]:
		_check_ref("config.starting_state.furniture", "furniture", furniture_id)
	for spool: Dictionary in start["spools"]:
		if _check_fields("config.starting_state.spools", spool, SPOOL_SCHEMA):
			_check_ref("config.starting_state.spools", "materials", spool["material"])
			_check_color_ref("config.starting_state.spools", spool["color"])
			_check_range("config.starting_state.spools.grams", spool["grams"], 1, INF)
	_check_starting_room(start, config["floor_printing"])

	_check_range("config.time.game_seconds_per_real_second", config["time"]["game_seconds_per_real_second"], 1, 10000)
	_check_range("config.time.offline_limit_real_hours", config["time"]["offline_limit_real_hours"], 0, 72)
	_check_order_board(config["order_board"], start)
	_check_range("config.design.focus_multiplier", config["design"]["focus_multiplier"], 0.1, 1.0)
	_check_range("config.printing.prep_minutes_per_piece", config["printing"]["prep_minutes_per_piece"], 0, 60)
	_check_range("config.late_delivery.payment_multiplier", config["late_delivery"]["payment_multiplier"], 0, 1)
	_check_range("config.late_delivery.xp_multiplier", config["late_delivery"]["xp_multiplier"], 0, 1)
	_check_range("config.storage.base_capacity_grams", config["storage"]["base_capacity_grams"], 0, INF)
	_check_range("config.floor_printing.max_printers", config["floor_printing"]["max_printers"], 0, 10)
	_check_range("config.floor_printing.reliability_penalty", config["floor_printing"]["reliability_penalty"], 0, 0.5)
	_check_range("config.shipping.express_days", config["shipping"]["express_days"], 1, 30)
	_check_range("config.shipping.express_fee", config["shipping"]["express_fee"], 0, INF)
	_check_range("config.local_store.price_multiplier", config["local_store"]["price_multiplier"], 1, 10)
	for material_id: String in config["local_store"]["materials"]:
		_check_ref("config.local_store.materials", "materials", material_id)
	_check_color_ref("config.local_store.color", config["local_store"]["color"])
	_check_range("config.local_store.grams", config["local_store"]["grams"], 1, INF)
	_check_ref("config.rescue.material", "materials", config["rescue"]["material"])
	_check_color_ref("config.rescue.color", config["rescue"]["color"])
	_check_range("config.rescue.grams", config["rescue"]["grams"], 1, INF)
	_check_failures(config["failures"])


## Tablero de pedidos y pedidos del primer mensaje. Cada pedido inicial debe
## poder hacerse con lo que se tiene al empezar la partida.
func _check_order_board(board: Dictionary, start: Dictionary) -> void:
	_check_range("config.order_board.slots", board["slots"], 1, 20)
	_check_range("config.order_board.new_order_every_game_minutes", board["new_order_every_game_minutes"], 1, INF)
	_check_range("config.order_board.max_active_orders", board["max_active_orders"], 1, 20)
	_check_range("config.order_board.first_offer_after_game_minutes", board["first_offer_after_game_minutes"], 0.1, 1440)
	_check_range("config.order_board.starting_offer_gap_game_minutes", board["starting_offer_gap_game_minutes"], 1, INF)
	var context: String = "config.order_board.starting_offers"
	var offers: Array = board["starting_offers"]
	if offers.size() > int(board["slots"]):
		_error("%s: hay más pedidos iniciales que lugares en el tablero" % context)
	var seen: Array[String] = []
	for order_id: String in offers:
		if order_id in seen:
			_error("%s: '%s' está repetido" % [context, order_id])
		seen.append(order_id)
		_check_ref(context, "orders", order_id)
		var order: Dictionary = _by_id["orders"].get(order_id, {})
		if order.is_empty():
			continue
		if int(order["min_level"]) != 1:
			_error("%s: '%s' es de nivel %d y debe ser de nivel 1" % [context, order_id, order["min_level"]])
		if not _starting_state_can_make(start, order):
			_error("%s: '%s' no se puede hacer con las impresoras y el material iniciales" % [context, order_id])


## Alguna impresora inicial puede hacer el pedido y tiene un carrete inicial
## de un material que aceptan los dos, con gramos para todas las piezas.
func _starting_state_can_make(start: Dictionary, order: Dictionary) -> bool:
	var needed_grams: int = int(order["pieces"]) * ceili(float(order["grams_per_piece"]))
	for printer_id: String in start["printers"]:
		var printer: Dictionary = _by_id["printers"].get(printer_id, {})
		if printer.is_empty() or not _printer_can_make(printer, order):
			continue
		for spool: Dictionary in start["spools"]:
			var material_id: Variant = spool.get("material")
			if material_id in order["materials"] and material_id in printer["materials"] \
					and _matches(spool.get("grams"), "number") and spool["grams"] >= needed_grams:
				return true
	return false


func _check_failures(failures: Dictionary) -> void:
	_check_range("config.failures.enclosed_warping_multiplier", failures["enclosed_warping_multiplier"], 0, 1)
	_check_range("config.failures.max_chance", failures["max_chance"], 0.01, 1)
	_check_range("config.failures.grace_pieces", failures["grace_pieces"], 0, 100)
	var weights: Dictionary = failures["random_type_weights"]
	_check_failure_types("config.failures.random_type_weights", weights)
	var total_weight: float = 0.0
	for failure_type: String in weights:
		total_weight += weights[failure_type]
	if total_weight <= 0.0:
		_error("config.failures: los pesos de los tipos de fallo deben sumar más que 0")
	var stop_progress: Dictionary = failures["stop_progress"]
	_check_failure_types("config.failures.stop_progress", stop_progress)
	for failure_type: String in stop_progress:
		var context: String = "config.failures.stop_progress." + failure_type
		_check_range(context, stop_progress[failure_type][0], 0.01, 0.99)
		_check_range(context, stop_progress[failure_type][1], 0.01, 0.99)


## Las claves deben ser exactamente los tipos de fallo conocidos.
func _check_failure_types(context: String, by_type: Dictionary) -> void:
	for failure_type: String in by_type:
		if failure_type not in FAILURE_TYPES:
			_error("%s: tipo de fallo desconocido '%s'" % [context, failure_type])
	for failure_type: String in FAILURE_TYPES:
		if not by_type.has(failure_type):
			_error("%s: falta el tipo de fallo '%s'" % [context, failure_type])


## Las impresoras iniciales deben caber en los muebles iniciales (o en el
## suelo), y los muebles iniciales en el espacio inicial.
func _check_starting_room(start: Dictionary, floor_printing: Dictionary) -> void:
	var printer_slots: int = int(floor_printing["max_printers"])
	var floor_slots: int = 0
	for furniture_id: String in start["furniture"]:
		var furniture: Dictionary = _by_id["furniture"].get(furniture_id, {})
		if not furniture.is_empty():
			printer_slots += int(furniture["printer_slots"])
			floor_slots += int(furniture["floor_slots"])
	if (start["printers"] as Array).size() > printer_slots:
		_error("config.starting_state: las impresoras iniciales no caben en los muebles iniciales ni en el suelo")
	var space: Dictionary = _by_id["spaces"].get(start["space"], {})
	if not space.is_empty() and floor_slots > int(space["floor_slots"]):
		_error("config.starting_state: los muebles iniciales no caben en el espacio inicial")
