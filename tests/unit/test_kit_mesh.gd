extends GutTest
## El kit de formas (KitMesh, biblia de arte §5): medidas exactas, caras y
## normales hacia afuera, sin triángulos degenerados ni valores raros, el
## detalle, la oclusión de contacto y los atributos de cada vértice, la caché
## y el tubo que sigue su curva sin retorcerse.

const GOAL_TOLERANCE: float = 0.00001
## El color y la oclusión llegan a la malla en 8 bits.
const BYTE: float = 1.5 / 255.0


func test_a_beveled_box_measures_exactly_its_size() -> void:
	var kit: KitMesh = KitMesh.new()
	kit.box(Vector3(0.6, 0.3, 0.4), Vector3(0.1, 0.15, -0.2), 0.02)
	var aabb: AABB = kit.commit().get_aabb()
	assert_almost_eq(aabb.position, Vector3(-0.2, 0.0, -0.4), Vector3.ONE * GOAL_TOLERANCE, "Empieza donde dice")
	assert_almost_eq(aabb.size, Vector3(0.6, 0.3, 0.4), Vector3.ONE * GOAL_TOLERANCE, "El bisel no la achica")
	assert_eq(kit.triangle_count(), 44, "6 caras, 12 aristas y 8 esquinas")

	var huge_bevel: KitMesh = KitMesh.new()
	huge_bevel.box(Vector3(0.2, 0.1, 0.3), Vector3.ZERO, 5.0)
	assert_almost_eq(huge_bevel.commit().get_aabb().size, Vector3(0.2, 0.1, 0.3), Vector3.ONE * GOAL_TOLERANCE, "Un bisel enorme se limita")

	var plain: KitMesh = KitMesh.new()
	plain.box(Vector3(0.2, 0.1, 0.3), Vector3.ZERO, 0.0)
	assert_eq(plain.triangle_count(), 12, "Sin bisel, una caja simple")


func test_shapes_follow_their_place_and_the_origin() -> void:
	var turned: KitMesh = KitMesh.new()
	turned.box(Vector3(0.6, 0.3, 0.4), Vector3(0.0, 0.15, 0.0), 0.02, Vector3(0.0, 90.0, 0.0))
	assert_almost_eq(turned.commit().get_aabb().size, Vector3(0.4, 0.3, 0.6), Vector3.ONE * GOAL_TOLERANCE, "Girada 90° en Y")

	var grouped: KitMesh = KitMesh.new()
	grouped.origin = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(1.0, 0.5, 0.0))
	grouped.box(Vector3(0.6, 0.3, 0.4), Vector3(0.2, 0.0, 0.0), 0.02)
	var aabb: AABB = grouped.commit().get_aabb()
	assert_almost_eq(aabb.get_center(), Vector3(1.0, 0.5, -0.2), Vector3.ONE * GOAL_TOLERANCE, "El grupo mueve y gira lo que se agrega")
	assert_almost_eq(aabb.size, Vector3(0.4, 0.3, 0.6), Vector3.ONE * GOAL_TOLERANCE)


func test_convex_shapes_face_outwards() -> void:
	var center: Vector3 = Vector3(0.2, 0.3, -0.1)
	var shapes: Dictionary[String, Callable] = {
		"caja con bisel": func(kit: KitMesh) -> void: kit.box(Vector3(0.3, 0.2, 0.25), center, 0.03),
		"caja sin bisel": func(kit: KitMesh) -> void: kit.box(Vector3(0.3, 0.2, 0.25), center, 0.0),
		"caja girada": func(kit: KitMesh) -> void: kit.box(Vector3(0.3, 0.2, 0.25), center, 0.02, Vector3(20.0, 35.0, -10.0)),
		"cilindro con canto": func(kit: KitMesh) -> void: kit.cylinder(0.1, 0.2, center, Vector3.ZERO, 16, 0.015),
		"cono": func(kit: KitMesh) -> void: kit.cylinder(0.1, 0.2, center, Vector3(90.0, 0.0, 0.0), 12, 0.0, 0.03),
		"torno": func(kit: KitMesh) -> void: kit.lathe(PackedVector2Array([Vector2(0.0, -0.1), Vector2(0.1, -0.1), Vector2(0.1, -0.1), Vector2(0.12, 0.0), Vector2(0.08, 0.1), Vector2(0.0, 0.12)]), center),
		"elipsoide": func(kit: KitMesh) -> void: kit.blob(Vector3(0.12, 0.08, 0.1), center),
		"caja redondeada": func(kit: KitMesh) -> void: kit.blob(Vector3(0.12, 0.08, 0.1), center, Vector3(0.0, 30.0, 0.0), 0.4, 0.4),
		"forma estrechada": func(kit: KitMesh) -> void: kit.blob(Vector3(0.12, 0.08, 0.1), center, Vector3.ZERO, 0.6, 0.8, Vector2(1.0, 0.6)),
		"cápsula": func(kit: KitMesh) -> void: kit.capsule(0.05, 0.04, 0.4, center - Vector3(0.0, 0.2, 0.0), Vector3.ZERO, 0.8),
	}
	for shape_name: String in shapes:
		var kit: KitMesh = KitMesh.new()
		(shapes[shape_name] as Callable).call(kit)
		var arrays: Array = kit.commit().surface_get_arrays(0)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var inward_normals: int = 0
		for i: int in positions.size():
			var away: Vector3 = positions[i] - center
			if away.length() > 0.0001 and normals[i].dot(away) <= 0.0:
				inward_normals += 1
		var inward_faces: int = 0
		for t: int in range(0, indices.size(), 3):
			var a: Vector3 = positions[indices[t]]
			var b: Vector3 = positions[indices[t + 1]]
			var c: Vector3 = positions[indices[t + 2]]
			if _front(a, b, c).dot((a + b + c) / 3.0 - center) <= 0.0:
				inward_faces += 1
		assert_eq(inward_normals, 0, "%s: normales hacia afuera" % shape_name)
		assert_eq(inward_faces, 0, "%s: el frente de cada triángulo mira hacia afuera" % shape_name)


func test_every_triangle_shows_its_front_where_its_normals_point() -> void:
	var kit: KitMesh = _every_shape()
	var arrays: Array = kit.commit().surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var backwards: int = 0
	for t: int in range(0, indices.size(), 3):
		var front: Vector3 = _front(positions[indices[t]], positions[indices[t + 1]], positions[indices[t + 2]])
		if front.dot(normals[indices[t]] + normals[indices[t + 1]] + normals[indices[t + 2]]) <= 0.0:
			backwards += 1
	assert_eq(backwards, 0, "Godot dibuja el frente en sentido horario: tiene que coincidir con las normales")


func test_no_degenerate_triangles_and_every_value_is_finite() -> void:
	var kit: KitMesh = _every_shape()
	var arrays: Array = kit.commit().surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_eq(indices.size() % 3, 0)
	assert_eq(indices.size() / 3, kit.triangle_count())
	var problems: Array[String] = []
	for t: int in range(0, indices.size(), 3):
		for k: int in 3:
			if indices[t + k] < 0 or indices[t + k] >= positions.size():
				problems.append("índice fuera de la malla en el triángulo %d" % (t / 3))
		var area: float = _front(positions[indices[t]], positions[indices[t + 1]], positions[indices[t + 2]]).length() / 2.0
		if not area > 1e-10:
			problems.append("triángulo %d con área %g" % [t / 3, area])
	for i: int in positions.size():
		if not positions[i].is_finite() or not normals[i].is_finite() or not uvs[i].is_finite() or not uv2s[i].is_finite():
			problems.append("vértice %d con un valor no finito" % i)
		elif absf(normals[i].length() - 1.0) > 0.001:
			problems.append("vértice %d con normal de largo %f" % [i, normals[i].length()])
		var color: Color = colors[i]
		if not (is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and is_finite(color.a)):
			problems.append("vértice %d con un color no finito" % i)
	assert_eq(problems, [] as Array[String])
	assert_gt(kit.triangle_count(), 1000, "Se armaron todas las formas")


func test_detail_changes_the_number_of_vertices() -> void:
	var counts: Array[int] = []
	for detail: float in [0.35, 0.6, 1.0, 1.5]:
		var kit: KitMesh = KitMesh.new()
		kit.detail = detail
		kit.cylinder(0.1, 0.2, Vector3.ZERO, Vector3.ZERO, 16, 0.01)
		kit.blob(Vector3.ONE * 0.1, Vector3.ZERO)
		kit.capsule(0.05, 0.04, 0.3, Vector3.ZERO)
		kit.torus(Vector2(0.1, 0.1), 0.02, Vector3.ZERO)
		kit.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.2, 0.1, 0.0), Vector3(0.4, 0.0, 0.1)]), 0.01)
		kit.disc(0.1, Vector3.ZERO)
		counts.append(kit.commit().surface_get_array_len(0))
	for i: int in range(1, counts.size()):
		assert_gt(counts[i], counts[i - 1], "Más detalle, más vértices: %s" % [counts])
	var boxes: Array[int] = []
	for detail: float in [0.35, 1.5]:
		var kit: KitMesh = KitMesh.new()
		kit.detail = detail
		kit.box(Vector3.ONE * 0.2, Vector3.ZERO, 0.02)
		boxes.append(kit.triangle_count())
	assert_eq(boxes[0], boxes[1], "Una caja no tiene lados redondos")


func test_bevel_cutoff_drops_only_the_small_bevels() -> void:
	var counts: Array[int] = []
	for cutoff: float in [0.0, 0.009]:
		var kit: KitMesh = KitMesh.new()
		kit.bevel_cutoff = cutoff
		kit.box(Vector3.ONE * 0.1, Vector3.ZERO, 0.005)
		kit.box(Vector3.ONE * 0.1, Vector3(0.3, 0.0, 0.0), 0.02)
		counts.append(kit.triangle_count())
		var bounds: AABB = kit.commit().get_aabb()
		assert_almost_eq(bounds.size, Vector3(0.4, 0.1, 0.1), Vector3.ONE * 0.0001, "Las cajas miden lo mismo con o sin bisel")
	assert_eq(counts[0], 88, "Sin corte, las dos cajas con bisel (44 triángulos cada una)")
	assert_eq(counts[1], 56, "Con corte, la del bisel chico sale sin bisel (12) y la otra lo mantiene (44)")


func test_contact_occlusion_is_baked_into_the_vertices() -> void:
	var standing: KitMesh = KitMesh.new()
	standing.quad(Vector2(0.4, 0.5), Vector3(0.0, 0.25, 0.0))
	var arrays: Array = standing.commit().surface_get_arrays(0)
	for i: int in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
		var y: float = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array)[i].y
		var occlusion: float = (arrays[Mesh.ARRAY_COLOR] as PackedColorArray)[i].a
		if y < 0.001:
			assert_almost_eq(occlusion, KitMesh.CONTACT_AO, BYTE, "En y = 0, la oclusión de contacto")
		else:
			assert_almost_eq(occlusion, 1.0, BYTE, "A %.2f m ya no hay oclusión" % y)

	var on_table: KitMesh = KitMesh.new()
	on_table.ao_base = 0.75
	on_table.quad(Vector2(0.2, 0.2), Vector3(0.0, 0.85, 0.0))
	assert_almost_eq(_lowest_occlusion(on_table), KitMesh.CONTACT_AO, BYTE, "El contacto puede ser la mesa")

	var hanging: KitMesh = KitMesh.new()
	hanging.ao_enabled = false
	hanging.quad(Vector2(0.4, 0.5), Vector3(0.0, 0.25, 0.0))
	assert_almost_eq(_lowest_occlusion(hanging), 1.0, BYTE, "Lo que cuelga no toca nada")

	var shelf: KitMesh = KitMesh.new()
	shelf.box(Vector3(0.5, 0.04, 0.3), Vector3(0.0, 1.0, 0.0), 0.0)
	assert_almost_eq(_lowest_occlusion(shelf), 1.0 - KitMesh.DOWN_AO, BYTE, "La cara de abajo se oscurece")

	var floor_box: KitMesh = KitMesh.new()
	floor_box.box(Vector3(0.5, 0.4, 0.3), Vector3(0.0, 0.2, 0.0), 0.0)
	assert_almost_eq(_lowest_occlusion(floor_box), KitMesh.CONTACT_AO * (1.0 - KitMesh.DOWN_AO), BYTE, "Abajo y en el piso: las dos")


func test_each_vertex_carries_what_is_painted() -> void:
	var wood: Array = _first_vertex(func(kit: KitMesh) -> void: kit.paint("3e4250", WorldPalette.Surface.WOOD, 0.3))
	assert_almost_eq((wood[0] as Color).r, Color("3e4250").r, BYTE, "Color")
	assert_almost_eq((wood[0] as Color).g, Color("3e4250").g, BYTE)
	assert_almost_eq((wood[0] as Color).b, Color("3e4250").b, BYTE)
	assert_almost_eq(wood[1], Vector2(WorldPalette.Surface.WOOD + 0.3, 0.0), Vector2.ONE * 0.0001, "Superficie y brillo; sin balanceo")
	assert_eq(wood[2], Vector2.ZERO, "No impreso y sin luz propia")

	var piece: Array = _first_vertex(func(kit: KitMesh) -> void: kit.printed("e0453a"))
	assert_almost_eq(piece[1], Vector2(WorldPalette.Surface.SMOOTH + WorldPalette.PRINTED_GLOSS, 0.0), Vector2.ONE * 0.0001, "Plástico satinado")
	assert_almost_eq((piece[2] as Vector2).x, PieceModel.LAYER_STEP, 0.0001, "Capas de la pieza por defecto")
	var base: Array = _first_vertex(func(kit: KitMesh) -> void: kit.printed("f2efe6", 0.024))
	assert_almost_eq((base[2] as Vector2).x, 0.024, 0.0001, "Su propio alto de capa")

	var led: Array = _first_vertex(func(kit: KitMesh) -> void: kit.glowing("7fe0a0", 1.5))
	assert_almost_eq((led[2] as Vector2).y, 1.5, 0.0001, "Encendido siempre")
	var lamp: Array = _first_vertex(func(kit: KitMesh) -> void: kit.night_glow("ffd27a", 0.8))
	assert_almost_eq((lamp[2] as Vector2).y, -0.8, 0.0001, "Solo de noche")

	var plant: Array = _first_vertex(func(kit: KitMesh) -> void:
		kit.printed("6fbf7a", 0.004)
		kit.sway = 0.6)
	assert_almost_eq((plant[1] as Vector2).y, 0.6, 0.0001, "Se balancea")
	var repainted: Array = _first_vertex(func(kit: KitMesh) -> void:
		kit.glowing("ffffff", 2.0)
		kit.sway = 0.6
		kit.paint("ffffff", WorldPalette.Surface.SMOOTH, 1.5))
	assert_eq(floori((repainted[1] as Vector2).x), WorldPalette.Surface.SMOOTH as int, "El brillo nunca cambia la superficie")
	assert_eq((repainted[1] as Vector2).y, 0.0, "paint quita el balanceo")
	assert_eq(repainted[2], Vector2.ZERO, "paint quita las capas y la luz propia")


func test_what_hangs_sways_more_the_lower_it_is() -> void:
	var kit: KitMesh = KitMesh.new()
	kit.paint("e2a93b", WorldPalette.Surface.FABRIC)
	kit.hanging(0.4, 2.2, 1.0)
	kit.box(Vector3(0.1, 1.6, 0.1), Vector3(0.0, 1.4, 0.0), 0.0)
	var arrays: Array = kit.commit().surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i: int in positions.size():
		var expected: float = 0.4 * clampf((2.2 - positions[i].y) / 1.0, 0.0, 1.0)
		assert_almost_eq(uvs[i].y, expected, 0.0001, "Balanceo a y = %.2f" % positions[i].y)
	assert_almost_eq(uvs[_index_at_height(positions, 2.2)].y, 0.0, 0.0001, "Arriba, donde cuelga, no se mueve")
	assert_almost_eq(uvs[_index_at_height(positions, 0.6)].y, 0.4, 0.0001, "Abajo, todo el balanceo")
	kit.paint("e2a93b")
	assert_eq(kit.sway_top, INF, "paint quita lo que cuelga")


func test_the_cache_builds_once_and_returns_the_same_mesh() -> void:
	var calls: Array[int] = [0]
	var build: Callable = func() -> ArrayMesh:
		calls[0] += 1
		var kit: KitMesh = KitMesh.new()
		kit.box(Vector3.ONE * 0.1, Vector3.ZERO)
		return kit.commit()
	var first: ArrayMesh = KitMesh.cached("test_kit_mesh:caja", build)
	var second: ArrayMesh = KitMesh.cached("test_kit_mesh:caja", build)
	assert_same(first, second, "La misma clave, la misma malla")
	assert_eq(calls[0], 1, "Se arma una sola vez")
	assert_not_same(KitMesh.cached("test_kit_mesh:otra", build), first, "Otra clave, otra malla")


func test_a_tube_passes_through_its_points_without_twisting() -> void:
	var points: PackedVector3Array = PackedVector3Array([Vector3(0.0, 0.1, 0.0), Vector3(0.3, 0.1, 0.1), Vector3(0.5, 0.1, 0.4), Vector3(0.4, 0.1, 0.7)])
	var steps: int = 4
	var path: PackedVector3Array = KitMesh.smooth_path(points, steps)
	for i: int in points.size():
		assert_almost_eq(path[i * steps], points[i], Vector3.ONE * GOAL_TOLERANCE, "La curva pasa por el punto %d" % i)

	var radius: float = 0.01
	var sides: int = 8
	var kit: KitMesh = KitMesh.new()
	kit.tube(points, radius, sides, steps, false)
	var positions: PackedVector3Array = kit.commit().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_eq(positions.size(), path.size() * (sides + 1), "Un anillo por punto de la curva")
	for k: int in path.size():
		var tangent: Vector3 = (path[mini(k + 1, path.size() - 1)] - path[maxi(k - 1, 0)]).normalized()
		for i: int in sides + 1:
			var offset: Vector3 = positions[k * (sides + 1) + i] - path[k]
			assert_almost_eq(offset.length(), radius, 0.0001, "Anillo %d redondo" % k)
			assert_almost_eq(offset.dot(tangent), 0.0, 0.0001, "Anillo %d de frente a la curva" % k)
		# En una curva plana y horizontal, el cuarto de vuelta queda siempre
		# vertical: el tubo no se retuerce.
		var quarter: Vector3 = positions[k * (sides + 1) + sides / 4] - path[k]
		assert_almost_eq(absf(quarter.y), radius, 0.0001, "Anillo %d sin retorcerse" % k)

	# Una curva que sube y gira: de un anillo al siguiente el giro es chico.
	var climbing: PackedVector3Array = PackedVector3Array([Vector3.ZERO, Vector3(0.3, 0.0, 0.0), Vector3(0.35, 0.3, 0.05), Vector3(0.2, 0.5, 0.3)])
	var curve: PackedVector3Array = KitMesh.smooth_path(climbing, steps)
	var turning: KitMesh = KitMesh.new()
	turning.tube(climbing, radius, sides, steps, false)
	var rings: PackedVector3Array = turning.commit().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for k: int in range(1, curve.size()):
		var before: Vector3 = (rings[(k - 1) * (sides + 1)] - curve[k - 1]).normalized()
		var after: Vector3 = (rings[k * (sides + 1)] - curve[k]).normalized()
		assert_gt(before.dot(after), 0.9, "Del anillo %d al %d gira poco" % [k - 1, k])


func test_a_repeated_profile_point_makes_a_sharp_edge() -> void:
	var kit: KitMesh = KitMesh.new()
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.1, 0.0), Vector2(0.1, 0.2), Vector2(0.1, 0.2), Vector2(0.0, 0.2)]), Vector3.ZERO, Vector3.ZERO, 8)
	var arrays: Array = kit.commit().surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var at_edge: Array[Vector3] = []
	for i: int in positions.size():
		if positions[i].is_equal_approx(Vector3(0.1, 0.0, 0.0)):
			at_edge.append(normals[i])
	assert_true(at_edge.any(func(n: Vector3) -> bool: return n.dot(Vector3.DOWN) > 0.999), "La tapa mira hacia abajo")
	assert_true(at_edge.any(func(n: Vector3) -> bool: return n.dot(Vector3.RIGHT) > 0.999), "El costado mira hacia afuera")
	assert_eq(kit.triangle_count(), 8 + 16 + 8, "Tapa, costado y tapa: ningún triángulo en las esquinas repetidas")


func test_an_empty_kit_gives_an_empty_mesh() -> void:
	var kit: KitMesh = KitMesh.new()
	assert_true(kit.is_empty())
	assert_eq(kit.commit().get_surface_count(), 0)
	kit.disc(0.1, Vector3.ZERO, Vector3.ZERO, 12)
	assert_false(kit.is_empty())
	assert_eq(kit.triangle_count(), 12)
	assert_eq(kit.commit().get_surface_count(), 1)


## Todas las formas, con giros, un grupo y casos difíciles (biseles enormes,
## polos, puntos repetidos, curvas cerradas).
func _every_shape() -> KitMesh:
	var kit: KitMesh = KitMesh.new()
	kit.paint("b97a48", WorldPalette.Surface.WOOD, 0.2)
	kit.box(Vector3(0.5, 0.05, 0.3), Vector3(0.0, 0.7, 0.0), 0.012)
	kit.box(Vector3(0.04, 0.7, 0.04), Vector3(0.2, 0.35, 0.1), 1.0, Vector3(0.0, 45.0, 0.0))
	kit.box(Vector3(0.3, 0.001, 0.3), Vector3(0.0, 0.0005, 0.0), 0.01)
	kit.printed("e0453a", 0.006)
	kit.cylinder(0.08, 0.1, Vector3(0.0, 0.8, 0.0), Vector3(90.0, 0.0, 0.0), 24, 0.01)
	kit.cylinder(0.05, 0.2, Vector3.ZERO, Vector3.ZERO, 8, 0.0, 0.0, false)
	kit.cylinder(0.05, 0.02, Vector3.ZERO, Vector3.ZERO, 8, 0.05, -1.0, false)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.06, 0.0), Vector2(0.05, 0.05), Vector2(0.07, 0.1), Vector2(0.0, 0.1)]), Vector3(0.3, 0.0, 0.0))
	kit.glowing("7fe0a0", 1.2)
	kit.blob(Vector3(0.1, 0.06, 0.08), Vector3(0.0, 1.0, 0.0), Vector3(10.0, 20.0, 30.0), 0.3, 0.25, Vector2(1.0, 0.5))
	kit.blob(Vector3(0.05, 0.12, 0.05), Vector3(0.0, 1.2, 0.0), Vector3.ZERO, 1.0, 1.0, Vector2(1.0, 0.0))
	kit.capsule(0.05, 0.03, 0.35, Vector3(0.1, 0.0, 0.0), Vector3(0.0, 0.0, 15.0), 0.7)
	kit.night_glow("ffd27a", 0.7)
	kit.torus(Vector2(0.12, 0.08), 0.02, Vector3(0.0, 0.5, 0.0), Vector3(90.0, 0.0, 0.0))
	kit.torus(Vector2(0.1, 0.1), 0.015, Vector3(0.0, 0.4, 0.0), Vector3.ZERO, PI * 0.8)
	kit.paint("2a2730")
	kit.tube(PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3(0.2, 0.0, 0.0), Vector3(0.2, 0.3, 0.0), Vector3(0.21, 0.31, 0.2), Vector3(0.0, 0.0, 0.0)]), 0.004)
	kit.tube(PackedVector3Array([Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.5, 0.0)]), 0.01, 3, 1)
	kit.origin = Transform3D(Basis(Vector3.UP, 0.7), Vector3(1.0, 0.0, -0.5))
	kit.disc(0.1, Vector3(0.0, 0.002, 0.0), Vector3(-90.0, 0.0, 0.0))
	kit.quad(Vector2(0.6, 0.4), Vector3(0.0, 0.003, 0.0), Vector3(-90.0, 0.0, 0.0))
	kit.triangle(Vector3.ZERO, Vector3(0.1, 0.0, 0.0), Vector3(0.05, 0.1, 0.0), Vector3(0.0, 1.0, 0.0))
	kit.triangle(Vector3.ZERO, Vector3(0.1, 0.0, 0.0), Vector3(0.2, 0.0, 0.0))
	return kit


## La cara del frente de un triángulo como lo dibuja Godot (sentido horario).
func _front(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	return (c - a).cross(b - a)


func _lowest_occlusion(kit: KitMesh) -> float:
	var lowest: float = 1.0
	for color: Color in kit.commit().surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray:
		lowest = minf(lowest, color.a)
	return lowest


## [COLOR, UV, UV2] del primer vértice de un cuadrado pintado con `paint`.
func _first_vertex(paint: Callable) -> Array:
	var kit: KitMesh = KitMesh.new()
	paint.call(kit)
	kit.quad(Vector2.ONE * 0.1, Vector3(0.0, 0.5, 0.0))
	var arrays: Array = kit.commit().surface_get_arrays(0)
	return [(arrays[Mesh.ARRAY_COLOR] as PackedColorArray)[0], (arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array)[0], (arrays[Mesh.ARRAY_TEX_UV2] as PackedVector2Array)[0]]


## Índice del primer vértice a esa altura.
func _index_at_height(positions: PackedVector3Array, y: float) -> int:
	for i: int in positions.size():
		if absf(positions[i].y - y) < 0.0001:
			return i
	return -1
