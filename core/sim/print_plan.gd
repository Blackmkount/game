class_name PrintPlan
extends RefCounted
## Los números de un plan de impresión, para mostrarlos antes de imprimir:
## tiempo, calidad, riesgo, material y ganancia. No se guarda en la partida.

## Se puede imprimir así. Si no, `reason` dice por qué.
var ok: bool = false
## Motivo por el que no se puede (el mismo del comando Imprimir); null si ok.
var reason: CommandResult = null
## uid del pedido; -1 en la estimación de un mensaje.
var order_uid: int = -1
var printer_uid: int = -1
var spool_uid: int = -1
var mode_id: String = ""
var material_id: String = ""
var color_id: String = ""
var quality: int = 0
var min_quality: int = 0
## Piezas que faltan imprimir.
var pieces: int = 0
var piece_seconds: int = 0
## Todas las piezas que faltan, una tras otra, sin fallas.
var total_seconds: int = 0
## Probabilidad de que falle cada pieza (espagueti más deformación).
var chance: float = 0.0
## Todas las piezas que faltan están en gracia: no pueden fallar.
var graced: bool = false
var grams_per_piece: int = 0
var grams_total: int = 0
## Gramos del carrete antes de apartar los del pedido.
var spool_grams: int = 0
var cost_cents: int = 0
var payment_cents: int = 0
var profit_cents: int = 0
var xp: int = 0
