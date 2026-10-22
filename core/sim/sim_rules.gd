class_name SimRules
extends RefCounted
## Reglas de balance listas para la simulación. Se arma una sola vez desde
## data/*.json con from_catalog() y es el único lugar donde los números del
## JSON se vuelven enteros: segundos de juego, gramos y centavos.
##
## advance() y los flujos leen de aquí y nunca llaman a DataLookup.by_id.
## Las pruebas pueden cambiar campos de su propia instancia.

var catalog: DataCatalog
## Elementos de data/*.json por id.
var printers: Dictionary[String, Dictionary] = {}
var materials: Dictionary[String, Dictionary] = {}
var orders: Dictionary[String, Dictionary] = {}
var clients: Dictionary[String, Dictionary] = {}
var accessories: Dictionary[String, Dictionary] = {}
var furniture: Dictionary[String, Dictionary] = {}
var spaces: Dictionary[String, Dictionary] = {}
## Modos de impresión (config.print_modes) por id.
var modes: Dictionary[String, Dictionary] = {}
## Colores de filamento (config.filament_colors) por id.
var colors: Dictionary[String, Dictionary] = {}
## Ids de los pedidos en el orden del archivo.
var order_list: Array[String] = []
## Orden en que se prueban los modos al recomendar un plan de impresión.
var mode_list: Array[String] = ["normal", "fine", "draft"]
## Mayor quality_delta entre los modos de impresión.
var best_quality_delta: int = 0
var levels: LevelTable

# Tablero de pedidos.
var board_slots: int = 0
var max_active_orders: int = 0
var offer_interval_seconds: int = 0
var first_offer_seconds: int = 0
var starting_gap_seconds: int = 0
var starting_offers: Array[String] = []

# Modelado.
## Parte del modelado que queda al tocar "Concentrarse"; 1.0 lo apaga.
var focus_multiplier: float = 1.0
var design_seconds: Dictionary[String, int] = {}

# Tiempos.
## Plazo de cada pedido en segundos de juego; 0 = sin plazo.
var deadline_seconds: Dictionary[String, int] = {}
var prep_seconds_per_piece: int = 0

# Pedidos.
## Gramos por pieza, redondeados hacia arriba.
var order_grams: Dictionary[String, int] = {}
var payment_cents: Dictionary[String, int] = {}

# Fallos.
var weight_spaghetti: float = 0.0
var weight_warping: float = 0.0
var enclosed_warping_multiplier: float = 1.0
var max_chance: float = 1.0
## Piezas del comienzo de la partida que nunca fallan.
var grace_pieces: int = 0
## Por tipo de fallo, entre qué avances de la pieza se detiene (x = mínimo, y = máximo).
var stop_ranges: Dictionary[String, Vector2] = {}

# Entrega atrasada.
var late_payment_multiplier: float = 1.0
var late_xp_multiplier: float = 1.0

# Taller.
var floor_reliability_penalty: float = 0.0
var floor_printer_limit: int = 0
var base_storage_grams: int = 0

# Ritmo del tiempo.
var game_seconds_per_real_second: int = 1


static func from_catalog(p_catalog: DataCatalog) -> SimRules:
	var rules: SimRules = SimRules.new()
	var files: Dictionary[String, Variant] = p_catalog.files
	var config: Dictionary = files["config"]
	rules.catalog = p_catalog
	_index(files["printers"], rules.printers)
	_index(files["materials"], rules.materials)
	_index(files["orders"], rules.orders)
	_index(files["clients"], rules.clients)
	_index(files["accessories"], rules.accessories)
	_index(files["furniture"], rules.furniture)
	_index(files["spaces"], rules.spaces)
	_index(config["print_modes"], rules.modes)
	_index(config["filament_colors"], rules.colors)
	rules.best_quality_delta = _best_quality_delta(config["print_modes"])
	rules.levels = LevelTable.from_catalog(p_catalog)
	rules._read_orders(files["orders"])
	rules._read_board(config["order_board"])
	rules._read_failures(config["failures"])
	rules.focus_multiplier = float(config["design"]["focus_multiplier"])
	rules.prep_seconds_per_piece = roundi(float(config["printing"]["prep_minutes_per_piece"]) * GameClock.SECONDS_PER_MINUTE)
	rules.late_payment_multiplier = float(config["late_delivery"]["payment_multiplier"])
	rules.late_xp_multiplier = float(config["late_delivery"]["xp_multiplier"])
	rules.floor_reliability_penalty = float(config["floor_printing"]["reliability_penalty"])
	rules.floor_printer_limit = int(config["floor_printing"]["max_printers"])
	rules.base_storage_grams = int(config["storage"]["base_capacity_grams"])
	rules.game_seconds_per_real_second = roundi(float(config["time"]["game_seconds_per_real_second"]))
	return rules


func _read_orders(list: Array) -> void:
	for order: Dictionary in list:
		var id: String = order["id"]
		order_list.append(id)
		design_seconds[id] = _minutes_to_seconds(float(order["design_minutes"]))
		var days: float = float(order["deadline_days"])
		deadline_seconds[id] = maxi(1, roundi(days * GameClock.SECONDS_PER_DAY)) if days > 0.0 else 0
		order_grams[id] = maxi(1, ceili(float(order["grams_per_piece"])))
		payment_cents[id] = roundi(float(order["payment"]) * 100.0)


func _read_board(board: Dictionary) -> void:
	board_slots = int(board["slots"])
	max_active_orders = int(board["max_active_orders"])
	offer_interval_seconds = _minutes_to_seconds(float(board["new_order_every_game_minutes"]))
	first_offer_seconds = _minutes_to_seconds(float(board["first_offer_after_game_minutes"]))
	starting_gap_seconds = _minutes_to_seconds(float(board["starting_offer_gap_game_minutes"]))
	for id: String in board["starting_offers"]:
		starting_offers.append(id)


func _read_failures(failures: Dictionary) -> void:
	var weights: Dictionary = failures["random_type_weights"]
	weight_spaghetti = float(weights["spaghetti"])
	weight_warping = float(weights["warping"])
	enclosed_warping_multiplier = float(failures["enclosed_warping_multiplier"])
	max_chance = float(failures["max_chance"])
	grace_pieces = int(failures["grace_pieces"])
	var stops: Dictionary = failures["stop_progress"]
	for type: String in stops:
		var stop: Array = stops[type]
		stop_ranges[type] = Vector2(float(stop[0]), float(stop[1]))


## Minutos de juego del JSON a segundos de juego; nunca menos de 1.
static func _minutes_to_seconds(minutes: float) -> int:
	return maxi(1, roundi(minutes * GameClock.SECONDS_PER_MINUTE))


static func _index(list: Array, target: Dictionary[String, Dictionary]) -> void:
	for entry: Dictionary in list:
		target[entry["id"]] = entry


static func _best_quality_delta(print_modes: Array) -> int:
	var best: int = int(print_modes[0]["quality_delta"])
	for mode: Dictionary in print_modes:
		best = maxi(best, int(mode["quality_delta"]))
	return best
