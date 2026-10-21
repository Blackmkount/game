class_name FailureRules
extends RefCounted
## Fallos de impresión (GDD 5.7). Al empezar cada pieza se decide si va a
## fallar, de qué tipo y en qué punto, con exactamente dos números del azar de
## las impresoras. Después el avance del tiempo solo compara enteros.
##
## Solo usa sumas, restas, multiplicaciones y divisiones, que dan el mismo
## resultado en cualquier equipo.

const SPAGHETTI: String = "spaghetti"
const WARPING: String = "warping"


## Probabilidad de falla de cada pieza: x = espagueti, y = deformación
## (warping). Sale de la fiabilidad de la impresora en el taller, el material
## y el modo. La deformación baja con los accesorios (los de fábrica y los
## instalados) y con la carcasa cerrada. Si la suma pasa del máximo, las dos
## se reducen en la misma proporción.
static func chances(state: GameState, rules: SimRules, printer: OwnedPrinter, material_id: String, mode_id: String) -> Vector2:
	var reliability: float = WorkshopRules.printer_reliability(state, rules, printer)
	var base: float = (1.0 - reliability) * float(rules.materials[material_id]["failure_multiplier"]) \
			* float(rules.modes[mode_id]["failure_multiplier"])
	var weights: float = rules.weight_spaghetti + rules.weight_warping
	var spaghetti: float = base * rules.weight_spaghetti / weights
	var warping: float = base * rules.weight_warping / weights * _warping_multiplier(rules, printer)
	var total: float = spaghetti + warping
	if total > rules.max_chance:
		var factor: float = rules.max_chance / total
		spaghetti *= factor
		warping *= factor
	return Vector2(spaghetti, warping)


## Decide la pieza que empieza en el segundo `t` y lo anota en el trabajo.
## Siempre usa exactamente dos números de `rng`, aunque la pieza esté en
## gracia o no pueda fallar, para que el azar no dependa de lo que pasó antes:
## el primero decide si falla y de qué tipo; el segundo, en qué punto se
## detiene (dentro del rango de ese tipo).
static func roll_into(job: PrintJob, rng: RandomNumberGenerator, piece_chances: Vector2, graced: bool, rules: SimRules, t: int) -> void:
	var fail_roll: float = rng.randf()
	var stop_roll: float = rng.randf()
	var failure: String = ""
	if not graced:
		if fail_roll < piece_chances.x:
			failure = SPAGHETTI
		elif fail_roll < piece_chances.x + piece_chances.y:
			failure = WARPING
	job.piece_started_at = t
	job.fails = failure != ""
	job.failure_type = failure
	if failure == "":
		job.ends_at = t + job.piece_seconds
		job.lost_grams = 0
		return
	var stop_range: Vector2 = rules.stop_ranges[failure]
	var stop: float = lerpf(stop_range.x, stop_range.y, stop_roll)
	job.ends_at = t + clampi(roundi(job.piece_seconds * stop), 1, job.piece_seconds)
	job.lost_grams = clampi(ceili(job.grams_per_piece * stop), 1, job.grams_per_piece)


## Multiplica los efectos sobre la deformación: cada accesorio de fábrica, cada
## accesorio instalado y la carcasa cerrada.
static func _warping_multiplier(rules: SimRules, printer: OwnedPrinter) -> float:
	var definition: Dictionary = rules.printers[printer.printer_id]
	var multiplier: float = 1.0
	for accessory_id: String in definition["built_in_accessories"]:
		multiplier *= float(rules.accessories[accessory_id]["warping_multiplier"])
	for accessory_id: String in printer.accessories:
		multiplier *= float(rules.accessories[accessory_id]["warping_multiplier"])
	if definition["enclosed"]:
		multiplier *= rules.enclosed_warping_multiplier
	return multiplier
