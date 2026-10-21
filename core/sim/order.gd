class_name Order
extends RefCounted
## Un pedido aceptado, desde que se modela hasta que se despacha.

enum Stage { WAITING_DESIGN, DESIGNING, READY_TO_PRINT, PRINTING, PRINTED, TO_PACK, PACKED }

## Es el uid del mensaje aceptado, para que la interfaz siga la misma tarjeta.
var uid: int
## Id del pedido en data/orders.json.
var order_id: String
var stage: Stage = Stage.WAITING_DESIGN
## Segundo de juego en que se aceptó.
var accepted_at: int
## Plazo en live_seconds; -1 = sin plazo.
var due_live: int = -1
## Segundo de juego en que termina el modelado; -1 si no se está modelando.
var design_ends_at: int = -1
## Ya se usó "Concentrarse" (una vez por pedido).
var focused: bool = false
## Piezas terminadas. Vive en el pedido: limpiar la impresora no lo borra.
var pieces_done: int = 0
## Impresora que lo imprime o lo guarda; -1 = ninguna.
var printer_uid: int = -1
## Color de las piezas; se fija al retirarlas (el color del carrete).
var color_id: String = ""


func _init(p_uid: int = 0, p_order_id: String = "", p_accepted_at: int = 0) -> void:
	uid = p_uid
	order_id = p_order_id
	accepted_at = p_accepted_at
