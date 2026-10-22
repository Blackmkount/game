extends GutTest
## El ciclo de pedidos jugado con toques de verdad, como en el teléfono: cada
## toque se manda con Input.parse_input_event y llega a los botones del HUD, a
## los paneles y a la burbuja de cercanía por el mismo camino que un dedo
## (las demás pruebas del ciclo tocan los botones con pressed.emit()).
##
## También se recarga la partida a mitad de una impresión con SaveManager, como
## al recargar la página: el mundo, las burbujas, el número de Pedidos y las
## tarjetas vuelven a quedar como estaban.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
## Cada prueba empieza con la misma partida nueva.
const SEED: int = 1234
## El primer mensaje (el llavero) tiene este uid.
const FIRST: int = 4
## Tamaño de ventana que da la pantalla real de 720×1280 de la interfaz.
const WINDOW_SIZE: Vector2i = Vector2i(405, 720)
const TEST_PATH: String = "user://test_player_touches.json"

var _main: Control
var _hud: Hud
var _controls: WorldControls
var _room: RoomView
var _previous_locale: String
var _previous_processing: bool
var _previous_window_size: Vector2i
var _previous_save_path: String
var _previous_save_enabled: bool
## El panel de resultados de GUT tapa parte de la ventana: se esconde mientras
## dura cada prueba para que los toques lleguen al juego.
var _gut_panel: Control


func before_each() -> void:
	_previous_processing = Game.is_processing()
	# La partida solo avanza cuando la prueba lo pide.
	Game.set_process(false)
	Game.reset_game(SEED)
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_previous_window_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	_previous_save_path = SaveManager.path
	_previous_save_enabled = SaveManager.enabled
	_gut_panel = _find_gut_panel()
	if _gut_panel != null:
		_gut_panel.visible = false
	await _open_main()


func after_each() -> void:
	if _gut_panel != null:
		_gut_panel.visible = true
	TranslationServer.set_locale(_previous_locale)
	get_tree().root.size = _previous_window_size
	SaveManager.path = _previous_save_path
	SaveManager.enabled = _previous_save_enabled
	for suffix: String in ["", SaveManager.TMP_SUFFIX, SaveManager.BAD_SUFFIX]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))
	Game.set_process(_previous_processing)


func test_the_first_sale_with_real_touches() -> void:
	var start: Vector2 = _room.character.floor_position
	Game.advance(3.0)
	await wait_process_frames(2)
	assert_eq(_badge(), "1", "Llegó el primer mensaje")
	await _touch_control(_hud.get_node("SideButtons/Side_orders"))
	assert_eq(_hud.current_screen_id(), "orders")
	assert_eq(_visible_status_bubbles(), 0, "Las burbujas de estado no se ven sobre una pantalla")
	await _touch_control(_card_button("Accept_%d" % FIRST))
	await wait_process_frames(1)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.DESIGNING, "Aceptado con un toque")
	assert_eq(_badge(), "", "Mientras se modela no hay nada que hacer")
	await _touch_control(_screen().find_child("CloseButton", true, false))
	assert_eq(_hud.current_screen_id(), "home")

	Game.advance(10.0)
	await wait_process_frames(2)
	assert_eq(_badge(), "1", "Modelo listo con la impresora libre")
	assert_eq(_controls.highlighted, _printer(), "El personaje empieza junto a la impresora")
	await _touch_control(_hud.bubble)
	assert_eq(_controls.sheet_item, _printer(), "La burbuja abre el plan")
	assert_null(Game.state.printers[0].job, "Nunca imprime a ciegas")
	await wait_process_frames(2)
	assert_has(_texts(_hud.current_sheet()), "Imprimir: Llavero con nombre")
	await _touch_control(_sheet_button("Action_print"))
	assert_not_null(Game.state.printers[0].job, "Imprimir con un toque")
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "Imprimiendo: Llavero con nombre")

	Game.advance(50.0)
	await wait_process_frames(2)
	assert_eq(_badge(), "1", "Pieza lista para retirar")
	await _touch_control(_sheet_button("Action_remove"))
	await wait_process_frames(1)
	assert_eq(_controls.sheet_item, _room.dispatch_item, "Sigue en el rincón de despacho")
	await wait_process_frames(2)
	await _touch_control(_sheet_button("Action_pack"))
	await wait_process_frames(1)
	await _touch_control(_sheet_button("Action_dispatch"))
	await wait_process_frames(1)
	assert_eq(Game.state.money_cents, 25600)
	assert_has(_texts(_hud.get_node("TopBar")), "$256")
	assert_eq(_badge(), "", "No queda nada por hacer")
	assert_eq(_room.character.floor_position, start, "Sin caminar")


func test_reloading_in_the_middle_of_a_print_restores_the_world() -> void:
	Game.advance(3.0)
	assert_true(Game.buy_local_material("petg").ok)
	# La perilla es de nivel 2: el mensaje se agrega a mano, como en las capturas.
	var knob: OrderOffer = OrderOffer.new(Game.state.take_uid(), "perilla", Game.state.game_seconds)
	Game.state.offers.append(knob)
	Events.offers_changed.emit()
	await wait_process_frames(1)
	assert_true(Game.accept_offer(FIRST).ok)
	assert_true(Game.accept_offer(knob.uid).ok)
	_advance_until(func() -> bool: return Game.state.find_order(FIRST).stage == Order.Stage.READY_TO_PRINT)
	_print_recommended(FIRST)
	_advance_until(func() -> bool: return Game.state.find_order(FIRST).stage == Order.Stage.PRINTED)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	_advance_until(func() -> bool: return Game.state.find_order(knob.uid).stage == Order.Stage.READY_TO_PRINT)
	_print_recommended(knob.uid)
	var job: PrintJob = Game.state.printers[0].job
	# La primera pieza lista y la segunda a la mitad.
	Game.advance(job.piece_seconds * 1.5 / Game.rules.game_seconds_per_real_second)
	assert_eq(Game.state.find_order(knob.uid).pieces_done, 1)
	assert_eq(job.status, PrintJob.Status.PRINTING)
	var accepted: Order = Game.state.find_order(_accept_next_offer())
	assert_eq(accepted.stage, Order.Stage.DESIGNING, "El computador modela el tercero")
	var saved: String = _encoded()
	var badge: String = _badge()

	SaveManager.path = TEST_PATH
	SaveManager.enabled = true
	assert_true(SaveManager.save_now())
	_main.queue_free()
	await wait_process_frames(1)
	Game.reset_game(SEED + 1)
	var loaded: GameState = SaveManager.load_state(Game.rules)
	SaveManager.enabled = false
	assert_not_null(loaded, "Se carga la partida guardada")
	Game._start(loaded)
	assert_eq(_encoded(), saved, "La misma partida")
	await _open_main()

	var printer: Node3D = _room.get_node("Printer%d" % Game.state.printers[0].uid)
	var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
	assert_true(piece.visible)
	assert_between((piece.mesh as BoxMesh).size.y, 0.001, PieceModel.SIZES["S"].y - 0.001, "La pieza sigue a la mitad")
	assert_true(printer.get_node("Tray0").visible, "La primera pieza espera en la bandeja")
	assert_true(_room.get_node("DispatchCorner/PackSpot0/OpenBox").visible, "El llavero espera en su caja")
	var screen: MeshInstance3D = _room.get_node("Furniture%d/Monitor/Screen" % Game.state.furniture[0].uid)
	assert_eq(screen.material_override, WorldPalette.glow("ffffff", "crt_modeling"), "El computador sigue modelando")
	assert_true(_controls.status.bubble_for(_desk()).visible)
	assert_true(_controls.status.bubble_for(_room.dispatch_item).visible)
	assert_eq(_badge(), badge, "El mismo número en Pedidos")
	await _touch_control(_hud.get_node("SideButtons/Side_orders"))
	for order: Order in Game.state.orders:
		var tracker: StepTracker = _screen().content.find_child("Steps_%d" % order.uid, true, false)
		assert_not_null(tracker, "Tarjeta del pedido %d" % order.uid)
		if tracker != null:
			assert_eq(tracker.step, OrderQueries.step_index(order))
	await _touch_control(_screen().find_child("CloseButton", true, false))

	# Sigue: la segunda pieza termina y la burbuja de cercanía la retira.
	_advance_until(func() -> bool: return Game.state.printers[0].job.status == PrintJob.Status.DONE)
	await wait_process_frames(2)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("check"))
	await _touch_control(_hud.bubble)
	assert_false(_hud.has_sheet(), "Retirar desde la burbuja no abre panel")
	assert_eq(Game.state.find_order(knob.uid).stage, Order.Stage.TO_PACK)


func test_a_finger_on_a_panel_button_survives_a_refresh() -> void:
	var order_uid: int = _accept_next_offer()
	_advance_until(func() -> bool: return Game.state.find_order(order_uid).stage == Order.Stage.READY_TO_PRINT)
	_controls.open_sheet(_printer())
	await wait_process_frames(2)
	var button: Button = _sheet_button("Action_print")
	var spot: Vector2 = button.get_global_rect().get_center()
	_send_touch(spot, true)
	await wait_process_frames(1)
	# Mientras el dedo está abajo, algo cambia en la partida (llega un mensaje)
	# y el panel abierto pide rearmarse.
	Events.offers_changed.emit()
	await wait_process_frames(2)
	assert_true(is_instance_valid(button) and button.is_inside_tree(), "El botón bajo el dedo sigue ahí")
	_send_touch(spot, false)
	await wait_process_frames(2)
	assert_not_null(Game.state.printers[0].job, "Al soltar, el toque cuenta: empieza a imprimir")
	assert_not_null(_hud.current_sheet().find_child("Progress_job", true, false), "Y después el panel se rearma")


func test_a_finger_on_an_orders_button_survives_a_rebuild() -> void:
	_advance_until(func() -> bool: return not Game.state.offers.is_empty())
	var offer_uid: int = Game.state.offers[0].uid
	await _touch_control(_hud.get_node("SideButtons/Side_orders"))
	await wait_process_frames(2)
	var button: Button = _card_button("Accept_%d" % offer_uid)
	var spot: Vector2 = button.get_global_rect().get_center()
	_send_touch(spot, true)
	await wait_process_frames(1)
	# Mientras el dedo está abajo, algo cambia en la partida y la pantalla
	# pide rearmarse.
	Events.offers_changed.emit()
	await wait_process_frames(2)
	assert_true(is_instance_valid(button) and button.is_inside_tree(), "El botón bajo el dedo sigue ahí")
	_send_touch(spot, false)
	await wait_process_frames(2)
	assert_not_null(Game.state.find_order(offer_uid), "Al soltar, el toque cuenta: el pedido se aceptó")
	assert_null(_screen().content.find_child("Accept_%d" % offer_uid, true, false), "Y después la pantalla se rearma")


func _open_main() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(3)
	_hud = _main.get_node("Hud")
	_controls = _main.get_node("WorldControls")
	_room = _main.get_node("WorldView/SubViewport/Room")


func _find_gut_panel() -> Control:
	var node: Node = get_tree().root.find_child("TestOutput", true, false)
	while node != null and node.get_parent() is Control:
		node = node.get_parent()
	return node as Control


## Acepta el primer mensaje del tablero y devuelve su uid.
func _accept_next_offer() -> int:
	_advance_until(func() -> bool: return not Game.state.offers.is_empty())
	var uid: int = Game.state.offers[0].uid
	assert_true(Game.accept_offer(uid).ok)
	return uid


func _print_recommended(order_uid: int) -> void:
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, Game.state.find_order(order_uid))
	assert_true(Game.start_print(order_uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)


## Avanza de a un segundo real hasta que se cumpla `condition`, con un límite
## para no quedar esperando para siempre.
func _advance_until(condition: Callable, max_real_seconds: int = 600) -> void:
	for i: int in max_real_seconds:
		if condition.call():
			return
		Game.advance(1.0)
	assert_true(condition.call(), "No llegó a tiempo")


func _encoded() -> String:
	return JSON.stringify(SaveCodec.encode(Game.state), "", true)


func _screen() -> ScreenBase:
	return _hud.get_node("ScreenHost/Screen")


func _card_button(button_name: String) -> Button:
	var button: Button = _screen().content.find_child(button_name, true, false)
	assert_not_null(button, button_name)
	return button


func _sheet_button(button_name: String) -> Button:
	assert_true(_hud.has_sheet(), "Hay un panel abierto")
	var button: Button = _hud.current_sheet().find_child(button_name, true, false)
	assert_not_null(button, button_name)
	return button


func _printer() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.PRINTER, Game.state.printers[0].uid)


func _desk() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.FURNITURE, Game.state.furniture[0].uid)


func _visible_status_bubbles() -> int:
	var count: int = 0
	for bubble: Node in _hud.status_bubbles.get_children():
		if (bubble as Control).is_visible_in_tree():
			count += 1
	return count


## Número rojo del botón Pedidos, o "" si no se ve.
func _badge() -> String:
	var badge: Control = _hud.get_node("SideButtons/Side_orders").find_children("*", "PanelContainer", false, false)[0]
	if not badge.visible:
		return ""
	return (badge.get_child(0) as Label).text


## Toca el centro de un control. Si está dentro de una lista, primero la
## desplaza hasta que se vea, como haría el jugador.
func _touch_control(control: Control) -> void:
	var parent: Node = control.get_parent()
	while parent != null and not parent is ScrollContainer:
		parent = parent.get_parent()
	if parent != null:
		(parent as ScrollContainer).ensure_control_visible(control)
		await wait_process_frames(2)
	assert_true(control.is_visible_in_tree(), "Se ve " + control.name)
	await _touch(control.get_global_rect().get_center())


## Un toque completo: bajar y subir el dedo en el mismo lugar.
func _touch(ui_position: Vector2) -> void:
	_send_touch(ui_position, true)
	await wait_process_frames(1)
	_send_touch(ui_position, false)
	await wait_process_frames(1)


func _send_touch(ui_position: Vector2, pressed: bool) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = pressed
	touch.position = get_tree().root.get_final_transform() * ui_position
	Input.parse_input_event(touch)
	Input.flush_buffered_events()


func _texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts
