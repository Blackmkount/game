class_name PropBounds
extends RefCounted
## Caja que envuelve un modelo armado con PropBuilder, en el espacio local de
## su nodo raíz.
##
## Se calcula con las medidas de cada forma (BoxMesh.size, CylinderMesh.radius...)
## y no con get_aabb(), porque sin pantalla (pruebas en modo headless) las
## mallas no tienen tamaño.


static func local_aabb(root: Node3D) -> AABB:
	var result: AABB = AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		if mesh_instance.mesh == null:
			continue
		var box: AABB = _relative_transform(root, mesh_instance) * mesh_aabb(mesh_instance.mesh)
		result = box if first else result.merge(box)
		first = false
	return result


## Caja de una malla centrada en su origen.
static func mesh_aabb(mesh: Mesh) -> AABB:
	if mesh is BoxMesh:
		var size: Vector3 = (mesh as BoxMesh).size
		return AABB(-size / 2.0, size)
	if mesh is CylinderMesh:
		var cylinder: CylinderMesh = mesh
		var radius: float = maxf(cylinder.top_radius, cylinder.bottom_radius)
		return AABB(Vector3(-radius, -cylinder.height / 2.0, -radius), Vector3(radius * 2.0, cylinder.height, radius * 2.0))
	if mesh is SphereMesh:
		var sphere: SphereMesh = mesh
		return AABB(Vector3(-sphere.radius, -sphere.height / 2.0, -sphere.radius), Vector3(sphere.radius * 2.0, sphere.height, sphere.radius * 2.0))
	if mesh is QuadMesh:
		var quad_size: Vector2 = (mesh as QuadMesh).size
		return AABB(Vector3(-quad_size.x / 2.0, -quad_size.y / 2.0, 0.0), Vector3(quad_size.x, quad_size.y, 0.0))
	return mesh.get_aabb()


static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var transform: Transform3D = Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform
