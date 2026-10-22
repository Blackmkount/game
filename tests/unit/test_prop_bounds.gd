extends GutTest
## Cajas de los modelos (de formas básicas y del kit) y dirección del
## joystick en el piso.


func test_bounds_of_a_model_cover_all_its_shapes() -> void:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	PropBuilder.box(root, "Base", Vector3(1.0, 0.2, 0.5), Vector3(0.0, 0.1, 0.0), WorldPalette.solid("ffffff"))
	var arm: Node3D = PropBuilder.group(root, "Arm", Vector3(0.0, 0.2, 0.0))
	PropBuilder.box(arm, "Post", Vector3(0.1, 1.0, 0.1), Vector3(0.4, 0.5, 0.0), WorldPalette.solid("ffffff"))
	var bounds: AABB = PropBounds.local_aabb(root)
	assert_almost_eq(bounds.position.x, -0.5, 0.0001)
	assert_almost_eq(bounds.end.x, 0.5, 0.0001)
	assert_almost_eq(bounds.end.y, 1.2, 0.0001, "Incluye la pieza dentro del grupo")
	assert_almost_eq(bounds.size.z, 0.5, 0.0001)


func test_bounds_follow_rotated_shapes() -> void:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	var box: MeshInstance3D = PropBuilder.box(root, "Box", Vector3(1.0, 0.1, 0.2), Vector3.ZERO, WorldPalette.solid("ffffff"))
	box.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	var bounds: AABB = PropBounds.local_aabb(root)
	assert_almost_eq(bounds.size.x, 0.2, 0.001)
	assert_almost_eq(bounds.size.z, 1.0, 0.001)


func test_bounds_cover_a_kit_mesh_placed_with_prop_builder() -> void:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	var kit: KitMesh = KitMesh.new()
	kit.box(Vector3(0.6, 0.05, 0.4), Vector3(0.0, 0.7, 0.0), 0.01)
	kit.cylinder(0.02, 0.7, Vector3(0.25, 0.35, 0.15))
	var body: MeshInstance3D = PropBuilder.kit(root, "Body", kit.commit(), null, Vector3(1.0, 0.0, 0.0))
	body.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	assert_same(body.material_override, WorldPalette.kit(), "Sin material, el del kit")
	var bounds: AABB = PropBounds.local_aabb(root)
	assert_almost_eq(bounds.size, Vector3(0.4, 0.725, 0.6), Vector3.ONE * 0.0001, "Una ArrayMesh también tiene tamaño sin pantalla")
	assert_almost_eq(bounds.position, Vector3(0.8, 0.0, -0.3), Vector3.ONE * 0.0001, "Con su lugar y su giro; apoyada en y = 0")


func test_the_printer_model_has_real_size_bounds() -> void:
	var root: Node3D = Node3D.new()
	add_child_autofree(root)
	var printer: Node3D = PrinterModel.build(root, "Printer", "cubo_uno")
	var bounds: AABB = PropBounds.local_aabb(printer)
	assert_between(bounds.size.x, 0.4, 0.5, "Una impresora tipo Ender mide unos 0,45 m")
	assert_almost_eq(bounds.position.y, 0.0, 0.001, "Apoyada en el piso")


func test_screen_directions_map_to_the_floor() -> void:
	var basis: Basis = Basis.from_euler(Vector3(deg_to_rad(CameraRig.PITCH), deg_to_rad(CameraRig.YAW), 0.0))
	var right: Vector2 = StickMapping.to_floor(Vector2(1.0, 0.0), basis, true)
	assert_almost_eq(right.dot(Vector2(basis.x.x, basis.x.z).normalized()), 1.0, 0.001, "Derecha en la pantalla es la derecha de la cámara")
	var half: Vector2 = StickMapping.to_floor(Vector2(0.0, -0.5), basis, true)
	assert_almost_eq(half.length(), 0.5, 0.001, "Conserva la fuerza del joystick")
	assert_eq(StickMapping.to_floor(Vector2.ZERO, basis, true), Vector2.ZERO)


func test_diagonal_push_moves_along_the_same_diagonal_on_screen() -> void:
	var basis: Basis = Basis.from_euler(Vector3(deg_to_rad(CameraRig.PITCH), deg_to_rad(CameraRig.YAW), 0.0))
	var push: Vector2 = Vector2(1.0, -1.0).normalized()
	var floor_direction: Vector2 = StickMapping.to_floor(push, basis, true)
	var world: Vector3 = Vector3(floor_direction.x, 0.0, floor_direction.y)
	# Cómo se ve ese movimiento en la pantalla (y hacia abajo).
	var on_screen: Vector2 = Vector2(world.dot(basis.x), -world.dot(basis.y)).normalized()
	assert_almost_eq(on_screen.angle_to(push), 0.0, 0.01, "El personaje va justo hacia donde apunta el pulgar")
	var uncorrected: Vector2 = StickMapping.to_floor(push, basis, false)
	var uncorrected_world: Vector3 = Vector3(uncorrected.x, 0.0, uncorrected.y)
	var uncorrected_screen: Vector2 = Vector2(uncorrected_world.dot(basis.x), -uncorrected_world.dot(basis.y)).normalized()
	assert_gt(absf(uncorrected_screen.angle_to(push)), 0.2, "Sin corregir, se desvía")
