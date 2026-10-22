extends GutTest
## El personaje (biblia de arte §7): los pivotes del contrato con rodillas,
## codos y el ancla del globo; la malla con piel que sigue a los pivotes; los
## contornos sin sombra; el pelo sano; el atlas de la cara; y las mallas
## compartidas entre los personajes (el cuarto y los dos retratos).

## Pivotes y medidas en reposo (biblia §7.1), en metros desde el piso.
const PIVOT_HEIGHTS: Dictionary[String, float] = {
	"HipL": 0.50, "HipR": 0.50, "HipL/KneeL": 0.27, "HipR/KneeR": 0.27, "Body": 0.50,
	"Body/ShoulderL": 0.90, "Body/ShoulderR": 0.90, "Body/ShoulderL/ElbowL": 0.70, "Body/ShoulderR/ElbowR": 0.70,
}
const TOLERANCE: float = 0.01

var _root: Node3D


func before_each() -> void:
	_root = Node3D.new()
	add_child_autofree(_root)


func test_the_contract_pivots_new_joints_and_speech_anchor_are_there() -> void:
	var model: Node3D = CharacterModel.build(_root, "Character")
	for path: String in PIVOT_HEIGHTS:
		var pivot: Node3D = model.get_node_or_null(path)
		assert_not_null(pivot, path)
		if pivot != null:
			assert_almost_eq(pivot.global_position.y, PIVOT_HEIGHTS[path], TOLERANCE, path)
	var head: Node3D = model.get_node_or_null("Body/Head")
	assert_not_null(head, "Body/Head")
	assert_almost_eq(head.rotation.x, CharacterModel.CHIN_UP, 0.0001, "Mentón levantado 6°")
	assert_almost_eq((head.global_transform * CharacterModel.SKULL_CENTER).y, 1.15, TOLERANCE, "Centro del cráneo")
	assert_almost_eq((head.global_transform * CharacterModel.SKULL_CENTER).y - CharacterModel.SKULL_HALF.y, 0.96, TOLERANCE, "Mentón")
	var anchor: Node = model.get_node_or_null("Body/Head/SpeechAnchor")
	assert_true(anchor is Marker3D, "El globo se ancla a un Marker3D en la cabeza")
	if anchor is Marker3D:
		assert_gt((anchor as Marker3D).global_position.y, CharacterModel.HEIGHT - 0.03, "Sobre el pelo")
	assert_almost_eq(PropBounds.local_aabb(model).end.y, CharacterModel.HEIGHT, 0.03, "Alto total hasta la punta del pelo")
	assert_almost_eq(PropBounds.local_aabb(model).position.y, 0.0, 0.001, "Parado en el piso")
	assert_eq((model.get_node("HipL") as Node3D).rotation.x, 0.0, "Quieto, las piernas derechas")


func test_each_bone_takes_the_pose_of_its_pivot() -> void:
	var model: Node3D = CharacterModel.build(_root, "Character")
	var rig: CharacterRig = model.get_node("Rig")
	assert_eq(rig.get_bone_count(), CharacterModel.Bone.size())
	for bone: int in CharacterModel.Bone.size():
		var pivot: Node3D = model.get_node(CharacterModel.PIVOT_PATHS[bone])
		assert_eq(rig.get_bone_name(bone), String(pivot.name))
		assert_true(rig.get_bone_rest(bone).is_equal_approx(pivot.transform), "Reposo de %s" % pivot.name)
	assert_eq(rig.get_bone_parent(CharacterModel.Bone.KNEE_L), CharacterModel.Bone.HIP_L)
	assert_eq(rig.get_bone_parent(CharacterModel.Bone.ELBOW_R), CharacterModel.Bone.SHOULDER_R)
	assert_eq(rig.get_bone_parent(CharacterModel.Bone.HEAD), CharacterModel.Bone.BODY)
	assert_eq(rig.get_bone_parent(CharacterModel.Bone.HIP_R), -1, "Las caderas cuelgan de la raíz, como sus pivotes")
	# Una pose cualquiera: después de follow() cada hueso tiene la de su pivote.
	(model.get_node("HipL") as Node3D).rotation.x = 0.4
	(model.get_node("HipL/KneeL") as Node3D).rotation.x = 1.0
	(model.get_node("Body/ShoulderR") as Node3D).rotation.x = -0.5
	(model.get_node("Body/ShoulderR/ElbowR") as Node3D).rotation.x = -1.1
	(model.get_node("Body/Head") as Node3D).rotation.y = 0.3
	var body: Node3D = model.get_node("Body")
	body.position.y += 0.04
	body.rotation.x = 0.12
	body.scale = Vector3(1.0, 1.015, 1.0)
	rig.follow()
	for bone: int in CharacterModel.Bone.size():
		var pivot: Node3D = model.get_node(CharacterModel.PIVOT_PATHS[bone])
		assert_true(rig.get_bone_pose_rotation(bone).is_equal_approx(pivot.quaternion), "Giro de %s" % pivot.name)
		assert_true(rig.get_bone_pose_position(bone).is_equal_approx(pivot.position), "Lugar de %s" % pivot.name)
		assert_true(rig.get_bone_pose_scale(bone).is_equal_approx(pivot.scale), "Escala de %s" % pivot.name)


func test_the_body_is_one_skinned_mesh_bent_only_at_the_joints() -> void:
	var model: Node3D = CharacterModel.build(_root, "Character")
	var rig: CharacterRig = model.get_node("Rig")
	var body: MeshInstance3D = model.get_node("Rig/Mesh")
	assert_eq(body.get_node(body.skeleton), rig, "La malla usa el esqueleto")
	assert_eq(body.skin, CharacterModel.skin())
	var arrays: Array = body.mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	assert_eq(bones.size(), positions.size() * 4)
	assert_eq(weights.size(), positions.size() * 4)
	var blended_knee: int = 0
	for i: int in positions.size():
		var sum: float = weights[i * 4] + weights[i * 4 + 1] + weights[i * 4 + 2] + weights[i * 4 + 3]
		assert_almost_eq(sum, 1.0, 0.001)
		var p: Vector3 = positions[i]
		var main: int = bones[i * 4] if weights[i * 4] >= weights[i * 4 + 1] else bones[i * 4 + 1]
		if p.y < 0.12:
			assert_true(main in [CharacterModel.Bone.KNEE_L, CharacterModel.Bone.KNEE_R], "Las zapatillas van con la rodilla")
		elif absf(p.x) < 0.1 and p.y > 0.62 and p.y < 0.82 and p.z > 0.0:
			assert_eq(main, CharacterModel.Bone.BODY, "El pecho va con el cuerpo")
		if absf(p.y - 0.27) < 0.02 and bones[i * 4] != bones[i * 4 + 1] and weights[i * 4 + 1] > 0.2 and weights[i * 4] > 0.2:
			blended_knee += 1
	assert_gt(blended_knee, 0, "En la rodilla los vértices mezclan los dos huesos (sin cortes)")
	assert_almost_eq(body.extra_cull_margin, CharacterModel.CULL_MARGIN, 0.0001, "Su caja es la del reposo")


func test_the_outlines_share_the_meshes_and_cast_no_shadow() -> void:
	var model: Node3D = CharacterModel.build(_root, "Character")
	for holder: String in ["Rig", "Body/Head"]:
		var mesh: MeshInstance3D = model.get_node(holder + "/Mesh")
		var outline: MeshInstance3D = model.get_node(holder + "/Outline")
		assert_same(outline.mesh, mesh.mesh, holder)
		assert_eq(outline.material_override, WorldPalette.outline_character())
		assert_eq(outline.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "El contorno no entra a la pasada de sombra")
		assert_eq(mesh.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "El personaje da sombra")
	assert_eq((model.get_node("Rig/Outline") as MeshInstance3D).skin, CharacterModel.skin(), "El contorno se dobla con el cuerpo")
	assert_eq((model.get_node("Rig/Mesh") as MeshInstance3D).material_override, WorldPalette.kit_character())
	assert_eq((model.get_node("Body/Head/Mesh") as MeshInstance3D).material_override, WorldPalette.kit_head())


func test_the_hair_is_one_healthy_surface_that_leaves_the_brows_free() -> void:
	var model: Node3D = CharacterModel.build(_root, "Character")
	var arrays: Array = (model.get_node("Body/Head/Mesh") as MeshInstance3D).mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var hair: int = 0
	var fringe_bottom: float = INF
	for i: int in positions.size():
		if floori(uvs[i].x) != WorldPalette.Surface.HAIR:
			continue
		hair += 1
		var p: Vector3 = positions[i]
		var n: Vector3 = normals[i]
		assert_true(p.is_finite() and n.is_finite(), "Valores finitos")
		assert_almost_eq(n.length(), 1.0, 0.001, "Normal no nula")
		# Lo que cae delante de la frente (el flequillo).
		if absf(p.x) < 0.08 and p.z > CharacterModel.SKULL_CENTER.z + 0.1:
			fringe_bottom = minf(fringe_bottom, p.y)
	assert_gt(hair, 1000, "El pelo es una superficie entera, no unos pocos mechones")
	var brows_top: float = CharacterModel.FACE_AXIS.y - FacePainter.BROW_Y + FacePainter.BROW_THICK
	assert_gt(fringe_bottom, brows_top + 0.01, "El flequillo termina al menos 1 cm sobre las cejas")


func test_the_face_atlas_has_eight_expressions_in_cells_of_128_px() -> void:
	var image: Image = FacePainter.atlas().get_image()
	assert_eq(image.get_width(), FacePainter.CELLS * FacePainter.CELL)
	assert_eq(image.get_height(), FacePainter.CELL)
	assert_eq(FacePainter.CELLS, 8)
	assert_eq(FacePainter.CELL, 128)
	var closed: Array[FacePainter.Face] = [FacePainter.Face.BLINK, FacePainter.Face.HAPPY]
	var eye: Vector2i = _cell_pixel(0, Vector2(FacePainter.EYE_X, 0.0))
	for face: int in FacePainter.CELLS:
		var alpha: float = image.get_pixel(eye.x + face * FacePainter.CELL, eye.y).a
		if face in closed:
			assert_eq(alpha, 0.0, "Con los ojos cerrados no hay máscara (%d)" % face)
		else:
			assert_gt(alpha, 0.9, "La máscara del ojo abierto está en el alfa (%d)" % face)
		if face > 0:
			assert_false(_cells_equal(image, 0, face), "Cada expresión es distinta (%d)" % face)
	# Ojos de al menos 6 píxeles de alto con el zoom normal (en el dibujo más
	# chico del mundo, 720 px de ancho).
	var rows: int = 0
	for y: int in FacePainter.CELL:
		if image.get_pixel(eye.x, y).a > 0.5:
			rows += 1
	var meters_per_pixel: float = RoomView.CAMERA_SIZE / 720.0
	assert_gte(rows * FacePainter.HEIGHT / FacePainter.CELL / meters_per_pixel, 6.0, "Ojos legibles con el zoom normal")


func test_the_meshes_skin_and_materials_are_shared_between_builds() -> void:
	var first: Node3D = CharacterModel.build(_root, "First")
	var second: Node3D = CharacterModel.build(_root, "Second")
	for path: String in ["Rig/Mesh", "Rig/Outline", "Body/Head/Mesh", "Body/Head/Outline"]:
		var a: MeshInstance3D = first.get_node(path)
		var b: MeshInstance3D = second.get_node(path)
		assert_same(a.mesh, b.mesh, path)
		assert_same(a.material_override, b.material_override, path)
	assert_same((first.get_node("Rig/Mesh") as MeshInstance3D).skin, (second.get_node("Rig/Mesh") as MeshInstance3D).skin)


func test_each_character_shows_its_own_expression() -> void:
	var first: Node3D = CharacterModel.build(_root, "First")
	var second: Node3D = CharacterModel.build(_root, "Second")
	CharacterModel.set_expression(first, FacePainter.Face.WORRIED)
	assert_eq((first.get_node("Body/Head/Mesh") as GeometryInstance3D).get_instance_shader_parameter(&"expression"), FacePainter.Face.WORRIED)
	assert_ne((second.get_node("Body/Head/Mesh") as GeometryInstance3D).get_instance_shader_parameter(&"expression"), FacePainter.Face.WORRIED, "La otra cara no cambia")


## Píxel de la celda `cell` del atlas en el punto `at` de la cara (m, desde
## el centro de la línea de los ojos, y hacia abajo).
func _cell_pixel(cell: int, at: Vector2) -> Vector2i:
	var x: int = floori((at.x / FacePainter.WIDTH + 0.5) * FacePainter.CELL)
	var y: int = floori((at.y / FacePainter.HEIGHT + 0.5) * FacePainter.CELL)
	return Vector2i(cell * FacePainter.CELL + x, y)


func _cells_equal(image: Image, a: int, b: int) -> bool:
	for y: int in FacePainter.CELL:
		for x: int in FacePainter.CELL:
			if not image.get_pixel(a * FacePainter.CELL + x, y).is_equal_approx(image.get_pixel(b * FacePainter.CELL + x, y)):
				return false
	return true
