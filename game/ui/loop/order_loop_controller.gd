class_name OrderLoopController
extends Node
## El ciclo de pedidos en la presentación: lleva los botones de las tarjetas
## de Pedidos a los comandos de Game y decide qué se ve después. Es hijo de
## WorldControls, que lo crea al armarse.
##
## - Aceptar, Rechazar, Concentrarse y Cancelar corren en el lugar: la
##   pantalla de Pedidos se refresca sola con las señales de Events.
## - Imprimir y Ver impresora cierran la pantalla y abren el panel de la
##   impresora, desde cualquier parte del cuarto (caminar nunca es obligatorio).
## - Retirar, Embalar y Despachar cierran la pantalla y corren el comando en
##   el cuadro siguiente, ya en la habitación, para que se vea lo que pasa en
##   el mundo y lo que se cobra.
## - Si un comando no se puede, el motivo aparece en un aviso rojo.
##
## Lo que falta del ciclo (los paneles para imprimir, retirar, embalar y
## despachar, el rincón de despacho y las burbujas que corren acciones) se
## suma aquí en el paso siguiente: run_sheet, run_quick y build_sheet.

var _controls: WorldControls


func _init(controls: WorldControls) -> void:
	_controls = controls


func _ready() -> void:
	_controls.hud.order_card_action.connect(run_card)


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
			_run_at_dispatch(Game.pack_order, uid)
		"dispatch":
			_run_at_dispatch(Game.dispatch_order, uid)
		_:
			push_error("Acción de tarjeta desconocida: " + verb)


## Cierra la pantalla y abre el panel de una impresora para imprimir el
## pedido: la de `printer_uid`, o la recomendada (PrintPlanner.recommend). Si
## ninguna lo puede tomar ahora, abre la primera que se probó.
func open_printer_for_order(order_uid: int, printer_uid: int = -1) -> void:
	var order: Order = Game.state.find_order(order_uid)
	if order == null:
		_report(CommandResult.fail("ERR_ORDER_GONE"))
		return
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order, printer_uid)
	if plan.printer_uid < 0:
		_report(plan.reason)
		return
	# Paso 12: aquí se elige el pedido en el panel (PrintChoice.order_uid),
	# para que la impresora muestre su plan.
	_open_in_world(WorldInteractable.Kind.PRINTER, plan.printer_uid)


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
	_open_in_world(WorldInteractable.Kind.PRINTER, printer.uid)


## Vuelve a la habitación y abre el panel de ese objeto.
func _open_in_world(kind: WorldInteractable.Kind, ref: int) -> void:
	_controls.hud.open_screen("home")
	var item: WorldInteractable = _controls.room.item_for(kind, ref)
	if item != null:
		_controls.open_sheet(item)


## Vuelve a la habitación y corre `command` con el uid del pedido en el cuadro
## siguiente, con la habitación ya a la vista.
func _run_at_dispatch(command: Callable, order_uid: int) -> void:
	_controls.hud.open_screen("home")
	# Paso 12: aquí se abre el panel del rincón de despacho
	# (room.dispatch_item), para que la cámara lo encuadre antes de que
	# aparezca la caja o salga el paquete.
	_run_command.call_deferred(command, order_uid)


func _run_command(command: Callable, order_uid: int) -> void:
	_report(command.call(order_uid))


## "Retirar" desde la tarjeta: retira las piezas de la impresora del pedido.
func _remove_order_pieces(order_uid: int) -> CommandResult:
	var order: Order = Game.state.find_order(order_uid)
	if order == null:
		return CommandResult.fail("ERR_ORDER_GONE")
	return Game.remove_pieces(order.printer_uid)


## Si el comando no se pudo, dice por qué en un aviso rojo.
func _report(result: CommandResult) -> void:
	if result.ok:
		return
	_controls.hud.feedback.toast(UiFormat.reason(result, Game.rules.game_seconds_per_real_second), UiPalette.BADGE)
