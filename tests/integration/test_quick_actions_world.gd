extends GutTest
## La burbuja de cercanía sobre la escena principal: al caminar cerca, corre
## la acción cuando no hay nada que decidir (retirar, embalar, despachar,
## concentrarse) sin abrir panel; imprimir y las fallas siempre abren el panel.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
## Cada prueba empieza con la misma partida nueva.
const SEED: int = 1234
## El primer mensaje (el llavero) tiene este uid.
const FIRST: int = 4
## Un lugar del piso frente al rincón de despacho.
const BY_THE_CORNER: Vector2 = Vector2(-1.45, 2.1)

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


func test_the_bubble_of_a_done_printer_removes_the_piece_without_a_sheet() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	await wait_process_frames(2)
	assert_eq(_controls.highlighted, _printer(), "El personaje empieza junto a su impresora")
	assert_true(_hud.bubble.visible)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("check"))
	assert_false(_controls.status.bubble_for(_printer()).visible, "La de cercanía reemplaza a la de estado")
	_tap_bubble()
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.TO_PACK, "Retiró la pieza")
	assert_false(_hud.has_sheet(), "Sin panel")
	await wait_process_frames(2)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("printer"), "La impresora quedó libre")


func test_the_bubble_of_a_printer_ready_to_print_opens_the_plan() -> void:
	_ready_keychain()
	await wait_process_frames(2)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("printer"))
	_tap_bubble()
	assert_eq(_controls.sheet_item, _printer(), "Abre el plan")
	assert_not_null(_hud.current_sheet().find_child("Action_print", true, false))
	assert_null(Game.state.printers[0].job, "No empieza nada a ciegas")


func test_the_bubble_of_a_failed_printer_opens_its_sheet() -> void:
	_ready_keychain()
	_start_print()
	assert_true(DebugTools.force_fail(Game.sim, Game.state.printers[0].uid, FailureRules.WARPING))
	Game.advance(20.0)
	await wait_process_frames(2)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("warning"))
	_tap_bubble()
	assert_eq(_controls.sheet_item, _printer())
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED, "Limpiar es una decisión: no se hace sola")


func test_the_corner_bubble_packs_then_dispatches() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	_room.character.floor_position = BY_THE_CORNER
	await wait_process_frames(3)
	assert_eq(_controls.highlighted, _room.dispatch_item)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("box"))
	_tap_bubble()
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.PACKED)
	assert_false(_hud.has_sheet())
	await wait_process_frames(2)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("truck"))
	_tap_bubble()
	assert_null(Game.state.find_order(FIRST), "Despachado")
	assert_eq(Game.state.money_cents, 25600)
	assert_false(_hud.has_sheet())
	await wait_process_frames(2)
	_tap_bubble()
	assert_eq(_controls.sheet_item, _room.dispatch_item, "Vacío, abre su panel")


func test_the_desk_bubble_focuses_the_model_once() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(FIRST).ok)
	var desk: WorldInteractable = _room.item_for(WorldInteractable.Kind.FURNITURE, Game.state.furniture[0].uid)
	var footprint: Rect2 = desk.footprint()
	_room.character.floor_position = Vector2(footprint.end.x + 0.25, footprint.get_center().y)
	await wait_process_frames(3)
	assert_eq(_controls.highlighted, desk)
	assert_eq(_hud.bubble.icon, UiKit.icon_texture("design"))
	_tap_bubble()
	assert_true(Game.state.find_order(FIRST).focused)
	assert_false(_hud.has_sheet())
	await wait_process_frames(2)
	_tap_bubble()
	assert_eq(_controls.sheet_item, desk, "Ya concentrado: abre el panel")


func test_the_interact_key_does_the_same_as_the_bubble() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	await wait_process_frames(2)
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await wait_process_frames(1)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.TO_PACK)
	assert_false(_hud.has_sheet())
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()


## Lleva el primer mensaje hasta el modelo listo.
func _ready_keychain() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(FIRST).ok)
	Game.advance(10.0)


func _start_print() -> void:
	assert_true(Game.start_print(FIRST, Game.state.printers[0].uid, Game.state.spools[0].uid, "normal").ok)


func _tap_bubble() -> void:
	assert_true(_hud.bubble.visible, "Se ve la burbuja de cercanía")
	_controls.tap(_hud.bubble.get_global_rect().get_center() - _controls.global_position)


func _printer() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.PRINTER, Game.state.printers[0].uid)
