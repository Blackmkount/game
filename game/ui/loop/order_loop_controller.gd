class_name OrderLoopController
extends Node
## El ciclo de pedidos en la presentación: lleva los botones de los paneles
## del mundo, de las tarjetas de Pedidos y de la burbuja de cercanía a los
## comandos de Game, y decide qué se ve después. Es hijo de WorldControls, que
## lo crea al armarse.
##
## Paneles del mundo (run_sheet):
## - Imprimir, Limpiar, Limpiar y reintentar, Concentrarse, Embalar y
##   Despachar refrescan el panel en el lugar.
## - Retirar sigue en la impresora si ya puede imprimir otro modelo listo (el
##   panel pasa al plan, con "Ir a embalar"); si no, abre el rincón de
##   despacho, donde aparece la caja.
## - Las opciones (modo, carrete, pedido) cambian lo elegido (PrintChoice).
## - Si un comando no se puede, el panel se vuelve a armar con el motivo en
##   rojo arriba (y el personaje se encoge de hombros).
##
## Tarjetas de Pedidos (run_card):
## - Aceptar, Rechazar, Concentrarse y Cancelar corren en el lugar.
## - Imprimir y Ver impresora cierran la pantalla y abren el panel de la
##   impresora, desde cualquier parte del cuarto (caminar nunca es obligatorio).
## - Retirar, Embalar y Despachar cierran la pantalla, abren el rincón de
##   despacho y corren el comando en el cuadro siguiente, para que se vea lo
##   que pasa en el mundo y lo que se cobra.
## - Si un comando no se puede, el motivo aparece en un aviso rojo.
##
## Ferretería (run_local_store), desde Pedidos o Inventario: compra en el
## lugar; la pantalla se refresca con las señales. Si no se puede, el motivo
## aparece en un aviso rojo.
##
## Burbuja de cercanía (run_quick): corre la acción sin abrir panel cuando no
## hay nada que decidir (QuickActions); si no se puede, el personaje dice por
## qué y se encoge de hombros.
##
## Al embalar o despachar con el personaje cerca del rincón de despacho, hace
## el gesto de embalar (biblia de arte §7.8; nunca hace falta caminar).
##
## El panel abierto se refresca solo con las señales de Events (al final del
## cuadro, una vez, y nunca dentro del botón que se tocó). Con el reloj solo
## cambian en el lugar las barras de avance y las cuentas regresivas; el
## rincón de despacho se rearma, además, cuando vence un plazo (no hay señal
## para eso y cambia lo que se cobra).

var _controls: WorldControls
## Lo elegido en el panel de la impresora abierta.
var _choice: PrintChoice = PrintChoice.new()
## Objeto al que pertenece lo elegido: si cambia, se empieza de nuevo.
var _choice_item: WorldInteractable = null
## Por qué no se pudo lo último que se intentó en el panel ("" = nada).
var _error: String = ""
var _refresh_queued: bool = false
## Panel para abrir al final del cuadro en lugar de refrescar el actual.
var _open_next: WorldInteractable = null
## Pedidos atrasados que muestra el panel del rincón de despacho armado.
var _late_shown: int = 0


func _init(controls: WorldControls) -> void:
	_controls = controls


func _ready() -> void:
	_controls.hud.order_card_action.connect(run_card)
	_controls.hud.sheet_command.connect(run_sheet)
	_controls.hud.local_store_requested.connect(run_local_store)
	Events.printer_changed.connect(_queue_refresh.unbind(1))
	Events.computer_changed.connect(_queue_refresh)
	Events.order_changed.connect(_queue_refresh.unbind(1))
	Events.order_removed.connect(_queue_refresh.unbind(1))
	Events.offers_changed.connect(_queue_refresh)
	Events.spools_changed.connect(_queue_refresh)
	Events.game_loaded.connect(_queue_refresh)
	Events.clock_ticked.connect(_on_clock_ticked)


## Panel de un objeto del mundo, con lo elegido y el último error. Lo elegido
## se olvida cuando cambia el objeto.
func build_sheet(item: WorldInteractable) -> BottomSheet:
	if item != _choice_item:
		_choice_item = item
		_choice = PrintChoice.new(item.ref if item.kind == WorldInteractable.Kind.PRINTER else -1)
		_error = ""
	var error: String = _error
	_error = ""
	if item.kind == WorldInteractable.Kind.DISPATCH:
		_late_shown = DispatchSheet.late_count(Game.state)
	return WorldSheets.build(item, _choice, error)


## Botón de un panel del mundo que no abre una sección (Hud.sheet_command).
func run_sheet(action_id: String) -> void:
	var item: WorldInteractable = _controls.sheet_item
	if Game.state == null or item == null:
		return
	match action_id:
		"print":
			_choice.normalize(Game.state, Game.rules)
			_after(Game.start_print(_choice.order_uid, _choice.printer_uid, _choice.spool_uid, _choice.mode_id), true)
		"retry":
			var printer: OwnedPrinter = Game.state.find_printer(item.ref)
			var mode_id: String = PrinterSheet.retry_mode(Game.rules, printer, _choice)
			_after(Game.retry_piece(item.ref, mode_id), true)
		"clean":
			_after(Game.clean_printer(item.ref), true)
		"remove":
			var result: CommandResult = Game.remove_pieces(item.ref)
			_after(result)
			if result.ok:
				_chain_after_remove(item)
		"focus":
			_after(Game.focus_design(Game.state.designing_uid))
		"pack":
			_after(_packed(Game.pack_all()))
		"dispatch":
			_after(_packed(Game.dispatch_all()))
		"go_pack":
			_open_later(_controls.room.dispatch_item)
		DeskSheet.PRINT_READY:
			var order: Order = DeskSheet.print_target(Game.state, Game.rules)
			if order != null:
				_open_printer_later(order.uid)
		_:
			_choose(action_id)


## Botón de una tarjeta de Pedidos (ver OrdersScreen.card_action).
func run_card(verb: String, uid: int) -> void:
	if Game.state == null:
		return
	match verb:
		"accept":
			_report(Game.accept_offer(uid))
		"reject":
			_report(Game.reject_offer(uid))
		"focus":
			_report(Game.focus_design(uid))
		"cancel":
			_report(Game.cancel_order(uid))
		"print":
			open_printer_for_order(uid)
		"see_printer":
			_see_printer(uid)
		"remove":
			_run_at_dispatch(_remove_order_pieces, uid)
		"pack":
			_run_at_dispatch(func(order_uid: int) -> CommandResult: return _packed(Game.pack_order(order_uid)), uid)
		"dispatch":
			_run_at_dispatch(func(order_uid: int) -> CommandResult: return _packed(Game.dispatch_order(order_uid)), uid)
		_:
			push_error("Acción de tarjeta desconocida: " + verb)


## Botón de la ferretería (Hud.local_store_requested): compra un carrete.
func run_local_store(material_id: String) -> void:
	if Game.state == null:
		return
	_report(Game.buy_local_material(material_id))


## Burbuja de cercanía de `item`: corre su acción si no hay nada que decidir
## (QuickActions). Devuelve false si no tiene acción (entonces se abre su
## panel). Si la acción no se puede, el personaje dice por qué.
func run_quick(item: WorldInteractable) -> bool:
	if item == null or Game.state == null:
		return false
	var result: CommandResult = null
	match QuickActions.for_item(Game.state, Game.rules, item)["action"]:
		QuickActions.REMOVE:
			result = Game.remove_pieces(item.ref)
		QuickActions.PACK_ALL:
			result = _packed(Game.pack_all())
		QuickActions.DISPATCH_ALL:
			result = _packed(Game.dispatch_all())
		QuickActions.FOCUS:
			result = Game.focus_design(Game.state.designing_uid)
		_:
			return false
	if not result.ok:
		_controls.loop_feedback.say(UiFormat.reason(result, Game.rules.game_seconds_per_real_second))
		_controls.room.character.animator.react(CharacterAnimator.Reaction.ACTION_FAILED)
	return true


## Cierra la pantalla y abre el panel de una impresora con el pedido elegido
## para imprimir: la de `printer_uid`, o la recomendada
## (PrintPlanner.recommend). Si ninguna lo puede tomar ahora, abre la primera
## que se probó, que dice por qué.
func open_printer_for_order(order_uid: int, printer_uid: int = -1) -> void:
	var item: WorldInteractable = _printer_item_for(order_uid, printer_uid)
	if item != null:
		_open_in_world(item)


## Lo elige para la impresora que corresponde y devuelve su objeto del mundo,
## o null (con el motivo en un aviso).
func _printer_item_for(order_uid: int, printer_uid: int) -> WorldInteractable:
	var order: Order = Game.state.find_order(order_uid)
	if order == null:
		_report(CommandResult.fail("ERR_ORDER_GONE"))
		return null
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order, printer_uid)
	if plan.printer_uid < 0:
		_report(plan.reason)
		return null
	var item: WorldInteractable = _controls.room.item_for(WorldInteractable.Kind.PRINTER, plan.printer_uid)
	if item != null:
		_choice_item = item
		_choice = PrintChoice.new(plan.printer_uid, order_uid)
	return item


## "Ver impresora": la que tiene la pieza que falló.
func _see_printer(order_uid: int) -> void:
	var order: Order = Game.state.find_order(order_uid)
	if order == null:
		_report(CommandResult.fail("ERR_ORDER_GONE"))
		return
	var printer: OwnedPrinter = OrderQueries.printer_for_order(Game.state, order)
	if printer == null:
		_report(CommandResult.fail("ERR_PRINTER_GONE"))
		return
	var item: WorldInteractable = _controls.room.item_for(WorldInteractable.Kind.PRINTER, printer.uid)
	if item != null:
		_open_in_world(item)


## Vuelve a la habitación y abre el panel de ese objeto.
func _open_in_world(item: WorldInteractable) -> void:
	_controls.hud.open_screen("home")
	_controls.open_sheet(item)


## Vuelve a la habitación, abre el rincón de despacho (la cámara lo encuadra)
## y corre `command` con el uid del pedido en el cuadro siguiente, con el
## rincón ya a la vista.
func _run_at_dispatch(command: Callable, order_uid: int) -> void:
	_open_in_world(_controls.room.dispatch_item)
	_run_command.call_deferred(command, order_uid)


func _run_command(command: Callable, order_uid: int) -> void:
	_report(command.call(order_uid))


## "Retirar" desde la tarjeta: retira las piezas de la impresora del pedido.
func _remove_order_pieces(order_uid: int) -> CommandResult:
	var order: Order = Game.state.find_order(order_uid)
	if order == null:
		return CommandResult.fail("ERR_ORDER_GONE")
	return Game.remove_pieces(order.printer_uid)


## Después de embalar o despachar: si se pudo y el personaje está cerca del
## rincón, hace el gesto de embalar. Devuelve el mismo resultado.
func _packed(result: CommandResult) -> CommandResult:
	var room: RoomView = _controls.room
	if result.ok and room.character_near(room.dispatch_item):
		room.character.animator.react(CharacterAnimator.Reaction.PACKED)
	return result


## Si el comando de una tarjeta no se pudo, dice por qué en un aviso rojo.
func _report(result: CommandResult) -> void:
	if result.ok:
		return
	_controls.hud.feedback.toast(UiFormat.reason(result, Game.rules.game_seconds_per_real_second), UiPalette.BADGE)


## Después de un comando de un panel. Si se pudo, el panel se refresca con las
## señales de Events (y, si `fresh_choice`, lo elegido vuelve a lo
## recomendado). Si no, se vuelve a armar con el motivo en rojo.
func _after(result: CommandResult, fresh_choice: bool = false) -> void:
	if not result.ok:
		_error = UiFormat.reason(result, Game.rules.game_seconds_per_real_second)
		_queue_refresh()
		_controls.room.character.animator.react(CharacterAnimator.Reaction.ACTION_FAILED)
	elif fresh_choice:
		_choice = PrintChoice.new(_choice.printer_uid)


## Retirar desde el panel de la impresora: si ya puede imprimir otro modelo
## listo, se queda (el panel pasa al plan, con "Ir a embalar"); si no, va al
## rincón de despacho.
func _chain_after_remove(item: WorldInteractable) -> void:
	var printer: OwnedPrinter = Game.state.find_printer(item.ref)
	if printer != null and OrderQueries.printer_status(Game.state, Game.rules, printer) == OrderQueries.PrinterStatus.IDLE_READY:
		return
	_open_later(_controls.room.dispatch_item)


## Una opción del panel ("mode_fine", "spool_3", "order_4"): cambia lo elegido
## y refresca.
func _choose(action_id: String) -> void:
	if action_id.begins_with("mode_"):
		_choice.mode_id = action_id.trim_prefix("mode_")
	elif action_id.begins_with("spool_"):
		_choice.spool_uid = action_id.trim_prefix("spool_").to_int()
	elif action_id.begins_with("order_"):
		# Otro pedido: su carrete y su modo recomendados.
		_choice = PrintChoice.new(_choice.printer_uid, action_id.trim_prefix("order_").to_int())
	else:
		push_error("Acción de panel desconocida: " + action_id)
		return
	_queue_refresh()


## Abre al final del cuadro la impresora para imprimir ese pedido.
func _open_printer_later(order_uid: int) -> void:
	var item: WorldInteractable = _printer_item_for(order_uid, -1)
	if item != null:
		_open_later(item)


## Abre el panel de `item` al final del cuadro (con animación: la cámara va
## hacia él), en lugar de refrescar el panel abierto.
func _open_later(item: WorldInteractable) -> void:
	_open_next = item
	_queue_refresh()


## Pide refrescar el panel abierto al final del cuadro: los avisos de un mismo
## cambio lo arman una sola vez, y nunca dentro del botón que se tocó.
func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh_now.call_deferred()


func _refresh_now() -> void:
	_refresh_queued = false
	if _wait_for_finger():
		return
	var target: WorldInteractable = _open_next
	_open_next = null
	if target != null:
		if _controls.hud.current_screen_id() == "home":
			_controls.open_sheet(target)
		return
	var item: WorldInteractable = _controls.sheet_item
	if item == null or not _controls.hud.has_sheet():
		_error = ""
		return
	var sheet: BottomSheet = build_sheet(item)
	if sheet == null:
		# Su objeto ya no está en la partida.
		_controls.hud.close_sheet()
		return
	_controls.hud.show_sheet(sheet, false)


## Si un dedo está sobre un botón del panel abierto, el panel no se rearma
## hasta que lo suelte: rearmarlo borraría el botón y el toque se perdería.
func _wait_for_finger() -> bool:
	var sheet: BottomSheet = _controls.hud.current_sheet()
	if sheet == null:
		return false
	var held: BaseButton = UiKit.held_button(sheet)
	if held == null:
		return false
	if not held.button_up.is_connected(_queue_refresh):
		held.button_up.connect(_queue_refresh, CONNECT_ONE_SHOT)
	return true


## Una vez por segundo real: las barras de avance del panel abierto. El
## rincón de despacho se rearma si un plazo venció (cambia lo que se cobra).
func _on_clock_ticked(game_seconds: int) -> void:
	var item: WorldInteractable = _controls.sheet_item
	if item == null or not _controls.hud.has_sheet() or Game.state == null:
		return
	if item.kind == WorldInteractable.Kind.PRINTER:
		PrinterSheet.tick(_controls.hud.current_sheet(), item.ref, game_seconds)
	elif item.kind == WorldInteractable.Kind.FURNITURE and QuickActions.is_computer_desk(Game.state, item.ref):
		DeskSheet.tick(_controls.hud.current_sheet(), game_seconds)
	elif item.kind == WorldInteractable.Kind.DISPATCH and DispatchSheet.late_count(Game.state) != _late_shown:
		_queue_refresh()
