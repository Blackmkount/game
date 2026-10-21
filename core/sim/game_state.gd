class_name GameState
extends RefCounted
## Estado completo de una partida: solo datos. Las reglas que lo modifican
## viven en otras clases de core/sim.

## El dinero se guarda en centavos para no acumular errores de redondeo.
var money_cents: int = 0
var xp: int = 0
## Minutos de juego desde el día 1 a las 00:00.
var game_minutes: float = 0.0
var space_id: String = ""
var spools: Array[Spool] = []
var printers: Array[OwnedPrinter] = []
var furniture: Array[OwnedFurniture] = []
## Semilla del azar de la partida, para que todo sea reproducible.
var rng_seed: int = 0
var _next_uid: int = 1


## Crea la partida inicial según config.starting_state.
static func new_game(catalog: DataCatalog, p_seed: int) -> GameState:
	var start: Dictionary = catalog.files["config"]["starting_state"]
	var state: GameState = GameState.new()
	state.rng_seed = p_seed
	state.money_cents = int(round(float(start["money"]) * 100.0))
	state.xp = int(start["xp"])
	state.game_minutes = float(start["start_hour"]) * GameClock.MINUTES_PER_HOUR
	state.space_id = start["space"]
	for spool: Dictionary in start["spools"]:
		state.spools.append(Spool.new(spool["material"], spool["color"], int(spool["grams"])))
	for furniture_id: String in start["furniture"]:
		state.furniture.append(OwnedFurniture.new(state.take_uid(), furniture_id, state.furniture.size()))
	for printer_id: String in start["printers"]:
		var place: int = state.free_printer_place(catalog)
		state.printers.append(OwnedPrinter.new(state.take_uid(), printer_id, place))
	return state


func take_uid() -> int:
	_next_uid += 1
	return _next_uid - 1


## Devuelve el uid de un mueble con lugar libre para una impresora, o
## OwnedPrinter.ON_FLOOR si no hay ninguno.
func free_printer_place(catalog: DataCatalog) -> int:
	var furniture_defs: Dictionary = DataLookup.by_id(catalog, "furniture")
	for item: OwnedFurniture in furniture:
		var slots: int = int(furniture_defs[item.furniture_id]["printer_slots"])
		var used: int = printers.filter(func(p: OwnedPrinter) -> bool: return p.furniture_uid == item.uid).size()
		if used < slots:
			return item.uid
	return OwnedPrinter.ON_FLOOR


func total_grams() -> int:
	var total: int = 0
	for spool: Spool in spools:
		total += spool.grams
	return total
