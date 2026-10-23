extends GutTest
## Lo que hay en el cuarto sigue al estado (Arte 2.0, paso 14; biblia de arte
## §12.2): RoomView.sync_models arma lo que falta y quita lo que sobra, con
## sus lugares libres, lo que se toca, la grilla de caminar, el mapa de
## oclusión del piso, los halos y las luces. Lo nuevo aparece imprimiéndose
## en su lugar (PrintIn) y un toque lo termina; al cargar otra partida
## (Events.game_loaded) el cuarto queda igual a su estado, sin efecto.
##
## Todavía no hay comando de compra (Fase 1, tarea 5): las pruebas agregan
## el mueble o la impresora al estado, como lo hará el comando, y piden
## sincronizar.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
const SEED: int = 1234
## Uid de la impresora del piso en una partida nueva.
const FLOOR_PRINTER_UID: int = 2
const CUBES_ID: String = "estanteria_cubos"
const SIDE_TABLE_ID: String = "mesa_auxiliar"
const WORK_TABLE_ID: String = "mesa_trabajo"
## Un lugar libre de la pared del fondo, otro a su lado y el del medio.
const BACK_SLOT: int = 3
const NEXT_SLOT: int = 4
const MIDDLE_SLOT: int = 5
## Segundos reales de más al esperar que termine un efecto (cuadros lentos).
const EFFECT_MARGIN: float = 0.4
## Tamaño de ventana que da la pantalla real de 720×1280 de la interfaz.
const WINDOW_SIZE: Vector2i = Vector2i(405, 720)

var _main: Control
var _room: RoomView
var _controls: WorldControls
var _hud: Hud
var _previous_processing: bool
var _previous_window_size: Vector2i


func before_each() -> void:
	_previous_processing = Game.is_processing()
	Game.set_process(false)
	_previous_window_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE


func after_each() -> void:
	get_tree().root.size = _previous_window_size
	Game.set_process(_previous_processing)


func test_new_furniture_appears_in_its_free_slot() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var layout: RoomLayout = RoomLayout.for_space(Game.state.space_id)
	var spot: Vector2 = _floor_of(layout.slots[BACK_SLOT])
	assert_true(_room.grid.is_free(spot), "Antes, el lugar libre se camina")
	var shade_before: float = _floor_ao_at(spot)
	var items_before: int = _room.interactables.size()
	watch_signals(_room)
	var furniture: OwnedFurniture = _add_furniture(CUBES_ID, BACK_SLOT)
	_room.sync_models()
	assert_signal_emitted(_room, "models_changed", "Avisa que cambió lo que hay")
	var node: Node3D = _room.get_node_or_null("Furniture%d" % furniture.uid)
	assert_not_null(node, "Aparece Furniture<uid>")
	assert_eq(node.transform, layout.slots[BACK_SLOT], "En su lugar")
	assert_null(_room.get_node_or_null("FreeSlot%d" % BACK_SLOT), "Su lugar ya no está libre")
	assert_eq(_free_slots().size(), 4, "Un lugar libre menos")
	var item: WorldInteractable = _room.item_for(WorldInteractable.Kind.FURNITURE, furniture.uid)
	assert_not_null(item, "Se puede tocar")
	assert_null(_room.item_for(WorldInteractable.Kind.SLOT, BACK_SLOT), "Su marca ya no")
	assert_eq(_room.interactables.size(), items_before, "El mueble reemplaza a su marca")
	assert_false(_room.grid.is_free(spot), "Es obstáculo para caminar")
	assert_has(_room.grid.obstacles(), item.footprint().grow(RoomView.OBSTACLE_MARGIN), "Con el margen de siempre")
	assert_lt(_floor_ao_at(spot), shade_before, "Oscurece el piso bajo él")
	_room.finish_print_ins()


func test_new_furniture_prints_in_and_gets_its_normal_material_back() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var furniture: OwnedFurniture = _add_furniture(CUBES_ID, BACK_SLOT)
	_room.sync_models()
	var node: Node3D = _room.get_node("Furniture%d" % furniture.uid)
	var body: MeshInstance3D = node.get_node("Body")
	var item: WorldInteractable = _room.item_for(WorldInteractable.Kind.FURNITURE, furniture.uid)
	var effect: PrintIn = _room.print_in_of(node)
	assert_not_null(effect, "Se está imprimiendo")
	assert_eq(body.material_override, WorldPalette.reveal_of(WorldPalette.kit()), "Con el material de revelado")
	assert_eq(item.local_bounds, PropBounds.local_aabb(node), "Lo que se toca sale de las mallas, también mientras se imprime")
	var first_cut: float = _cut_of(body)
	await wait_process_frames(3)
	assert_gt(_cut_of(body), first_cut, "El corte sube solo, con los cuadros")
	assert_true(effect.is_running())
	await wait_seconds(PrintIn.FURNITURE_SECONDS + EFFECT_MARGIN)
	assert_false(effect.is_running(), "Termina en lo que dura")
	assert_null(_room.print_in_of(node))
	assert_eq(body.material_override, WorldPalette.kit(), "Vuelve el material de siempre")
	assert_eq(item.local_bounds, PropBounds.local_aabb(node), "La misma zona de toque")
	var budget: RefCounted = SceneBudget.measure(_room)
	assert_false((budget.get("materials") as Dictionary).has(WorldPalette.reveal_of(WorldPalette.kit())), "Al final nadie paga el corte")


func test_the_cut_rises_from_below_the_base_to_above_the_top() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var table: OwnedFurniture = _add_furniture(SIDE_TABLE_ID, BACK_SLOT)
	var printer: OwnedPrinter = _add_printer("cubo_uno", table.uid)
	_room.sync_models()
	var node: Node3D = _room.get_node("Printer%d" % printer.uid)
	var effect: PrintIn = _room.print_in_of(node)
	var body: MeshInstance3D = node.get_node("Body")
	var display: MeshInstance3D = node.get_node("Display")
	var piece: MeshInstance3D = node.get_node("PieceSpot/Piece")
	var box: AABB = node.global_transform * PropBounds.local_aabb(node)
	var screen: AABB = display.global_transform * PropBounds.mesh_aabb(display.mesh)
	effect.hold(0.0)
	assert_lt(_cut_of(body), box.position.y, "Al empezar no hay nada impreso")
	assert_false(display.visible, "La pantallita (no es del kit) espera al corte")
	effect.hold(0.5)
	assert_between(_cut_of(body), box.position.y, box.end.y, "A la mitad, el corte va por dentro")
	assert_almost_eq(_cut_of(body), lerpf(box.position.y - PrintIn.START_BELOW, box.end.y + PrintIn.END_ABOVE, 0.5), 0.0001)
	assert_eq(display.visible, _cut_of(body) >= screen.get_center().y, "Aparece cuando el corte pasa su mitad")
	effect.hold(1.0)
	assert_gt(_cut_of(body), box.end.y, "Al final todo impreso")
	assert_true(display.visible)
	assert_false(piece.visible, "Lo escondido (la pieza sin trabajo) sigue escondido")
	effect.finish()
	assert_eq(body.material_override, WorldPalette.kit())
	assert_true(display.visible)
	assert_false(piece.visible)


func test_a_touch_in_the_world_finishes_the_print_at_once() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var furniture: OwnedFurniture = _add_furniture(CUBES_ID, BACK_SLOT)
	_room.sync_models()
	var body: MeshInstance3D = _room.get_node("Furniture%d/Body" % furniture.uid)
	assert_eq(body.material_override, WorldPalette.reveal_of(WorldPalette.kit()))
	var floor_point: Vector2 = _controls.world_to_ui(Vector3(0.3, 0.0, 0.2))
	_send_touch(floor_point, true)
	await wait_process_frames(1)
	assert_eq(body.material_override, WorldPalette.kit(), "El dedo baja y termina al instante")
	assert_null(_room.print_in_of(body.get_parent()))
	_send_touch(floor_point, false)
	await wait_process_frames(1)


func test_printers_on_new_furniture_sit_on_its_spots_and_wait_for_it() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var halos_before: int = _room.halos.count()
	var table: OwnedFurniture = _add_furniture(WORK_TABLE_ID, NEXT_SLOT)
	var printers: Array[OwnedPrinter] = [_add_printer("rayo_x1", table.uid), _add_printer("boveda_p1", table.uid)]
	_room.sync_models()
	var furniture: Node3D = _room.get_node("Furniture%d" % table.uid)
	for i: int in printers.size():
		var node: Node3D = _room.get_node("Printer%d" % printers[i].uid)
		var spot: Node3D = furniture.get_node("PrinterSpot%d" % i)
		assert_eq(node.transform, furniture.transform * spot.transform, "La impresora %d en su PrinterSpot" % i)
		var item: WorldInteractable = _room.item_for(WorldInteractable.Kind.PRINTER, printers[i].uid)
		assert_not_null(item, "Se puede tocar")
		assert_not_null(_controls.status.bubble_for(item), "Tiene su burbuja de estado")
	await wait_process_frames(3)
	var table_effect: PrintIn = _room.print_in_of(furniture)
	var printer_effect: PrintIn = _room.print_in_of(_room.get_node("Printer%d" % printers[0].uid))
	assert_gt(table_effect.progress(), 0.0, "El mueble se imprime primero")
	assert_eq(printer_effect.progress(), 0.0, "La impresora espera a su mueble (solo la vista previa)")
	assert_eq(_room.halos.count(), halos_before + printers.size(), "Un halo de noche más por impresora")
	assert_eq(_room.character.animator.watch_points.size(), 1 + printers.size(), "El personaje puede mirar sus cabezales")
	_room.finish_print_ins()
	assert_false(printer_effect.is_running(), "Un toque las termina todas")
	assert_eq((_room.get_node("Printer%d/Body" % printers[0].uid) as MeshInstance3D).material_override, WorldPalette.kit())


func test_removing_furniture_brings_back_its_free_slot() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var layout: RoomLayout = RoomLayout.for_space(Game.state.space_id)
	var halos_before: int = _room.halos.count()
	var table: OwnedFurniture = _add_furniture(SIDE_TABLE_ID, BACK_SLOT)
	var printer: OwnedPrinter = _add_printer("cubo_uno", table.uid)
	_room.sync_models()
	_room.finish_print_ins()
	var printer_item: WorldInteractable = _room.item_for(WorldInteractable.Kind.PRINTER, printer.uid)
	watch_signals(_room)
	Game.state.printers.erase(printer)
	Game.state.furniture.erase(table)
	_room.sync_models()
	assert_signal_emitted(_room, "models_changed")
	assert_null(_room.get_node_or_null("Furniture%d" % table.uid), "El mueble desaparece")
	assert_null(_room.get_node_or_null("Printer%d" % printer.uid), "Su impresora también")
	assert_not_null(_room.get_node_or_null("FreeSlot%d" % BACK_SLOT), "Vuelve su lugar libre")
	assert_eq(_free_slots().size(), 5)
	assert_null(_room.item_for(WorldInteractable.Kind.FURNITURE, table.uid))
	assert_not_null(_room.item_for(WorldInteractable.Kind.SLOT, BACK_SLOT))
	assert_null(_controls.status.bubble_for(printer_item), "Sin burbuja")
	assert_true(_room.grid.is_free(_floor_of(layout.slots[BACK_SLOT])), "Se vuelve a caminar")
	assert_eq(_room.halos.count(), halos_before, "Sin su halo")


func test_loading_a_game_with_other_furniture_leaves_the_room_like_its_state() -> void:
	var full: GameState = _full_game()
	await _load(full)
	var fresh_full: RefCounted = SceneBudget.measure(_room)
	await _load(GameState.new_game(Game.rules, SEED))
	var fresh_start: RefCounted = SceneBudget.measure(_room)

	Game._start(_full_game())
	_assert_room_matches_state("Cargada con el cuarto armado")
	assert_true(_print_ins_done(), "Al cargar no se imprime nada")
	_assert_same_cost(SceneBudget.measure(_room), fresh_full, "Igual que el cuarto lleno armado de cero")
	Game.reset_game(SEED)
	_assert_room_matches_state("Partida nueva")
	assert_eq(_free_slots().size(), 5, "Una partida nueva tiene 5 lugares libres")
	_assert_same_cost(SceneBudget.measure(_room), fresh_start, "Igual que el cuarto inicial armado de cero")


func test_a_printer_with_the_same_uid_but_another_model_is_built_again() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var before: Node3D = _room.get_node("Printer%d" % FLOOR_PRINTER_UID)
	var other: GameState = GameState.new_game(Game.rules, SEED)
	other.find_printer(FLOOR_PRINTER_UID).printer_id = "boveda_p1"
	Game._start(other)
	var after: Node3D = _room.get_node("Printer%d" % FLOOR_PRINTER_UID)
	assert_ne(after, before, "Se armó de nuevo")
	assert_not_null(after.get_node_or_null("Platform"), "Ahora es la cerrada")
	assert_eq(after.transform, RoomLayout.for_space(other.space_id).floor_printer_spots[0], "En el piso, sobre su baldosa")
	assert_not_null(_room.get_node_or_null("Decor/Paver"), "La baldosa sigue")


func test_without_a_floor_printer_there_is_no_paver_nor_bed_light() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var lamp: Vector4 = _room.day_cycle.light_place("printer_led")
	assert_gt(lamp.w, 0.0, "La impresora del piso alumbra su cama")
	var empty: GameState = GameState.new_game(Game.rules, SEED)
	empty.printers.clear()
	Game._start(empty)
	assert_null(_room.get_node_or_null("Printer%d" % FLOOR_PRINTER_UID))
	assert_null(_room.get_node_or_null("Decor/Paver"), "Sin impresora del piso, sin baldosa")
	assert_eq(_room.day_cycle.light_place("printer_led"), Vector4.ZERO, "Ni luz en su cama")
	Game.reset_game(SEED)
	assert_not_null(_room.get_node_or_null("Decor/Paver"), "Vuelve con la impresora")
	assert_eq(_room.day_cycle.light_place("printer_led"), lamp, "Y su luz en el mismo lugar")


func test_the_panel_of_something_that_leaves_closes() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	_controls.open_sheet(_room.item_for(WorldInteractable.Kind.PRINTER, FLOOR_PRINTER_UID))
	await wait_process_frames(2)
	assert_true(_hud.has_sheet())
	var empty: GameState = GameState.new_game(Game.rules, SEED)
	empty.printers.clear()
	Game._start(empty)
	assert_false(_hud.has_sheet(), "Su impresora ya no está: el panel se cierra")
	assert_null(_controls.sheet_item)


func test_new_furniture_where_the_character_stands_moves_him_out() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var layout: RoomLayout = RoomLayout.for_space(Game.state.space_id)
	var middle: Vector2 = _floor_of(layout.slots[MIDDLE_SLOT])
	_room.character.floor_position = middle
	_add_furniture(WORK_TABLE_ID, MIDDLE_SLOT)
	_room.sync_models()
	assert_true(_room.grid.is_free(_room.character.floor_position), "Queda afuera del mueble nuevo")
	assert_lt(_room.character.floor_position.distance_to(middle), 1.0, "Al lado, no lejos")
	_room.finish_print_ins()


func test_printing_in_asks_no_memory_per_frame() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	var table: OwnedFurniture = _add_furniture(SIDE_TABLE_ID, BACK_SLOT)
	_add_printer("cubo_uno", table.uid)
	_room.sync_models()
	var effect: PrintIn = _room.print_in_of(_room.get_node("Furniture%d" % table.uid))
	effect.hold(0.0)
	var before: int = OS.get_static_memory_usage()
	for i: int in 120:
		effect.set_progress(i / 119.0)
	assert_eq(OS.get_static_memory_usage(), before, "Avanzar el corte no pide memoria")
	_room.finish_print_ins()


# --- Ayudas ---------------------------------------------------------------------


func _load(state: GameState) -> void:
	if _main != null and is_instance_valid(_main):
		_main.queue_free()
		await wait_process_frames(1)
	Game._start(state)
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(3)
	_room = _main.get_node("WorldView/SubViewport/Room")
	_controls = _main.get_node("WorldControls")
	_hud = _main.get_node("Hud")


## Una partida nueva con el cuarto lleno (estanterías e impresoras en todos
## los lugares libres).
func _full_game() -> GameState:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	DebugTools.fill_workshop(state, Game.rules)
	return state


## Agrega al estado un mueble en `slot`, como lo hará el comando de compra.
func _add_furniture(furniture_id: String, slot: int) -> OwnedFurniture:
	var furniture: OwnedFurniture = OwnedFurniture.new(Game.state.take_uid(), furniture_id, slot)
	Game.state.furniture.append(furniture)
	return furniture


func _add_printer(printer_id: String, furniture_uid: int) -> OwnedPrinter:
	var printer: OwnedPrinter = OwnedPrinter.new(Game.state.take_uid(), printer_id, furniture_uid)
	Game.state.printers.append(printer)
	return printer


## Lo que el cuarto muestra es lo del estado: un Furniture<uid> y un
## Printer<uid> por cada uno (las impresoras en su lugar), una marca por
## lugar libre, nada de más, y lo que se toca lo mismo.
func _assert_room_matches_state(what: String) -> void:
	var state: GameState = Game.state
	var layout: RoomLayout = RoomLayout.for_space(state.space_id)
	var expected: Array[String] = []
	var used: Array[int] = []
	for item: OwnedFurniture in state.furniture:
		expected.append("Furniture%d" % item.uid)
		used.append(item.slot)
		assert_eq((_room.get_node("Furniture%d" % item.uid) as Node3D).transform, layout.slots[item.slot], "%s: mueble %d en su lugar" % [what, item.uid])
	var spot_index: Dictionary[int, int] = {}
	for printer: OwnedPrinter in state.printers:
		expected.append("Printer%d" % printer.uid)
		var node: Node3D = _room.get_node("Printer%d" % printer.uid)
		if printer.is_on_floor():
			assert_eq(node.transform, layout.floor_printer_spots[0], "%s: la del piso en su lugar" % what)
			continue
		var index: int = spot_index.get(printer.furniture_uid, 0)
		spot_index[printer.furniture_uid] = index + 1
		var furniture: Node3D = _room.get_node("Furniture%d" % printer.furniture_uid)
		assert_eq(node.transform, furniture.transform * (furniture.get_node("PrinterSpot%d" % index) as Node3D).transform, "%s: impresora %d en su PrinterSpot" % [what, printer.uid])
	for slot: int in layout.slots.size():
		if slot not in used:
			expected.append("FreeSlot%d" % slot)
	var shown: Array[String] = []
	for child: Node in _room.get_children():
		for prefix: String in ["Furniture", "Printer", "FreeSlot"]:
			if String(child.name).begins_with(prefix):
				shown.append(String(child.name))
	expected.sort()
	shown.sort()
	assert_eq(shown, expected, what + ": ni más ni menos que en el estado")
	var touchable: int = state.furniture.size() + state.printers.size() + layout.slots.size() - used.size() + 3
	assert_eq(_room.interactables.size(), touchable, what + ": se toca cada cosa (y la puerta, el rincón y el personaje)")


func _assert_same_cost(measured: RefCounted, fresh: RefCounted, what: String) -> void:
	for field: String in ["draw_calls", "visible_triangles", "shadow_triangles", "shadow_meshes", "transparent_surfaces"]:
		assert_eq(measured.get(field), fresh.get(field), "%s: %s" % [what, field])
	assert_eq((measured.get("materials") as Dictionary).size(), (fresh.get("materials") as Dictionary).size(), what + ": materiales")


func _print_ins_done() -> bool:
	for child: Node in _room.get_children():
		if child is Node3D and _room.print_in_of(child as Node3D) != null:
			return false
	return true


func _free_slots() -> Array[Node]:
	var slots: Array[Node] = []
	for child: Node in _room.get_children():
		if String(child.name).begins_with("FreeSlot"):
			slots.append(child)
	return slots


func _floor_of(at: Transform3D) -> Vector2:
	return Vector2(at.origin.x, at.origin.z)


## Cuánto deja pasar el mapa de oclusión del piso en ese punto (1 = nada).
func _floor_ao_at(point: Vector2) -> float:
	var image: Image = _room.floor_ao.get_image()
	var bounds: Rect2 = _room.grid.bounds
	var texel: Vector2i = Vector2i(((point - bounds.position) / bounds.size * FloorAO.TEXELS).floor())
	return image.get_pixelv(texel).r


func _cut_of(mesh: MeshInstance3D) -> float:
	return float(mesh.get_instance_shader_parameter(PrintIn.REVEAL_Y))


func _send_touch(ui_position: Vector2, pressed: bool) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = pressed
	touch.position = get_tree().root.get_final_transform() * ui_position
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
