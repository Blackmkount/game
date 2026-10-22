class_name OrderOffer
extends RefCounted
## Un mensaje de un cliente que todavía no se acepta ni se rechaza. No vence.

var uid: int
## Id del pedido en data/orders.json.
var order_id: String
## Segundo de juego en que llegó.
var arrived_at: int


func _init(p_uid: int = 0, p_order_id: String = "", p_arrived_at: int = 0) -> void:
	uid = p_uid
	order_id = p_order_id
	arrived_at = p_arrived_at
