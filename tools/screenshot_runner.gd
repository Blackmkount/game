extends Node
## Ejecutor de tools/screenshots.gd: arma la escena principal, la lleva por
## varias situaciones y guarda una captura de cada una.
##
## La partida no corre sola: empieza siempre igual (Game.reset_game con la
## misma semilla) y solo avanza cuando el ejecutor lo pide (Game.advance), así
## cada corrida da las mismas capturas. Las del ciclo de pedidos (13 a 24) se
## juegan con los comandos de Game, como lo haría el jugador.
##
## El mundo avanza con paso fijo: el ejecutor apaga el _process de
## WorldControls y lo llama él mismo con 1/60 s en cada cuadro. Así lo que
## camina o se mueve no depende de lo rápido que dibuje la máquina (con
## llvmpipe un cuadro tarda mucho más que en un teléfono). El personaje
## tiene una semilla fija y lo de adorno quieto (CharacterAnimator.freeze_idle:
## sin respirar, parpadear ni gestos sueltos); sus reacciones sí se ven, y su
## tiempo solo avanza con los cuadros: mientras se espera en tiempo real (los
## avisos, el globo) queda en pausa. Cuando en el juego ya habría pasado un
## rato (se esperó que se fueran los avisos, se aceptó un pedido, la partida
## saltó horas), termina de una vez lo que estaba haciendo (_settle_character):
## así una reacción no sigue en capturas que son de otra cosa.
##
## La calidad gráfica (GraphicsQuality) la elige --quality (Alta, por
## defecto): sin eso, la automática mediría los cuadros lentos de llvmpipe y
## bajaría a Baja. 30_heroe_sin_hud_baja se saca siempre en Baja.
##
## Antes de empezar escribe manifest.txt con los nombres de las capturas que
## va a sacar; después de cada una agrega una fila a budget.csv con lo que
## contó OpenGL al dibujar el mundo y la estimación sin pantalla de
## tests/helpers/scene_budget.gd. tools/screenshots.sh falla si falta alguna
## o si el registro tiene un error.

const MAIN_SCENE: String = "res://game/scenes/main.tscn"
const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
const CalibrationBoard := preload("res://tools/calibration_board.gd")
## Semilla de las partidas: los mismos mensajes en cada corrida.
const SEED: int = 1234
## Paso del mundo en cada cuadro (segundos).
const FRAME_STEP: float = 1.0 / 60.0
## Uids de la partida nueva (GameState.new_game): la mesa del computador y la
## impresora del piso.
const DESK_UID: int = 1
const PRINTER_UID: int = 2
## Índices de zoom de CameraRig: lejos y cerca.
const ZOOM_FAR: int = 0
const ZOOM_NEAR: int = 2
## Puntos del piso donde el personaje queda lejos de todo objeto, para que
## se vean las burbujas de estado (la de cercanía las reemplaza): uno a la
## vista de la impresora y otro en medio del cuarto.
const NEAR_PRINTER_SPOT: Vector2 = Vector2(-0.3, -0.25)
const ROOM_MIDDLE_SPOT: Vector2 = Vector2(0.3, 0.2)
## Lejos de la impresora del piso, fuera del encuadre de 36 (la impresora de
## cerca, sin la manga del personaje en el borde).
const AWAY_FROM_PRINTER_SPOT: Vector2 = Vector2(-1.2, 1.2)
## Caminata con el joystick de 04 y 05: en línea recta desde el primer punto
## hasta el segundo, junto a la impresora del piso (a su izquierda en la
## pantalla, como el punto de partida). Son 1,27 m, más que
## HintFlow.WALK_DISTANCE: así se aprende la primera pista y 05 muestra la
## segunda, "Toca un objeto para verlo".
const JOYSTICK_WALK_FROM: Vector2 = Vector2(-1.1, 0.35)
const JOYSTICK_WALK_TO: Vector2 = Vector2(-1.1, -0.92)
## Cuadros de arrastre antes de la captura 04, y a qué distancia del final
## (metros) se suelta el joystick.
const JOYSTICK_FRAMES_BEFORE_04: int = 6
const JOYSTICK_ARRIVE_DISTANCE: float = 0.05
## Tiempo de animación del mundo en cada captura (RoomView.anim_time): las
## pantallas y los latidos de las marcas salen siempre en el mismo punto, con
## las marcas en su alfa más alto y la barra de la pantallita a medias.
const CAPTURE_ANIM_TIME: float = 4.8
## Lo más que se avanza la partida esperando que pase algo (segundos reales).
const MAX_WAIT_SECONDS: int = 600
## Lo más que se espera a que se vayan el globo de diálogo y los avisos.
const MAX_QUIET_FRAMES: int = 600
## Tiempo del personaje que basta para que termine cualquier reacción (la más
## larga, preocupado, dura CharacterFace.WORRIED_TIME) y su cabeza vuelva al
## frente.
const SETTLE_SECONDS: float = 4.0
## Lo más que se deja caminar al personaje con el joystick (cuadros).
const MAX_WALK_FRAMES: int = 300

## Grupos de capturas (--only=...): todas, solo las de arte (con las del
## personaje) o solo las del personaje.
const ONLY_ALL: String = "all"
const ONLY_ART: String = "art"
const ONLY_CHARACTER: String = "char"
## Lo que se puede pedir con --quality (GraphicsQuality.MODE_NAMES).
const QUALITIES: Array[String] = ["auto", "high", "low"]
## Las capturas de cada grupo, en el orden en que se sacan.
const GAME_SHOTS: Array[String] = [
	"01_inicio", "02_zoom_lejos", "03_zoom_cerca", "04_joystick", "05_cerca_de_la_impresora",
	"06_panel_impresora", "07_panel_computador", "08_panel_lugar_libre", "09_panel_puerta",
	"10_globo_personaje", "11_tienda_muebles", "12_ajustes", "13_pedidos_mensaje_nuevo",
	"14_pedidos_oferta", "16_computador_modelando", "17_plan_impresion", "18_imprimiendo",
	"20_rincon_embalar", "21_listo_despachar", "22_cobro", "15_pedidos_en_curso",
	"24_zoom_lejos_taller", "23a_fallo_reaccion", "23_fallo", "19_pieza_lista",
]
const CHARACTER_SHOTS: Array[String] = [
	"32a_personaje_frente", "32b_personaje_perfil", "32c_personaje_espalda", "33_personaje_retrato",
	"48_personaje_celebra", "49_personaje_falla", "47_perfil",
]
const ART_SHOTS: Array[String] = [
	"00_calibracion", "30_heroe_sin_hud", "30_heroe_sin_hud_baja", "31_normal_sin_hud", "34_impresora_y_escritorio", "45_pieza_creciendo_lejos",
	"36_impresora_cerca", "46_tienda_impresoras", "39_compra_imprimiendose", "42_tarde_sin_hud", "41_tarde_con_hud", "35_noche_sin_hud",
	"36b_noche", "44_alba_sin_hud", "26_familias_de_impresoras", "37_taller_lleno_sin_hud", "38_impresoras_de_cerca",
	"43_taller_lleno_noche",
]
## Columnas de budget.csv. quality: el nivel de calidad gráfica que se veía
## (high o low). gl_*: lo que contó OpenGL al dibujar el mundo
## (WorldView/SubViewport); las llamadas suman las de color y las de sombra
## (en Compatibility 4.7.2 las de sombra ya vienen dentro de las visibles).
## estimated_draw_calls: tests/helpers/scene_budget.gd sobre Room, que no
## descarta lo que queda fuera de la vista. frame_*: todo el cuadro, con la
## interfaz (lo que mostrará el panel de depuración en el teléfono).
const BUDGET_HEADER: String = "shot,window,world_view,camera_size,quality,gl_draw_calls,estimated_draw_calls,gl_primitives,gl_shadow_primitives,gl_objects,frame_draw_calls,frame_primitives"

## Encuadres de las capturas de arte. Ancho de la vista (metros) con el zoom
## cerca: el personaje de cuerpo entero y su cara con el pelo (unos 0,58 m de
## ancho, como los retratos de los prototipos).
const BODY_FRAME: float = 2.0
const PORTRAIT_FRAME: float = 1.15
## Giro del personaje (grados; 0 mira hacia +Z y la cámara mira desde +X +Z):
## de frente, de perfil y de espaldas a la cámara.
const CHARACTER_TURNS: Array[float] = [45.0, 135.0, 225.0]
## Los gestos en su punto alto: captura, gesto y cara.
const PEAK_SHOTS: Array[Array] = [
	["48_personaje_celebra", CharacterGestures.Gesture.CHEER, FacePainter.Face.HAPPY],
	["49_personaje_falla", CharacterGestures.Gesture.HANDS_ON_HEAD, FacePainter.Face.WORRIED],
]
## El cuarto entero: punto que queda al centro con el zoom lejos.
const ROOM_CENTER: Vector3 = Vector3(0.0, 0.8, 0.0)
## La impresora del piso y el escritorio, de cerca (zoom normal).
const STARS_POINT: Vector3 = Vector3(-1.55, 0.55, -1.35)
const STARS_FRAME: float = 3.4
## La impresora del piso imprimiendo, de muy cerca (zoom cerca): el punto que
## queda al centro (sobre la impresora, espacio de la impresora) y el ancho.
const PRINTER_POINT: Vector3 = Vector3(0.0, 0.3, 0.0)
const PRINTER_FRAME: float = 1.5
## La firma (39, biblia §12.2): lo que se compra aparece imprimiéndose. Una
## estantería de cubos en un lugar libre del fondo y, en el de al lado, una
## mesita (ya impresa) con una impresora, quietas en ese avance (0 a 1). El
## personaje mira desde el medio del cuarto; el encuadre, con el zoom normal.
const PURCHASE_SHELF_ID: String = "estanteria_cubos"
const PURCHASE_SHELF_SLOT: int = 2
const PURCHASE_SHELF_PROGRESS: float = 0.55
const PURCHASE_TABLE_ID: String = "mesa_auxiliar"
const PURCHASE_TABLE_SLOT: int = 3
const PURCHASE_PRINTER_ID: String = "rayo_x1"
const PURCHASE_PRINTER_PROGRESS: float = 0.5
const PURCHASE_SPOT: Vector2 = Vector2(0.35, -1.45)
const PURCHASE_LOOK: Vector2 = Vector2(-0.6, -2.6)
const PURCHASE_POINT: Vector3 = Vector3(-0.55, 0.85, -2.45)
const PURCHASE_FRAME: float = 2.8
## La pieza lista (19): los destellos quietos en este momento (s) de los
## DURATION de ReadySparkles, cuando se ven las tres estrellitas.
const SPARKLES_SHOT_TIME: float = 0.3
## Las siete familias: la del piso más dos por mesa de trabajo en los lugares
## de la pared del fondo (de frente a la cámara, para comparar siluetas).
const FAMILY_TABLE_ID: String = "mesa_trabajo"
const FAMILY_TABLES: Array[Array] = [
	[2, ["rayo_mini", "rayo_x1"]], [3, ["prisma_mc", "boveda_p1"]], [4, ["gota_r1", "titan_pro"]],
]
const FAMILIES_POINT: Vector3 = Vector3(0.4, 0.6, -2.3)
const FAMILIES_FRAME: float = 5.0
## Las estanterías del fondo del cuarto lleno, de cerca (zoom cerca).
const RACKS_POINT: Vector3 = Vector3(1.0, 0.9, -2.3)
## Donde está el personaje en el cuarto lleno: a la vista en 37 (al lado de
## la estantería del frente, no detrás) y fuera del encuadre de 38.
const FULL_ROOM_SPOT: Vector2 = Vector2(-0.6, 1.6)
## Las horas de las capturas del día (biblia §6.1): en medio de la tarde
## dorada, de la noche y el alba del día siguiente.
const GOLDEN_HOUR: float = 17.25
const NIGHT_HOUR: float = 22.0
const DAWN_HOUR: float = 5.75

var _out: String = ""
var _only: String = ONLY_ALL
var _quality: String = "high"
var _planned: Array[String] = []
var _captured: Array[String] = []
var _budget_file: FileAccess
var _main: Control
var _hud: Hud
var _controls: WorldControls
var _room: RoomView
## Punto que sigue la cámara en las capturas de arte (null: la maneja
## WorldControls, como en el juego).
var _camera_point: Variant = null
## Hacia dónde gira el personaje quieto (CharacterController.camera_yaw),
## guardado mientras está en pausa.
var _camera_yaw: float = NAN


func _init(out_dir: String, only: String, quality: String) -> void:
	_out = out_dir
	_only = only
	_quality = quality


func _ready() -> void:
	# Ajustes en un archivo aparte, para que las pistas se vean siempre, y la
	# calidad gráfica pedida.
	UserSettings.path = "user://screenshots_settings.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(UserSettings.path))
	GraphicsQuality.current = GraphicsQuality.new(UserSettings.load_settings())
	GraphicsQuality.current.set_mode(GraphicsQuality.mode_from_name(_quality))
	_run.call_deferred()


## Un paso fijo del mundo por cuadro (ver arriba).
func _process(_delta: float) -> void:
	if _controls == null:
		return
	if _camera_point == null:
		_controls._process(FRAME_STEP)
		return
	_room.camera.inset_top_px = 0.0
	_room.camera.inset_bottom_px = 0.0
	_room.camera.follow_point = _camera_point
	_room.step(FRAME_STEP)


func _run() -> void:
	if _only not in [ONLY_ALL, ONLY_ART, ONLY_CHARACTER] or _quality not in QUALITIES:
		push_error("Capturas: opciones no válidas (--only=%s, --quality=%s)" % [_only, _quality])
		get_tree().quit(1)
		return
	_planned = _planned_shots()
	_write_manifest()
	_budget_file = FileAccess.open(_out.path_join("budget.csv"), FileAccess.WRITE)
	_budget_file.store_line(BUDGET_HEADER)
	Game.set_process(false)
	Game.reset_game(SEED)
	await _load_main()

	if _only == ONLY_ALL:
		await _controls_and_screens()
		await _first_sale()
		await _orders_in_progress()
		await _failed_piece()
	await _character_shots()
	if _only != ONLY_CHARACTER:
		await _calibration()
		await _art_room_shots()
		await _purchase_printing_in()
		await _day_and_night()
		await _families_room()
		await _full_room()
	for shot: String in _planned:
		if shot not in _captured:
			push_error("Capturas: faltó %s" % shot)
	_budget_file.close()
	get_tree().quit()


func _planned_shots() -> Array[String]:
	var shots: Array[String] = []
	if _only == ONLY_ALL:
		shots.append_array(GAME_SHOTS)
	shots.append_array(CHARACTER_SHOTS)
	if _only != ONLY_CHARACTER:
		shots.append_array(ART_SHOTS)
	return shots


func _write_manifest() -> void:
	var file: FileAccess = FileAccess.open(_out.path_join("manifest.txt"), FileAccess.WRITE)
	for shot: String in _planned:
		file.store_line(shot)
	file.close()


## 01 a 12: la habitación, el zoom, el joystick, los paneles y las secciones.
func _controls_and_screens() -> void:
	await _capture("01_inicio")
	_zoom(ZOOM_FAR)
	await _frames(40)
	await _capture("02_zoom_lejos")
	_zoom(ZOOM_NEAR)
	await _frames(40)
	await _capture("03_zoom_cerca")
	_zoom(CameraRig.DEFAULT_ZOOM_INDEX)
	await _frames(30)

	# Joystick a mitad de un arrastre, caminando hacia la impresora. Se
	# suelta al llegar junto a ella.
	_place_character(JOYSTICK_WALK_FROM)
	await _frames(30)
	var printer: WorldInteractable = _first(WorldInteractable.Kind.PRINTER)
	var start: Vector2 = Vector2(360.0, 900.0)
	var knob: Vector2 = start + _ui_direction(JOYSTICK_WALK_FROM, JOYSTICK_WALK_TO) * 50.0
	_controls.tracker.press(0, start)
	_controls.tracker.drag(0, knob)
	await _frames(JOYSTICK_FRAMES_BEFORE_04)
	await _capture("04_joystick")
	await _walk_until_near(JOYSTICK_WALK_TO)
	_controls.tracker.release(0, knob)
	await _frames(20)
	if _hud.move_hint.mode != MoveHint.Mode.TAP:
		push_error("Capturas: en 05 tiene que verse la pista de tocar un objeto")
	await _capture("05_cerca_de_la_impresora")

	_controls.open_sheet(printer)
	await _frames(30)
	await _capture("06_panel_impresora")
	_hud.close_sheet()
	await _frames(20)

	_controls.open_sheet(_first(WorldInteractable.Kind.FURNITURE))
	await _frames(30)
	await _capture("07_panel_computador")
	_controls.open_sheet(_first(WorldInteractable.Kind.SLOT))
	await _frames(30)
	await _capture("08_panel_lugar_libre")
	_controls.open_sheet(_first(WorldInteractable.Kind.DOOR))
	await _frames(30)
	await _capture("09_panel_puerta")
	_hud.close_sheet()
	await _frames(20)

	_hud.speech.say(TranslationServer.translate("CHARACTER_LINE_1"))
	await _frames(10)
	await _capture("10_globo_personaje")

	_hud.open_screen("shop", "furniture")
	await _frames(10)
	await _capture("11_tienda_muebles")
	_hud.open_screen("settings")
	await _frames(10)
	await _capture("12_ajustes")
	_hud.open_screen("home")


## 13, 14, 16, 17, 18, 20, 21 y 22: la primera venta, el llavero, desde el
## mensaje hasta el cobro.
func _first_sale() -> void:
	await _new_game(_start_spot())
	# Llega el mensaje: mira el celular (en su punto alto).
	Game.advance(3.0)
	_advance_character(CharacterGestures.Gesture.PHONE)
	await _seconds(0.6)
	await _capture("13_pedidos_mensaje_nuevo")

	_hud.open_screen("orders")
	await _frames(10)
	await _capture("14_pedidos_oferta")
	var order: Order = _accept(Game.state.offers[0].uid)
	_hud.open_screen("home")
	# Leer y aceptar el pedido lleva unos segundos: el celular ya se guardó.
	_settle_character()

	Game.advance(4.0)
	_controls.open_sheet(_room.item_for(WorldInteractable.Kind.FURNITURE, DESK_UID))
	await _frames(30)
	await _capture("16_computador_modelando")
	_hud.close_sheet()

	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	_controls.open_sheet(_printer_item())
	await _frames(30)
	await _capture("17_plan_impresion")

	_press("print")
	await _frames(2)
	_hud.close_sheet()
	_place_character(NEAR_PRINTER_SPOT)
	_zoom(ZOOM_NEAR)
	Game.advance(25.0)
	await _frames(40)
	await _capture("18_imprimiendo")

	_advance_until(func() -> bool: return order.stage == Order.Stage.PRINTED)
	# Hasta que el jugador vuelve a la impresora, el pulgar arriba de la
	# impresión que terminó ya pasó (ese momento es la captura 19).
	_settle_character()
	_zoom(CameraRig.DEFAULT_ZOOM_INDEX)
	_place_character(_start_spot())
	_controls.open_sheet(_printer_item())
	await _frames(20)
	_press("remove")
	await _frames(40)
	await _capture("20_rincon_embalar")
	_press("pack")
	await _frames(30)
	await _capture("21_listo_despachar")
	# El festejo (puño arriba) en su punto alto, con lo cobrado volando.
	_press("dispatch")
	_advance_character(CharacterGestures.Gesture.CHEER)
	await _seconds(0.35)
	await _capture("22_cobro")
	_hud.close_sheet()


## 15 y 24: tres pedidos en curso, cada uno en otro paso (uno embalado, otro
## imprimiéndose y otro modelándose), en Pedidos y en el cuarto desde lejos.
func _orders_in_progress() -> void:
	await _new_game(ROOM_MIDDLE_SPOT)
	Game.advance(3.0)
	var first: Order = _accept(Game.state.offers[0].uid)
	_advance_until(func() -> bool: return first.stage == Order.Stage.READY_TO_PRINT)
	_print_recommended(first)
	_advance_until(func() -> bool: return not Game.state.offers.is_empty())
	var second: Order = _accept(Game.state.offers[0].uid)
	_advance_until(func() -> bool: return second.stage == Order.Stage.READY_TO_PRINT)
	_check(Game.remove_pieces(PRINTER_UID))
	_check(Game.pack_order(first.uid))
	_print_recommended(second)
	_advance_until(func() -> bool: return not Game.state.offers.is_empty())
	_accept(Game.state.offers[0].uid)
	Game.advance(4.0)

	_hud.open_screen("orders")
	await _frames(10)
	await _capture("15_pedidos_en_curso")
	_hud.open_screen("home")
	_zoom(ZOOM_FAR)
	await _frames(40)
	await _capture("24_zoom_lejos_taller")


## 23a, 23 y 19: un pedido de varias piezas (la perilla, en PETG de la
## ferretería). La segunda pieza falla a propósito (23a: en ese momento, el
## personaje se agarra la cabeza); después se reintenta y termina, con la
## primera pieza en la bandeja.
func _failed_piece() -> void:
	await _new_game(_start_spot())
	_check(Game.buy_local_material("petg"))
	# La perilla pide nivel 2: el mensaje se agrega a mano, como si ya lo
	# hubiera mandado el tablero.
	var offer: OrderOffer = OrderOffer.new(Game.state.take_uid(), "perilla", Game.state.game_seconds)
	Game.state.offers.append(offer)
	var order: Order = _accept(offer.uid)
	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	_print_recommended(order)
	# Desde el mismo lugar y zoom que "18_imprimiendo", para comparar la
	# pieza fallida y la terminada con la que se está imprimiendo.
	_place_character(NEAR_PRINTER_SPOT)
	_zoom(ZOOM_NEAR)
	_advance_until(func() -> bool: return order.pieces_done == 1)
	Game.advance(20.0)
	# Como en una partida ya avanzada: las piezas de regalo de Don Ernesto ya
	# pasaron, así el panel de la falla muestra el riesgo de verdad.
	Game.state.pieces_started = Game.rules.grace_pieces
	DebugTools.force_fail(Game.sim, PRINTER_UID, FailureRules.SPAGHETTI)
	var printer: OwnedPrinter = Game.state.find_printer(PRINTER_UID)
	_advance_until(func() -> bool: return printer.job.status == PrintJob.Status.FAILED)
	# Lo que se ve al fallar: las manos a la cabeza en su punto alto, el globo
	# y el retrato del HUD preocupado (con la cámara ya en el zoom de 23).
	_advance_character(CharacterGestures.Gesture.HANDS_ON_HEAD)
	_room.camera.snap_to_goal()
	await _seconds(0.35)
	await _capture("23a_fallo_reaccion")
	# El jugador lee "¡Nooo! Un espagueti." y después toca la impresora: así
	# el globo no tapa la pieza fallida.
	await _wait_quiet()
	_controls.open_sheet(_printer_item())
	await _frames(30)
	await _capture("23_fallo")

	# El reintento vuelve a ser de regalo para que no falle al azar: la
	# captura 19 necesita la pieza terminada.
	Game.state.pieces_started = 0
	_press("retry")
	await _frames(2)
	_hud.close_sheet()
	# Un cuadro sin el panel (el personaje lo sabe en cada cuadro): así el
	# pulgar arriba es para el jugador, de frente a la cámara.
	await _frames(1)
	_advance_until(func() -> bool: return order.stage == Order.Stage.PRINTED)
	# La partida avanzó sin que pasara tiempo real, así que el globo de alguna
	# frase de recién seguiría ahí; en el juego ya se habría ido.
	_hud.speech.hush()
	# Junto a la impresora que terminó, el pulgar arriba (se da vuelta hacia
	# la cámara y mira la impresora de reojo).
	_advance_character(CharacterGestures.Gesture.THUMBS_UP)
	await _seconds(1.0)
	# Los destellos de "lista" duran 0,6 s reales y ya pasaron: se muestran
	# quietos en su mejor momento, donde salieron.
	var sparkles: ReadySparkles = _room.get_node("Printer%d/PieceSpot/Sparkles" % PRINTER_UID)
	sparkles.hold(SPARKLES_SHOT_TIME)
	await _capture("19_pieza_lista")
	sparkles.stop()
	_zoom(CameraRig.DEFAULT_ZOOM_INDEX)


## 32a, 32b, 32c y 33: el personaje sin interfaz, de cuerpo entero de frente,
## de perfil y de espaldas, y la cara de muy cerca. La cámara lo sigue a él y
## no a WorldControls, así nada cercano le cambia la mirada. 48 y 49: de
## frente, los gestos de cobrar (puño arriba y feliz) y de una falla (manos a
## la cabeza y preocupado), quietos en su punto alto. 47: la pantalla de
## perfil, con su retrato de cuerpo entero.
func _character_shots() -> void:
	await _new_game(ROOM_MIDDLE_SPOT)
	_hud.visible = false
	var character: CharacterController = _room.character
	character.look_target = null
	var base: float = _base_size()
	_zoom(ZOOM_NEAR)
	_room.camera.set_base_size(BODY_FRAME)
	for i: int in CHARACTER_TURNS.size():
		_turn_character(CHARACTER_TURNS[i])
		_camera_point = character.model.position + Vector3(0.0, CharacterModel.HEIGHT / 2.0, 0.0)
		await _frames(40)
		await _capture(CHARACTER_SHOTS[i])
	_turn_character(CHARACTER_TURNS[0])
	_room.camera.set_base_size(PORTRAIT_FRAME)
	_camera_point = _head_center()
	await _frames(40)
	await _capture("33_personaje_retrato")
	_room.camera.set_base_size(BODY_FRAME)
	_camera_point = character.model.position + Vector3(0.0, CharacterModel.HEIGHT / 2.0, 0.0)
	for shot: Array in PEAK_SHOTS:
		character.animator.hold(shot[1], shot[2])
		await _frames(20)
		await _capture(shot[0])
	character.animator.release()
	await _back_to_game(base)
	_hud.open_screen("profile")
	await _frames(30)
	await _capture("47_perfil")
	_hud.open_screen("home")
	await _frames(10)


## 00: el modelo de color (tools/calibration_board.gd). Falla si los píxeles
## no dan lo que dice la biblia de arte §2.4.
func _calibration() -> void:
	var board: CalibrationBoard = CalibrationBoard.new()
	add_child(board)
	await board.render_all()
	await _frames(2)
	await _capture("00_calibracion")
	for problem: String in board.problems:
		push_error("Capturas: calibración: " + problem)
	board.queue_free()
	_room.day_cycle.set_hour(Game.state.game_minutes / GameClock.MINUTES_PER_HOUR)
	await _frames(2)


## 30, 31, 34, 45, 36 y 46: el cuarto inicial a las 08:00 sin interfaz
## (entero y con el zoom normal), las dos estrellas de cerca, la pieza que
## crece vista desde lejos y de muy cerca (capas y capa caliente), y la tienda
## de impresoras.
func _art_room_shots() -> void:
	await _new_game(_start_spot())
	_hud.visible = false
	var base: float = _base_size()
	_zoom(ZOOM_FAR)
	_camera_point = ROOM_CENTER
	await _frames(40)
	await _capture("30_heroe_sin_hud")
	# El mismo cuarto con la calidad Baja (sin sombra del sol, menos píxeles y
	# suavizado; ColorProbe vuelve a medir) y de vuelta a la pedida.
	GraphicsQuality.current.set_mode(GraphicsQuality.Mode.LOW)
	await _frames(40)
	await _capture("30_heroe_sin_hud_baja")
	GraphicsQuality.current.set_mode(GraphicsQuality.mode_from_name(_quality))
	await _frames(10)
	_camera_point = null
	_zoom(CameraRig.DEFAULT_ZOOM_INDEX)
	await _frames(40)
	await _capture("31_normal_sin_hud")
	_room.camera.set_base_size(STARS_FRAME)
	_camera_point = STARS_POINT
	await _frames(40)
	await _capture("34_impresora_y_escritorio")
	await _back_to_game(base)

	# La capa caliente tiene que leerse aun con el zoom lejos.
	Game.advance(3.0)
	var order: Order = _accept(Game.state.offers[0].uid)
	_advance_until(func() -> bool: return order.stage == Order.Stage.READY_TO_PRINT)
	_print_recommended(order)
	Game.advance(25.0)
	_hud.speech.hush()
	await _wait_quiet()
	_hud.visible = false
	_place_character(ROOM_MIDDLE_SPOT)
	_zoom(ZOOM_FAR)
	await _frames(40)
	await _capture("45_pieza_creciendo_lejos")
	_zoom(ZOOM_NEAR)
	_place_character(AWAY_FROM_PRINTER_SPOT)
	_room.camera.set_base_size(PRINTER_FRAME)
	_camera_point = _room.get_node("Printer%d" % PRINTER_UID).global_transform * PRINTER_POINT
	await _frames(40)
	await _capture("36_impresora_cerca")
	await _back_to_game(base)

	_hud.open_screen("shop", "printers")
	await _frames(10)
	await _capture("46_tienda_impresoras")
	_hud.open_screen("home")


## 39: lo que se compra aparece imprimiéndose en su lugar (biblia §12.2). Se
## agregan al estado como lo hará el comando de compra (Fase 1, tarea 5) y el
## cuarto los arma con su efecto (RoomView.sync_models); la mesita termina y
## la estantería y la impresora quedan quietas a mitad (PURCHASE_*). La
## partida nueva que sigue los quita (también con sync_models, sin efecto).
func _purchase_printing_in() -> void:
	await _new_game(PURCHASE_SPOT)
	var base: float = _base_size()
	var state: GameState = Game.state
	var shelf: OwnedFurniture = OwnedFurniture.new(state.take_uid(), PURCHASE_SHELF_ID, PURCHASE_SHELF_SLOT)
	state.furniture.append(shelf)
	var table: OwnedFurniture = OwnedFurniture.new(state.take_uid(), PURCHASE_TABLE_ID, PURCHASE_TABLE_SLOT)
	state.furniture.append(table)
	var printer: OwnedPrinter = OwnedPrinter.new(state.take_uid(), PURCHASE_PRINTER_ID, table.uid)
	state.printers.append(printer)
	_room.sync_models()
	_room.print_in_of(_room.get_node("Furniture%d" % shelf.uid)).hold(PURCHASE_SHELF_PROGRESS)
	_room.print_in_of(_room.get_node("Furniture%d" % table.uid)).finish()
	_room.print_in_of(_room.get_node("Printer%d" % printer.uid)).hold(PURCHASE_PRINTER_PROGRESS)
	_hud.visible = false
	_room.character.face(PURCHASE_LOOK)
	_room.camera.set_base_size(PURCHASE_FRAME)
	_camera_point = PURCHASE_POINT
	await _frames(40)
	await _capture("39_compra_imprimiendose")
	_room.finish_print_ins()
	await _back_to_game(base)


## 42, 41, 35, 36b y 44: el cuarto inicial a otras horas (biblia §6). La
## tarde dorada y la noche, enteras sin interfaz y con el zoom normal y la
## interfaz (lo que ve el jugador, con el personaje junto al escritorio), y
## el alba del día siguiente. El reloj avanza de verdad: en el camino llegan
## mensajes.
func _day_and_night() -> void:
	await _new_game(_start_spot())
	var base: float = _base_size()
	await _advance_to_hour(GOLDEN_HOUR)
	await _whole_room_shot("42_tarde_sin_hud", base)
	await _capture("41_tarde_con_hud")
	await _advance_to_hour(NIGHT_HOUR)
	await _whole_room_shot("35_noche_sin_hud", base)
	await _capture("36b_noche")
	await _advance_to_hour(DAWN_HOUR)
	await _whole_room_shot("44_alba_sin_hud", base)


## El cuarto entero sin interfaz (como 30) y después de vuelta al juego.
func _whole_room_shot(file_name: String, base_size: float) -> void:
	_hud.visible = false
	_zoom(ZOOM_FAR)
	_camera_point = ROOM_CENTER
	await _frames(40)
	await _capture(file_name)
	await _back_to_game(base_size)


## Adelanta la partida hasta la próxima vez que el reloj marque `hour` (lo
## que pasa en el camino pasa: llegan mensajes) y deja la luz de esa hora de
## una vez, sin esperar su mezcla. El personaje vuelve a donde empieza y,
## como el jugador que lee los avisos, se espera a que se vayan.
func _advance_to_hour(hour: float) -> void:
	var minutes: float = fposmod(hour * GameClock.MINUTES_PER_HOUR - Game.state.game_minutes, GameClock.MINUTES_PER_DAY)
	Game.advance(minutes * GameClock.SECONDS_PER_MINUTE / Game.rules.game_seconds_per_real_second)
	_room.day_cycle.set_hour(Game.state.game_minutes / GameClock.MINUTES_PER_HOUR)
	_hud.speech.hush()
	await _wait_quiet()
	_place_character(_start_spot())
	_turn_character(CHARACTER_TURNS[0])
	await _frames(30)


## 26: una impresora de cada familia en el cuarto (la del piso y dos por mesa
## de trabajo en la pared del fondo), para comparar sus siluetas.
func _families_room() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	for table: Array in FAMILY_TABLES:
		var furniture: OwnedFurniture = OwnedFurniture.new(state.take_uid(), FAMILY_TABLE_ID, int(table[0]))
		state.furniture.append(furniture)
		for printer_id: String in table[1]:
			state.printers.append(OwnedPrinter.new(state.take_uid(), printer_id, furniture.uid))
	await _rebuild_main(state)
	_hud.visible = false
	_place_character(ROOM_MIDDLE_SPOT)
	_room.camera.set_base_size(FAMILIES_FRAME)
	_camera_point = FAMILIES_POINT
	await _frames(40)
	await _capture("26_familias_de_impresoras")


## 37 y 38: el cuarto más cargado (el mismo que mide la prueba de
## presupuesto), entero y con las estanterías de cerca.
func _full_room() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	DebugTools.fill_workshop(state, Game.rules)
	await _rebuild_main(state)
	_hud.visible = false
	_place_character(FULL_ROOM_SPOT)
	_zoom(ZOOM_FAR)
	_camera_point = ROOM_CENTER
	await _frames(40)
	await _capture("37_taller_lleno_sin_hud")
	_zoom(ZOOM_NEAR)
	_camera_point = RACKS_POINT
	await _frames(40)
	await _capture("38_impresoras_de_cerca")

	# 43: el mismo taller, guardado de noche y ya en el nivel del taller, con
	# impresoras en cada estado. Se carga como una partida (la luz de la hora,
	# sin mezcla).
	state = GameState.new_game(Game.rules, SEED)
	DebugTools.fill_workshop(state, Game.rules)
	state.game_seconds = roundi(NIGHT_HOUR * GameClock.SECONDS_PER_HOUR)
	state.xp = Game.rules.levels.thresholds[DebugTools.WORKSHOP_LEVEL - 1]
	DebugTools.give_jobs(state, Game.rules)
	await _rebuild_main(state)
	_hud.visible = false
	_place_character(FULL_ROOM_SPOT)
	_zoom(ZOOM_FAR)
	_camera_point = ROOM_CENTER
	await _frames(40)
	await _capture("43_taller_lleno_noche")


## Vuelve a crear la escena principal con `state`, como al cargar la partida
## (el cuarto se arma una sola vez, al crear la escena).
func _rebuild_main(state: GameState) -> void:
	_controls = null
	_camera_point = null
	_main.queue_free()
	await _frames(1)
	Game._start(state)
	await _load_main()


func _load_main() -> void:
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	get_tree().root.add_child(_main)
	_hud = _main.get_node("Hud")
	_room = _main.get_node("WorldView/SubViewport/Room")
	_controls = _main.get_node("WorldControls")
	# Desde aquí lo mueve el ejecutor, con paso fijo (ver _process).
	_controls.set_process(false)
	if _room.character != null:
		_room.character.animator.reseed(SEED)
		_room.character.animator.freeze_idle = true
	await _frames(30)


## Empieza la misma partida nueva, de vuelta en la habitación con el zoom
## normal y el personaje en `spot`, cuando ya no queda nada de la anterior en
## pantalla (avisos ni globos).
func _new_game(spot: Vector2) -> void:
	_hud.open_screen("home")
	_hud.speech.hush()
	await _wait_quiet()
	Game.reset_game(SEED)
	_zoom(CameraRig.DEFAULT_ZOOM_INDEX)
	_place_character(spot)
	await _frames(30)


## Después de una captura de arte: la cámara y la interfaz como en el juego.
func _back_to_game(base_size: float) -> void:
	_camera_point = null
	_room.camera.set_base_size(base_size)
	_zoom(CameraRig.DEFAULT_ZOOM_INDEX)
	_hud.visible = true
	await _frames(30)


## Espera a que se vayan solos el globo de diálogo y los avisos (en tiempo
## real: el personaje queda en pausa). Después el personaje termina lo que
## estaba haciendo, como en el juego mientras uno lee (y como el retrato del
## HUD, que cuenta en tiempo real).
func _wait_quiet() -> void:
	var toast: Control = _hud.feedback.get_node("Toast")
	_pause_character(true)
	for i: int in MAX_QUIET_FRAMES:
		if not toast.visible and not _hud.speech.is_talking():
			_pause_character(false)
			_settle_character()
			return
		await _frames(1)
	_pause_character(false)
	push_error("Capturas: el globo o el aviso no se fueron")


## Donde empieza el personaje en una partida nueva.
func _start_spot() -> Vector2:
	var start: Transform3D = RoomLayout.for_space(Game.state.space_id).character_spot
	return Vector2(start.origin.x, start.origin.z)


## Ancho de la vista con el zoom 1× (lo que cambian las capturas de arte).
func _base_size() -> float:
	return _room.camera.size * _room.camera.zoom


func _zoom(index: int) -> void:
	_room.camera.set_zoom_index(index)
	_hud.set_zoom_label(index)


func _place_character(spot: Vector2) -> void:
	_room.character.stop_path()
	_room.character.floor_position = _room.grid.resolve(spot)


## Gira al personaje (grados; 0 mira hacia +Z) mirando un punto del piso.
func _turn_character(degrees: float) -> void:
	var character: CharacterController = _room.character
	var angle: float = deg_to_rad(degrees)
	character.face(character.floor_position + Vector2(sin(angle), cos(angle)))


## Dirección en la pantalla de un punto del piso hacia otro (con el joystick
## alineado a la pantalla, el personaje camina justo por esa línea).
func _ui_direction(from: Vector2, to: Vector2) -> Vector2:
	var from_ui: Vector2 = _controls.world_to_ui(Vector3(from.x, 0.0, from.y))
	var to_ui: Vector2 = _controls.world_to_ui(Vector3(to.x, 0.0, to.y))
	return (to_ui - from_ui).normalized()


## Deja correr cuadros, con el joystick empujado, hasta que el personaje
## llega cerca de `spot`.
func _walk_until_near(spot: Vector2) -> void:
	for i: int in MAX_WALK_FRAMES:
		if _room.character.floor_position.distance_to(spot) <= JOYSTICK_ARRIVE_DISTANCE:
			return
		await _frames(1)
	push_error("Capturas: el personaje no llegó caminando a %s" % spot)


## Centro de la cabeza (de sus mallas, o del pivote si no tiene).
func _head_center() -> Vector3:
	var head: Node3D = _room.character.model.get_node("Body/Head")
	return head.global_transform * PropBounds.local_aabb(head).get_center()


func _printer_item() -> WorldInteractable:
	return _room.item_for(WorldInteractable.Kind.PRINTER, PRINTER_UID)


func _accept(offer_uid: int) -> Order:
	_check(Game.accept_offer(offer_uid))
	return Game.state.find_order(offer_uid)


## Imprime el pedido con lo que recomienda el plan.
func _print_recommended(order: Order) -> void:
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	_check(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id))


## Toca un botón del panel abierto, como el jugador.
func _press(action_id: String) -> void:
	var sheet: BottomSheet = _hud.current_sheet()
	var button: Button = sheet.find_child("Action_" + action_id, true, false) if sheet != null else null
	if button == null or button.disabled:
		push_error("Capturas: no se puede tocar " + action_id)
		return
	button.pressed.emit()


## Avanza la partida de a un segundo real hasta que pase lo que se espera.
func _advance_until(condition: Callable) -> void:
	for i: int in MAX_WAIT_SECONDS:
		if condition.call():
			return
		Game.advance(1.0)
	push_error("Capturas: no pasó lo que se esperaba")


func _check(result: CommandResult) -> void:
	if not result.ok:
		push_error("Capturas: no se pudo (%s)" % result.reason)


func _first(kind: WorldInteractable.Kind) -> WorldInteractable:
	for item: WorldInteractable in _room.interactables:
		if item.kind == kind:
			return item
	return null


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


## Espera en tiempo real, con el personaje en pausa.
func _seconds(seconds: float) -> void:
	_pause_character(true)
	await get_tree().create_timer(seconds).timeout
	_pause_character(false)


## Adelanta al personaje (su giro y su animación), sin dibujar, hasta el
## punto alto de ese gesto (el que acaba de empezar una reacción): así se ve
## junto a lo que pasa en tiempo real (lo cobrado que vuela, los avisos).
func _advance_character(gesture: CharacterGestures.Gesture) -> void:
	for i: int in ceili(CharacterGestures.peak_of(gesture) / FRAME_STEP):
		_room.character.step(FRAME_STEP)


## Termina de una vez, sin dibujar, el gesto, la cara y la mirada que tenga
## el personaje (SETTLE_SECONDS de su tiempo).
func _settle_character() -> void:
	if _room.character == null:
		return
	for i: int in ceili(SETTLE_SECONDS / FRAME_STEP):
		_room.character.animator.step(FRAME_STEP)


## Pausa (o no) el tiempo del personaje: su animación y su giro hacia la
## cámara cuando está quieto. Pausar dos veces seguidas no pierde el giro.
func _pause_character(paused: bool) -> void:
	var character: CharacterController = _room.character
	if character == null or character.animator.paused == paused:
		return
	character.animator.paused = paused
	if paused:
		_camera_yaw = character.camera_yaw
	character.camera_yaw = NAN if paused else _camera_yaw


## El nivel de calidad gráfica que se ve ahora ("high" o "low").
func _level_name() -> String:
	return "low" if GraphicsQuality.current.level == GraphicsQuality.Level.LOW else "high"


## Guarda la captura (con la interfaz) y anota lo que costó dibujar el mundo.
func _capture(file_name: String) -> void:
	if file_name not in _planned:
		push_error("Capturas: %s no está en el manifiesto" % file_name)
	_room.anim_time = CAPTURE_ANIM_TIME
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png(_out.path_join(file_name + ".png"))
	_captured.append(file_name)
	var sub: SubViewport = _main.get_node("WorldView/SubViewport")
	var visible_type: Viewport.RenderInfoType = Viewport.RENDER_INFO_TYPE_VISIBLE
	var shadow_type: Viewport.RenderInfoType = Viewport.RENDER_INFO_TYPE_SHADOW
	var estimate: RefCounted = SceneBudget.measure(_room)
	var window: Vector2i = get_tree().root.size
	_budget_file.store_line("%s,%dx%d,%dx%d,%.3f,%s,%d,%d,%d,%d,%d,%d,%d" % [
		file_name, window.x, window.y, sub.size.x, sub.size.y, _room.camera.size, _level_name(),
		sub.get_render_info(visible_type, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			+ sub.get_render_info(shadow_type, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		estimate.get("draw_calls"),
		sub.get_render_info(visible_type, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		sub.get_render_info(shadow_type, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		sub.get_render_info(visible_type, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	_budget_file.flush()
