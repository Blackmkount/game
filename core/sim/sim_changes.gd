class_name SimChanges
extends RefCounted
## Lo que cambió desde el último aviso. Los comandos y advance() lo llenan, y
## Game lo convierte en señales de Events y lo vacía.

## uids de impresoras, sin repetir, en orden de llegada.
var printers: Array[int] = []
## uids de impresoras cuya pieza falló.
var failures: Array[int] = []
var computer: bool = false
## uids de pedidos que cambiaron, sin repetir.
var orders: Array[int] = []
## uids de pedidos que ya no están (despachados o cancelados), sin repetir.
var removed_orders: Array[int] = []
var offers: bool = false
## uids de los mensajes que llegaron.
var arrived_offers: Array[int] = []
var spools: bool = false
var money: bool = false
var xp: bool = false
var deliveries: Array[Delivery] = []
## Nivel nuevo al que se subió; 0 = ninguno.
var level_up: int = 0


func add_printer(uid: int) -> void:
	if not printers.has(uid):
		printers.append(uid)


func add_order(uid: int) -> void:
	if not orders.has(uid):
		orders.append(uid)


func add_removed(uid: int) -> void:
	if not removed_orders.has(uid):
		removed_orders.append(uid)


func is_empty() -> bool:
	return printers.is_empty() and failures.is_empty() and not computer and orders.is_empty() \
		and removed_orders.is_empty() and not offers and arrived_offers.is_empty() and not spools \
		and not money and not xp and deliveries.is_empty() and level_up == 0


func clear() -> void:
	printers.clear()
	failures.clear()
	computer = false
	orders.clear()
	removed_orders.clear()
	offers = false
	arrived_offers.clear()
	spools = false
	money = false
	xp = false
	deliveries.clear()
	level_up = 0
