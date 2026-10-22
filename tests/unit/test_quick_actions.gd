extends GutTest
## Qué muestra y qué hace la burbuja de cercanía de cada objeto
## (QuickActions): corre la acción sola solo cuando no hay nada que decidir.

var _rules: SimRules
var _sim: Simulation
var _state: GameState
var _commands: GameCommands


func before_each() -> void:
	_rules = SimRules.from_catalog(DataCatalog.load_from())
	# Las piezas salen bien salvo que se fuerce una falla.
	_rules.grace_pieces = 1000
	_sim = SimFixtures.new_sim(_rules)
	_state = _sim.state
	_commands = GameCommands.new(_sim)
	SimFixtures.quiet_board(_state)


func test_a_printer_runs_only_remove() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	var printer: WorldInteractable = _item(WorldInteractable.Kind.PRINTER, cubo.uid)
	assert_eq(_quick(printer), {"icon": "printer", "action": ""}, "Libre")
	var order: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.READY_TO_PRINT)
	assert_eq(OrderQueries.printer_status(_state, _rules, cubo), OrderQueries.PrinterStatus.IDLE_READY)
	assert_eq(_quick(printer), {"icon": "printer", "action": ""}, "Imprimir siempre abre el plan")
	var plan: PrintPlan = PrintPlanner.recommend(_state, _rules, order)
	assert_true(_commands.start_print(order.uid, cubo.uid, plan.spool_uid, plan.mode_id).ok)
	assert_eq(_quick(printer), {"icon": "printer", "action": ""}, "Imprimiendo")
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	assert_eq(cubo.job.status, PrintJob.Status.DONE)
	assert_eq(_quick(printer), {"icon": "check", "action": QuickActions.REMOVE}, "Retirar no tiene nada que decidir")


func test_a_failed_printer_always_opens_its_panel() -> void:
	var cubo: OwnedPrinter = _state.printers[0]
	SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTING)
	assert_true(DebugTools.force_fail(_sim, cubo.uid, FailureRules.SPAGHETTI))
	_sim.advance_game_seconds(cubo.job.ends_at - _state.game_seconds)
	assert_eq(cubo.job.status, PrintJob.Status.FAILED)
	assert_eq(_quick(_item(WorldInteractable.Kind.PRINTER, cubo.uid)), {"icon": "warning", "action": ""})


func test_the_desk_runs_focus_only_while_it_is_available() -> void:
	var desk: WorldInteractable = _item(WorldInteractable.Kind.FURNITURE, _state.furniture[0].uid)
	assert_eq(_quick(desk), {"icon": "design", "action": ""}, "Sin modelar")
	var order: Order = SimFixtures.accept(_sim, "maceta")
	assert_eq(order.stage, Order.Stage.DESIGNING)
	assert_eq(_quick(desk), {"icon": "design", "action": QuickActions.FOCUS})
	assert_true(_commands.focus_design(order.uid).ok)
	assert_eq(_quick(desk), {"icon": "design", "action": ""}, "Concentrarse se usa una vez")
	SimFixtures.accept(_sim, "llavero")
	SimFixtures.finish_designs(_sim)
	_rules.focus_multiplier = 1.0
	SimFixtures.accept(_sim, "llavero")
	assert_eq(_quick(desk), {"icon": "design", "action": ""}, "Apagado desde los datos")


func test_the_dispatch_corner_packs_first_then_dispatches() -> void:
	var corner: WorldInteractable = _item(WorldInteractable.Kind.DISPATCH, 0)
	assert_eq(_quick(corner), {"icon": "truck", "action": ""}, "Vacío")
	var packed: Order = SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	assert_eq(_quick(corner), {"icon": "truck", "action": QuickActions.DISPATCH_ALL})
	SimFixtures.order_at(_sim, "llavero", Order.Stage.TO_PACK)
	assert_eq(_quick(corner), {"icon": "box", "action": QuickActions.PACK_ALL}, "Embalar va primero")
	assert_true(_commands.dispatch_order(packed.uid).ok)
	assert_eq(_quick(corner), {"icon": "box", "action": QuickActions.PACK_ALL})


func test_other_objects_keep_their_icon_and_open_their_panel() -> void:
	var table: OwnedFurniture = OwnedFurniture.new(_state.take_uid(), "mesa_trabajo", 1)
	_state.furniture.append(table)
	assert_eq(_quick(_item(WorldInteractable.Kind.FURNITURE, table.uid)), {"icon": "wrench", "action": ""})
	assert_eq(_quick(_item(WorldInteractable.Kind.DOOR, 0)), {"icon": "map", "action": ""})
	assert_eq(_quick(_item(WorldInteractable.Kind.SLOT, 2)), {"icon": "box", "action": ""})


func test_asking_changes_nothing() -> void:
	SimFixtures.order_at(_sim, "llavero", Order.Stage.PACKED)
	SimFixtures.order_at(_sim, "llavero", Order.Stage.PRINTED)
	var before: String = JSON.stringify(SaveCodec.encode(_state), "", true)
	for item: WorldInteractable in [_item(WorldInteractable.Kind.PRINTER, _state.printers[0].uid), _item(WorldInteractable.Kind.DISPATCH, 0)]:
		_quick(item)
	assert_eq(JSON.stringify(SaveCodec.encode(_state), "", true), before)


func _quick(item: WorldInteractable) -> Dictionary:
	return QuickActions.for_item(_state, _rules, item)


func _item(kind: WorldInteractable.Kind, ref: int) -> WorldInteractable:
	return WorldInteractable.new(kind, ref, AABB(Vector3.ZERO, Vector3.ONE))
