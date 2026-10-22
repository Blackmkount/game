class_name ObjectiveProgress
extends RefCounted
## Avance de un objetivo de data/objectives.json según la partida, para
## mostrarlo ("(1/3)"). Por ahora solo cuentan los pedidos entregados: los
## demás tipos de objetivo y las recompensas llegan en la tarea 9 y dan 0.

const DELIVER_ORDERS: String = "deliver_orders"


## Pedidos entregados de ese tipo (`target`), o todos si `target` está vacío.
## No se limita a la meta: eso lo decide quien lo muestra.
static func progress(objective: Dictionary, state: GameState) -> int:
	if String(objective["type"]) != DELIVER_ORDERS:
		return 0
	var target: String = objective["target"]
	if target.is_empty():
		return state.delivered_total
	return int(state.delivered_by_order.get(target, 0))
