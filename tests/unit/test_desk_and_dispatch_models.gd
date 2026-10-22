extends GutTest
## El escritorio del comienzo, el rincón de despacho y sus cajas, del kit
## (biblia de arte §10): medidas que fijan los toques y la caminata, nodos del
## contrato con DeskView, DispatchView y RoomView, y presupuesto (§5.2).

const SceneBudget: GDScript = preload("res://tests/helpers/scene_budget.gd")
## La caja que se toca del escritorio, en su espacio (la de siempre: el
## personaje lo resalta a 0,25 m de su borde y no entra en él).
const DESK_MIN: Vector3 = Vector3(-0.65, 0.0, -0.41)
const DESK_MAX: Vector3 = Vector3(0.65, 1.15, 0.81)
## Presupuesto del escritorio completo (biblia §5.2): triángulos y llamadas
## de dibujo contando la pasada de sombra.
const DESK_MAX_TRIANGLES: int = 4000
const DESK_MAX_DRAW_CALLS: int = 3
## Lo fijo del rincón es un mueble (§5.2): 1.500 triángulos, 2 llamadas.
const DISPATCH_MAX_TRIANGLES: int = 1500
const DISPATCH_MAX_DRAW_CALLS: int = 2
const TOLERANCE: float = 0.01

var _root: Node3D


func before_each() -> void:
	_root = Node3D.new()
	add_child_autofree(_root)


func test_the_desk_keeps_its_footprint() -> void:
	var bounds: AABB = PropBounds.local_aabb(_desk())
	assert_almost_eq(bounds.position, DESK_MIN, Vector3.ONE * TOLERANCE, "Lo de siempre: desde la pared y la cajonera")
	assert_almost_eq(bounds.end, DESK_MAX, Vector3.ONE * TOLERANCE, "Hasta la caja-silla y la torre")
	assert_gte(bounds.position.y, -0.0001, "Nada se hunde en el piso")


func test_the_desk_has_every_node_of_the_contract() -> void:
	var desk: Node3D = _desk()
	var body: MeshInstance3D = desk.get_node_or_null("Body")
	assert_not_null(body)
	assert_same(body.material_override, WorldPalette.kit(), "Lo fijo es una malla del kit")
	var screen: MeshInstance3D = desk.get_node_or_null("Monitor/Screen")
	assert_not_null(screen, "DeskView cambia la pantalla")
	assert_eq(screen.material_override, WorldPalette.glow("ffffff", "crt_screen"))
	assert_eq(screen.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	for marker_name: String in ["LampBulb", "ScreenGlow"]:
		assert_true(desk.get_node_or_null(marker_name) is Marker3D, marker_name)
	assert_eq(desk.get_child_count(), 4, "Body, Monitor y los dos marcadores: nada más se dibuja aparte")


func test_the_lights_sit_on_the_lamp_and_in_front_of_the_screen() -> void:
	var desk: Node3D = _desk()
	var bulb: Vector3 = (desk.get_node("LampBulb") as Node3D).position
	assert_gt(bulb.y, ComputerDeskModel.TABLE_SIZE.y + 0.2, "La ampolleta, arriba de la mesa")
	assert_true(ComputerDeskModel.table_box().grow(0.01).has_point(Vector3(bulb.x, 0.1, bulb.z)), "Sobre el tablero")
	var screen: Transform3D = (desk.get_node("Monitor") as Node3D).transform * (desk.get_node("Monitor/Screen") as Node3D).transform
	var glow: Vector3 = (desk.get_node("ScreenGlow") as Node3D).position
	var screen_center: Vector3 = screen.origin
	var facing: Vector3 = screen.basis.z
	assert_almost_eq((glow - screen_center).dot(facing), ComputerDeskModel.SCREEN_GLOW_AHEAD, 0.0001, "Delante de la pantalla")
	assert_almost_eq((glow - screen_center).cross(facing).length(), 0.0, 0.0001, "Justo enfrente de su centro")


func test_the_table_box_is_the_real_desk_top() -> void:
	var body: MeshInstance3D = _desk().get_node("Body")
	var box: AABB = ComputerDeskModel.table_box()
	# Un rayo hacia abajo donde no hay nada sobre la mesa (a la derecha, al
	# frente): lo primero que toca es el tablero.
	var hits: Array[float] = _heights(body, Vector3(0.58, 2.0, 0.24))
	assert_false(hits.is_empty())
	assert_almost_eq(hits.max(), box.end.y, 0.001, "El tablero está donde dice table_box() (tapa el parche de sol)")
	assert_almost_eq(box.size.x, DESK_MAX.x - DESK_MIN.x, 0.001, "Todo el ancho")


func test_the_desk_fits_its_budget_and_is_built_once() -> void:
	_sun()
	var desk: Node3D = _desk()
	var budget: RefCounted = SceneBudget.measure(_root)
	assert_lte(budget.get("triangles"), DESK_MAX_TRIANGLES, "Triángulos")
	assert_lte(budget.get("draw_calls"), DESK_MAX_DRAW_CALLS, "Llamadas con la sombra")
	var other: Node3D = ComputerDeskModel.build(_root, "Other")
	assert_same((other.get_node("Body") as MeshInstance3D).mesh, (desk.get_node("Body") as MeshInstance3D).mesh, "Una sola malla en caché")


func test_the_dispatch_corner_fits_its_budget_and_keeps_its_markers() -> void:
	_sun()
	var corner: Node3D = DispatchCornerModel.build(_root, "DispatchCorner")
	var budget: RefCounted = SceneBudget.measure(_root)
	assert_lte(budget.get("triangles"), DISPATCH_MAX_TRIANGLES, "Triángulos")
	assert_lte(budget.get("draw_calls"), DISPATCH_MAX_DRAW_CALLS, "Llamadas con la sombra")
	assert_same((corner.get_node("Body") as MeshInstance3D).material_override, WorldPalette.kit())
	for i: int in DispatchCornerModel.PACK_SPOTS:
		var pack: Node3D = corner.get_node("PackSpot%d" % i)
		assert_almost_eq(pack.position.y, DispatchCornerModel.TABLE_TOP, 0.0001, "Las cajas abiertas, sobre la mesa")
	for i: int in DispatchCornerModel.OUT_SPOTS:
		var out: Node3D = corner.get_node("OutSpot%d" % i)
		var expected: float = DispatchCornerModel.CRATE_HEIGHT + DispatchCornerModel.PACKAGE_HEIGHT * (i + 0.5)
		assert_almost_eq(out.position.y, expected, 0.0001, "Los paquetes, apilados sobre el guacal")


func test_the_dispatch_corner_keeps_its_footprint_with_every_box_and_package() -> void:
	var corner: Node3D = DispatchCornerModel.build(_root, "DispatchCorner")
	for i: int in DispatchCornerModel.PACK_SPOTS:
		PackageModel.open_box(corner.get_node("PackSpot%d" % i), "OpenBox").visible = false
	for i: int in DispatchCornerModel.OUT_SPOTS:
		PackageModel.package(corner.get_node("OutSpot%d" % i), "Package").visible = false
	var bounds: AABB = PropBounds.local_aabb(corner)
	assert_almost_eq(bounds.position.x, -0.435, TOLERANCE)
	assert_almost_eq(bounds.end.x, 0.45, TOLERANCE)
	assert_almost_eq(bounds.position.z, -0.2, TOLERANCE)
	assert_almost_eq(bounds.end.z, 0.2, TOLERANCE)
	assert_gte(bounds.position.y, -0.0001)


func test_a_package_is_one_shared_mesh_and_an_open_box_shows_its_piece() -> void:
	var a: Node3D = PackageModel.package(_root, "A")
	var b: Node3D = PackageModel.package(_root, "B")
	var box: MeshInstance3D = a.get_node("Box")
	assert_same(box.mesh, (b.get_node("Box") as MeshInstance3D).mesh, "Todos los paquetes comparten la malla")
	assert_same(box.material_override, WorldPalette.kit())
	var size: Vector3 = PropBounds.local_aabb(a).size
	assert_almost_eq(size.y, DispatchCornerModel.PACKAGE_HEIGHT, 0.005, "Se apilan sin hundirse uno en otro")
	var open: Node3D = PackageModel.open_box(_root, "Open")
	var shell: AABB = (open.get_node("Box") as MeshInstance3D).mesh.get_aabb()
	var piece: MeshInstance3D = open.get_node("Piece")
	assert_eq(piece.material_override, WorldPalette.solid(WorldPalette.PLASTIC_BEIGE), "DispatchView la tiñe")
	var piece_box: AABB = piece.transform * piece.mesh.get_aabb()
	assert_gt(piece_box.end.y, PackageModel.OPEN_BOX_SIZE.y, "La pieza asoma por arriba")
	assert_lt(piece_box.position.y, PackageModel.OPEN_BOX_SIZE.y, "Y está adentro de la caja")
	assert_almost_eq(shell.position.y, 0.0, 0.0001, "Apoyada en la mesa")
	assert_gt(shell.size.z, PackageModel.OPEN_BOX_SIZE.z + 0.05, "Con las solapas abiertas hacia afuera")


func _desk() -> Node3D:
	return ComputerDeskModel.build(_root, "Desk")


func _sun() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_root.add_child(sun)


## Alturas donde un rayo hacia abajo desde `from` toca la malla de `node`.
func _heights(node: MeshInstance3D, from: Vector3) -> Array[float]:
	var heights: Array[float] = []
	var faces: PackedVector3Array = node.mesh.get_faces()
	for i: int in range(0, faces.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(from, Vector3.DOWN, faces[i], faces[i + 1], faces[i + 2])
		if hit != null:
			heights.append((hit as Vector3).y)
	return heights
