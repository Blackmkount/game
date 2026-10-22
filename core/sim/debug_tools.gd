class_name DebugTools
extends RefCounted
## Herramientas para las pruebas, las capturas y el futuro menú de depuración:
## fuerzan situaciones que el azar solo da a veces. Nunca usan el azar.


## Hace que la pieza en curso de la impresora falle con `failure_type` al
## llegar a `stop` de su avance, o en el próximo segundo si ese punto ya pasó.
## Devuelve false, sin cambiar nada, si la impresora no está imprimiendo o el
## tipo de fallo no existe.
static func force_fail(sim: Simulation, printer_uid: int, failure_type: String, stop: float = 0.35) -> bool:
	var printer: OwnedPrinter = sim.state.find_printer(printer_uid)
	if printer == null or printer.job == null or printer.job.status != PrintJob.Status.PRINTING:
		return false
	if not sim.rules.stop_ranges.has(failure_type):
		return false
	var job: PrintJob = printer.job
	var stop_seconds: int = clampi(roundi(job.piece_seconds * stop), 1, job.piece_seconds)
	job.fails = true
	job.failure_type = failure_type
	job.ends_at = maxi(sim.state.game_seconds + 1, job.piece_started_at + stop_seconds)
	job.lost_grams = clampi(ceili(job.grams_per_piece * stop), 1, job.grams_per_piece)
	sim.mark_dirty()
	return true
