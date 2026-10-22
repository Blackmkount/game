class_name Delivery
extends RefCounted
## Registro de un pedido despachado.

var order_uid: int
## Id del pedido en data/orders.json.
var order_id: String
## Lo que se cobró, en centavos.
var cents: int
var xp: int
## Se despachó después del plazo (cobra menos y no da XP).
var late: bool
## Clave de texto del agradecimiento del cliente.
var thanks_key: String
## Segundo de juego del despacho.
var delivered_at: int


func _init(p_order_uid: int = 0, p_order_id: String = "", p_cents: int = 0, p_xp: int = 0, p_late: bool = false, p_thanks_key: String = "", p_delivered_at: int = 0) -> void:
	order_uid = p_order_uid
	order_id = p_order_id
	cents = p_cents
	xp = p_xp
	late = p_late
	thanks_key = p_thanks_key
	delivered_at = p_delivered_at
