extends GutTest
## Clases de valores de la simulación: avance de una pieza, resultado de un
## comando y acumulador de cambios.


func test_job_progress_is_nominal_while_printing() -> void:
	var job: PrintJob = _job()
	job.fails = true
	job.ends_at = 1350
	assert_eq(job.progress_at(1000), 0.0)
	assert_eq(job.progress_at(1600), 0.5, "Mientras imprime no adelanta la falla")
	assert_eq(job.progress_at(5000), 1.0)
	assert_eq(job.progress_at(500), 0.0)


func test_failed_job_stops_where_it_failed() -> void:
	var job: PrintJob = _job()
	job.status = PrintJob.Status.FAILED
	job.ends_at = 1420
	assert_almost_eq(job.progress_at(9999), 0.35, 0.0001)
	assert_eq(job.fail_percent(), 35)


func test_done_job_is_complete() -> void:
	var job: PrintJob = _job()
	job.status = PrintJob.Status.DONE
	assert_eq(job.progress_at(0), 1.0)


func test_command_result_success_and_failure() -> void:
	var ok: CommandResult = CommandResult.success()
	assert_true(ok.ok)
	assert_eq(ok.uid, -1)
	var failed: CommandResult = CommandResult.fail("ERR_PRINTER_BUSY", ["PRINTER_CUBO_UNO", CommandResult.seconds_arg(600)])
	assert_false(failed.ok)
	assert_eq(failed.reason, "ERR_PRINTER_BUSY")
	assert_eq(failed.args, ["PRINTER_CUBO_UNO", {"seconds": 600}])
	assert_eq(CommandResult.grams_arg(8), {"grams": 8})
	assert_eq(CommandResult.cents_arg(600), {"cents": 600})


func test_changes_keep_each_uid_once_in_order() -> void:
	var changes: SimChanges = SimChanges.new()
	assert_true(changes.is_empty())
	changes.add_printer(5)
	changes.add_printer(2)
	changes.add_printer(5)
	changes.add_order(7)
	changes.add_order(7)
	changes.add_removed(7)
	changes.add_removed(7)
	assert_eq(changes.printers, [5, 2] as Array[int])
	assert_eq(changes.orders, [7] as Array[int])
	assert_eq(changes.removed_orders, [7] as Array[int])
	assert_false(changes.is_empty())


func test_changes_clear_leaves_nothing() -> void:
	var changes: SimChanges = SimChanges.new()
	changes.add_printer(2)
	changes.failures.append(2)
	changes.computer = true
	changes.add_order(4)
	changes.add_removed(4)
	changes.offers = true
	changes.arrived_offers.append(9)
	changes.spools = true
	changes.money = true
	changes.xp = true
	changes.deliveries.append(Delivery.new(4, "llavero", 600, 5))
	changes.level_up = 2
	changes.clear()
	assert_true(changes.is_empty())


func test_each_change_alone_is_not_empty() -> void:
	var setters: Array[Callable] = [
		func(c: SimChanges) -> void: c.failures.append(1),
		func(c: SimChanges) -> void: c.computer = true,
		func(c: SimChanges) -> void: c.add_removed(1),
		func(c: SimChanges) -> void: c.offers = true,
		func(c: SimChanges) -> void: c.arrived_offers.append(1),
		func(c: SimChanges) -> void: c.spools = true,
		func(c: SimChanges) -> void: c.money = true,
		func(c: SimChanges) -> void: c.xp = true,
		func(c: SimChanges) -> void: c.deliveries.append(Delivery.new()),
		func(c: SimChanges) -> void: c.level_up = 2,
	]
	for setter: Callable in setters:
		var changes: SimChanges = SimChanges.new()
		setter.call(changes)
		assert_false(changes.is_empty())


func _job() -> PrintJob:
	var job: PrintJob = PrintJob.new()
	job.pieces_total = 1
	job.grams_per_piece = 8
	job.piece_seconds = 1200
	job.piece_started_at = 1000
	job.ends_at = 2200
	return job
