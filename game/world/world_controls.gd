class_name WorldControls
extends Control
## Controles del mundo: recibe los toques que no caen sobre la interfaz y los
## convierte en movimiento del personaje, zoom y paneles de los objetos.
## También decide el orden de cada cuadro: personaje, cámara y lo que la
## interfaz dibuja encima del mundo (joystick, burbuja, globo, pistas).
##
## Las partes que se pueden separar viven aparte: TouchTracker (gestos),
## StickMapping (dirección en el piso), KeyBindings (teclado), HintFlow
## (pistas), ReachTracker (cercanía) y, como hijos de este nodo, el ciclo de
## pedidos: OrderLoopController (lo que hacen los paneles, las tarjetas y la
## burbuja de cercanía), StatusPresenter (las burbujas de estado) y
## LoopFeedback (lo que se celebra y lo que dice el personaje).
##
## Está entre la vista del mundo y el HUD. El HUD, que va encima, se queda con
## los toques sobre sus botones; el resto llega aquí. Una vez que un dedo
## empezó un gesto en el mundo, sus arrastres siguen llegando aquí aunque pase
## por encima de un botón.
##
## Regla de oro: el personaje es solo presentación. Todo lo que es información
## o una decisión se puede hacer tocando, sin caminar.

## Índice reservado para el mouse, que se trata como un dedo más: un clic es
## un toque y arrastrar es el joystick.
const MOUSE_INDEX: int = -100
## Lado mínimo (píxeles de la interfaz) de lo que se puede tocar en el mundo.
const MIN_TOUCH_PX: float = 88.0
## Cantidad de frases graciosas del personaje (CHARACTER_LINE_1...).
const CHARACTER_LINES: int = 6

var tuning: ControlsTuning
var tracker: TouchTracker
var reach: ReachTracker
var room: RoomView
var hud: Hud
var world_view: WorldViewport
## Lleva las acciones del ciclo de pedidos (paneles, tarjetas de Pedidos y
## burbuja de cercanía) a Game.
var loop: OrderLoopController
## Burbujas de estado sobre los objetos y qué muestra la burbuja de cercanía.
var status: StatusPresenter
## Lo que se cobra vuela al HUD; el personaje comenta y recuerda.
var loop_feedback: LoopFeedback
## Objeto resaltado por cercanía (o null).
var highlighted: WorldInteractable = null
## Objeto con el panel abierto (o null).
var sheet_item: WorldInteractable = null
## Qué hace "atrás" cuando ya no queda nada que cerrar. Las pruebas lo cambian
## para que no se cierre el programa de pruebas.
var quit_game: Callable = func() -> void: get_tree().quit()

var _hints: HintFlow
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _wheel_cooldown: float = 0.0
var _was_pinching: bool = false
var _ready_done: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tuning = ControlsTuning.current
	tracker = TouchTracker.new(tuning)
	reach = ReachTracker.new(tuning)
	_rng.randomize()
	# El botón "atrás" de Android cierra primero el panel o la pantalla abierta.
	get_tree().quit_on_go_back = false
	get_window().focus_exited.connect(_cancel_gestures)
	KeyBindings.ensure()
	# El HUD todavía no está listo: termina de armarse al final del cuadro.
	_setup.call_deferred()


func _setup() -> void:
	world_view = get_node("../WorldView")
	room = get_node("../WorldView/SubViewport/Room")
	hud = get_node("../Hud")
	hud.sheet_closed.connect(_on_sheet_closed)
	hud.screen_changed.connect(_on_screen_changed)
	hud.zoom_pressed.connect(_cycle_zoom)
	hud.set_zoom_label(room.camera.zoom_index)
	room.models_changed.connect(_on_models_changed)
	_hints = HintFlow.new(UserSettings.load_settings())
	hud.move_hint.set_mode(_hints.mode())
	loop = OrderLoopController.new(self)
	loop.name = "OrderLoop"
	add_child(loop)
	status = StatusPresenter.new(self)
	status.name = "StatusPresenter"
	add_child(status)
	loop_feedback = LoopFeedback.new(self)
	loop_feedback.name = "LoopFeedback"
	add_child(loop_feedback)
	_ready_done = true


func _process(delta: float) -> void:
	if not _ready_done:
		return
	var playing: bool = hud.current_screen_id() == "home"
	var character: CharacterController = room.character
	var stick: Vector2 = Vector2.ZERO
	if playing:
		stick = tracker.joystick_vector()
		if stick == Vector2.ZERO:
			stick = KeyBindings.move_vector()
	if character != null:
		character.stick = StickMapping.to_floor(stick, room.camera.basis, tuning.joystick_screen_aligned)
		if stick != Vector2.ZERO:
			# Caminar cierra el panel abierto.
			if hud.has_sheet():
				hud.close_sheet()
		# Mueve la boca mientras se ve el globo; con un panel o una pantalla
		# abierta no saca el celular ni hace gestos sueltos.
		character.animator.talking = hud.speech.is_talking()
		character.animator.panel_open = hud.has_sheet() or not playing
	_update_pinch()
	_wheel_cooldown = maxf(_wheel_cooldown - delta, 0.0)

	var insets: Vector2 = hud.world_insets() * world_view.view_per_ui
	room.camera.inset_top_px = insets.x
	room.camera.inset_bottom_px = insets.y
	if sheet_item != null:
		room.camera.follow_point = sheet_item.top_center()
	elif character != null:
		room.camera.follow_point = room.character_focus_point()
	var walked_before: float = character.distance_walked if character != null else 0.0
	room.step(delta)
	if character != null:
		if stick != Vector2.ZERO:
			_hints.add_walk(character.distance_walked - walked_before)
		_update_reach()
	_update_overlays()
	_update_hints()


## Punto de la interfaz → píxel del dibujo del mundo.
func ui_to_view(ui_position: Vector2) -> Vector2:
	return world_view.ui_to_view(ui_position + global_position)


## Punto del mundo → punto de la interfaz.
func world_to_ui(point: Vector3) -> Vector2:
	return world_view.view_to_ui(room.camera.unproject_position(point)) - global_position


## Abre el panel de un objeto. El personaje se gira a mirarlo.
func open_sheet(item: WorldInteractable) -> void:
	if room.character == null:
		return
	var sheet: BottomSheet = loop.build_sheet(item)
	if sheet == null:
		return
	sheet_item = item
	hud.show_sheet(sheet)
	room.set_highlight(item)
	room.character.stop_path()
	var center: Vector3 = item.bounds.get_center()
	room.character.face(Vector2(center.x, center.z))
	_hints.sheet_opened()


## Toque en el mundo (píxeles de la interfaz). Primero las burbujas: la de
## cercanía (va encima) corre su acción o abre el panel; una de estado abre el
## panel de su objeto, a cualquier distancia. Después, los objetos y el piso.
func tap(ui_position: Vector2) -> void:
	# Sin partida (datos con errores) no hay personaje ni objetos que tocar.
	if hud.current_screen_id() != "home" or room.character == null:
		return
	var point: Vector2 = ui_position + global_position
	if hud.bubble.visible and highlighted != null and hud.bubble.get_global_rect().has_point(point):
		_use_nearby()
		return
	var bubble_item: WorldInteractable = hud.status_bubbles.hit(point)
	if bubble_item != null:
		open_sheet(bubble_item)
		return
	var view_position: Vector2 = ui_to_view(ui_position)
	var item: WorldInteractable = room.pick(view_position, MIN_TOUCH_PX * world_view.view_per_ui)
	if hud.has_sheet():
		# Con un panel abierto, tocar otro objeto cambia el panel; tocar
		# cualquier otra cosa lo cierra (y no camina).
		if item != null and item != sheet_item and item.kind != WorldInteractable.Kind.CHARACTER:
			open_sheet(item)
		else:
			hud.close_sheet()
		return
	if item == null:
		var floor_at: Variant = room.floor_point(view_position)
		if floor_at != null and room.character.walk_to(floor_at):
			room.show_destination(room.character.path_end())
			_hints.walked_by_tap()
		return
	if item.kind == WorldInteractable.Kind.CHARACTER:
		# Se da vuelta, saluda y dice algo gracioso.
		room.character.face_camera()
		room.character.animator.react(CharacterAnimator.Reaction.TAPPED)
		hud.speech.say(tr("CHARACTER_LINE_%d" % _rng.randi_range(1, CHARACTER_LINES)))
		return
	open_sheet(item)


func _gui_input(event: InputEvent) -> void:
	if not _ready_done or hud.current_screen_id() != "home":
		return
	# Al tocar la pantalla, el sistema también inventa eventos de mouse: se
	# ignoran para no contar dos veces el mismo dedo.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.canceled:
			_cancel_gestures()
		elif touch.pressed:
			_press(touch.index, touch.position)
		else:
			_release(touch.index, touch.position)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		tracker.drag(drag.index, drag.position)
		accept_event()
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_press(MOUSE_INDEX, button.position)
			else:
				_release(MOUSE_INDEX, button.position)
		elif button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_wheel_zoom(1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else -1)
		accept_event()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			tracker.drag(MOUSE_INDEX, motion.position)
			accept_event()
	elif event is InputEventMagnifyGesture:
		_wheel_zoom(1 if (event as InputEventMagnifyGesture).factor > 1.0 else -1)
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _ready_done or hud.current_screen_id() != "home" or event.is_echo():
		return
	if event.is_action_pressed("interact"):
		if not hud.has_sheet() and highlighted != null:
			_use_nearby()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("zoom_cycle"):
		_cycle_zoom()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and hud.has_sheet():
		hud.close_sheet()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_cancel_gestures()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_go_back()


## La burbuja de cercanía: corre la acción del objeto si no hay nada que
## decidir; si no, abre su panel.
func _use_nearby() -> void:
	if not loop.run_quick(highlighted):
		open_sheet(highlighted)


## Un dedo baja en el mundo. Si algo se está imprimiendo en el cuarto (una
## compra que acaba de llegar), termina ya: el toque sigue haciendo lo suyo.
func _press(index: int, position: Vector2) -> void:
	room.finish_print_ins()
	tracker.area = Rect2(tuning.edge_ignore_px, 0.0, size.x - tuning.edge_ignore_px * 2.0, size.y)
	tracker.press(index, position)


func _release(index: int, position: Vector2) -> void:
	var tap_position: Variant = tracker.release(index, position)
	if tap_position != null:
		tap(tap_position)


func _cancel_gestures() -> void:
	tracker.cancel()
	if room != null and room.character != null:
		room.character.stick = Vector2.ZERO


## Android "atrás": cierra el panel, después la pantalla y por último sale.
func _go_back() -> void:
	if not _ready_done:
		return
	if hud.has_sheet():
		hud.close_sheet()
	elif hud.current_screen_id() != "home":
		hud.open_screen("home")
	else:
		# Salir así no avisa del cierre a la app: se guarda antes.
		SaveManager.save_now()
		quit_game.call()


func _cycle_zoom() -> void:
	room.camera.cycle_zoom()
	hud.set_zoom_label(room.camera.zoom_index)


func _wheel_zoom(direction: int) -> void:
	if _wheel_cooldown > 0.0:
		return
	_wheel_cooldown = tuning.wheel_cooldown
	room.camera.step_zoom(direction)
	hud.set_zoom_label(room.camera.zoom_index)


func _update_pinch() -> void:
	var pinching: bool = tracker.is_pinching()
	if pinching and not _was_pinching:
		room.camera.begin_pinch()
	if pinching:
		room.camera.update_pinch(tracker.pinch_ratio)
	elif _was_pinching:
		room.camera.end_pinch()
		hud.set_zoom_label(room.camera.zoom_index)
	_was_pinching = pinching


func _update_reach() -> void:
	var character: CharacterController = room.character
	var target: WorldInteractable = reach.update(character.floor_position, room.interactables)
	if target != highlighted:
		highlighted = target
		status.on_highlight_changed(target)
		if sheet_item == null:
			room.set_highlight(target)
	character.look_target = target.bounds.get_center() if target != null else null


func _update_overlays() -> void:
	if tracker.is_joystick():
		hud.joystick.show_at(tracker.joystick_base, tracker.joystick_knob)
	else:
		hud.joystick.hide_stick()
	if highlighted != null and sheet_item == null and hud.current_screen_id() == "home":
		hud.place_bubble(status.bubble_icon, world_to_ui(highlighted.top_center()))
	else:
		hud.bubble.hide_bubble()
	status.place_bubbles()
	if hud.speech.is_talking() and room.character != null:
		hud.place_speech(world_to_ui(room.speech_point()))


func _update_hints() -> void:
	var mode: MoveHint.Mode = _hints.mode()
	if hud.move_hint.mode != mode:
		hud.move_hint.set_mode(mode)
	# El joystick fantasma de la pista no se dibuja sobre el de verdad.
	hud.move_hint.modulate.a = 0.0 if tracker.is_joystick() else 1.0


## Cambió lo que hay en el cuarto (RoomView.sync_models): si el panel abierto
## era de algo que ya no está, se cierra.
func _on_models_changed() -> void:
	if sheet_item != null and sheet_item not in room.interactables:
		hud.close_sheet()


func _on_sheet_closed() -> void:
	sheet_item = null
	room.set_highlight(highlighted)


func _on_screen_changed(screen_id: String) -> void:
	# En la tienda, las marcas de lugares libres se encienden: ahí va lo que
	# se compre.
	room.markers_emphasis = screen_id == "shop"
	if screen_id != "home":
		_cancel_gestures()
		if room.character != null:
			room.character.stop_path()
		hud.joystick.hide_stick()
		hud.bubble.hide_bubble()
		hud.speech.hush()
