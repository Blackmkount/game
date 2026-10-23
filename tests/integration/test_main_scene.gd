extends GutTest
## La escena principal arma la habitación inicial y la interfaz, y las
## secciones se abren y se cierran.

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
## Cada prueba empieza con la misma partida nueva.
const SEED: int = 1234

var _main: Control
var _hud: Hud
var _room: Node3D
var _previous_locale: String


func before_each() -> void:
	Game.reset_game(SEED)
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_hud = _main.get_node("Hud")
	_room = _main.get_node("WorldView/SubViewport/Room")


func after_each() -> void:
	TranslationServer.set_locale(_previous_locale)


func test_room_starts_with_table_printer_on_floor_and_character() -> void:
	assert_not_null(_room.get_node_or_null("Furniture%d" % Game.state.furniture[0].uid))
	assert_not_null(_room.get_node_or_null("Printer%d" % Game.state.printers[0].uid))
	assert_not_null(_room.get_node_or_null("Character"))
	var free_slots: Array[Node] = _room.find_children("FreeSlot*", "", false, false)
	assert_eq(free_slots.size(), 5, "La habitación tiene 6 lugares y la mesa ocupa uno")


func test_the_dispatch_corner_stands_by_the_door_without_taking_a_slot() -> void:
	var corner: Node3D = _room.get_node_or_null("DispatchCorner")
	assert_not_null(corner)
	for i: int in 3:
		assert_true(corner.get_node_or_null("PackSpot%d" % i) is Marker3D, "PackSpot%d" % i)
		assert_true(corner.get_node_or_null("OutSpot%d" % i) is Marker3D, "OutSpot%d" % i)
	var room: RoomView = _room
	assert_eq(room.dispatch_item.kind, WorldInteractable.Kind.DISPATCH)
	assert_eq(room.item_for(WorldInteractable.Kind.DISPATCH, 0), room.dispatch_item)
	assert_true(room.dispatch_item.reachable)
	assert_eq(_room.find_children("FreeSlot*", "", false, false).size(), 5, "No usa ninguno de los 6 lugares")


func test_the_dispatch_corner_measures_the_same_with_its_hidden_boxes() -> void:
	var corner: Node3D = _room.get_node("DispatchCorner")
	for i: int in DispatchCornerModel.PACK_SPOTS:
		assert_false((corner.get_node("PackSpot%d/OpenBox" % i) as Node3D).visible, "PackSpot%d vacío al empezar" % i)
	for i: int in DispatchCornerModel.OUT_SPOTS:
		assert_false((corner.get_node("OutSpot%d/Package" % i) as Node3D).visible, "OutSpot%d vacío al empezar" % i)
	# La zona que se toca (y el obstáculo) incluye las cajas escondidas.
	var bounds: AABB = PropBounds.local_aabb(corner)
	assert_almost_eq(Vector2(bounds.position.x, bounds.end.x), Vector2(-0.435, 0.45), Vector2.ONE * 0.01, "De x −0,435 a 0,45")
	assert_almost_eq(Vector2(bounds.position.z, bounds.end.z), Vector2(-0.2, 0.2), Vector2.ONE * 0.01, "De z −0,2 a 0,2")


func test_the_desk_lamp_and_monitor_light_from_the_desk_markers() -> void:
	var room: RoomView = _room
	var desk: Node3D = _room.get_node("Furniture%d" % Game.state.furniture[0].uid)
	# Lo que se publica en cc_pl0 y cc_pl1: el lugar y el alcance (0 = no alumbra).
	var bulb: Vector3 = (desk.get_node("LampBulb") as Node3D).global_position
	var screen: Vector3 = (desk.get_node("ScreenGlow") as Node3D).global_position
	var lamp_reach: float = DayCycle.LIGHTS["desk_lamp"]["range"]
	var monitor_reach: float = DayCycle.LIGHTS["monitor"]["range"]
	assert_almost_eq(room.day_cycle.light_place("desk_lamp").w, lamp_reach, 0.0001, "La lámpara del escritorio tiene lugar y alumbra (cc_pl0)")
	assert_almost_eq(room.day_cycle.light_place("desk_lamp"), Vector4(bulb.x, bulb.y, bulb.z, lamp_reach), Vector4.ONE * 0.0001, "En la ampolleta")
	assert_almost_eq(room.day_cycle.light_place("monitor"), Vector4(screen.x, screen.y, screen.z, monitor_reach), Vector4.ONE * 0.0001, "Delante de la pantalla (cc_pl1)")


func test_the_floor_darkens_under_the_desk_the_printer_and_the_dispatch_corner() -> void:
	var room: RoomView = _room
	var image: Image = room.floor_ao.get_image()
	var spots: Dictionary[String, WorldInteractable] = {
		"escritorio": room.item_for(WorldInteractable.Kind.FURNITURE, Game.state.furniture[0].uid),
		"impresora del piso": room.item_for(WorldInteractable.Kind.PRINTER, Game.state.printers[0].uid),
		"rincón de despacho": room.dispatch_item,
	}
	for spot_name: String in spots:
		var under: float = _floor_light(room, image, spots[spot_name].footprint().get_center())
		assert_almost_eq(under, 1.0 - FloorAO.STRENGTH, 1.5 / 255.0, "Mancha de oclusión bajo el %s" % spot_name)
	var feet: Vector3 = room.character.model.position
	assert_eq(_floor_light(room, image, Vector2(feet.x, feet.z)), 1.0, "Donde empieza el personaje, el piso limpio")
	for slot: Node in _room.find_children("FreeSlot*", "", false, false):
		var marker: Node3D = slot
		assert_eq(_floor_light(room, image, Vector2(marker.position.x, marker.position.z)), 1.0, "Un lugar libre no tiene mancha (%s)" % slot.name)


func test_the_floor_printer_stands_on_its_concrete_paver_with_a_cable_to_the_outlet() -> void:
	var room: RoomView = _room
	var uid: int = Game.state.printers[0].uid
	var printer: Node3D = _room.get_node("Printer%d" % uid)
	var paver: MeshInstance3D = _room.get_node_or_null("Decor/Paver")
	assert_not_null(paver, "La baldosa va con la decoración")
	assert_almost_eq(PaverModel.SIZE.y, RoomLayout.FLOOR_PRINTER_RAISE, 0.0001)
	assert_almost_eq(printer.position.y, RoomLayout.FLOOR_PRINTER_RAISE, 0.0001, "La impresora apoyada sobre la baldosa")
	assert_eq(paver.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var touch: AABB = room.item_for(WorldInteractable.Kind.PRINTER, uid).bounds
	assert_gte(touch.position.y, RoomLayout.FLOOR_PRINTER_RAISE - 0.001, "La baldosa no agranda la zona de toque")
	var spot: Transform3D = printer.transform
	var on_floor: Transform3D = Transform3D(spot.basis, Vector3(spot.origin.x, 0.0, spot.origin.z))
	var wall: float = -RoomShell.SIZE / 2.0
	var aabb: AABB = paver.mesh.get_aabb()
	assert_lte(aabb.position.z, wall + 0.03, "El cable llega a la pared")
	assert_gte(aabb.end.y, RoomShell.OUTLET_Y, "Y sube hasta el enchufe")
	# En el piso el cable es plano (≤ 4 mm) y no pisa ningún lugar de muebles.
	var slots: Array[Rect2] = []
	for slot: Transform3D in RoomLayout.for_space(Game.state.space_id).slots:
		var corner: Vector3 = slot * Vector3(-SlotMarker.SIZE.x / 2.0, 0.0, -SlotMarker.SIZE.y / 2.0)
		var far: Vector3 = slot * Vector3(SlotMarker.SIZE.x / 2.0, 0.0, SlotMarker.SIZE.y / 2.0)
		slots.append(Rect2(Vector2(minf(corner.x, far.x), minf(corner.z, far.z)), (Vector2(far.x, far.z) - Vector2(corner.x, corner.z)).abs()))
	var tall: Array[String] = []
	var on_slot: Array[String] = []
	var floor_points: int = 0
	for vertex: Vector3 in paver.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
		var local: Vector3 = on_floor.affine_inverse() * vertex
		var on_paver: bool = absf(local.x) <= PaverModel.SIZE.x / 2.0 + 0.05 and absf(local.z) <= PaverModel.SIZE.z / 2.0 + 0.05
		if on_paver or vertex.z < wall + 0.08:
			continue
		floor_points += 1
		if vertex.y > 0.0045:
			tall.append(str(vertex))
		for rect: Rect2 in slots:
			if rect.has_point(Vector2(vertex.x, vertex.z)):
				on_slot.append(str(vertex))
	assert_gt(floor_points, 20, "El cable cruza el piso")
	assert_eq(tall, [] as Array[String], "En el piso mide 4 mm de alto")
	assert_eq(on_slot, [] as Array[String], "No cruza ningún lugar de muebles")


func test_the_room_shows_a_loaded_print_halfway() -> void:
	# Un llavero a mitad de impresión, guardado y cargado de nuevo.
	Game.advance(3.0)
	Game.accept_offer(Game.state.offers[0].uid)
	Game.advance(10.0)
	var order: Order = Game.state.orders[0]
	var plan: PrintPlan = PrintPlanner.recommend(Game.state, Game.rules, order)
	assert_true(Game.start_print(order.uid, plan.printer_uid, plan.spool_uid, plan.mode_id).ok)
	Game.advance(25.0)
	var errors: Array[String] = []
	var loaded: GameState = SaveCodec.decode(SaveCodec.encode(Game.state), Game.rules, errors)
	assert_true(errors.is_empty(), str(errors))
	_main.queue_free()
	await wait_process_frames(1)
	Game._start(loaded)
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_room = _main.get_node("WorldView/SubViewport/Room")
	var piece: MeshInstance3D = _room.get_node("Printer%d/PieceSpot/Piece" % plan.printer_uid)
	assert_true(piece.visible, "La pieza está en la cama")
	var height: float = PieceModel.shown_height(piece)
	assert_gt(height, 0.0)
	assert_lt(height, PieceModel.SIZES["S"].y, "Va por la mitad")


func test_top_bar_shows_level_and_money() -> void:
	var labels: Array[String] = _label_texts(_hud.get_node("TopBar"))
	assert_has(labels, "Nivel 1")
	assert_has(labels, "$250")


func test_shop_lists_all_printers_and_furniture() -> void:
	_hud.open_screen("shop")
	var shop: ShopScreen = _hud.get_node("ScreenHost/Screen")
	assert_eq(_cards(shop).size(), (Game.catalog.files["printers"] as Array).size())
	assert_eq(_views(shop).size(), 7, "Cada impresora con su vista 3D (biblia de arte §11)")
	shop.show_category("furniture")
	assert_eq(_cards(shop).size(), 6, "La mesa del computador no se vende")
	assert_eq(_views(shop).size(), 6, "Cada mueble con su vista 3D")


func test_closing_a_screen_goes_back_home() -> void:
	_hud.open_screen("inventory")
	assert_not_null(_hud.get_node_or_null("ScreenHost/Screen"))
	_hud.open_screen("home")
	await wait_process_frames(1)
	assert_eq(_hud.current_screen_id(), "home")
	assert_null(_hud.get_node_or_null("ScreenHost/Screen"))


func test_the_inventory_hides_empty_spools() -> void:
	var empty: Spool = Spool.new(Game.state.take_uid(), "petg", "negro", 0)
	Game.state.spools.append(empty)
	_hud.open_screen("inventory")
	var texts: Array[String] = _label_texts(_hud.get_node("ScreenHost/Screen"))
	assert_has(texts, "PLA · Blanco")
	assert_does_not_have(texts, "PETG · Negro", "El carrete vacío no se muestra")
	_hud.open_screen("home")
	await wait_process_frames(1)


func test_every_screen_opens() -> void:
	for screen_id: String in ["workshop", "inventory", "shop", "profile", "orders", "tasks", "map", "settings"]:
		_hud.open_screen(screen_id)
		assert_not_null(_hud.get_node_or_null("ScreenHost/Screen"), screen_id)


func _cards(screen: ScreenBase) -> Array[Node]:
	return screen.content.get_children().filter(func(child: Node) -> bool: return child is ItemCard)


## Las vistas 3D de las tarjetas que se ven (ModelPreview).
func _views(screen: ScreenBase) -> Array[Node]:
	var views: Array[Node] = []
	for card: Node in _cards(screen):
		views.append_array(card.find_children("*", "", true, false).filter(func(node: Node) -> bool: return node is ModelPreview))
	return views


func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


## Luz del mapa de oclusión del piso en un punto (x, z) del cuarto.
func _floor_light(room: RoomView, image: Image, point: Vector2) -> float:
	var texel: Vector2i = Vector2i(((point - room.grid.bounds.position) / room.grid.bounds.size * FloorAO.TEXELS).floor())
	return image.get_pixelv(texel).r
