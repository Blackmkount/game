class_name QuickActions
extends RefCounted
## Qué muestra y qué hace la burbuja de cercanía de un objeto (la que aparece
## al caminar cerca). Solo lo decide: no cambia la partida.
##
## La burbuja corre la acción sola únicamente cuando no hay nada que decidir:
## retirar las piezas listas, embalar, despachar o concentrarse. Imprimir,
## una falla y todo lo demás abren el panel del objeto.

## Acciones que puede correr la burbuja.
const REMOVE: String = "remove"
const PACK_ALL: String = "pack_all"
const DISPATCH_ALL: String = "dispatch_all"
const FOCUS: String = "focus"


## {"icon": nombre del icono, "action": "" (abre el panel) o una de las
## acciones de arriba}.
static func for_item(state: GameState, rules: SimRules, item: WorldInteractable) -> Dictionary:
	match item.kind:
		WorldInteractable.Kind.PRINTER:
			var printer: OwnedPrinter = state.find_printer(item.ref)
			if printer != null:
				match OrderQueries.printer_status(state, rules, printer):
					OrderQueries.PrinterStatus.DONE:
						return _quick("check", REMOVE)
					OrderQueries.PrinterStatus.FAILED:
						return _quick("warning", "")
		WorldInteractable.Kind.FURNITURE:
			if is_computer_desk(state, item.ref):
				var designing: Order = state.find_order(state.designing_uid)
				var focus: bool = designing != null and OrderQueries.focus_available(designing, rules)
				return _quick("design", FOCUS if focus else "")
		WorldInteractable.Kind.DISPATCH:
			if OrderQueries.count_stage(state, Order.Stage.TO_PACK) > 0:
				return _quick("box", PACK_ALL)
			if OrderQueries.count_stage(state, Order.Stage.PACKED) > 0:
				return _quick("truck", DISPATCH_ALL)
			return _quick("truck", "")
	return _quick(InteractBubble.icon_for(item), "")


## El mueble con ese uid es la mesa del computador (donde se modela).
static func is_computer_desk(state: GameState, furniture_uid: int) -> bool:
	for furniture: OwnedFurniture in state.furniture:
		if furniture.uid == furniture_uid:
			return furniture.furniture_id == DeskSheet.FURNITURE_ID
	return false


static func _quick(icon_name: String, action: String) -> Dictionary:
	return {"icon": icon_name, "action": action}
