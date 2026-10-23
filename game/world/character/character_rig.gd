class_name CharacterRig
extends Skeleton3D
## El esqueleto del personaje (biblia de arte §7.2): un hueso por cada pivote
## de CharacterModel (Body, HipL/R y sus rodillas, ShoulderL/R y sus codos,
## Head), con la misma jerarquía. Los pivotes siguen siendo el contrato: el
## controlador (y el animador) los mueven y las pruebas los leen. follow()
## copia cada cuadro la pose de cada pivote a su hueso, sin crear memoria;
## RoomView lo llama después de mover al personaje.
##
## El cuerpo es UNA malla con piel (skinned_mesh): cada parte es rígida
## (todos sus vértices van a un hueso) salvo un anillo de mezcla de ±BLEND
## alrededor de cada articulación, donde pasan de un hueso al siguiente. Así
## rodillas, codos, hombros y caderas se doblan sin cortes.

## Medio ancho (m) del anillo de mezcla de cada articulación.
const BLEND: float = 0.04
## Huesos por vértice (el formato de Godot sin ARRAY_FLAG_USE_8_BONE_WEIGHTS).
const WEIGHTS_PER_VERTEX: int = 4


## Una parte del cuerpo: sus formas y cómo se reparten sus vértices entre
## los huesos. `bones` va en cadena, del padre a la punta (con uno solo, la
## parte es rígida); `joints` dice dónde está cada articulación, en metros a
## lo largo de `axis` desde el origen de `frame` (el reposo del primer hueso
## de la cadena, en el espacio del modelo).
class Part:
	var kit: KitMesh
	var bones: PackedInt32Array
	var joints: PackedFloat32Array
	var frame: Transform3D
	var axis: Vector3

	func _init(p_kit: KitMesh, p_bones: PackedInt32Array, p_joints: PackedFloat32Array = PackedFloat32Array(), p_frame: Transform3D = Transform3D.IDENTITY, p_axis: Vector3 = Vector3.DOWN) -> void:
		kit = p_kit
		bones = p_bones
		joints = p_joints
		frame = p_frame
		axis = p_axis


## Los pivotes de cada hueso, en el orden de los huesos.
var _pivots: Array[Node3D] = []


## Arma el esqueleto de un personaje con un hueso por pivote (en ese orden;
## el padre de cada hueso es el pivote padre). El reposo de cada hueso es la
## pose de su pivote al armarlo.
static func create(pivots: Array[Node3D]) -> CharacterRig:
	var rig: CharacterRig = CharacterRig.new()
	rig.name = "Rig"
	for pivot: Node3D in pivots:
		rig.add_bone(pivot.name)
	for i: int in pivots.size():
		rig.set_bone_parent(i, pivots.find(pivots[i].get_parent() as Node3D))
		rig.set_bone_rest(i, pivots[i].transform)
	rig.reset_bone_poses()
	rig._pivots = pivots.duplicate()
	return rig


## Una piel para el cuerpo: el reposo de cada hueso en el espacio del modelo
## (su inversa es la pose de enlace).
static func skin_for(rests: Array[Transform3D]) -> Skin:
	var skin: Skin = Skin.new()
	for i: int in rests.size():
		skin.add_bind(i, rests[i].affine_inverse())
	return skin


## Une las partes en una malla con piel: los vértices de cada parte con sus
## huesos y pesos (ver Part).
static func skinned_mesh(parts: Array[Part]) -> ArrayMesh:
	var positions: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	var uvs: PackedVector2Array = PackedVector2Array()
	var uv2s: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var bones: PackedInt32Array = PackedInt32Array()
	var weights: PackedFloat32Array = PackedFloat32Array()
	for part: Part in parts:
		var arrays: Array = part.kit.arrays()
		var part_positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var first: int = positions.size()
		var to_frame: Transform3D = part.frame.affine_inverse()
		for p: Vector3 in part_positions:
			var bone_weight: Vector3 = _bone_weight(part, (to_frame * p).dot(part.axis))
			bones.append(int(bone_weight.x))
			bones.append(int(bone_weight.y))
			weights.append(1.0 - bone_weight.z)
			weights.append(bone_weight.z)
			for k: int in WEIGHTS_PER_VERTEX - 2:
				bones.append(0)
				weights.append(0.0)
		positions.append_array(part_positions)
		normals.append_array(arrays[Mesh.ARRAY_NORMAL])
		colors.append_array(arrays[Mesh.ARRAY_COLOR])
		uvs.append_array(arrays[Mesh.ARRAY_TEX_UV])
		uv2s.append_array(arrays[Mesh.ARRAY_TEX_UV2])
		for index: int in arrays[Mesh.ARRAY_INDEX] as PackedInt32Array:
			indices.append(first + index)
	var result: Array = []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = positions
	result[Mesh.ARRAY_NORMAL] = normals
	result[Mesh.ARRAY_COLOR] = colors
	result[Mesh.ARRAY_TEX_UV] = uvs
	result[Mesh.ARRAY_TEX_UV2] = uv2s
	result[Mesh.ARRAY_BONES] = bones
	result[Mesh.ARRAY_WEIGHTS] = weights
	result[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, result)
	return mesh


## Los dos huesos de un vértice que está `along` metros a lo largo de la
## cadena de `part`, y el peso del segundo: (hueso, hueso, peso).
static func _bone_weight(part: Part, along: float) -> Vector3:
	if part.joints.is_empty():
		return Vector3(part.bones[0], part.bones[0], 0.0)
	# La articulación más cercana decide: fuera de su anillo, el vértice es
	# entero de uno de sus dos huesos.
	var nearest: int = 0
	for k: int in part.joints.size():
		if absf(along - part.joints[k]) < absf(along - part.joints[nearest]):
			nearest = k
	var joint: float = part.joints[nearest]
	return Vector3(part.bones[nearest], part.bones[nearest + 1], smoothstep(joint - BLEND, joint + BLEND, along))


## Copia la pose de cada pivote a su hueso. Sin memoria nueva: lo llaman
## cada cuadro.
func follow() -> void:
	for i: int in _pivots.size():
		var pivot: Node3D = _pivots[i]
		set_bone_pose_position(i, pivot.position)
		set_bone_pose_rotation(i, pivot.quaternion)
		set_bone_pose_scale(i, pivot.scale)
