extends GutTest
## Controles del mundo en la escena principal: tocar objetos, paneles,
## joystick, cercanía y zoom.
##
## Los toques se mandan con Input.parse_input_event, el mismo camino que en el
## teléfono: así también se prueba que los clics de mouse que inventa el
## sistema al tocar no cuenten doble.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SETTINGS_PATH: String = "user://test_world_controls_settings.cfg"
## Tamaño de ventana que da la pantalla real de 720×1280 de la interfaz.
const WINDOW_SIZE: Vector2i = Vector2i(405, 720)

var _main: Control
var _hud: Hud
var _controls: WorldControls
var _room: RoomView
var _previous_locale: String
var _previous_window_size: Vector2i
var _previous_settings_path: String
var _quit_calls: int = 0


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_previous_window_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	_previous_settings_path = UserSettings.path
	UserSettings.path = SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	ControlsTuning.reset()
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(3)
	_hud = _main.get_node("Hud")
	_controls = _main.get_node("WorldControls")
	_room = _main.get_node("WorldView/SubViewport/Room")
	# "Atrás" en la pantalla de inicio cierra el juego: aquí solo se cuenta.
	_quit_calls = 0
	_controls.quit_game = func() -> void: _quit_calls += 1


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)
	get_tree().root.size = _previous_window_size
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	UserSettings.path = _previous_settings_path


func test_tapping_the_printer_opens_its_panel() -> void:
	await _touch(_screen_of(_printer()))
	assert_true(_hud.has_sheet())
	assert_eq(_controls.sheet_item, _printer())
	var texts: Array[String] = _label_texts(_hud.current_sheet())
	assert_has(texts, "Cubo Uno")
	assert_has(texts, "Fiabilidad: 80%", "85% de fábrica menos 5% por estar en el suelo")


func test_a_touch_counts_once_even_with_the_invented_mouse_click() -> void:
	# Si el clic inventado contara, el segundo "toque" cerraría el panel.
	await _touch(_screen_of(_printer()))
	await wait_process_frames(2)
	assert_true(_hud.has_sheet())


func test_panel_button_opens_the_shop_on_furniture() -> void:
	_controls.open_sheet(_printer())
	await wait_process_frames(2)
	var button: Button = _hud.current_sheet().find_child("Action_shop_furniture", true, false)
	button.pressed.emit()
	assert_eq(_hud.current_screen_id(), "shop")
	assert_false(_hud.has_sheet())
	var shop: ShopScreen = _hud.get_node("ScreenHost/Screen")
	assert_not_null(shop.content.find_child("Item_mesa_auxiliar", true, false), "Abre en la pestaña de muebles")


func test_a_panel_fits_on_screen_with_its_title_visible() -> void:
	_controls.open_sheet(_printer())
	await wait_process_frames(30)
	var sheet: BottomSheet = _hud.current_sheet()
	var screen: Vector2 = _hud.get_viewport_rect().size
	assert_lt(sheet.size.y, screen.y * 0.6, "Deja ver el cuarto encima")
	assert_gt(sheet.get_global_rect().position.y, Hud.CONTENT_TOP)
	var title: Label = sheet.find_child("Title", true, false)
	assert_gt(title.get_global_rect().position.y, 0.0)
	assert_almost_eq(_hud.world_insets().y, sheet.size.y + Hud.MARGIN, 1.0, "La cámara sabe cuánto tapa")


func test_closing_a_panel_in_the_same_frame_it_opened_leaves_no_ghost() -> void:
	_controls.open_sheet(_printer())
	_hud.close_sheet()
	var host: Node = _hud.get_node("SheetHost")
	await wait_until(func() -> bool: return host.get_child_count() == 0, BottomSheet.SLIDE_TIME + 1.0)
	await wait_process_frames(5)
	assert_eq(host.get_child_count(), 0, "El panel no vuelve a subir solo")


func test_tapping_another_object_swaps_the_panel_and_empty_floor_closes_it() -> void:
	_controls.open_sheet(_printer())
	await wait_process_frames(2)
	_controls.tap(_screen_of(_desk()))
	assert_eq(_controls.sheet_item, _desk())
	_controls.tap(_screen_of_floor(Vector3(0.8, 0.0, 0.2)))
	assert_false(_hud.has_sheet())
	assert_false(_room.character.is_following_path(), "Ese toque solo cierra el panel")


func test_a_free_spot_opens_wherever_no_other_object_stands_in_front() -> void:
	# En la partida nueva, la impresora del suelo queda delante del lugar libre 2.
	var blockers: Array[Node3D] = [_room.get_node("RoomShell/Door"), _room.get_node("Character")]
	for child: Node in _room.get_children():
		if child.name.begins_with("Printer") or child.name.begins_with("Furniture"):
			blockers.append(child)
	var checked: int = 0
	var wrong: Array[String] = []
	for slot: WorldInteractable in _room.interactables:
		if slot.kind != WorldInteractable.Kind.SLOT:
			continue
		var area: Rect2 = slot.footprint().grow(-0.05)
		for i: int in 9:
			for j: int in 9:
				var point: Vector3 = Vector3(area.position.x + area.size.x * (i + 0.5) / 9.0, 0.01, area.position.y + area.size.y * (j + 0.5) / 9.0)
				var view: Vector2 = _room.camera.unproject_position(point)
				if _is_behind_something(view, blockers):
					continue
				checked += 1
				var picked: WorldInteractable = _room.pick(view, 0.0)
				if picked != slot:
					wrong.append("lugar %d en (%.2f, %.2f)" % [slot.ref, point.x, point.z])
	assert_gt(checked, 300, "Se probaron puntos de todos los lugares libres")
	assert_eq(wrong.size(), 0, "Abren otra cosa: %s" % ", ".join(wrong.slice(0, 6)))


func test_tapping_the_floor_walks_there() -> void:
	var target: Vector3 = Vector3(0.8, 0.0, 0.2)
	await _touch(_screen_of_floor(target))
	assert_true(_room.character.is_following_path())
	await wait_seconds(2.0)
	assert_lt(_room.character.floor_position.distance_to(Vector2(target.x, target.z)), 0.25)


func test_tapping_the_character_makes_it_talk() -> void:
	await _touch(_screen_of(_item(WorldInteractable.Kind.CHARACTER)))
	assert_true(_hud.speech.is_talking())
	assert_false(_hud.has_sheet())


func test_joystick_drag_walks_where_the_thumb_points() -> void:
	var start: Vector3 = _room.character.model.position
	var finger: Vector2 = Vector2(360.0, 900.0)
	await _press(finger)
	# Hacia abajo en la pantalla: hacia el frente del cuarto, donde no hay muebles.
	await _drag(finger + Vector2(0.0, 70.0))
	await wait_seconds(0.4)
	assert_true(_hud.joystick.is_shown())
	# Cómo se ve el recorrido en la pantalla, sin contar que la cámara lo sigue.
	var moved: Vector3 = _room.character.model.position - start
	var on_screen: Vector2 = Vector2(moved.dot(_room.camera.basis.x), -moved.dot(_room.camera.basis.y))
	assert_gt(on_screen.y, 0.3, "Baja por la pantalla")
	assert_lt(absf(on_screen.x), on_screen.y * 0.15, "Sin desviarse a un lado")
	await _release(finger + Vector2(0.0, 70.0))
	assert_false(_hud.joystick.is_shown())


func test_a_drag_over_the_bottom_bar_keeps_steering() -> void:
	var finger: Vector2 = Vector2(360.0, 1000.0)
	await _press(finger)
	await _drag(finger + Vector2(0.0, 60.0))
	await _drag(Vector2(360.0, 1200.0))
	assert_true(_controls.tracker.is_joystick(), "El dedo sigue siendo el joystick sobre la barra")
	await _release(Vector2(360.0, 1200.0))
	assert_eq(_hud.current_screen_id(), "home", "No abrió ninguna sección")


func test_touching_a_hud_button_does_not_reach_the_world() -> void:
	var zoom: Button = _hud.get_node("ZoomButton")
	await _touch(zoom.get_global_rect().get_center())
	assert_eq(_room.camera.zoom_index, 2, "El botón se tocó una sola vez")
	assert_false(_room.character.is_following_path(), "El toque no hizo caminar al personaje")
	assert_eq(_controls.tracker.state, TouchTracker.State.IDLE)


func test_touching_a_bottom_bar_button_opens_its_section() -> void:
	var shop_button: Button = _hud.get_node("BottomNav").find_child("shop", true, false)
	await _touch(shop_button.get_global_rect().get_center())
	assert_eq(_hud.current_screen_id(), "shop")


func test_walking_closes_an_open_panel() -> void:
	_controls.open_sheet(_printer())
	await wait_process_frames(2)
	var finger: Vector2 = Vector2(360.0, 300.0)
	await _press(finger)
	await _drag(finger + Vector2(60.0, 0.0))
	await wait_process_frames(2)
	assert_false(_hud.has_sheet())
	await _release(finger + Vector2(60.0, 0.0))


func test_nearby_printer_is_highlighted_and_its_bubble_opens_the_panel() -> void:
	assert_eq(_controls.highlighted, _printer(), "El personaje empieza junto a su impresora")
	assert_true(_hud.bubble.visible)
	await _touch(_hud.bubble.get_global_rect().get_center())
	assert_eq(_controls.sheet_item, _printer())


func test_pushing_into_the_desk_keeps_the_body_outside() -> void:
	var desk: Rect2 = _desk().footprint()
	_room.character.floor_position = Vector2(-1.2, -1.2)
	var finger: Vector2 = Vector2(360.0, 1000.0)
	await _press(finger)
	# Hacia arriba a la izquierda en la pantalla: hacia el escritorio.
	await _drag(finger + Vector2(-60.0, -40.0))
	for i: int in 60:
		await wait_process_frames(1)
		assert_gte(WalkGrid.distance_to_rect(_room.character.floor_position, desk), _room.grid.radius - 0.001, "El cuerpo no entra en el escritorio")
	await _release(finger + Vector2(-60.0, -40.0))


func test_zoom_button_cycles_and_names_the_level() -> void:
	var button: Button = _hud.get_node("ZoomButton")
	assert_eq(button.text, "Normal")
	button.pressed.emit()
	assert_eq(_room.camera.zoom_index, 2)
	assert_eq(button.text, "Cerca")
	button.pressed.emit()
	assert_eq(button.text, "Lejos")


func test_an_open_screen_ignores_the_world() -> void:
	_hud.open_screen("inventory")
	_controls.tap(_screen_of(_printer()))
	assert_false(_hud.has_sheet())


func test_back_button_closes_the_panel_then_the_section_then_quits() -> void:
	_controls.open_sheet(_printer())
	await wait_process_frames(2)
	assert_true(_hud.has_sheet())
	_controls.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_false(_hud.has_sheet(), "Primero cierra el panel")
	assert_eq(_quit_calls, 0)
	_hud.open_screen("inventory")
	_controls.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(_hud.current_screen_id(), "home", "Después cierra la sección")
	assert_eq(_quit_calls, 0)
	_controls.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(_quit_calls, 1, "Al final sale del juego")


func test_two_fingers_spreading_zoom_in() -> void:
	await _press(Vector2(300.0, 900.0), 0)
	await _press(Vector2(420.0, 900.0), 1)
	await _drag(Vector2(560.0, 900.0), 1)
	assert_gt(_room.camera.zoom, 1.0, "Sigue a los dedos")
	await _release(Vector2(560.0, 900.0), 1)
	await _release(Vector2(300.0, 900.0), 0)
	assert_eq(_room.camera.zoom_index, 2)
	assert_eq((_hud.get_node("ZoomButton") as Button).text, "Cerca")


func test_losing_focus_lets_go_of_the_joystick() -> void:
	var finger: Vector2 = Vector2(360.0, 1000.0)
	await _press(finger)
	await _drag(finger + Vector2(0.0, 60.0))
	assert_true(_controls.tracker.is_joystick())
	_controls.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await wait_process_frames(1)
	assert_eq(_room.character.stick, Vector2.ZERO)
	assert_false(_hud.joystick.is_shown())


func test_drags_starting_at_the_side_edges_do_not_walk() -> void:
	await _press(Vector2(5.0, 1000.0))
	await _drag(Vector2(75.0, 1000.0))
	assert_false(_controls.tracker.is_joystick(), "Ahí empiezan los gestos de 'atrás' del teléfono")
	await _release(Vector2(75.0, 1000.0))


func test_move_hint_gives_way_to_the_tap_hint_after_walking() -> void:
	assert_eq(_hud.move_hint.mode, MoveHint.Mode.MOVE)
	var finger: Vector2 = Vector2(360.0, 1000.0)
	await _press(finger)
	await _drag(finger + Vector2(70.0, 0.0))
	await wait_seconds(1.0)
	await _release(finger + Vector2(70.0, 0.0))
	assert_eq(_hud.move_hint.mode, MoveHint.Mode.TAP)
	assert_true(UserSettings.load_settings().has_seen(HintFlow.MOVE), "Se recuerda para la próxima vez")


func test_the_hint_only_works_every_frame_while_its_ghost_joystick_is_on_screen() -> void:
	assert_true(_hud.move_hint.is_processing(), "El joystick fantasma se mueve")
	_controls.open_sheet(_printer())
	await wait_process_frames(2)
	assert_false(_hud.move_hint.is_processing(), "Escondida bajo el panel no se redibuja")
	_hud.close_sheet()
	await wait_process_frames(2)
	assert_true(_hud.move_hint.visible)
	assert_true(_hud.move_hint.is_processing(), "Vuelve a moverse al cerrar el panel")
	_hud.move_hint.set_mode(MoveHint.Mode.TAP)
	assert_false(_hud.move_hint.is_processing(), "La pista de tocar es solo texto: no se redibuja")


func _printer() -> WorldInteractable:
	return _item(WorldInteractable.Kind.PRINTER)


func _desk() -> WorldInteractable:
	return _item(WorldInteractable.Kind.FURNITURE)


func _item(kind: WorldInteractable.Kind) -> WorldInteractable:
	for item: WorldInteractable in _room.interactables:
		if item.kind == kind:
			return item
	return null


func _screen_of(item: WorldInteractable) -> Vector2:
	if item.kind == WorldInteractable.Kind.CHARACTER:
		return _controls.world_to_ui(_room.character.model.position + Vector3(0.0, 0.7, 0.0))
	return _controls.world_to_ui(item.bounds.get_center())


func _screen_of_floor(point: Vector3) -> Vector2:
	return _controls.world_to_ui(point)


## Si en ese punto de la vista hay un objeto (su caja, girada con él) delante.
func _is_behind_something(view: Vector2, blockers: Array[Node3D]) -> bool:
	var origin: Vector3 = _room.camera.project_ray_origin(view)
	var direction: Vector3 = _room.camera.project_ray_normal(view)
	for node: Node3D in blockers:
		var inverse: Transform3D = node.global_transform.affine_inverse()
		if PropBounds.local_aabb(node).intersects_ray(inverse * origin, inverse.basis * direction) != null:
			return true
	return false


## Un toque completo: bajar y subir el dedo en el mismo lugar.
func _touch(ui_position: Vector2) -> void:
	await _press(ui_position)
	await _release(ui_position)


func _press(ui_position: Vector2, index: int = 0) -> void:
	_send_touch(ui_position, true, index)
	await wait_process_frames(1)


func _release(ui_position: Vector2, index: int = 0) -> void:
	_send_touch(ui_position, false, index)
	await wait_process_frames(1)


func _drag(ui_position: Vector2, index: int = 0) -> void:
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = index
	drag.position = _to_window(ui_position)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	await wait_process_frames(1)


func _send_touch(ui_position: Vector2, pressed: bool, index: int) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = index
	touch.pressed = pressed
	touch.position = _to_window(ui_position)
	Input.parse_input_event(touch)
	Input.flush_buffered_events()


func _to_window(ui_position: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * ui_position


func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts
