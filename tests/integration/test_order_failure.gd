extends GutTest
## Una pieza que falla, sobre la escena principal: la burbuja roja, lo que
## dice el personaje, el panel de la falla, Limpiar y reintentar (con otro
## modo, o sin material) y Limpiar.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
## Cada prueba empieza con la misma partida nueva.
const SEED: int = 1234
## El primer mensaje (el llavero) tiene este uid.
const FIRST: int = 4
## Un lugar del piso lejos de la impresora: su burbuja de cercanía no tapa la
## de estado.
const AWAY: Vector2 = Vector2(1.0, 1.6)

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


func test_a_failed_piece_shows_its_bubble_its_sheet_and_can_be_retried() -> void:
	_room.character.floor_position = AWAY
	_fail_keychain()
	await wait_process_frames(2)
	var bubble: StatusBubble = _controls.status.bubble_for(_printer())
	assert_true(bubble.visible, "Burbuja de falla sobre la impresora")
	assert_eq(_bubble_icon(bubble), UiKit.icon_texture("warning"))
	assert_true(_hud.speech.is_talking())
	assert_has(_texts(_hud.speech), "¡Nooo! Un espagueti.")
	_controls.tap(bubble.get_global_rect().get_center())
	assert_eq(_controls.sheet_item, _printer(), "La burbuja abre el panel")
	var sheet: BottomSheet = _hud.current_sheet()
	var texts: Array[String] = _texts(sheet)
	assert_string_starts_with(_label(sheet, "Title"), "Falló: espagueti")
	assert_has(texts, "Falló: espagueti al 35%")
	assert_has(texts, "Se perdieron 3 g de PLA Blanco")
	assert_has(texts, "Las piezas terminadas se guardan (0 de 1)")
	assert_has(texts, "Le pasa a los mejores. Limpia la cama y dale otra vez.")
	assert_not_null(sheet.find_child("Action_clean", true, false))
	var retry: Button = _button(sheet, "Action_retry")
	assert_eq(retry.theme_type_variation, "PrimaryButton")
	retry.pressed.emit()
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.PRINTING, "Imprime otra vez")
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "Imprimiendo: Llavero con nombre")


func test_a_message_at_the_same_time_does_not_hide_the_failure() -> void:
	Game.advance(3.0)
	_hud.speech.hush()
	assert_true(Game.accept_offer(FIRST).ok)
	Game.advance(10.0)
	var printer_uid: int = Game.state.printers[0].uid
	assert_true(Game.start_print(FIRST, printer_uid, Game.state.spools[0].uid, "normal").ok)
	assert_true(DebugTools.force_fail(Game.sim, printer_uid, FailureRules.SPAGHETTI))
	# Falla a los 30,5 s y el segundo mensaje llega a los 70 s: en el mismo avance.
	Game.advance(60.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED)
	assert_eq(Game.state.offers.size(), 1)
	assert_has(_texts(_hud.speech), "¡Nooo! Un espagueti.")


func test_retrying_with_another_mode_shows_its_risk_first() -> void:
	# Ya se usaron las piezas calibradas: se ve el riesgo de verdad.
	Game.state.pieces_started = Game.rules.grace_pieces
	_fail_keychain()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	var sheet: BottomSheet = _hud.current_sheet()
	assert_has(_texts(sheet), "Calidad 2 (pide 1) · Riesgo de fallo 20%", "El modo del trabajo: normal")
	assert_eq(_button(sheet, "Chip_mode_normal").theme_type_variation, "PrimaryButton")
	_button(sheet, "Chip_mode_fine").pressed.emit()
	await wait_process_frames(1)
	sheet = _hud.current_sheet()
	assert_has(_texts(sheet), "Calidad 3 (pide 1) · Riesgo de fallo 16%")
	await wait_process_frames(30)
	assert_lt(sheet.size.y, _hud.get_viewport_rect().size.y * BottomSheet.MAX_COVER, "Cabe con lugar para el cuarto")
	_button(sheet, "Action_retry").pressed.emit()
	var job: PrintJob = Game.state.printers[0].job
	assert_eq(job.mode_id, "fine")
	assert_eq(job.piece_seconds, 1920)


func test_retry_without_material_says_why_and_changes_nothing() -> void:
	_fail_keychain()
	Game.state.spools[0].grams = 5
	Events.spools_changed.emit()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	var retry: Button = _button(_hud.current_sheet(), "Action_retry")
	assert_true(retry.disabled)
	assert_eq(_label(_hud.current_sheet(), "Note_retry"), "No alcanza el material: quedan 5 g y hacen falta 8 g.")
	var before: String = JSON.stringify(SaveCodec.encode(Game.state), "", true)
	_controls.loop.run_sheet("retry")
	assert_eq(JSON.stringify(SaveCodec.encode(Game.state), "", true), before, "Ni gramos ni azar")
	await wait_process_frames(1)
	assert_not_null(_hud.current_sheet().find_child("Error", true, false), "Dice por qué arriba")


func test_cleaning_sends_the_order_back_to_print() -> void:
	_fail_keychain()
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	_button(_hud.current_sheet(), "Action_clean").pressed.emit()
	assert_null(Game.state.printers[0].job, "La impresora queda libre")
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.READY_TO_PRINT)
	await wait_process_frames(1)
	assert_has(_texts(_hud.current_sheet()), "Imprimir: Llavero con nombre", "El panel pasa al plan")
	_hud.open_screen("orders")
	var screen: OrdersScreen = _hud.get_node("ScreenHost/Screen")
	assert_eq(_button(screen.content, "Next_%d" % FIRST).text, "Imprimir", "La tarjeta vuelve a Imprimir")


## Imprime el llavero en la Cubo Uno y lo hace fallar con espagueti al 35%
## (420 gs = 17,5 s reales).
func _fail_keychain() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(FIRST).ok)
	Game.advance(10.0)
	var printer_uid: int = Game.state.printers[0].uid
	assert_true(Game.start_print(FIRST, printer_uid, Game.state.spools[0].uid, "normal").ok)
	assert_true(DebugTools.force_fail(Game.sim, printer_uid, FailureRules.SPAGHETTI))
	Game.advance(20.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED)


func _printer() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.PRINTER, Game.state.printers[0].uid)


func _bubble_icon(bubble: StatusBubble) -> Texture2D:
	return (bubble.find_children("*", "TextureRect", true, false)[0] as TextureRect).texture


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
