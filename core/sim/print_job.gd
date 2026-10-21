class_name PrintJob
extends RefCounted
## El trabajo de una impresora: las piezas de un pedido, una tras otra. Al
## empezar cada pieza ya se decide si falla y en qué punto (ends_at).

enum Status { PRINTING, FAILED, DONE }

var order_uid: int
var spool_uid: int
var mode_id: String
var color_id: String
var pieces_total: int
var grams_per_piece: int
var piece_seconds: int
## Segundo de juego en que empezó la pieza actual.
var piece_started_at: int
## Fin del intento actual (éxito o falla), decidido al empezar la pieza.
var ends_at: int = -1
var fails: bool = false
## "spaghetti", "warping" o "" si la pieza no falla.
var failure_type: String = ""
## Gramos que se pierden si la pieza falla.
var lost_grams: int = 0
var status: Status = Status.PRINTING


## Avance de la pieza actual entre 0 y 1. Mientras imprime es el avance
## nominal: nunca adelanta una falla que todavía no ocurre.
func progress_at(now: int) -> float:
	match status:
		Status.PRINTING:
			return clampf(float(now - piece_started_at) / float(piece_seconds), 0.0, 1.0)
		Status.FAILED:
			return float(ends_at - piece_started_at) / float(piece_seconds)
	return 1.0


## Porcentaje de la pieza en que se detuvo la falla.
func fail_percent() -> int:
	return roundi(float(ends_at - piece_started_at) * 100.0 / float(piece_seconds))
