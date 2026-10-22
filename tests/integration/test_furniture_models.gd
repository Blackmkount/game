extends GutTest
## Los muebles del kit (biblia de arte §10): cada tipo se arma con sus
## lugares para impresoras, cuesta lo que dice el presupuesto (§5.2), en la
## estantería metálica cabe cualquier impresora en cada piso, y lo que se
## cuelga (repisa de filamento y tablero de herramientas) queda pegado a la
## pared donde la hay y sobre su pie propio donde no (el lugar del medio).

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
const FullRoom: GDScript = preload("res://tests/helpers/full_room.gd")
const SEED: int = 1234
const DESK_ID: String = "mesa_computador"
const RACK_ID: String = "estanteria_metalica"
## Presupuesto de un mueble (biblia §5.2): triángulos y llamadas de dibujo con
## la pasada de sombra (UNA malla con su sombra).
const MAX_TRIANGLES: int = 1500
const MAX_DRAW_CALLS: int = 2
## Lo que se cuelga queda a esto o menos de la pared (m).
const WALL_TOLERANCE: float = 0.02
## Las paredes del cuarto (las de la ventana y del fondo) por dentro.
const WALL_PLANE: float = -RoomShell.SIZE / 2.0
## Lugar del medio del cuarto (sin pared detrás) y lugar bajo la ventana.
const MIDDLE_SLOT: int = 5
const WINDOW_SLOT: int = 0

var _root: Node3D
var _main: Control
var _room: RoomView
var _previous_processing: bool


func before_each() -> void:
	_main = null
	_room = null
	_root = Node3D.new()
	add_child_autofree(_root)
	_previous_processing = Game.is_processing()
	Game.set_process(false)
	Game.reset_game(SEED)


func after_each() -> void:
	Game.set_process(_previous_processing)


func test_every_furniture_builds_with_its_printer_spots() -> void:
	for entry: Dictionary in Game.catalog.files["furniture"]:
		var id: String = String(entry["id"])
		for gap: float in [FurnitureModel.NO_WALL, 0.4]:
			var furniture: Node3D = FurnitureModel.build(_root, "F", id, gap)
			var bounds: AABB = PropBounds.local_aabb(furniture)
			assert_almost_eq(bounds.position.y, 0.0, 0.001, "%s apoyado en el piso" % id)
			var spots: Array[Marker3D] = []
			for child: Node in furniture.get_children():
				if child.name.begins_with("PrinterSpot"):
					assert_true(child is Marker3D, "%s: %s es un Marker3D" % [id, child.name])
					spots.append(child as Marker3D)
			assert_eq(spots.size(), int(entry["printer_slots"]), "%s: un lugar por impresora del catálogo" % id)
			for i: int in spots.size():
				assert_not_null(furniture.get_node_or_null("PrinterSpot%d" % i), "%s: PrinterSpot%d en orden" % [id, i])
			if id != DESK_ID:
				var body: MeshInstance3D = furniture.get_node("Body")
				assert_eq(body.material_override, WorldPalette.kit(), "%s: una malla con el material del kit" % id)
				assert_eq(furniture.find_children("*", "GeometryInstance3D", true, false).size(), 1, "%s: todo en una malla (también los carretes)" % id)
			_root.remove_child(furniture)
			furniture.free()


func test_each_furniture_fits_its_budget_and_its_mesh_is_shared() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_root.add_child(sun)
	for entry: Dictionary in Game.catalog.files["furniture"]:
		var id: String = String(entry["id"])
		if id == DESK_ID:
			continue
		for gap: float in [FurnitureModel.NO_WALL, 0.4]:
			var furniture: Node3D = FurnitureModel.build(_root, "F", id, gap)
			var budget: RefCounted = SceneBudget.measure(_root)
			assert_lte(budget.get("triangles"), MAX_TRIANGLES, "%s (pared %s): triángulos" % [id, gap])
			assert_lte(budget.get("draw_calls"), MAX_DRAW_CALLS, "%s (pared %s): llamadas con la sombra" % [id, gap])
			var again: Node3D = FurnitureModel.build(_root, "G", id, gap)
			assert_same((again.get_node("Body") as MeshInstance3D).mesh, (furniture.get_node("Body") as MeshInstance3D).mesh, "%s: la malla se arma una vez" % id)
			for node: Node3D in [furniture, again]:
				_root.remove_child(node)
				node.free()


func test_the_metal_rack_leaves_room_for_the_tallest_printer() -> void:
	var heights: Array[float] = MetalRackModel.spot_heights()
	assert_eq(heights.size(), 3)
	var expected: Array[float] = [0.075, 0.845, 1.615]
	for i: int in heights.size():
		assert_almost_eq(heights[i], expected[i], 0.0001, "Cara de arriba de la tabla %d" % i)
		var free: float = MetalRackModel.BOARDS[i + 1] - MetalRackModel.BOARD_THICKNESS / 2.0 - heights[i]
		assert_almost_eq(free, 0.74, 0.0001, "0,74 m libres sobre la tabla %d" % i)
		assert_gt(free, PrinterModel.MAX_HEIGHT, "Cabe la impresora más alta permitida")
	var rack: Node3D = FurnitureModel.build(_root, "Rack", RACK_ID)
	var post_top: float = 0.0
	var corner: Vector2 = MetalRackModel.HALF_SIZE - Vector2.ONE * (MetalRackModel.ANGLE + 0.001)
	for vertex: Vector3 in (rack.get_node("Body") as MeshInstance3D).mesh.get_faces():
		if absf(vertex.x) > corner.x and absf(vertex.z) > corner.y:
			post_top = maxf(post_top, vertex.y)
	assert_almost_eq(post_top, MetalRackModel.HEIGHT, 0.001, "Postes de 2,40 m")
	for i: int in heights.size():
		assert_almost_eq((rack.get_node("PrinterSpot%d" % i) as Node3D).position, Vector3(0.0, expected[i], 0.0), Vector3.ONE * 0.0001)


func test_every_family_fits_every_level_of_the_rack() -> void:
	var rack: Node3D = FurnitureModel.build(_root, "Rack", RACK_ID)
	var depth: float = MetalRackModel.HALF_SIZE.y - MetalRackModel.ANGLE_THICKNESS * 2.0
	for entry: Dictionary in Game.catalog.files["printers"]:
		var id: String = String(entry["id"])
		for level: int in MetalRackModel.spot_heights().size():
			var spot: Node3D = rack.get_node("PrinterSpot%d" % level)
			var printer: Node3D = PrinterModel.build(spot, "P", id, "f2efe6", PrinterParts.FURNITURE_DETAIL)
			var bounds: AABB = spot.transform * PropBounds.local_aabb(printer)
			var next_board: float = MetalRackModel.BOARDS[level + 1] - MetalRackModel.BOARD_THICKNESS / 2.0
			assert_lt(bounds.end.y, next_board, "%s cabe bajo la tabla %d" % [id, level + 1])
			assert_lte(absf(bounds.position.z), depth + 0.001, "%s: no se sale por delante ni por detrás" % id)
			assert_lte(bounds.end.z, depth + 0.001, "%s: no se sale por delante" % id)
			spot.remove_child(printer)
			printer.free()


func test_in_the_full_room_no_printer_goes_through_a_board() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	FullRoom.fill(state, Game.rules)
	await _load(state)
	var checked: int = 0
	for printer: OwnedPrinter in state.printers:
		if printer.is_on_floor():
			continue
		var rack: Node3D = _room.get_node("Furniture%d" % printer.furniture_uid)
		var node: Node3D = _room.get_node("Printer%d" % printer.uid)
		var top: float = (node.transform * PropBounds.local_aabb(node)).end.y - rack.position.y
		var bottom: float = node.position.y - rack.position.y
		var level: int = -1
		var heights: Array[float] = MetalRackModel.spot_heights()
		for i: int in heights.size():
			if absf(heights[i] - bottom) < 0.001:
				level = i
		assert_gte(level, 0, "La impresora %s está sobre una tabla" % printer.printer_id)
		if level >= 0:
			assert_lt(top, MetalRackModel.BOARDS[level + 1] - MetalRackModel.BOARD_THICKNESS / 2.0, "%s no atraviesa la tabla de arriba" % printer.printer_id)
		checked += 1
	assert_eq(checked, 15, "Las 15 impresoras de las 5 estanterías")


func test_wall_gaps_reach_the_wall_behind_each_slot() -> void:
	var layout: RoomLayout = RoomLayout.for_space(Game.state.space_id)
	assert_eq(layout.wall_gaps.size(), layout.slots.size(), "Una distancia por lugar")
	for slot: int in layout.slots.size():
		var at: Transform3D = layout.slots[slot]
		var back: Vector3 = -at.basis.z
		var gap: float = layout.wall_gaps[slot]
		if gap < 0.0:
			continue
		var wall_point: Vector3 = at.origin + back * gap
		assert_almost_eq(minf(wall_point.x, wall_point.z), WALL_PLANE, 0.001, "Lugar %d: la distancia llega a la pared" % slot)
	# Sin pared donde colgar: el del medio (lejos de toda pared) y el de la
	# ventana (lo que se cuelga taparía el hueco).
	assert_eq(layout.wall_gaps[MIDDLE_SLOT], FurnitureModel.NO_WALL)
	var middle: Vector3 = layout.slots[MIDDLE_SLOT].origin
	assert_gt(minf(middle.x, middle.z) - WALL_PLANE, 1.0, "El lugar del medio no tiene pared cerca")
	assert_eq(layout.wall_gaps[WINDOW_SLOT], FurnitureModel.NO_WALL)
	var under_window: float = layout.slots[WINDOW_SLOT].origin.z
	assert_true(under_window > WindowSpec.HOLE_Z.x and under_window < WindowSpec.HOLE_Z.y, "El lugar 0 está bajo la ventana")


func test_hanging_furniture_sits_on_the_wall_or_on_its_own_stand() -> void:
	var layout: RoomLayout = RoomLayout.for_space(Game.state.space_id)
	for id: String in FurnitureModel.HANGING:
		var state: GameState = GameState.new_game(Game.rules, SEED)
		var placed: Dictionary[int, int] = {}
		for slot: int in layout.slots.size():
			if slot == WINDOW_SLOT:
				continue
			var item: OwnedFurniture = OwnedFurniture.new(state.take_uid(), id, slot)
			state.furniture.append(item)
			placed[slot] = item.uid
		await _load(state)
		for slot: int in placed:
			var node: Node3D = _room.get_node("Furniture%d" % placed[slot])
			var bounds: AABB = node.transform * PropBounds.local_aabb(node)
			var body: MeshInstance3D = node.get_node("Body")
			if layout.wall_gaps[slot] >= 0.0:
				var to_wall: float = minf(bounds.position.x, bounds.position.z) - WALL_PLANE
				assert_between(to_wall, 0.0, WALL_TOLERANCE, "%s en el lugar %d: pegado a la pared" % [id, slot])
				assert_same(body.mesh, FurnitureModel.body_mesh(id, true), "%s en el lugar %d: sin pie" % [id, slot])
			else:
				assert_same(body.mesh, FurnitureModel.body_mesh(id, false), "%s en el lugar %d: con su pie" % [id, slot])
				assert_gt(minf(bounds.position.x, bounds.position.z) - WALL_PLANE, 0.5, "%s en el lugar %d: lejos de las paredes" % [id, slot])
				_assert_stand_holds_it_up(body, id)


func test_the_cube_shelf_stands_against_the_wall() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	var against: OwnedFurniture = OwnedFurniture.new(state.take_uid(), "estanteria_cubos", 3)
	var middle: OwnedFurniture = OwnedFurniture.new(state.take_uid(), "estanteria_cubos", MIDDLE_SLOT)
	state.furniture.append_array([against, middle])
	await _load(state)
	var node: Node3D = _room.get_node("Furniture%d" % against.uid)
	var bounds: AABB = node.transform * PropBounds.local_aabb(node)
	assert_between(bounds.position.z - WALL_PLANE, 0.0, WALL_TOLERANCE, "Arrimado a la pared del fondo")
	var centered: Node3D = _room.get_node("Furniture%d" % middle.uid)
	assert_almost_eq(PropBounds.local_aabb(centered).get_center().z, 0.0, 0.001, "Sin pared, centrado en su lugar")


## Lo que sostiene la repisa o el tablero sin pared: dos parantes que van del
## piso hasta más arriba que su tabla o tablero de abajo.
func _assert_stand_holds_it_up(body: MeshInstance3D, id: String) -> void:
	var post_x: float = FilamentStorageModels.SHELF_BRACKET_X if id == "repisa_filamento" else PegboardModel.STAND_X
	var holds_up_to: float = FilamentStorageModels.SHELF_TOPS[0] if id == "repisa_filamento" else PegboardModel.BOARD_BOTTOM
	for side: float in [-1.0, 1.0]:
		var low: float = INF
		var high: float = -INF
		for vertex: Vector3 in body.mesh.get_faces():
			if absf(vertex.x - side * post_x) <= FurnitureParts.STAND_POST / 2.0 + 0.001:
				low = minf(low, vertex.y)
				high = maxf(high, vertex.y)
		assert_almost_eq(low, 0.0, 0.001, "%s: el parante %s llega al piso" % [id, side])
		assert_gt(high, holds_up_to, "%s: el parante %s sostiene lo de arriba" % [id, side])


func _load(state: GameState) -> void:
	if _main != null and is_instance_valid(_main):
		_main.queue_free()
		await wait_process_frames(1)
	Game._start(state)
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_room = _main.get_node("WorldView/SubViewport/Room")
