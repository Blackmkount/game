class_name OrderQueries
extends RefCounted
## Consultas de solo lectura sobre los pedidos, para la interfaz y para los
## motivos de error. Son cuentas con los enteros guardados en el estado y
## nunca lo cambian.


## Segundos de juego que faltan para terminar todas las piezas del trabajo.
## Es el tiempo nominal: nunca adelanta una falla que todavía no ocurre.
static func order_seconds_left(job: PrintJob, order: Order, now: int) -> int:
	var current_piece: int = maxi(0, job.piece_started_at + job.piece_seconds - now)
	return current_piece + (job.pieces_total - order.pieces_done - 1) * job.piece_seconds
