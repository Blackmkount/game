extends GutTest
## Las siete familias de impresoras (biblia de arte §9.2–9.3): se arman sin
## errores, caben en la estantería, tienen las partes del contrato de su modo
## (abiertas, cerradas, de resina), cuestan lo que dice el presupuesto (§5.2)
## y, en el cuarto, TODAS muestran la pieza que crece y su falla. De noche
## cada una tiene su halo del color del estado. Con el zoom lejos cada una
## pasa a su versión lejana (§5.2 y §13).

const MAIN_SCENE: PackedScene = preload("res://game/scenes/main.tscn")
const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
const SEED: int = 1234
const FAMILIES: Array[String] = ["cubo_uno", "rayo_mini", "rayo_x1", "prisma_mc", "boveda_p1", "titan_pro", "gota_r1"]
const OPEN: Array[String] = ["cubo_uno", "rayo_mini", "rayo_x1", "prisma_mc"]
const CLOSED: Array[String] = ["boveda_p1", "titan_pro"]
## Presupuesto por impresora (biblia §5.2): triángulos y llamadas de dibujo
## con la pasada de sombra, en el piso y en un mueble.
const FLOOR_MAX_TRIANGLES: int = 2400
const FLOOR_MAX_DRAW_CALLS: int = 9
const FURNITURE_MAX_TRIANGLES: int = 1200
const FURNITURE_MAX_DRAW_CALLS: int = 6
## La versión lejana (§5.2): triángulos de su malla y llamadas con la sombra
## (sin trabajo; las cerradas, dos más: la cama y la luz de adentro).
const FAR_MAX_TRIANGLES: int = 450
const FAR_MAX_DRAW_CALLS: int = 3
## Lo que se esconde con el zoom lejos, por modo (PrinterView.set_far).
const FAR_HIDDEN_OPEN: Array[String] = ["Gantry", "PrintHead", "Spool"]
const FAR_HIDDEN_CLOSED: Array[String] = ["PrintHead"]
const FAR_HIDDEN_RESIN: Array[String] = ["Plate", "Resin", "Lid", "PieceSpot"]
## Dos familias se distinguen por la silueta: su caja difiere al menos esto
## en alguna medida (m).
const SILHOUETTE_GAP: float = 0.02

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


func test_the_catalog_has_these_seven_families() -> void:
	var ids: Array[String] = []
	for printer: Dictionary in Game.catalog.files["printers"]:
		ids.append(String(printer["id"]))
	ids.sort()
	var expected: Array[String] = FAMILIES.duplicate()
	expected.sort()
	assert_eq(ids, expected, "Cada impresora del catálogo tiene su modelo")


func test_every_family_builds_and_fits_the_shelf() -> void:
	for id: String in FAMILIES:
		for detail: float in [PrinterParts.FLOOR_DETAIL, PrinterParts.FURNITURE_DETAIL]:
			var printer: Node3D = PrinterModel.build(_root, "P", id, "f2efe6", detail)
			var bounds: AABB = PropBounds.local_aabb(printer)
			assert_almost_eq(bounds.position.y, 0.0, 0.001, "%s apoyada (detalle %s)" % [id, detail])
			assert_lte(bounds.end.y, PrinterModel.MAX_HEIGHT, "%s cabe en la estantería (detalle %s)" % [id, detail])
			assert_lte(bounds.size.x, 0.6, "%s cabe en la mesa auxiliar" % id)
			assert_lte(bounds.size.z, 0.55, "%s cabe en el fondo de la mesa auxiliar" % id)
			var display: MeshInstance3D = printer.get_node_or_null("Display")
			assert_not_null(display, "%s tiene pantallita" % id)
			if display != null:
				assert_eq(display.material_override, WorldPalette.glow("ffffff", "printer_display"))
				assert_eq(display.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			assert_same((printer.get_node("Body") as MeshInstance3D).material_override, WorldPalette.kit(), "%s: lo fijo es una malla del kit" % id)
			for marker_name: String in ["PieceAnchor", "TrayAnchor", "BedLight"]:
				assert_true(printer.get_node_or_null(marker_name) is Marker3D, "%s: %s" % [id, marker_name])
			_root.remove_child(printer)
			printer.free()


func test_each_mode_has_its_parts() -> void:
	for id: String in OPEN:
		var printer: Node3D = PrinterModel.build(_root, id, id)
		for part: String in ["Gantry", "PrintHead/Carriage", "Spool/Filament"]:
			assert_true(printer.get_node_or_null(part) is MeshInstance3D, "%s: %s" % [id, part])
		for marker_name: String in ["Bed", "HeadRest", "HeadPark"]:
			assert_true(printer.get_node_or_null(marker_name) is Marker3D, "%s: %s" % [id, marker_name])
	for id: String in CLOSED:
		var printer: Node3D = PrinterModel.build(_root, id, id)
		for part: String in ["Platform", "Interior", "PrintHead/Carriage"]:
			assert_true(printer.get_node_or_null(part) is MeshInstance3D, "%s: %s" % [id, part])
		for marker_name: String in ["PlatformLow", "HeadRest", "HeadPark"]:
			assert_true(printer.get_node_or_null(marker_name) is Marker3D, "%s: %s" % [id, marker_name])
		assert_false(printer.has_node("Bed"), "%s no es abierta" % id)
		var anchor: Vector3 = (printer.get_node("PieceAnchor") as Node3D).position
		var rest: Vector3 = (printer.get_node("HeadRest") as Node3D).position
		assert_almost_eq(rest.y - anchor.y, PrinterView.HEAD_CLEARANCE, 0.0001, "%s: la cama empieza bajo la boquilla" % id)
		assert_lt((printer.get_node("PlatformLow") as Node3D).position.y, anchor.y - PieceModel.SIZES["M"].y, "%s: la cama baja más que la pieza más alta" % id)
	var resin: Node3D = PrinterModel.build(_root, "gota_r1", "gota_r1")
	for part: String in ["Plate", "Resin", "Lid"]:
		assert_true(resin.get_node_or_null(part) is MeshInstance3D, "gota_r1: %s" % part)
	for marker_name: String in ["PlateTop", "VatFloor"]:
		assert_true(resin.get_node_or_null(marker_name) is Marker3D, "gota_r1: %s" % marker_name)
	var lid: MeshInstance3D = resin.get_node("Lid")
	assert_true(SceneBudget.is_transparent(lid.material_override), "La tapa ámbar es transparente")
	assert_eq(lid.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "La tapa no da sombra")
	var top: float = (resin.get_node("PlateTop") as Node3D).position.y
	var anchor_y: float = (resin.get_node("PieceAnchor") as Node3D).position.y
	assert_gte(top - anchor_y, PieceModel.SIZES["S"].y, "Arriba, la placa deja colgar la pieza entera")


func test_every_family_fits_its_budget_on_the_floor_and_on_furniture() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_root.add_child(sun)
	for id: String in FAMILIES:
		var floor_budget: RefCounted = _measure(id, PrinterParts.FLOOR_DETAIL)
		assert_lte(floor_budget.get("triangles"), FLOOR_MAX_TRIANGLES, "%s en el piso: triángulos" % id)
		assert_lte(floor_budget.get("draw_calls"), FLOOR_MAX_DRAW_CALLS, "%s en el piso: llamadas" % id)
		var furniture_budget: RefCounted = _measure(id, PrinterParts.FURNITURE_DETAIL)
		assert_lte(furniture_budget.get("triangles"), FURNITURE_MAX_TRIANGLES, "%s en un mueble: triángulos" % id)
		assert_lte(furniture_budget.get("draw_calls"), FURNITURE_MAX_DRAW_CALLS, "%s en un mueble: llamadas" % id)
		assert_lte(furniture_budget.get("shadow_meshes"), 1, "%s en un mueble: solo el cuerpo da sombra" % id)


func test_the_seven_silhouettes_differ() -> void:
	var sizes: Dictionary[String, Vector3] = {}
	for id: String in FAMILIES:
		sizes[id] = PropBounds.local_aabb(PrinterModel.build(_root, id, id)).size
	for a: int in FAMILIES.size():
		for b: int in range(a + 1, FAMILIES.size()):
			var gap: Vector3 = (sizes[FAMILIES[a]] - sizes[FAMILIES[b]]).abs()
			assert_gt(maxf(gap.x, maxf(gap.y, gap.z)), SILHOUETTE_GAP, "%s y %s se distinguen por la silueta" % [FAMILIES[a], FAMILIES[b]])


func test_furniture_printers_are_lighter_than_the_floor_one() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	var table: OwnedFurniture = OwnedFurniture.new(state.take_uid(), "mesa_trabajo", 2)
	state.furniture.append(table)
	state.printers.append(OwnedPrinter.new(state.take_uid(), "cubo_uno", table.uid))
	await _load(state)
	var floor_printer: Node3D = _room.get_node("Printer%d" % state.printers[0].uid)
	var table_printer: Node3D = _room.get_node("Printer%d" % state.printers[1].uid)
	assert_eq((floor_printer.get_node("Gantry") as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "La del piso: todo da sombra")
	for part: String in ["Gantry", "PrintHead/Carriage", "Spool/Filament"]:
		assert_eq((table_printer.get_node(part) as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "La del mueble: %s sin sombra" % part)
	var floor_triangles: int = (floor_printer.get_node("Body") as MeshInstance3D).mesh.get_faces().size()
	var table_triangles: int = (table_printer.get_node("Body") as MeshInstance3D).mesh.get_faces().size()
	assert_lt(table_triangles, floor_triangles, "La del mueble, con menos detalle")


## Biblia §2.6: en las impresoras de los muebles solo "Body" da sombra; la
## pieza, el espagueti y la bandeja también son de "solo Body". En la del
## piso dan sombra.
func test_on_furniture_only_the_body_casts_a_shadow() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	DebugTools.fill_workshop(state, Game.rules)
	DebugTools.give_jobs(state, Game.rules)
	await _load(state)
	for printer: OwnedPrinter in state.printers:
		var node: Node3D = _room.get_node("Printer%d" % printer.uid)
		var expected: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if printer.is_on_floor() else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for part: String in ["PieceSpot/Piece", "PieceSpot/Spaghetti", "Tray0", "Tray5"]:
			assert_eq((node.get_node(part) as MeshInstance3D).cast_shadow, expected, "%s (%s): %s" % [printer.printer_id, "piso" if printer.is_on_floor() else "mueble", part])


## Cada familia tiene su malla lejana: lo fijo con menos detalle (≤ 450
## triángulos, menos que la de mueble), del tamaño de la impresora entera
## (con lo que va aparte), y cuesta ≤ 3
## llamadas con la sombra (las cerradas, dos más: la cama y la luz de
## adentro).
func test_every_family_has_a_cheap_far_version_of_the_same_size() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_root.add_child(sun)
	for id: String in FAMILIES:
		var far: ArrayMesh = PrinterModel.far_body(id, "3b7fe0")
		assert_eq(PrinterModel.far_body(id, "3b7fe0"), far, "%s: en caché" % id)
		var far_triangles: int = far.get_faces().size() / 3
		assert_lte(far_triangles, FAR_MAX_TRIANGLES, "%s lejana: triángulos" % id)
		var printer: Node3D = PrinterModel.build(_root, "Measured", id, "3b7fe0", PrinterParts.FURNITURE_DETAIL)
		var body: MeshInstance3D = printer.get_node("Body")
		assert_lt(far_triangles, body.mesh.get_faces().size() / 3, "%s lejana: menos que la de mueble" % id)
		var near_box: AABB = PropBounds.local_aabb(printer)
		var far_box: AABB = far.get_aabb()
		assert_almost_eq(far_box.size.x, near_box.size.x, 0.03, "%s lejana: mismo ancho" % id)
		assert_almost_eq(far_box.size.z, near_box.size.z, 0.03, "%s lejana: mismo fondo" % id)
		assert_almost_eq(far_box.end.y, near_box.end.y, 0.03, "%s lejana: mismo alto" % id)
		_root.remove_child(printer)
		printer.free()
	var state: GameState = GameState.new_game(Game.rules, SEED)
	DebugTools.fill_workshop(state, Game.rules)
	await _load(state)
	await _set_zoom(0)
	assert_true(_room.far_printers, "Con el zoom lejos")
	for printer: OwnedPrinter in state.printers:
		var node: Node3D = _room.get_node("Printer%d" % printer.uid)
		var calls: int = SceneBudget.measure(node).get("draw_calls")
		var extra: int = 2 if printer.printer_id in CLOSED else 0
		assert_lte(calls, FAR_MAX_DRAW_CALLS + extra, "%s lejana: llamadas" % printer.printer_id)


## Con el zoom lejos cada impresora del cuarto usa su malla lejana y esconde
## lo que se mueve (los nodos siguen ahí); la pieza que crece, su capa
## caliente, el espagueti, la pantallita y la luz de adentro se siguen
## viendo; la zona que se toca no cambia. Con el zoom normal todo vuelve.
func test_at_far_zoom_every_printer_switches_to_its_far_version() -> void:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	DebugTools.fill_workshop(state, Game.rules)
	DebugTools.give_jobs(state, Game.rules)
	await _load(state)
	var near_bodies: Dictionary[int, Mesh] = {}
	var touch: Dictionary[int, AABB] = {}
	var pieces: Dictionary[int, bool] = {}
	for printer: OwnedPrinter in state.printers:
		var node: Node3D = _room.get_node("Printer%d" % printer.uid)
		near_bodies[printer.uid] = (node.get_node("Body") as MeshInstance3D).mesh
		touch[printer.uid] = _room.item_for(WorldInteractable.Kind.PRINTER, printer.uid).bounds
		pieces[printer.uid] = (node.get_node("PieceSpot/Piece") as Node3D).visible
	await _set_zoom(0)
	assert_true(_room.far_printers)
	for printer: OwnedPrinter in state.printers:
		var node: Node3D = _room.get_node("Printer%d" % printer.uid)
		var what: String = "%s %d" % [printer.printer_id, printer.uid]
		var view: PrinterView = node.get_node("View")
		assert_true(view.is_far(), what + ": lejana")
		assert_eq((node.get_node("Body") as MeshInstance3D).mesh, PrinterModel.far_body(printer.printer_id, WorldPalette.PLASTIC_BEIGE if state.spools.is_empty() else _spool_hex(state)), what + ": su malla lejana")
		for part: String in _far_hidden(printer.printer_id):
			assert_not_null(node.get_node_or_null(part), what + ": %s sigue existiendo" % part)
			assert_false((node.get_node(part) as Node3D).visible, what + ": %s escondido" % part)
		for i: int in PrinterView.TRAY_BLOCKS:
			assert_false((node.get_node("Tray%d" % i) as Node3D).visible, what + ": sin bandeja")
		assert_true((node.get_node("Display") as Node3D).visible, what + ": la pantallita se ve")
		if printer.printer_id in CLOSED:
			assert_true((node.get_node("Interior") as Node3D).visible, what + ": la luz de adentro se ve")
			assert_true((node.get_node("Platform") as Node3D).visible, what + ": y la cama")
		if printer.printer_id != "gota_r1":
			assert_eq((node.get_node("PieceSpot/Piece") as Node3D).is_visible_in_tree(), pieces[printer.uid], what + ": la pieza se sigue viendo")
		assert_eq(_room.item_for(WorldInteractable.Kind.PRINTER, printer.uid).bounds, touch[printer.uid], what + ": se toca igual")
	# Quieto con el zoom lejos, cada cuadro no pide memoria.
	var before: int = OS.get_static_memory_usage()
	for i: int in 60:
		_room.step(1.0 / 60.0)
	assert_eq(OS.get_static_memory_usage(), before, "Con el zoom lejos, los cuadros no piden memoria")
	await _set_zoom(CameraRig.DEFAULT_ZOOM_INDEX)
	assert_false(_room.far_printers)
	for printer: OwnedPrinter in state.printers:
		var node: Node3D = _room.get_node("Printer%d" % printer.uid)
		assert_eq((node.get_node("Body") as MeshInstance3D).mesh, near_bodies[printer.uid], "%s: de vuelta su malla" % printer.printer_id)
		for part: String in _far_hidden(printer.printer_id):
			assert_true((node.get_node(part) as Node3D).visible, "%s: de vuelta %s" % [printer.printer_id, part])


## Una impresora que se compra con el zoom lejos llega ya en su versión
## lejana, con la zona que se toca de siempre.
func test_a_printer_that_appears_at_far_zoom_is_far_too() -> void:
	await _load(GameState.new_game(Game.rules, SEED))
	await _set_zoom(0)
	var table: OwnedFurniture = OwnedFurniture.new(Game.state.take_uid(), "mesa_trabajo", 3)
	Game.state.furniture.append(table)
	var printer: OwnedPrinter = OwnedPrinter.new(Game.state.take_uid(), "rayo_x1", table.uid)
	Game.state.printers.append(printer)
	_room.sync_models(false)
	var node: Node3D = _room.get_node("Printer%d" % printer.uid)
	assert_true((node.get_node("View") as PrinterView).is_far(), "Llega lejana")
	assert_false((node.get_node("Gantry") as Node3D).visible)
	var far_zone: AABB = _room.item_for(WorldInteractable.Kind.PRINTER, printer.uid).local_bounds
	# El mismo cuarto armado con el zoom normal: la misma zona.
	await _load(Game.state)
	assert_false((_room.get_node("Printer%d/View" % printer.uid) as PrinterView).is_far())
	assert_eq(_room.item_for(WorldInteractable.Kind.PRINTER, printer.uid).local_bounds, far_zone, "La misma zona que con el zoom normal")


func test_an_open_compact_printer_grows_the_piece_and_raises_its_head() -> void:
	await _load(_with_floor_printer("rayo_mini"))
	var printer: Node3D = _floor_printer()
	var scale: float = PrinterModel.frame_scale("rayo_mini")
	_start_print("llavero")
	Game.advance(20.0)
	var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
	var height: float = PieceModel.shown_height(piece)
	assert_true(piece.visible)
	assert_gt(height, PieceModel.LAYER_STEP, "Crece")
	var anchor: Vector3 = (printer.get_node("PieceAnchor") as Node3D).position
	assert_eq((printer.get_node("PieceSpot") as Node3D).position, anchor, "Sobre la cama")
	var head: Node3D = printer.get_node("PrintHead")
	assert_almost_eq(head.position.y, maxf((printer.get_node("HeadRest") as Node3D).position.y, anchor.y + PrinterView.HEAD_CLEARANCE * scale + height), 0.0001, "El cabezal sube con la pieza")
	assert_almost_eq((printer.get_node("Gantry") as Node3D).position.y, head.position.y, 0.0001, "Y su brazo")


func test_a_closed_printer_lowers_its_bed_and_lights_up_by_state() -> void:
	for id: String in CLOSED:
		await _load(_with_floor_printer(id))
		var printer: Node3D = _floor_printer()
		var interior: MeshInstance3D = printer.get_node("Interior")
		var platform: Node3D = printer.get_node("Platform")
		var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
		var idle_interior: Material = interior.material_override
		assert_almost_eq(platform.position.y, (printer.get_node("PlatformLow") as Node3D).position.y, 0.0001, "%s: sin trabajo, la cama abajo" % id)
		_start_print("llavero")
		var previous: float = 0.0
		var grew: int = 0
		var anchor: Vector3 = (printer.get_node("PieceAnchor") as Node3D).position
		for second: int in 8:
			Game.advance(2.0)
			var height: float = PieceModel.shown_height(piece)
			assert_gte(height, previous, "%s: nunca baja" % id)
			if height > previous:
				grew += 1
			previous = height
			if height >= PieceModel.LAYER_STEP:
				var top: float = (printer.get_node("PieceSpot") as Node3D).position.y + height
				assert_almost_eq(top, anchor.y, 0.0001, "%s: la pieza termina bajo la boquilla" % id)
				assert_almost_eq(platform.position.y, anchor.y - height, 0.0001, "%s: la cama baja con la pieza" % id)
		assert_gt(grew, 2, "%s: la pieza crece mientras imprime" % id)
		assert_eq(interior.material_override, WorldPalette.glow(PrinterModel.interior_hex(id)), "%s: adentro, la luz de imprimir" % id)
		assert_ne(interior.material_override, idle_interior)
		var hex: String = PieceModel.filament_hex(Game.rules, Game.state.printers[0].job.color_id)
		assert_true(DebugTools.force_fail(Game.sim, Game.state.printers[0].uid, FailureRules.SPAGHETTI))
		Game.advance(30.0)
		assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED)
		assert_eq(piece.material_override, WorldPalette.solid(WorldPalette.FAILED_PIECE), "%s: la pieza fallida, oscura" % id)
		var nest: MeshInstance3D = printer.get_node("PieceSpot/Spaghetti")
		assert_true(nest.visible, "%s: el espagueti se ve adentro" % id)
		assert_eq(nest.material_override, PieceModel.spaghetti_material(hex))
		assert_eq(interior.material_override, WorldPalette.glow(LookPalette.STATE_FAILED), "%s: el interior pasa a rojo" % id)
		assert_true(Game.clean_printer(Game.state.printers[0].uid).ok)
		assert_eq(interior.material_override, idle_interior, "%s: limpia, la luz de siempre" % id)
		assert_false(piece.visible)


func test_a_resin_piece_hangs_from_the_rising_plate_and_falls_when_it_fails() -> void:
	await _load(_with_floor_printer("gota_r1"))
	var printer: Node3D = _floor_printer()
	var plate: Node3D = printer.get_node("Plate")
	var spot: Node3D = printer.get_node("PieceSpot")
	var piece: MeshInstance3D = printer.get_node("PieceSpot/Piece")
	var top_y: float = (printer.get_node("PlateTop") as Node3D).position.y
	assert_almost_eq(plate.position.y, top_y, 0.0001, "Sin trabajo, la placa arriba")
	_start_print("llavero", "resina")
	var resin: MeshInstance3D = printer.get_node("Resin")
	var hex: String = PieceModel.filament_hex(Game.rules, Game.state.printers[0].job.color_id)
	assert_eq(resin.material_override, WorldPalette.solid(hex), "La resina, del color del trabajo")
	var previous: float = 0.0
	var grew: int = 0
	for second: int in 10:
		Game.advance(2.0)
		var height: float = PieceModel.shown_height(piece)
		assert_gte(height, previous, "Nunca baja")
		if height > previous:
			grew += 1
		previous = height
		if height < PieceModel.LAYER_STEP:
			continue
		var bounds: AABB = piece.global_transform * piece.mesh.get_aabb()
		var plate_bottom: float = (printer.global_transform * plate.position).y
		assert_almost_eq(bounds.end.y, plate_bottom, 0.0005, "El borde de arriba de la pieza, pegado a la placa")
		assert_almost_eq(plate.position.y, (printer.get_node("PieceAnchor") as Node3D).position.y + height, 0.0001, "La placa sube con la pieza")
		assert_eq(piece.material_override, WorldPalette.printing(hex), "Con la capa caliente")
		var hot: float = piece.get_instance_shader_parameter(&"hot_top")
		assert_almost_eq((piece.global_transform * Vector3(0.0, hot, 0.0)).y, bounds.position.y, 0.0005, "La capa nueva (caliente) queda abajo, sobre la resina")
	assert_gt(grew, 2, "La pieza crece hacia abajo mientras imprime")
	assert_true(DebugTools.force_fail(Game.sim, Game.state.printers[0].uid, FailureRules.WARPING))
	Game.advance(30.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.FAILED)
	assert_true(piece.visible, "La pieza fallida se ve")
	assert_eq(piece.material_override, WorldPalette.solid(WorldPalette.FAILED_PIECE))
	assert_almost_eq(plate.position.y, top_y, 0.0001, "La placa sube vacía")
	var fallen: AABB = piece.global_transform * piece.mesh.get_aabb()
	var vat_floor: float = (printer.global_transform * (printer.get_node("VatFloor") as Node3D).position).y
	assert_almost_eq(fallen.position.y, vat_floor, 0.002, "Cayó a la tina")
	assert_gt(absf(spot.rotation_degrees.z) + absf(spot.rotation_degrees.x), 10.0, "Inclinada")
	assert_false((printer.get_node("PieceSpot/Spaghetti") as Node3D).visible, "La resina no hace espagueti")


func test_each_printer_has_a_night_halo_of_its_state_color() -> void:
	var state: GameState = _with_floor_printer("boveda_p1")
	var table: OwnedFurniture = OwnedFurniture.new(state.take_uid(), "mesa_trabajo", 2)
	state.furniture.append(table)
	state.printers.append(OwnedPrinter.new(state.take_uid(), "rayo_x1", table.uid))
	await _load(state)
	var halos: HaloField = _room.halos
	# Los de las impresoras van primero; detrás, los del escritorio y las
	# luces de noche de la decoración (RoomDecor).
	assert_eq(halos.count(), 2 + ComputerDeskModel.night_lights().size() + DecorWall.night_lights().size(), "Un halo por impresora (y los del escritorio y la decoración)")
	assert_false(halos.visible, "De día no se dibujan")
	assert_eq(halos.color_of(0), HaloField.OFF, "Sin trabajo, apagado")
	halos.set_night(1.0)
	assert_true(halos.visible, "De noche sí")
	_start_print("llavero")
	assert_eq(halos.color_of(0), Color(LookPalette.STATE_PRINTING), "Imprimiendo: cálido")
	assert_eq(halos.color_of(1), HaloField.OFF, "La otra sigue apagada")
	Game.advance(60.0)
	assert_eq(Game.state.printers[0].job.status, PrintJob.Status.DONE)
	assert_eq(halos.color_of(0), Color(LookPalette.STATE_DONE), "Lista: verde")
	assert_eq((_floor_printer().get_node("Interior") as MeshInstance3D).material_override, WorldPalette.glow(LookPalette.STATE_DONE), "Y su interior, verde")
	# El halo queda bajo la impresora, apoyado donde ella apoya.
	var at: Transform3D = halos.transform_of(0)
	var printer: Node3D = _floor_printer()
	assert_almost_eq(Vector2(at.origin.x, at.origin.z).distance_to(Vector2(printer.position.x, printer.position.z)), 0.0, 0.1)
	assert_almost_eq(at.origin.y, printer.position.y + HaloField.LIFT, 0.001)
	halos.set_night(0.0)
	assert_false(halos.visible)


## Una partida nueva con la impresora del piso de otra familia.
func _with_floor_printer(printer_id: String) -> GameState:
	var state: GameState = GameState.new_game(Game.rules, SEED)
	state.printers[0].printer_id = printer_id
	return state


func _load(state: GameState) -> void:
	if _main != null and is_instance_valid(_main):
		_main.queue_free()
		await wait_process_frames(1)
	Game._start(state)
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	await wait_process_frames(2)
	_room = _main.get_node("WorldView/SubViewport/Room")


## Lleva la cámara al escalón de zoom `index` de una vez y deja pasar dos
## cuadros (RoomView.step decide la versión de las impresoras).
func _set_zoom(index: int) -> void:
	_room.camera.set_zoom_index(index)
	_room.camera.snap_to_goal()
	await wait_process_frames(2)


## Lo que la versión lejana esconde de una familia.
static func _far_hidden(printer_id: String) -> Array[String]:
	if printer_id in OPEN:
		return FAR_HIDDEN_OPEN
	if printer_id in CLOSED:
		return FAR_HIDDEN_CLOSED
	return FAR_HIDDEN_RESIN


## El color del primer carrete de la partida (con el que se arman las
## impresoras, RoomView).
static func _spool_hex(state: GameState) -> String:
	var color: Dictionary = DataLookup.config_entry(Game.catalog, "filament_colors", state.spools[0].color_id)
	return color.get("hex", WorldPalette.PLASTIC_BEIGE)


func _floor_printer() -> Node3D:
	return _room.get_node("Printer%d" % Game.state.printers[0].uid)


## Empieza a imprimir un pedido `order_id` en la impresora del piso con un
## carrete nuevo de `material_id` (sin pasar por el computador ni revisar el
## material: aquí solo importa lo que se ve).
func _start_print(order_id: String, material_id: String = "pla") -> Order:
	var state: GameState = Game.state
	var order: Order = Order.new(state.take_uid(), order_id, state.game_seconds)
	order.stage = Order.Stage.READY_TO_PRINT
	state.orders.append(order)
	var spool: Spool = Spool.new(state.take_uid(), material_id, "rojo", 5000)
	state.spools.append(spool)
	PrintFlow.start_job(Game.sim, order, state.printers[0], spool, "normal", state.game_seconds)
	Game.advance(0.0)
	return order


## Triángulos y llamadas de una impresora sola con ese detalle (con el sol
## de _root dando sombra).
func _measure(id: String, detail: float) -> RefCounted:
	var printer: Node3D = PrinterModel.build(_root, "Measured", id, "f2efe6", detail)
	var budget: RefCounted = SceneBudget.measure(_root)
	_root.remove_child(printer)
	printer.free()
	return budget
