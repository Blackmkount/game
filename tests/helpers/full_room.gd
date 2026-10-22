extends RefCounted
## El cuarto más cargado que se puede armar hoy, para medir y fotografiar el
## peor caso: lo de la partida nueva (escritorio e impresora del piso) más una
## estantería metálica en cada lugar libre, con una impresora en cada uno de
## sus lugares, recorriendo en orden todas las familias del catálogo.
##
## Lo usan la prueba de presupuesto y las capturas 37 y 38, para que midan y
## muestren el mismo cuarto. Sin class_name: se carga con preload.

const RACK_ID: String = "estanteria_metalica"


## Agrega las estanterías y las impresoras a `state` (una partida nueva).
static func fill(state: GameState, rules: SimRules) -> void:
	var families: Array[String] = []
	for printer: Dictionary in rules.catalog.files["printers"]:
		families.append(String(printer["id"]))
	var used: Array[int] = []
	for item: OwnedFurniture in state.furniture:
		used.append(item.slot)
	var per_rack: int = int(rules.furniture[RACK_ID]["printer_slots"])
	var next: int = 0
	for slot: int in RoomLayout.for_space(state.space_id).slots.size():
		if slot in used:
			continue
		var rack: OwnedFurniture = OwnedFurniture.new(state.take_uid(), RACK_ID, slot)
		state.furniture.append(rack)
		for i: int in per_rack:
			state.printers.append(OwnedPrinter.new(state.take_uid(), families[next % families.size()], rack.uid))
			next += 1
