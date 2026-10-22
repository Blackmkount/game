extends GutTest
## El ciclo de pedidos por el mundo, sobre la escena principal: la primera
## venta (el llavero) desde el mensaje hasta el cobro, con los paneles de la
## impresora, del computador y del rincón de despacho, y cómo un panel se
## refresca, encadena al siguiente o dice por qué no se pudo.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
## Cada prueba empieza con la misma partida nueva.
const SEED: int = 1234
## El primer mensaje (el llavero) tiene este uid.
const FIRST: int = 4

var _main: Control
var _hud: Hud
var _controls: WorldControls
var _room: RoomView
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
	_room = _main.get_node("WorldView/SubViewport/Room")


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)
	Game.set_process(_previous_processing)


func test_the_first_sale_from_the_message_to_the_payment() -> void:
	Game.advance(3.0)
	await wait_process_frames(1)
	assert_eq(_badge(), "1", "Llegó el primer mensaje")
	_hud.open_screen("orders")
	var screen: OrdersScreen = _hud.get_node("ScreenHost/Screen")
	_button(screen, "Accept_%d" % FIRST).pressed.emit()
	await wait_process_frames(1)
	var next: Button = screen.content.find_child("Next_%d" % FIRST, true, false)
	assert_true(next == null or next.text == "Concentrarse")
	assert_eq((screen.content.find_child("Steps_%d" % FIRST, true, false) as StepTracker).step, 2, "Modelando")

	Game.advance(10.0)
	_hud.open_screen("home")
	_controls.open_sheet(_printer())
	await wait_process_frames(30)
	var plan: BottomSheet = _hud.current_sheet()
	var texts: Array[String] = _texts(plan)
	assert_has(texts, "Imprimir: Llavero con nombre")
	assert_has(texts, "Lista en 50 s (20 min de juego)")
	assert_has(texts, "Calidad 2 (pide 1) · Riesgo de fallo 0% (Don Ernesto la dejó recién calibrada)")
	assert_has(texts, "8 g de PLA Blanco (quedan 1.000 g)")
	assert_has(texts, "Material $0,14 · Ganancia $5,86")
	assert_eq(_button(plan, "Chip_mode_normal").theme_type_variation, "PrimaryButton", "Normal, el recomendado")
	assert_false(_button(plan, "Action_print").disabled)
	assert_lt(plan.size.y, _hud.get_viewport_rect().size.y * 0.5, "El plan tapa menos de la mitad")

	_button(plan, "Action_print").pressed.emit()
	assert_not_null(Game.state.printers[0].job, "Empezó a imprimir")
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "Imprimiendo: Llavero con nombre", "El panel pasa a imprimiendo")
	Game.advance(25.0)
	var piece: MeshInstance3D = _room.get_node("Printer%d/PieceSpot/Piece" % Game.state.printers[0].uid)
	assert_true(piece.visible)
	assert_between((piece.mesh as BoxMesh).size.y, 0.001, PieceModel.SIZES["S"].y - 0.001, "La pieza va creciendo")
	assert_eq(_label(_hud.current_sheet(), "ProgressText_job"), "Lista en 25 s", "La cuenta regresiva sigue al reloj")

	Game.advance(25.0)
	await wait_process_frames(1)
	var done: BottomSheet = _hud.current_sheet()
	assert_has(_texts(done), "¡Listo! Llavero con nombre · 1 pieza")
	_button(done, "Action_remove").pressed.emit()
	await wait_process_frames(1)
	assert_eq(_controls.sheet_item.kind, WorldInteractable.Kind.DISPATCH, "Sigue en el rincón de despacho")
	var corner: Node3D = _room.get_node("DispatchCorner")
	assert_true(corner.get_node("PackSpot0/OpenBox").visible, "Aparece la caja abierta")
	assert_has(_texts(_hud.current_sheet()), "Por embalar: Llavero con nombre")

	_button(_hud.current_sheet(), "Action_pack").pressed.emit()
	await wait_process_frames(1)
	assert_true(corner.get_node("OutSpot0/Package").visible, "Paquete en el cajón")
	var dispatch: BottomSheet = _hud.current_sheet()
	assert_has(_texts(dispatch), "Para despachar: Llavero con nombre · Pasan a buscarlo · $6 · +5 XP")
	assert_eq(_button(dispatch, "Action_dispatch").text, "Despachar")

	_button(dispatch, "Action_dispatch").pressed.emit()
	await wait_process_frames(1)
	assert_has(_texts(_hud.get_node("TopBar")), "$256")
	assert_has(_texts(_hud.get_node("TopBar")), "5 / 100 XP")
	assert_has(_texts(_hud.get_node("ObjectivesPanel")), "Entrega 3 llaveros (1/3)")
	assert_has(_flying(), "+$6", "Lo cobrado vuela al dinero")
	assert_has(_flying(), "+5 XP")
	assert_has(_texts(_hud.feedback.get_node("Toast")), "Amigos y familia: «¡Quedó genial! Ya todos me preguntan dónde lo hice.»")
	assert_eq(_badge(), "", "No queda nada por hacer")
	assert_has(_texts(_hud.current_sheet()), "Aquí llegan las piezas que retiras de la impresora.", "El rincón quedó vacío")


func test_a_mode_chip_changes_the_plan_in_place() -> void:
	_ready_keychain()
	_controls.open_sheet(_printer())
	await wait_process_frames(2)
	var sheet: BottomSheet = _hud.current_sheet()
	_button(sheet, "Chip_mode_fine").pressed.emit()
	assert_same(_hud.current_sheet(), sheet, "No se rearma dentro del botón")
	await wait_process_frames(1)
	var fine: BottomSheet = _hud.current_sheet()
	assert_has(_texts(fine), "Lista en 1 min 20 s (32 min de juego)")
	assert_has(_texts(fine), "Calidad 3 (pide 1) · Riesgo de fallo 0% (Don Ernesto la dejó recién calibrada)")
	assert_eq(_button(fine, "Chip_mode_fine").theme_type_variation, "PrimaryButton")
	assert_eq(fine.offset_transform_position, Vector2.ZERO, "Se refresca en su lugar, sin deslizarse")
	_button(fine, "Action_print").pressed.emit()
	assert_eq(Game.state.printers[0].job.mode_id, "fine")
	assert_eq(Game.state.printers[0].job.piece_seconds, 1920)


func test_the_choice_is_forgotten_when_another_object_opens() -> void:
	_ready_keychain()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	_button(_hud.current_sheet(), "Chip_mode_fine").pressed.emit()
	await wait_process_frames(1)
	_hud.close_sheet()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	assert_eq(_button(_hud.current_sheet(), "Chip_mode_fine").theme_type_variation, "PrimaryButton", "Mismo objeto: se recuerda")
	_controls.open_sheet(_desk())
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	assert_eq(_button(_hud.current_sheet(), "Chip_mode_normal").theme_type_variation, "PrimaryButton", "Otro objeto en medio: vuelve a lo recomendado")


func test_a_plan_shows_the_real_risk_after_the_calibrated_pieces() -> void:
	Game.state.pieces_started = Game.rules.grace_pieces
	_ready_keychain()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "Calidad 2 (pide 1) · Riesgo de fallo 20%", "Cubo Uno en el suelo")


func test_a_command_that_fails_shows_why_at_the_top() -> void:
	_ready_keychain()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	# El carrete se vacía sin avisar: el plan que se ve quedó viejo.
	Game.state.spools[0].grams = 0
	_button(_hud.current_sheet(), "Action_print").pressed.emit()
	assert_null(Game.state.printers[0].job, "No empezó nada")
	await wait_process_frames(1)
	var error: Node = _hud.current_sheet().find_child("Error", true, false)
	assert_not_null(error)
	assert_has(_texts(error), "No alcanza el material: quedan 0 g y hacen falta 8 g.")
	Events.spools_changed.emit()
	await wait_process_frames(1)
	assert_null(_hud.current_sheet().find_child("Error", true, false), "El motivo se muestra una vez")


func test_removing_stays_on_the_printer_when_another_model_is_ready() -> void:
	Game.advance(3.0)
	var second: int = _add_offer("llavero")
	assert_true(Game.accept_offer(FIRST).ok)
	assert_true(Game.accept_offer(second).ok)
	Game.advance(20.0)
	_start_recommended(FIRST)
	Game.advance(50.0)
	assert_eq(Game.state.find_order(second).stage, Order.Stage.READY_TO_PRINT)
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	_button(_hud.current_sheet(), "Action_remove").pressed.emit()
	await wait_process_frames(1)
	assert_eq(_controls.sheet_item, _printer(), "Se queda: puede imprimir el otro")
	var plan: BottomSheet = _hud.current_sheet()
	assert_has(_texts(plan), "Imprimir: Llavero con nombre")
	assert_eq(_button(plan, "Action_print").theme_type_variation, "PrimaryButton")
	_button(plan, "Action_go_pack").pressed.emit()
	await wait_process_frames(1)
	assert_eq(_controls.sheet_item, _room.dispatch_item, "Ir a embalar abre el rincón")


func test_the_order_chips_pick_which_model_to_print() -> void:
	Game.advance(3.0)
	var planter: int = _add_offer("maceta")
	assert_true(Game.accept_offer(FIRST).ok)
	assert_true(Game.accept_offer(planter).ok)
	Game.advance(60.0)
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	var sheet: BottomSheet = _hud.current_sheet()
	assert_has(_texts(sheet), "Imprimir: Llavero con nombre", "El primero")
	_button(sheet, "Chip_order_%d" % planter).pressed.emit()
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "Imprimir: Maceta decorativa")
	_button(_hud.current_sheet(), "Action_print").pressed.emit()
	assert_eq(Game.state.find_order(planter).stage, Order.Stage.PRINTING)


func test_the_desk_shows_the_model_and_lets_you_focus() -> void:
	Game.advance(3.0)
	var second: int = _add_offer("maceta")
	assert_true(Game.accept_offer(FIRST).ok)
	assert_true(Game.accept_offer(second).ok)
	_controls.open_sheet(_desk())
	await wait_process_frames(1)
	var sheet: BottomSheet = _hud.current_sheet()
	var texts: Array[String] = _texts(sheet)
	assert_has(texts, "Modelando: Llavero con nombre · Plantilla: solo hay que adaptarla")
	assert_has(texts, "Listo en 10 s")
	assert_has(texts, "En cola: Maceta decorativa")
	assert_has(texts, "Si te concentras, te ahorras el 50% del tiempo que falta (una vez por pedido).")
	Game.advance(2.0)
	assert_eq(_label(sheet, "ProgressText_design"), "Listo en 8 s", "Cuenta hacia atrás sin rearmarse")
	_button(sheet, "Action_focus").pressed.emit()
	assert_true(Game.state.find_order(FIRST).focused)
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "¡Concentrado! Sin celular hasta terminar.")
	assert_has(_texts(_hud.current_sheet()), "Listo en 4 s")
	Game.advance(4.0)
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "Modelo listo: Llavero con nombre")
	assert_has(_texts(_hud.current_sheet()), "Modelando: Maceta decorativa · Diseño a medida desde cero", "Sigue con la fila")
	_button(_hud.current_sheet(), "Action_focus").pressed.emit()
	await wait_process_frames(1)
	var ready: BottomSheet = _hud.current_sheet()
	assert_null(ready.find_child("Action_focus", true, false))
	_button(ready, "Action_print_ready").pressed.emit()
	await wait_process_frames(1)
	assert_eq(_controls.sheet_item, _printer(), "Imprimir abre la impresora")
	assert_has(_texts(_hud.current_sheet()), "Imprimir: Llavero con nombre")


func test_the_dispatch_corner_packs_and_dispatches_everything() -> void:
	Game.advance(3.0)
	var second: int = _add_offer("llavero")
	assert_true(Game.accept_offer(FIRST).ok)
	assert_true(Game.accept_offer(second).ok)
	for uid: int in [FIRST, second]:
		_advance_until(func() -> bool: return Game.state.find_order(uid).stage == Order.Stage.READY_TO_PRINT)
		var printer_uid: int = _start_recommended(uid)
		_advance_until(func() -> bool: return Game.state.find_order(uid).stage == Order.Stage.PRINTED)
		assert_true(Game.remove_pieces(printer_uid).ok)
	assert_true(Game.pack_order(FIRST).ok)
	_controls.open_sheet(_room.dispatch_item)
	await wait_process_frames(1)
	var sheet: BottomSheet = _hud.current_sheet()
	assert_eq(_button(sheet, "Action_pack").theme_type_variation, "PrimaryButton", "Embalar va primero")
	assert_eq(_button(sheet, "Action_dispatch").text, "Despachar (1)")
	_button(sheet, "Action_pack").pressed.emit()
	await wait_process_frames(1)
	var both: Button = _button(_hud.current_sheet(), "Action_dispatch")
	assert_eq(both.text, "Despachar (2)")
	both.pressed.emit()
	await wait_process_frames(1)
	assert_eq(Game.state.money_cents, 25000 + 2 * 600)
	assert_has(_flying(), "+$12", "Un solo vuelo con todo lo cobrado")
	var third: int = _add_offer("llavero")
	assert_true(Game.accept_offer(third).ok)
	_advance_until(func() -> bool: return Game.state.find_order(third).stage == Order.Stage.READY_TO_PRINT)
	var printer_uid: int = _start_recommended(third)
	_advance_until(func() -> bool: return Game.state.find_order(third).stage == Order.Stage.PRINTED)
	assert_true(Game.remove_pieces(printer_uid).ok)
	assert_true(Game.pack_order(third).ok)
	assert_true(Game.dispatch_order(third).ok)
	await wait_process_frames(1)
	assert_does_not_have(_flying(), "+$18", "Cada cobro vuela solo con lo suyo")
	assert_has(_flying(), "+$6")


func test_the_status_bubbles_show_what_each_object_is_doing() -> void:
	# Lejos del computador y de la impresora: sus burbujas no se reemplazan.
	_room.character.floor_position = Vector2(1.0, 1.6)
	Game.advance(3.0)
	assert_true(Game.accept_offer(FIRST).ok)
	await wait_process_frames(2)
	var desk: StatusBubble = _controls.status.bubble_for(_desk())
	assert_true(desk.visible, "El computador muestra que modela")
	assert_eq(_bubble_icon(desk), UiKit.icon_texture("design"))
	assert_has(_texts(desk), "10 s")
	Game.advance(1.0)
	assert_has(_texts(desk), "9 s", "Cuenta hacia atrás con el reloj")
	Game.advance(9.0)
	await wait_process_frames(2)
	assert_false(desk.visible, "Terminó de modelar")
	var printer: StatusBubble = _controls.status.bubble_for(_printer())
	assert_true(printer.visible, "La impresora avisa que puede imprimir")
	assert_eq(_bubble_icon(printer), UiKit.icon_texture("printer"))
	assert_false(_controls.status.bubble_for(_room.dispatch_item).visible, "El rincón está vacío")
	_controls.tap(printer.get_global_rect().get_center())
	assert_eq(_controls.sheet_item, _printer(), "Tocar la burbuja abre su panel")
	await wait_process_frames(1)
	assert_false(printer.visible, "Con su panel abierto no se ve")


func test_the_character_comments_and_reminds_what_comes_next() -> void:
	Game.advance(3.0)
	assert_true(_hud.speech.is_talking())
	assert_has(_texts(_hud.speech), "¡Me escribieron! Lo veo en Pedidos.")
	await wait_process_frames(1)
	_hud.speech.hush()
	Game.advance(1.0)
	Game.advance(2.0)
	assert_false(_hud.speech.is_talking(), "Ya lo dijo al llegar el mensaje: no lo repite")
	assert_true(Game.accept_offer(FIRST).ok)
	Game.advance(10.0)
	await wait_process_frames(1)
	_hud.speech.hush()
	Game.advance(1.0)
	assert_false(_hud.speech.is_talking(), "Espera a que el paso se mantenga")
	Game.advance(2.0)
	assert_true(_hud.speech.is_talking())
	assert_has(_texts(_hud.speech), "El modelo está listo: ¡a imprimir!")
	_hud.speech.hush()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	# El segundo mensaje llega a los 70 s, con el panel abierto.
	Game.advance(60.0)
	assert_false(_hud.speech.is_talking(), "Con un panel abierto no habla")


## Lleva el primer mensaje hasta el modelo listo.
func _ready_keychain() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(FIRST).ok)
	Game.advance(10.0)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.READY_TO_PRINT)


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


func _printer() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.PRINTER, Game.state.printers[0].uid)


func _desk() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.FURNITURE, Game.state.furniture[0].uid)


func _bubble_icon(bubble: StatusBubble) -> Texture2D:
	return (bubble.find_children("*", "TextureRect", true, false)[0] as TextureRect).texture


## Número rojo del botón Pedidos, o "" si no se ve.
func _badge() -> String:
	var badge: Control = _hud.get_node("SideButtons/Side_orders").find_children("*", "PanelContainer", false, false)[0]
	if not badge.visible:
		return ""
	return (badge.get_child(0) as Label).text


## Textos que vuelan ahora en la capa de celebraciones.
func _flying() -> Array[String]:
	var texts: Array[String] = []
	for node: Node in _hud.feedback.get_children():
		if node is Label and (node as Label).visible:
			texts.append((node as Label).text)
	return texts


func _button(root: Node, button_name: String) -> Button:
	var button: Button = root.find_child(button_name, true, false)
	assert_not_null(button, button_name)
	return button


func _label(root: Node, label_name: String) -> String:
	var label: Label = root.find_child(label_name, true, false)
	assert_not_null(label, label_name)
	return label.text if label != null else ""


func _texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts
