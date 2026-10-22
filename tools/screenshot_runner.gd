extends Node
## Ejecutor de tools/screenshots.gd: arma la escena principal, la lleva por
## varias situaciones y guarda una captura de cada una.
##
## La partida no corre sola: empieza siempre igual (Game.reset_game con la
## misma semilla) y solo avanza cuando el ejecutor lo pide (Game.advance), así
## cada corrida da las mismas capturas. Las del ciclo de pedidos (13 a 24) se
## juegan con los comandos de Game, como lo haría el jugador.

const MAIN_SCENE: String = "res://game/scenes/main.tscn"
## Semilla de las partidas: los mismos mensajes en cada corrida.
const SEED: int = 1234
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
## Lo más que se avanza la partida esperando que pase algo (segundos reales).
const MAX_WAIT_SECONDS: int = 600
## Lo más que se espera a que se vayan el globo de diálogo y los avisos.
const MAX_QUIET_FRAMES: int = 600

var _out: String = ""
var _main: Control
var _hud: Hud
var _controls: WorldControls
var _room: RoomView


func _init(out_dir: String) -> void:
	_out = out_dir


func _ready() -> void:
	# Ajustes en un archivo aparte, para que las pistas se vean siempre.
	UserSettings.path = "user://screenshots_settings.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(UserSettings.path))
	_run.call_deferred()


func _run() -> void:
	Game.set_process(false)
	Game.reset_game(SEED)
	_main = load(MAIN_SCENE).instantiate()
	get_tree().root.add_child(_main)
	await _frames(30)
	_hud = _main.get_node("Hud")
	_controls = _main.get_node("WorldControls")
	_room = _main.get_node("WorldView/SubViewport/Room")

	await _controls_and_screens()
	await _first_sale()
	await _orders_in_progress()
	await _failed_piece()
	get_tree().quit()


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

	# Joystick a mitad de un arrastre, caminando hacia la impresora.
	var printer: WorldInteractable = _first(WorldInteractable.Kind.PRINTER)
	var start: Vector2 = Vector2(360.0, 900.0)
	var direction: Vector2 = (_controls.world_to_ui(printer.top_center()) - _controls.world_to_ui(_room.character_focus_point())).normalized()
	_controls.tracker.press(0, start)
	_controls.tracker.drag(0, start + direction * 50.0)
	await _frames(6)
	await _capture("04_joystick")
	await _frames(40)
	_controls.tracker.release(0, start + direction * 50.0)
	await _frames(20)
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
	Game.advance(3.0)
	await _seconds(0.6)
	await _capture("13_pedidos_mensaje_nuevo")

	_hud.open_screen("orders")
	await _frames(10)
	await _capture("14_pedidos_oferta")
	var order: Order = _accept(Game.state.offers[0].uid)
	_hud.open_screen("home")

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
	_press("dispatch")
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


## 23 y 19: un pedido de varias piezas (la perilla, en PETG de la
## ferretería). La segunda pieza falla a propósito; después se reintenta y
## termina, con la primera pieza en la bandeja.
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
	_advance_until(func() -> bool: return order.stage == Order.Stage.PRINTED)
	# La partida avanzó sin que pasara tiempo real, así que el globo de alguna
	# frase de recién seguiría ahí; en el juego ya se habría ido.
	_hud.speech.hush()
	await _seconds(1.0)
	await _capture("19_pieza_lista")
	_zoom(CameraRig.DEFAULT_ZOOM_INDEX)


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


## Espera a que se vayan solos el globo de diálogo y los avisos.
func _wait_quiet() -> void:
	var toast: Control = _hud.feedback.get_node("Toast")
	for i: int in MAX_QUIET_FRAMES:
		if not toast.visible and not _hud.speech.is_talking():
			return
		await _frames(1)
	push_error("Capturas: el globo o el aviso no se fueron")


## Donde empieza el personaje en una partida nueva.
func _start_spot() -> Vector2:
	var start: Transform3D = RoomLayout.for_space(Game.state.space_id).character_spot
	return Vector2(start.origin.x, start.origin.z)


func _zoom(index: int) -> void:
	_room.camera.set_zoom_index(index)
	_hud.set_zoom_label(index)


func _place_character(spot: Vector2) -> void:
	_room.character.stop_path()
	_room.character.floor_position = _room.grid.resolve(spot)


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


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png(_out.path_join(file_name + ".png"))
