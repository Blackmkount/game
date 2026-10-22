extends GutTest
## La primera venta entera sin tocar el mundo ni caminar: solo con los botones
## de las tarjetas de Pedidos y los de los paneles que se abren solos (GDD 7.1:
## caminar nunca es obligatorio).

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


func test_the_whole_order_with_cards_and_the_sheets_they_open() -> void:
	var start: Vector2 = _room.character.floor_position
	Game.advance(3.0)
	_card_button("Accept_%d" % FIRST).pressed.emit()
	assert_not_null(Game.state.find_order(FIRST))
	Game.advance(10.0)

	var print_button: Button = await _next_button()
	assert_eq(print_button.text, "Imprimir")
	print_button.pressed.emit()
	assert_eq(_hud.current_screen_id(), "home", "Vuelve a la habitación")
	assert_eq(_controls.sheet_item.kind, WorldInteractable.Kind.PRINTER, "Con el panel de la impresora abierto")
	assert_has(_texts(_hud.current_sheet()), "Imprimir: Llavero con nombre")
	_sheet_button("Action_print").pressed.emit()
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.PRINTING)
	Game.advance(50.0)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.PRINTED)

	var remove: Button = await _next_button()
	assert_eq(remove.text, "Retirar pieza")
	remove.pressed.emit()
	assert_eq(_controls.sheet_item, _room.dispatch_item, "Abre el rincón de despacho")
	await wait_process_frames(1)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.TO_PACK, "Retira en el cuadro siguiente")
	assert_true(_room.get_node("DispatchCorner/PackSpot0/OpenBox").visible)

	_sheet_button("Action_pack").pressed.emit()
	await wait_process_frames(1)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.PACKED)

	var dispatch: Button = await _next_button()
	assert_eq(dispatch.text, "Despachar")
	dispatch.pressed.emit()
	assert_eq(_controls.sheet_item, _room.dispatch_item)
	await wait_process_frames(1)
	assert_null(Game.state.find_order(FIRST), "Despachado")
	assert_eq(Game.state.money_cents, 25600)
	assert_eq(Game.state.xp, 5)
	assert_has(_texts(_hud.get_node("TopBar")), "$256")
	assert_eq(_room.character.floor_position, start, "Sin caminar")


func test_print_from_a_card_opens_the_plan_for_that_order() -> void:
	Game.advance(3.0)
	var planter: OrderOffer = OrderOffer.new(Game.state.take_uid(), "maceta", Game.state.game_seconds)
	Game.state.offers.append(planter)
	Events.offers_changed.emit()
	await wait_process_frames(1)
	_card_button("Accept_%d" % FIRST).pressed.emit()
	await wait_process_frames(1)
	_card_button("Accept_%d" % planter.uid).pressed.emit()
	Game.advance(60.0)
	await wait_process_frames(1)
	_card_button("Next_%d" % planter.uid).pressed.emit()
	assert_eq(_controls.sheet_item.kind, WorldInteractable.Kind.PRINTER)
	assert_has(_texts(_hud.current_sheet()), "Imprimir: Maceta decorativa", "El pedido de la tarjeta, no el primero")
	_sheet_button("Action_print").pressed.emit()
	assert_eq(Game.state.find_order(planter.uid).stage, Order.Stage.PRINTING)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.READY_TO_PRINT)
	await wait_process_frames(1)


## Abre Pedidos con el botón del costado y devuelve el botón del paso
## siguiente del primer pedido.
func _next_button() -> Button:
	await wait_process_frames(1)
	return _card_button("Next_%d" % FIRST)


## Un botón de una tarjeta de Pedidos (abre la pantalla si hace falta).
func _card_button(button_name: String) -> Button:
	if _hud.current_screen_id() != "orders":
		(_hud.get_node("SideButtons/Side_orders") as Button).pressed.emit()
	var screen: OrdersScreen = _hud.get_node("ScreenHost/Screen")
	var button: Button = screen.content.find_child(button_name, true, false)
	assert_not_null(button, button_name)
	return button


## Un botón del panel que se abrió solo.
func _sheet_button(button_name: String) -> Button:
	assert_true(_hud.has_sheet(), "Hay un panel abierto")
	var button: Button = _hud.current_sheet().find_child(button_name, true, false)
	assert_not_null(button, button_name)
	return button


func _texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts
