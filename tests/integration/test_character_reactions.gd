extends GutTest
## El personaje reacciona a lo que pasa en la partida (biblia de arte §7.8),
## en la escena principal: RoomView le cuenta a su animador las señales de
## Events, WorldControls los toques y el globo de diálogo, y
## OrderLoopController lo que se embala o no se pudo hacer.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
## Cada prueba empieza con la misma partida nueva.
const SEED: int = 1234
## El primer mensaje (el llavero) tiene este uid.
const FIRST: int = 4
## Un lugar del piso frente al rincón de despacho, y otro lejos de todo.
const BY_THE_CORNER: Vector2 = Vector2(-1.45, 2.1)
const FAR_FROM_ALL: Vector2 = Vector2(0.9, 1.6)
## Desde aquí hasta FAR_FROM_ALL camina hacia la cámara más de 1 m.
const WALK_FROM: Vector2 = Vector2(-0.6, 0.2)

var _main: Control
var _hud: Hud
var _controls: WorldControls
var _room: RoomView
var _animator: CharacterAnimator
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
	_animator = _room.character.animator


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)
	Game.set_process(_previous_processing)


func test_the_big_moments_of_the_game_show_on_the_character() -> void:
	Events.print_failed.emit(Game.state.printers[0].uid, "spaghetti")
	assert_eq(_animator.emotion(), FacePainter.Face.WORRIED, "Falla una pieza: preocupado")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.HANDS_ON_HEAD, "y se agarra la cabeza")
	_animator.reset()
	Events.level_up.emit(2)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.JUMP, "Sube de nivel: salta")
	assert_eq(_animator.emotion(), FacePainter.Face.SURPRISE)
	_animator.reset()
	Events.order_delivered.emit(1, "llavero", 100, 10, false)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.CHEER, "Cobra: puño arriba")
	assert_eq(_animator.emotion(), FacePainter.Face.HAPPY)
	_animator.reset()
	Events.order_delivered.emit(1, "llavero", 100, 10, true)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.SCRATCH_HEAD, "Atrasado: se rasca la cabeza")
	assert_eq(_animator.emotion(), FacePainter.Face.NEUTRAL)
	Events.game_loaded.emit()
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE, "Una partida nueva lo deja tranquilo")


func test_a_message_makes_it_check_the_phone_unless_a_panel_is_open() -> void:
	_controls.open_sheet(_printer())
	await wait_process_frames(1)
	Events.offer_arrived.emit(1)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE, "Con el panel abierto no saca el celular")
	_hud.close_sheet()
	await wait_process_frames(1)
	Events.offer_arrived.emit(1)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.PHONE, "Quieto y sin panel, lo mira")


func test_tapping_the_character_turns_it_to_wave() -> void:
	_controls.tap(_controls.world_to_ui(_room.character.model.position + Vector3(0.0, 0.7, 0.0)))
	assert_true(_hud.speech.is_talking(), "Dice algo")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.WAVE, "y saluda")
	assert_eq(_animator.emotion(), FacePainter.Face.HAPPY)
	await wait_seconds(0.4)
	assert_almost_eq(wrapf(_room.character.yaw - deg_to_rad(CameraRig.YAW), -PI, PI), 0.0, 0.05, "De frente a la cámara")
	assert_true(_animator.expression() in [FacePainter.Face.HAPPY, FacePainter.Face.TALK_A, FacePainter.Face.TALK_B], "Feliz mientras habla")


func test_the_mouth_moves_while_the_speech_bubble_shows() -> void:
	_hud.speech.say("Hola")
	await wait_process_frames(2)
	assert_true(_animator.talking)
	_hud.speech.hush()
	await wait_process_frames(2)
	assert_false(_animator.talking)


func test_a_print_that_finishes_nearby_gets_a_thumbs_up() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.THUMBS_UP, "Empieza junto a su impresora")
	assert_eq(_animator.emotion(), FacePainter.Face.HAPPY)


func test_the_thumbs_up_turns_to_the_player() -> void:
	_ready_keychain()
	_start_print()
	_room.character.yaw = deg_to_rad(CameraRig.YAW + 180.0)
	Game.advance(50.0)
	await wait_seconds(0.4)
	assert_almost_eq(wrapf(_room.character.yaw - deg_to_rad(CameraRig.YAW), -PI, PI), 0.0, 0.05, "Se da vuelta hacia la cámara para el pulgar arriba")


func test_with_a_panel_open_the_thumbs_up_keeps_facing_the_printer() -> void:
	_ready_keychain()
	_start_print()
	_controls.open_sheet(_printer())
	await wait_seconds(0.4)
	var facing_printer: float = _room.character.yaw
	Game.advance(50.0)
	await wait_seconds(0.4)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.THUMBS_UP, "Con el panel abierto, igual levanta el pulgar")
	assert_almost_eq(_room.character.yaw, facing_printer, 0.001, "pero sigue mirando la impresora del panel")


func test_a_print_that_finishes_far_away_gets_no_reaction() -> void:
	_ready_keychain()
	_start_print()
	_room.character.floor_position = FAR_FROM_ALL
	await wait_process_frames(2)
	Game.advance(50.0)
	assert_ne(_animator.current_gesture(), CharacterGestures.Gesture.THUMBS_UP)
	assert_ne(_animator.emotion(), FacePainter.Face.HAPPY)


func test_packing_by_the_corner_and_a_failed_command() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	_room.character.floor_position = BY_THE_CORNER
	await wait_process_frames(3)
	_animator.reset()
	_controls.tap(_hud.bubble.get_global_rect().get_center() - _controls.global_position)
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.PACKED)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.PACK, "Embala junto al rincón")
	_controls.open_sheet(_printer())
	_controls.loop.run_sheet("clean")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.SHRUG, "No había nada que limpiar: se encoge de hombros")


## Despachar junto al rincón (con la burbuja de cercanía, lo de siempre):
## el cobro se festeja con el puño y la subida de nivel con el salto. El
## gesto de embalar no los corta (el despacho los avisa antes de terminar).
func test_dispatching_by_the_corner_cheers_the_payday() -> void:
	await _packed_keychain_by_the_corner()
	_controls.tap(_hud.bubble.get_global_rect().get_center() - _controls.global_position)
	assert_null(Game.state.find_order(FIRST), "Se despachó")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.CHEER, "Cobra: puño arriba")
	assert_eq(_animator.emotion(), FacePainter.Face.HAPPY)


func test_a_level_up_by_the_corner_jumps() -> void:
	await _packed_keychain_by_the_corner()
	Game.state.xp = Game.levels.thresholds[1] - 1
	_controls.tap(_hud.bubble.get_global_rect().get_center() - _controls.global_position)
	assert_eq(Game.level(), 2, "Subió de nivel")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.JUMP, "Sube de nivel: salta")
	assert_eq(_animator.emotion(), FacePainter.Face.SURPRISE)


## Embalar sí corta un gesto suelto (el celular, estirarse).
func test_packing_cuts_a_loose_gesture() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	_room.character.floor_position = BY_THE_CORNER
	await wait_process_frames(3)
	_animator.reset()
	Events.offer_arrived.emit(1)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.PHONE)
	_controls.tap(_hud.bubble.get_global_rect().get_center() - _controls.global_position)
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.PACK, "Deja el celular y embala")


## Tocar al personaje mientras camina solo (por un toque en el piso): se
## detiene, saluda apenas se queda quieto y se queda de frente a la cámara
## (antes seguía caminando y al llegar quedaba de espaldas).
func test_tapping_the_character_while_it_walks_stops_it_to_wave() -> void:
	var character: CharacterController = _room.character
	character.floor_position = WALK_FROM
	await wait_process_frames(2)
	assert_true(character.walk_to(FAR_FROM_ALL))
	await wait_seconds(0.15)
	assert_true(character.is_following_path(), "Camina")
	_controls.tap(_controls.world_to_ui(character.model.position + Vector3(0.0, 0.7, 0.0)))
	assert_false(character.is_following_path(), "Al tocarlo se detiene")
	var waved: bool = false
	for frame: int in 60:
		await wait_process_frames(1)
		waved = waved or _animator.current_gesture() == CharacterGestures.Gesture.WAVE
	assert_true(waved, "y saluda apenas se queda quieto")
	await wait_seconds(1.0)
	assert_almost_eq(wrapf(character.yaw - deg_to_rad(CameraRig.YAW), -PI, PI), 0.0, 0.05, "De frente a la cámara")


## Al fallar una impresión con el personaje mirándola (acaba de usar su
## panel), se da vuelta hacia la cámara: la cara preocupada se ve.
func test_a_failed_print_turns_the_worried_face_to_the_player() -> void:
	_ready_keychain()
	_start_print()
	_controls.open_sheet(_printer())
	await wait_seconds(0.4)
	_hud.close_sheet()
	await wait_process_frames(2)
	assert_gt(absf(wrapf(_room.character.yaw - deg_to_rad(CameraRig.YAW), -PI, PI)), 0.5, "Mira la impresora, no la cámara")
	Events.print_failed.emit(Game.state.printers[0].uid, "spaghetti")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.HANDS_ON_HEAD)
	await wait_seconds(0.6)
	assert_almost_eq(wrapf(_room.character.yaw - deg_to_rad(CameraRig.YAW), -PI, PI), 0.0, 0.05, "Se da vuelta hacia la cámara")


func test_packing_from_far_away_has_no_gesture() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	_room.character.floor_position = FAR_FROM_ALL
	await wait_process_frames(2)
	_animator.reset()
	_controls.open_sheet(_room.dispatch_item)
	_controls.loop.run_sheet("pack")
	assert_eq(Game.state.find_order(FIRST).stage, Order.Stage.PACKED, "Embalar nunca obliga a caminar")
	assert_eq(_animator.current_gesture(), CharacterGestures.Gesture.NONE)


func test_the_animator_knows_the_room() -> void:
	var desk: WorldInteractable = _room.item_for(WorldInteractable.Kind.FURNITURE, Game.state.furniture[0].uid)
	assert_eq(_animator.desk_area, desk.footprint(), "Dónde está el escritorio")
	assert_eq(_animator.watch_points.size(), Game.state.printers.size(), "Los cabezales que puede mirar")
	assert_eq(_room.character.camera_yaw, deg_to_rad(CameraRig.YAW), "Hacia dónde está la cámara")
	assert_false(_animator.modeling)
	Game.advance(3.0)
	assert_true(Game.accept_offer(FIRST).ok)
	assert_true(_animator.modeling, "Modela: la cara concentrada si está cerca")
	Game.advance(10.0)
	assert_false(_animator.modeling, "Terminó de modelar")
	assert_almost_eq(_animator.game_minutes, Game.state.game_minutes, 1.0, "Sabe la hora")


## El llavero impreso, retirado y embalado, con el personaje junto al
## rincón de despacho y sin gestos.
func _packed_keychain_by_the_corner() -> void:
	_ready_keychain()
	_start_print()
	Game.advance(50.0)
	assert_true(Game.remove_pieces(Game.state.printers[0].uid).ok)
	assert_true(Game.pack_order(FIRST).ok)
	_room.character.floor_position = BY_THE_CORNER
	await wait_process_frames(3)
	_animator.reset()


func _ready_keychain() -> void:
	Game.advance(3.0)
	assert_true(Game.accept_offer(FIRST).ok)
	Game.advance(10.0)


func _start_print() -> void:
	assert_true(Game.start_print(FIRST, Game.state.printers[0].uid, Game.state.spools[0].uid, "normal").ok)


func _printer() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.PRINTER, Game.state.printers[0].uid)
