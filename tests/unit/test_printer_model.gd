extends GutTest
## La impresora estrella del kit (Cubo Uno, biblia de arte §9.3), su carrete,
## el nido de espagueti y los destellos de "pieza lista": medidas, nodos del
## contrato con PrinterView y presupuesto (§5.2).

const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
## Presupuesto de la impresora del piso (biblia §5.2, detalle 1,0):
## triángulos y llamadas de dibujo contando la pasada de sombra.
const FLOOR_PRINTER_MAX_TRIANGLES: int = 2400
const FLOOR_PRINTER_MAX_DRAW_CALLS: int = 9
## Lo que el cabezal sostiene sobre la pieza (PrinterView.HEAD_CLEARANCE): la
## boquilla queda casi tocando la capa de arriba.
const NOZZLE_GAP_MAX: float = 0.004

var _root: Node3D


func before_each() -> void:
	_root = Node3D.new()
	add_child_autofree(_root)


func test_the_cubo_uno_is_real_size_and_fits_the_shelf() -> void:
	var bounds: AABB = PropBounds.local_aabb(_cubo())
	assert_between(bounds.size.x, 0.4, 0.5, "Una impresora tipo Ender mide unos 0,45 m")
	assert_almost_eq(bounds.position.y, 0.0, 0.001, "Apoyada en el piso")
	assert_lte(bounds.end.y, PrinterModel.MAX_HEIGHT, "Con su carrete cabe en la estantería")


func test_the_cubo_uno_has_every_node_of_the_contract() -> void:
	var printer: Node3D = _cubo()
	for mesh_name: String in ["Body", "Gantry", "PrintHead/Carriage", "Display", "Spool/Filament"]:
		assert_true(printer.get_node_or_null(mesh_name) is MeshInstance3D, mesh_name)
	for marker_name: String in ["Bed", "PieceAnchor", "HeadRest", "HeadPark", "TrayAnchor", "BedLight"]:
		assert_true(printer.get_node_or_null(marker_name) is Marker3D, marker_name)
	assert_same((printer.get_node("Body") as MeshInstance3D).material_override, WorldPalette.kit(), "Lo fijo es una malla del kit")
	assert_eq((printer.get_node("Display") as MeshInstance3D).material_override, WorldPalette.glow("ffffff", "printer_display"))
	assert_eq((printer.get_node("Display") as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_eq(printer.get_node("PrintHead").position, printer.get_node("HeadRest").position, "El cabezal empieza quieto en su lugar")
	assert_eq((printer.get_node("Gantry") as Node3D).position.y, printer.get_node("HeadRest").position.y, "La barra X a la altura del cabezal")


func test_the_cubo_uno_markers_are_the_view_constants() -> void:
	var printer: Node3D = _cubo()
	var anchor: Vector3 = (printer.get_node("PieceAnchor") as Node3D).position
	assert_almost_eq(anchor, Vector3(0.0, PrinterView.BED_TOP, PrinterView.PIECE_Z), Vector3.ONE * 0.0001, "La pieza en la cama")
	assert_almost_eq((printer.get_node("Bed") as Node3D).position, anchor, Vector3.ONE * 0.0001)
	assert_almost_eq((printer.get_node("HeadRest") as Node3D).position.y, PrinterView.HEAD_REST_Y, 0.0001)
	assert_almost_eq((printer.get_node("HeadPark") as Node3D).position.x, PrinterView.HEAD_PARK_X, 0.0001)
	var tray: Vector3 = Vector3(PrinterView.TRAY_START_X, PrinterView.TRAY_BASE_Y, PrinterView.TRAY_Z)
	assert_almost_eq((printer.get_node("TrayAnchor") as Node3D).position, tray, Vector3.ONE * 0.0001)
	var light: Vector3 = (printer.get_node("BedLight") as Node3D).position
	assert_gt(light.y, anchor.y + 0.25, "La barra LED alumbra la cama desde arriba")


func test_the_bed_and_the_nozzle_are_where_the_view_puts_the_piece() -> void:
	var printer: Node3D = _cubo()
	var anchor: Vector3 = (printer.get_node("PieceAnchor") as Node3D).position
	var bed: Array[float] = _heights(_hits(printer.get_node("Body"), anchor + Vector3(0.0, 0.05, 0.0), Vector3.DOWN))
	assert_false(bed.is_empty())
	assert_almost_eq(bed.max(), anchor.y, 0.001, "La lámina de la cama está justo bajo la pieza")
	var rest: Vector3 = printer.get_node("HeadRest").position
	var tip: float = (printer.get_node("PrintHead/Carriage") as MeshInstance3D).mesh.get_aabb().position.y
	assert_between(tip, -PrinterView.HEAD_CLEARANCE, -PrinterView.HEAD_CLEARANCE + NOZZLE_GAP_MAX, "La boquilla casi toca la capa de arriba")
	# La punta (los vértices de más abajo del cabezal) queda sobre el centro
	# de la pieza. (Con un rayo no se puede: Geometry3D descarta triángulos
	# tan chicos como los de la boquilla.)
	var vertices: PackedVector3Array = (printer.get_node("PrintHead/Carriage") as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var sum: Vector3 = Vector3.ZERO
	var count: int = 0
	for vertex: Vector3 in vertices:
		if vertex.y < tip + 0.001:
			sum += vertex
			count += 1
	assert_gt(count, 0)
	var center: Vector3 = sum / maxi(count, 1)
	assert_almost_eq(Vector2(center.x, center.z), Vector2(anchor.x - rest.x, anchor.z - rest.z), Vector2.ONE * 0.001, "La boquilla está sobre el centro de la pieza")


func test_the_floor_printer_fits_its_budget() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_root.add_child(sun)
	_cubo()
	var budget: RefCounted = SceneBudget.measure(_root)
	assert_lte(budget.get("triangles"), FLOOR_PRINTER_MAX_TRIANGLES, "Triángulos")
	assert_lte(budget.get("draw_calls"), FLOOR_PRINTER_MAX_DRAW_CALLS, "Llamadas con la sombra")


func test_two_printers_share_their_meshes() -> void:
	var a: Node3D = PrinterModel.build(_root, "A", "cubo_uno")
	var b: Node3D = PrinterModel.build(_root, "B", "cubo_uno", "e0453a")
	for mesh_name: String in ["Body", "Gantry", "PrintHead/Carriage", "Spool/Filament"]:
		assert_same((a.get_node(mesh_name) as MeshInstance3D).mesh, (b.get_node(mesh_name) as MeshInstance3D).mesh, mesh_name)
	assert_eq((b.get_node("Spool/Filament") as MeshInstance3D).material_override, WorldPalette.solid("e0453a"), "El bobinado del color del carrete")


func test_the_spool_lies_on_its_side_with_open_flanges_ten_percent_bigger() -> void:
	var radius: float = 0.1
	var spool: Node3D = SpoolModel.build(_root, "Spool", Vector3.ZERO, "4cbf5a", radius)
	var filament: MeshInstance3D = spool.get_node("Filament")
	var flanges: MeshInstance3D = spool.get_node("Flanges")
	assert_eq(filament.material_override, WorldPalette.solid("4cbf5a"))
	assert_almost_eq(absf(filament.global_basis.y.x), 1.0, 0.001, "Acostado: el eje (y las capas, los surcos del bobinado) a lo largo de X")
	var winding: AABB = filament.transform * filament.mesh.get_aabb()
	var flange: AABB = flanges.mesh.get_aabb()
	assert_almost_eq(flange.size.y / winding.size.y, 1.1, 0.01, "Las tapas, un 10 % más grandes que el bobinado")
	assert_lt(winding.size.x, flange.size.x, "El bobinado entre las dos tapas")
	# Las tapas son abiertas: entre dos rayos se ve el bobinado.
	var between_spokes: Vector3 = Vector3(radius, 0.0, radius * 0.6)
	assert_true(_hits(flanges, between_spokes, Vector3.LEFT).is_empty(), "Entre los rayos no hay tapa")
	var on_spoke: Vector3 = Vector3(radius, radius * 0.6 * cos(PI / 4.0), radius * 0.6 * sin(PI / 4.0))
	assert_false(_hits(flanges, on_spoke, Vector3.LEFT).is_empty(), "En un rayo sí")


func test_the_spaghetti_nest_is_hidden_and_its_strands_reach_the_nozzle() -> void:
	var nest: MeshInstance3D = PieceModel.build_spaghetti(_root, "Spaghetti")
	assert_false(nest.visible, "Escondido hasta que falla")
	var bounds: AABB = nest.mesh.get_aabb()
	assert_gte(bounds.position.y, 0.0, "Encima de la pieza, nada adentro")
	assert_almost_eq(bounds.end.y, PieceModel.SPAGHETTI_RISE + PieceModel.SPAGHETTI_RADIUS, 0.002, "Las hebras llegan a la boquilla")
	assert_between(bounds.size.x, 0.1, 0.2, "Un nido del tamaño de la pieza")
	assert_same(PieceModel.build_spaghetti(_root, "Other").mesh, nest.mesh, "Una sola malla para todos")
	var white: Color = Color("f2efe6")
	var albedo: Color = PieceModel.spaghetti_material("f2efe6").get_shader_parameter("albedo")
	assert_almost_eq(albedo.r, minf(white.r * PieceModel.SPAGHETTI_BRIGHTNESS, 1.0), 0.004, "Del color del filamento, más claro")
	var red: Color = PieceModel.spaghetti_material("e0453a").get_shader_parameter("albedo")
	assert_almost_eq(red.g, Color("e0453a").g * PieceModel.SPAGHETTI_BRIGHTNESS, 0.004)


func test_the_ready_sparkles_pop_and_go_out() -> void:
	var sparkles: ReadySparkles = ReadySparkles.new()
	_root.add_child(sparkles)
	assert_false(sparkles.visible)
	assert_eq(sparkles.multimesh.instance_count, ReadySparkles.COUNT)
	assert_eq(sparkles.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	sparkles.play(Vector3(0.0, 0.14, 0.0))
	assert_true(sparkles.visible)
	assert_true(sparkles.is_playing())
	await wait_seconds(ReadySparkles.DURATION / 2.0)
	var lit: int = 0
	for i: int in ReadySparkles.COUNT:
		if sparkles.multimesh.get_instance_transform(i).basis.get_scale().x > 0.1:
			lit += 1
	assert_gt(lit, 0, "A mitad, alguna brilla")
	await wait_seconds(ReadySparkles.DURATION / 2.0 + 0.15)
	assert_false(sparkles.visible, "Y se apagan solas")
	assert_false(sparkles.is_playing())


func _cubo() -> Node3D:
	return PrinterModel.build(_root, "Printer", "cubo_uno")


## Puntos donde un rayo toca la malla de `node` (todo en el espacio de la
## malla).
func _hits(node: Node, from: Vector3, direction: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var faces: PackedVector3Array = (node as MeshInstance3D).mesh.get_faces()
	for i: int in range(0, faces.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(from, direction, faces[i], faces[i + 1], faces[i + 2])
		if hit != null:
			points.append(hit)
	return points


func _heights(points: Array[Vector3]) -> Array[float]:
	var heights: Array[float] = []
	for point: Vector3 in points:
		heights.append(point.y)
	return heights
