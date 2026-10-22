extends GutTest
## La pantalla de Pedidos sobre la escena principal:
## - la línea de arriba: cuenta regresiva, tablero lleno y nada que se pueda
##   hacer;
## - las tarjetas de mensajes (chat) y de pedidos en curso, con su paso, su
##   estado, su plazo y el botón del paso siguiente;
## - se refresca sola con las señales (al final del cuadro) y con el reloj
##   solo cambian las cuentas regresivas;
## - cancelar pide dos toques en 3 segundos;
## - los botones de las tarjetas llegan al ciclo de pedidos: en el lugar, o de
##   vuelta en la habitación con el panel de la impresora.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SEED: int = 1234
## uid que no existe en la partida.
const GONE_UID: int = 9000

var _main: Control
var _hud: Hud
var _controls: WorldControls
var _previous_locale: String
var _previous_processing: bool


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_hud = _main.get_node("Hud")
	_controls = _main.get_node("WorldControls")


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)
	Game.set_process(_previous_processing)


func test_the_header_counts_down_then_fills_then_says_nothing_is_makeable() -> void:
	var screen: OrdersScreen = _open_orders()
	assert_eq(_header(screen), "Llega un mensaje nuevo en 3 s", "El primer mensaje llega a los 2,5 s")
	Game.advance(3.0)
	await wait_process_frames(1)
	assert_eq(_header(screen), "Llega un mensaje nuevo en 1 min 7 s", "El segundo, 27 min de juego después")
	Game.advance(1.0)
	assert_eq(_header(screen), "Llega un mensaje nuevo en 1 min 6 s", "Cuenta hacia atrás con el reloj")
	# El tercer mensaje llena el tablero (3 lugares) y se deja de esperar.
	Game.advance(220.0)
	await wait_process_frames(1)
	assert_eq(Game.state.offers.size(), 3)
	assert_eq(_header(screen), "Responde un mensaje para recibir más.")
	# Sin material, la ferretería va primero aunque el tablero esté lleno:
	# rechazar mensajes no ayudaría.
	Game.state.spools[0].grams = 0
	Events.spools_changed.emit()
	await wait_process_frames(1)
	var none_makeable: String = "Ahora nadie te pide algo que puedas hacer. Revisa tu material."
	assert_eq(_header(screen), none_makeable, "Sin material, el aviso de la ferretería va primero")
	assert_true(screen.find_child("LocalStoreBox", true, false).visible, "Con los botones de la ferretería")
	_press(screen, "Reject_%d" % Game.state.offers[0].uid)
	await wait_process_frames(1)
	assert_eq(_header(screen), none_makeable)
	Game.advance(1.0)
	assert_eq(_header(screen), none_makeable, "Sin cuenta regresiva: no se promete un mensaje")
	var first_offer: int = Game.state.offers[0].uid
	assert_true(_button(screen, "Accept_%d" % first_offer).disabled)
	assert_eq(_label(screen, "AcceptNote_%d" % first_offer), "No tienes material para este pedido.")
	# Vuelve el material (por ejemplo, una compra): se rearma con su aviso.
	Game.state.spools[0].grams = 1000
	Events.spools_changed.emit()
	await wait_process_frames(1)
	assert_string_starts_with(_header(screen), "Llega un mensaje nuevo en ")
	assert_null(screen.find_child("AcceptNote_%d" % first_offer, true, false))


func test_the_first_message_reads_like_a_chat() -> void:
	Game.advance(3.0)
	var screen: OrdersScreen = _open_orders()
	var card: OfferCard = screen.content.find_child("Offer_4", true, false)
	assert_not_null(card)
	var texts: Array[String] = _texts(card)
	assert_has(_texts(screen.content), "Mensajes nuevos (1)")
	assert_has(texts, "Amigos y familia")
	assert_has(texts, "Día 1 · 08:01")
	assert_has(texts, "¿Me haces un llavero con mi nombre? Es para la mochila.")
	assert_has(texts, "Llavero con nombre")
	for chip: String in ["Tamaño S", "Calidad 1", "PLA", "1 pieza", "Sin plazo"]:
		assert_has(texts, chip)
	assert_has(texts, "Modelar 10 s · Imprimir 50 s")
	assert_has(texts, "$6 · +5 XP · Ganancia ≈ $5,86")
	var avatar: PanelContainer = card.find_child("Avatar", true, false)
	assert_eq((avatar.get_child(0) as TextureRect).modulate, ClientStyle.color("amigos"))
	assert_false(_button(card, "Accept_4").disabled)
	assert_false(_button(card, "Reject_4").disabled)
	assert_null(card.find_child("AcceptNote_4", true, false))
	assert_has(_texts(screen.content), "En curso (0 de 3)")
	assert_has(_texts(screen.content), "No tienes pedidos en curso.")
	var locked: int = 0
	for order_id: String in Game.rules.order_list:
		if int(Game.rules.orders[order_id]["min_level"]) > 1:
			locked += 1
	assert_has(_texts(screen.content), "Hay %d pedidos más que se desbloquean al subir de nivel." % locked)


func test_an_order_with_a_deadline_shows_it_and_says_when_material_is_missing() -> void:
	var uid: int = _add_offer("perilla")
	var screen: OrdersScreen = _open_orders()
	var card: OfferCard = screen.content.find_child("Offer_%d" % uid, true, false)
	var texts: Array[String] = _texts(card)
	assert_has(texts, "Perilla de lavadora")
	assert_has(texts, "Plazo: 3 días")
	assert_has(texts, "2 piezas")
	assert_eq((card.find_child("Avatar", true, false).get_child(0) as TextureRect).modulate, ClientStyle.color("vecinos"))
	assert_true(_button(card, "Accept_%d" % uid).disabled, "No hay PETG")
	assert_eq(_label(card, "AcceptNote_%d" % uid), "No tienes material para este pedido.")


func test_accepting_moves_the_card_to_in_progress_after_the_tap() -> void:
	Game.advance(3.0)
	var screen: OrdersScreen = _open_orders()
	var offer_card: OfferCard = screen.content.find_child("Offer_4", true, false)
	_press(screen, "Accept_4")
	assert_not_null(Game.state.find_order(4), "El comando corrió")
	assert_true(offer_card.is_inside_tree(), "No se rearma dentro del botón que se tocó")
	await wait_process_frames(1)
	assert_null(screen.content.find_child("Offer_4", true, false))
	assert_does_not_have(_texts(screen.content), "Mensajes nuevos (0)", "Sin mensajes no hay sección")
	assert_has(_texts(screen.content), "En curso (1 de 3)")
	var card: OrderCard = screen.content.find_child("Order_4", true, false)
	assert_not_null(card)
	var steps: StepTracker = card.find_child("Steps_4", true, false)
	assert_eq(steps.step, 2)
	assert_eq(_label(steps, "StepName"), "Paso 2 de 6: Modelar")
	assert_eq(_step_color(steps, 1), UiPalette.XP_FILL, "El mensaje ya está")
	assert_eq(_step_color(steps, 2), UiPalette.ACCENT, "Ahora se modela")
	assert_eq(_step_color(steps, 3), UiPalette.TEXT_MUTED)
	assert_eq(_label(card, "Status"), "Modelando en el computador · listo en 10 s")
	assert_eq(_button(card, "Next_4").text, "Concentrarse")


func test_the_clock_changes_only_countdowns_and_bars() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	var screen: OrdersScreen = _open_orders()
	var card: OrderCard = screen.content.find_child("Order_4", true, false)
	var bar: ProgressBar = card.find_child("Progress", true, false)
	var before: float = bar.value
	Game.advance(1.0)
	assert_eq(_label(card, "Status"), "Modelando en el computador · listo en 9 s")
	assert_gt(bar.value, before)
	await wait_process_frames(1)
	assert_same(screen.content.find_child("Order_4", true, false), card, "La tarjeta no se rearmó")


func test_focus_runs_in_place() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	var screen: OrdersScreen = _open_orders()
	_press(screen, "Next_4")
	assert_true(Game.state.find_order(4).focused)
	assert_eq(_hud.current_screen_id(), "orders", "Se queda en Pedidos")
	await wait_process_frames(1)
	var card: OrderCard = screen.content.find_child("Order_4", true, false)
	assert_null(card.find_child("Next_4", true, false), "Concentrarse se usa una vez")
	assert_eq(_label(card, "Status"), "Modelando en el computador · listo en 5 s")


func test_reject_removes_the_message_in_place() -> void:
	Game.advance(3.0)
	var screen: OrdersScreen = _open_orders()
	_press(screen, "Reject_4")
	assert_eq(Game.state.offers.size(), 0)
	await wait_process_frames(1)
	assert_null(screen.content.find_child("Offer_4", true, false))
	assert_eq(_hud.current_screen_id(), "orders")


func test_a_queued_order_says_when_it_starts() -> void:
	Game.advance(3.0)
	var second: int = _add_offer("llavero")
	assert_true(Game.accept_offer(4).ok)
	assert_true(Game.accept_offer(second).ok)
	var screen: OrdersScreen = _open_orders()
	var card: OrderCard = screen.content.find_child("Order_%d" % second, true, false)
	assert_eq(_label(card, "Status"), "En cola para modelar · empieza en 10 s")
	var queued: Button = _button(card, "Next_%d" % second)
	assert_eq(queued.text, "En cola para modelar")
	assert_true(queued.disabled)
	assert_eq(_label(card, "NextNote_%d" % second), "Empieza en 10 s")
	Game.advance(1.0)
	assert_eq(_label(card, "NextNote_%d" % second), "Empieza en 9 s")


func test_accept_is_disabled_with_a_note_at_three_active_orders() -> void:
	Game.advance(3.0)
	var uids: Array[int] = [4, _add_offer("llavero"), _add_offer("llavero")]
	for uid: int in uids:
		assert_true(Game.accept_offer(uid).ok)
	var fourth: int = _add_offer("llavero")
	var screen: OrdersScreen = _open_orders()
	assert_has(_texts(screen.content), "En curso (3 de 3)")
	assert_true(_button(screen, "Accept_%d" % fourth).disabled)
	assert_eq(_label(screen, "AcceptNote_%d" % fourth), "Tienes 3 pedidos en curso: termina uno antes.")
	assert_false(_button(screen, "Reject_%d" % fourth).disabled, "Rechazar siempre se puede")


func test_cancel_needs_two_taps_within_three_seconds() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	var screen: OrdersScreen = _open_orders()
	_press(screen, "Cancel_4")
	assert_eq(_button(screen, "Cancel_4").text, "¿Seguro? Toca otra vez")
	assert_not_null(Game.state.find_order(4), "Un toque no cancela")
	await wait_seconds(OrdersScreen.CANCEL_CONFIRM_SECONDS + 0.2)
	assert_eq(_button(screen, "Cancel_4").text, "Cancelar pedido", "Pasado el tiempo hay que empezar de nuevo")
	_press(screen, "Cancel_4")
	assert_not_null(Game.state.find_order(4))
	_press(screen, "Cancel_4")
	assert_null(Game.state.find_order(4), "El segundo toque cancela")
	await wait_process_frames(1)
	assert_null(screen.content.find_child("Order_4", true, false))
	assert_has(_texts(screen.content), "No tienes pedidos en curso.")


func test_the_cancel_confirmation_survives_a_rebuild() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	var screen: OrdersScreen = _open_orders()
	_press(screen, "Cancel_4")
	# Termina el modelado entre los dos toques: la tarjeta se rearma.
	Game.advance(10.0)
	await wait_process_frames(1)
	assert_eq(_label(screen, "Status"), "Modelo listo: falta imprimir")
	assert_eq(_button(screen, "Cancel_4").text, "¿Seguro? Toca otra vez")
	_press(screen, "Cancel_4")
	assert_null(Game.state.find_order(4))


func test_print_goes_to_the_recommended_printer() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	Game.advance(10.0)
	var screen: OrdersScreen = _open_orders()
	var card: OrderCard = screen.content.find_child("Order_4", true, false)
	assert_eq(_label(card, "Status"), "Modelo listo: falta imprimir")
	assert_eq(card.find_child("Steps_4", true, false).step, 3)
	var next: Button = _button(card, "Next_4")
	assert_eq(next.text, "Imprimir")
	assert_false(next.disabled)
	next.pressed.emit()
	assert_eq(_hud.current_screen_id(), "home", "Se cierra la pantalla")
	assert_true(_hud.has_sheet())
	assert_eq(_controls.sheet_item.kind, WorldInteractable.Kind.PRINTER)
	assert_eq(_controls.sheet_item.ref, Game.state.printers[0].uid)
	# La pantalla cerrada se borra al final del cuadro.
	await wait_process_frames(1)


func test_print_is_disabled_with_the_reason_while_the_printer_is_busy() -> void:
	Game.advance(3.0)
	var second: int = _add_offer("llavero")
	assert_true(Game.accept_offer(4).ok)
	assert_true(Game.accept_offer(second).ok)
	_advance_until(func() -> bool: return Game.state.find_order(4).stage == Order.Stage.READY_TO_PRINT)
	_start_recommended(4)
	_advance_until(func() -> bool: return Game.state.find_order(second).stage == Order.Stage.READY_TO_PRINT)
	var screen: OrdersScreen = _open_orders()
	var printing: OrderCard = screen.content.find_child("Order_4", true, false)
	assert_string_starts_with(_label(printing, "Status"), "Imprimiendo en la Cubo Uno · lista en ")
	assert_null(printing.find_child("Next_4", true, false), "Mientras imprime no hay nada que tocar")
	var card: OrderCard = screen.content.find_child("Order_%d" % second, true, false)
	assert_true(_button(card, "Next_%d" % second).disabled)
	var note: String = _label(card, "NextNote_%d" % second)
	assert_string_starts_with(note, "La Cubo Uno está ocupada: se libera en ")
	Game.advance(1.0)
	assert_ne(_label(card, "NextNote_%d" % second), note, "La espera cuenta hacia atrás")


func test_remove_pack_and_dispatch_run_back_in_the_room() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	_advance_until(func() -> bool: return Game.state.find_order(4).stage == Order.Stage.READY_TO_PRINT)
	_start_recommended(4)
	_advance_until(func() -> bool: return Game.state.find_order(4).stage == Order.Stage.PRINTED)
	var steps: Array[Dictionary] = [
		{"button": "Retirar pieza", "status": "Impreso: retíralo de la Cubo Uno", "step": 4, "after": Order.Stage.TO_PACK},
		{"button": "Embalar", "status": "En el rincón de despacho: embálalo", "step": 5, "after": Order.Stage.PACKED},
	]
	for expected: Dictionary in steps:
		var screen: OrdersScreen = _open_orders()
		var card: OrderCard = screen.content.find_child("Order_4", true, false)
		assert_eq(_label(card, "Status"), expected["status"])
		assert_eq(card.find_child("Steps_4", true, false).step, expected["step"])
		var stage: Order.Stage = Game.state.find_order(4).stage
		_press(card, "Next_4")
		assert_eq(_hud.current_screen_id(), "home", "Vuelve a la habitación")
		assert_eq(Game.state.find_order(4).stage, stage, "El comando corre en el cuadro siguiente")
		await wait_process_frames(1)
		assert_eq(Game.state.find_order(4).stage, expected["after"])
	var screen: OrdersScreen = _open_orders()
	assert_eq(_label(screen, "Status"), "Embalado: listo para despachar")
	assert_eq(_button(screen, "Next_4").text, "Despachar")
	_press(screen, "Next_4")
	await wait_process_frames(1)
	assert_null(Game.state.find_order(4))
	assert_eq(Game.state.money_cents, 25600)
	screen = _open_orders()
	var delivered: Array[String] = _texts(screen.content.find_child("Delivered_4", true, false))
	assert_has(_texts(screen.content), "Entregados")
	assert_has(delivered, "Llavero con nombre · $6 · +5 XP")
	assert_has(delivered, "Amigos y familia: «¡Quedó genial! Ya todos me preguntan dónde lo hice.»")


func test_a_failed_piece_sends_to_its_printer() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	_advance_until(func() -> bool: return Game.state.find_order(4).stage == Order.Stage.READY_TO_PRINT)
	var printer_uid: int = _start_recommended(4)
	assert_true(DebugTools.force_fail(Game.sim, printer_uid, FailureRules.SPAGHETTI))
	var printer: OwnedPrinter = Game.state.find_printer(printer_uid)
	_advance_until(func() -> bool: return printer.job.status == PrintJob.Status.FAILED)
	var screen: OrdersScreen = _open_orders()
	var card: OrderCard = screen.content.find_child("Order_4", true, false)
	assert_eq(_label(card, "Status"), "Falló la pieza 1 de 1 en la Cubo Uno")
	assert_null(card.find_child("Progress", true, false), "Sin barra: la pieza se detuvo")
	var next: Button = _button(card, "Next_4")
	assert_eq(next.text, "Ver impresora")
	next.pressed.emit()
	assert_eq(_hud.current_screen_id(), "home")
	assert_eq(_controls.sheet_item.kind, WorldInteractable.Kind.PRINTER)
	assert_eq(_controls.sheet_item.ref, printer_uid)
	await wait_process_frames(1)


func test_the_deadline_turns_red_when_late() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(4).ok)
	var order: Order = Game.state.find_order(4)
	# Un plazo de 2 s reales, armado a mano (el llavero no tiene plazo).
	order.due_live = Game.state.live_seconds + 2 * Game.rules.game_seconds_per_real_second
	var screen: OrdersScreen = _open_orders()
	var deadline: Label = screen.content.find_child("Deadline", true, false)
	assert_eq(deadline.text, "Entregar antes del Día 1 · 08:02")
	Game.advance(3.0)
	assert_eq(deadline.text, "Atrasado: cobras la mitad y sin XP")
	assert_eq(deadline.get_theme_color("font_color"), UiPalette.BADGE)


func test_a_command_that_fails_says_why() -> void:
	_controls.loop.run_card("accept", GONE_UID)
	var toast: Control = _hud.feedback.get_node("Toast")
	assert_true(toast.visible)
	assert_has(_texts(toast), "Ese mensaje ya no está.")


func _open_orders() -> OrdersScreen:
	_hud.open_screen("orders")
	return _hud.get_node("ScreenHost/Screen")


## Agrega un mensaje armado a mano y avisa, como cuando llega uno.
func _add_offer(order_id: String) -> int:
	var offer: OrderOffer = OrderOffer.new(Game.state.take_uid(), order_id, Game.state.game_seconds)
	Game.state.offers.append(offer)
	Events.offers_changed.emit()
	return offer.uid


## Imprime el pedido con el plan recomendado. Devuelve la impresora.
func _start_recommended(order_uid: int) -> int:
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, Game.state.find_order(order_uid))
	assert_true(Game.start_print(order_uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	return plan.printer_uid


## Avanza de a un segundo real hasta que se cumpla `condition`, con un límite
## para no quedar esperando para siempre.
func _advance_until(condition: Callable, max_real_seconds: int = 120) -> void:
	for i: int in max_real_seconds:
		if condition.call():
			return
		Game.advance(1.0)
	assert_true(condition.call(), "No llegó a tiempo")


func _header(screen: OrdersScreen) -> String:
	var header: Control = screen.find_child("HeaderLine", true, false)
	if not header.visible:
		return ""
	return _label(header, "HeaderText")


func _press(root: Node, button_name: String) -> void:
	_button(root, button_name).pressed.emit()


func _button(root: Node, button_name: String) -> Button:
	var button: Button = root.find_child(button_name, true, false)
	assert_not_null(button, button_name)
	return button


func _label(root: Node, label_name: String) -> String:
	var label: Label = root.find_child(label_name, true, false)
	assert_not_null(label, label_name)
	return label.text if label != null else ""


func _step_color(steps: StepTracker, index: int) -> Color:
	return (steps.get_node("Step%d" % index).get_child(0) as TextureRect).modulate


func _texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts
