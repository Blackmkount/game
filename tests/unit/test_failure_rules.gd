extends GutTest
## Fallos de impresión (GDD 5.7): la probabilidad de cada pieza y la tirada
## de dos números que decide, al empezar la pieza, si falla y dónde.

const START: int = 50000

var _rules: SimRules
var _state: GameState


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	_state = GameState.new_game(_rules, 1234)


# --- Probabilidades --------------------------------------------------------


func test_reference_chances_on_the_floor() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	assert_true(cubo.is_on_floor())
	var normal: Vector2 = FailureRules.chances(_state, _rules, cubo, "pla", "normal")
	assert_almost_eq(normal.x, 0.10, 0.0001, "Mitad espagueti")
	assert_almost_eq(normal.y, 0.10, 0.0001, "Mitad deformación")
	_assert_total(cubo, "pla", "normal", 0.20)
	_assert_total(cubo, "pla", "fine", 0.16)
	_assert_total(cubo, "pla", "draft", 0.26)
	_assert_total(cubo, "petg", "normal", 0.23)


func test_a_table_removes_the_floor_penalty() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	cubo.furniture_uid = _add_furniture("mesa_auxiliar")
	_assert_total(cubo, "pla", "normal", 0.15)


func test_rayo_x1_on_a_table_with_petg() -> void:
	var rayo: OwnedPrinter = OwnedPrinter.new(_state.take_uid(), "rayo_x1", _add_furniture("mesa_trabajo"))
	_state.printers.append(rayo)
	var chances: Vector2 = FailureRules.chances(_state, _rules, rayo, "petg", "normal")
	assert_almost_eq(chances.x, 0.046, 0.0001)
	assert_almost_eq(chances.y, 0.023, 0.0001, "La lámina PEI de fábrica reduce a la mitad la deformación")
	_assert_total(rayo, "petg", "normal", 0.069)


func test_pei_and_enclosure_only_lower_warping() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	cubo.accessories.append("pei_sheet")
	var with_pei: Vector2 = FailureRules.chances(_state, _rules, cubo, "pla", "normal")
	assert_almost_eq(with_pei.x, 0.10, 0.0001, "El espagueti no cambia")
	assert_almost_eq(with_pei.y, 0.05, 0.0001, "Lámina PEI instalada")
	var boveda: OwnedPrinter = OwnedPrinter.new(_state.take_uid(), "boveda_p1", _add_furniture("mesa_trabajo"))
	var closed: Vector2 = FailureRules.chances(_state, _rules, boveda, "pla", "normal")
	assert_almost_eq(closed.x, 0.03, 0.0001)
	assert_almost_eq(closed.y, 0.03 * 0.5 * 0.5, 0.0001, "PEI de fábrica y carcasa cerrada")


func test_chances_are_capped_at_max_chance() -> void:
	_rules.max_chance = 0.1
	var cubo: OwnedPrinter = _state.printers[0]
	cubo.accessories.append("pei_sheet")
	var capped: Vector2 = FailureRules.chances(_state, _rules, cubo, "pla", "draft")
	assert_almost_eq(capped.x + capped.y, 0.1, 0.0001, "0,13 + 0,065 baja al máximo")
	assert_almost_eq(capped.x, 2.0 * capped.y, 0.0001, "Las dos bajan en la misma proporción")
	_rules.max_chance = 0.9
	_assert_total(cubo, "pla", "draft", 0.195)


# --- La tirada de cada pieza -----------------------------------------------


func test_every_roll_uses_exactly_two_numbers() -> void:
	var cases: Array[Dictionary] = [
		{"chances": Vector2(0.1, 0.1), "graced": false},
		{"chances": Vector2(0.1, 0.1), "graced": true},
		{"chances": Vector2.ZERO, "graced": false},
		{"chances": Vector2(1.0, 1.0), "graced": false},
	]
	for entry: Dictionary in cases:
		var twin: RandomNumberGenerator = _twin(_state.prints_rng)
		FailureRules.roll_into(_job(2700, 20), _state.prints_rng, entry["chances"], entry["graced"], _rules, START)
		twin.randf()
		twin.randf()
		assert_eq(_state.prints_rng.state, twin.state, "Caso %s" % entry)


func test_first_number_picks_the_failure_and_second_the_stop() -> void:
	var twin: RandomNumberGenerator = _twin(_state.prints_rng)
	var fail_roll: float = twin.randf()
	var stop_roll: float = twin.randf()
	var job: PrintJob = _job(2700, 20)
	FailureRules.roll_into(job, _state.prints_rng, Vector2(fail_roll + 0.001, 0.0), false, _rules, START)
	assert_true(job.fails)
	assert_eq(job.failure_type, "spaghetti")
	var stop_range: Vector2 = _rules.stop_ranges["spaghetti"]
	var stop: float = lerpf(stop_range.x, stop_range.y, stop_roll)
	assert_eq(job.piece_started_at, START)
	assert_eq(job.ends_at, START + roundi(2700 * stop))
	assert_eq(job.lost_grams, ceili(20 * stop))


func test_after_the_spaghetti_chance_comes_warping() -> void:
	var job: PrintJob = _job(2700, 20)
	FailureRules.roll_into(job, _state.prints_rng, Vector2(0.0, 1.0), false, _rules, START)
	assert_true(job.fails)
	assert_eq(job.failure_type, "warping")


func test_a_successful_piece_clears_the_previous_failure() -> void:
	var job: PrintJob = _job(2700, 20)
	job.fails = true
	job.failure_type = "warping"
	job.ends_at = 10
	job.lost_grams = 5
	FailureRules.roll_into(job, _state.prints_rng, Vector2.ZERO, false, _rules, START)
	assert_false(job.fails)
	assert_eq(job.failure_type, "")
	assert_eq(job.piece_started_at, START)
	assert_eq(job.ends_at, START + 2700)
	assert_eq(job.lost_grams, 0)


func test_grace_forces_success_even_on_a_sure_failure() -> void:
	# Con probabilidad 1 + 1, cualquier primer número (incluso 0) es una falla.
	var job: PrintJob = _job(2700, 20)
	FailureRules.roll_into(job, _state.prints_rng, Vector2(1.0, 1.0), false, _rules, START)
	assert_true(job.fails, "Sin gracia falla")
	FailureRules.roll_into(job, _state.prints_rng, Vector2(1.0, 1.0), true, _rules, START)
	assert_false(job.fails, "Don Ernesto la dejó recién calibrada")
	assert_eq(job.ends_at, START + 2700)
	assert_eq(job.lost_grams, 0)


func test_stops_stay_inside_their_ranges() -> void:
	var cases: Dictionary[String, Vector2] = {"spaghetti": Vector2(1.0, 0.0), "warping": Vector2(0.0, 1.0)}
	for failure: String in cases:
		var stop_range: Vector2 = _rules.stop_ranges[failure]
		var earliest: int = START + 2700
		var latest: int = START
		for i: int in 300:
			var job: PrintJob = _job(2700, 20)
			FailureRules.roll_into(job, _state.prints_rng, cases[failure], false, _rules, START)
			assert_eq(job.failure_type, failure)
			earliest = mini(earliest, job.ends_at)
			latest = maxi(latest, job.ends_at)
			assert_between(job.lost_grams, ceili(20 * stop_range.x), ceili(20 * stop_range.y), failure)
		assert_between(earliest, START + roundi(2700 * stop_range.x), START + roundi(2700 * stop_range.y), failure)
		assert_between(latest, START + roundi(2700 * stop_range.x), START + roundi(2700 * stop_range.y), failure)
		var width: float = 2700 * (stop_range.y - stop_range.x)
		assert_gt(latest - earliest, roundi(width * 0.8), "Los puntos de falla cubren el rango de %s" % failure)


func test_end_time_and_lost_grams_are_clamped() -> void:
	_rules.stop_ranges["spaghetti"] = Vector2.ZERO
	var early: PrintJob = _job(2700, 20)
	FailureRules.roll_into(early, _state.prints_rng, Vector2(1.0, 0.0), false, _rules, START)
	assert_eq(early.ends_at, START + 1, "Nunca falla en el mismo segundo en que empieza")
	assert_eq(early.lost_grams, 1, "Siempre se pierde al menos 1 g")
	_rules.stop_ranges["spaghetti"] = Vector2(1.5, 1.5)
	var late: PrintJob = _job(2700, 20)
	FailureRules.roll_into(late, _state.prints_rng, Vector2(1.0, 0.0), false, _rules, START)
	assert_eq(late.ends_at, START + 2700, "Nunca después del fin de la pieza")
	assert_eq(late.lost_grams, 20, "Nunca más que los gramos de la pieza")


# --- Ayudantes -------------------------------------------------------------


func _assert_total(printer: OwnedPrinter, material_id: String, mode_id: String, expected: float) -> void:
	var chances: Vector2 = FailureRules.chances(_state, _rules, printer, material_id, mode_id)
	assert_almost_eq(chances.x + chances.y, expected, 0.0001, "%s, %s, %s" % [printer.printer_id, material_id, mode_id])


func _add_furniture(furniture_id: String) -> int:
	var item: OwnedFurniture = OwnedFurniture.new(_state.take_uid(), furniture_id, _state.furniture.size())
	_state.furniture.append(item)
	return item.uid


func _job(piece_seconds: int, grams_per_piece: int) -> PrintJob:
	var job: PrintJob = PrintJob.new()
	job.pieces_total = 1
	job.piece_seconds = piece_seconds
	job.grams_per_piece = grams_per_piece
	return job


func _twin(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	var twin: RandomNumberGenerator = RandomNumberGenerator.new()
	twin.seed = rng.seed
	twin.state = rng.state
	return twin
