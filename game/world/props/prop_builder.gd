class_name PropBuilder
extends RefCounted
## Atajos para poner mallas en un modelo. kit() pone una malla del kit
## (KitMesh: varias formas en una malla, con el origen en la base del
## objeto). Las formas básicas de antes (box, cylinder, sphere, quad) quedan
## centradas en su origen (la capa caliente de la pieza que se imprime lo
## supone) hasta que todos los modelos pasen al kit.


## Una malla del kit (KitMesh) como hijo de `parent`. Sin `material` usa el
## del kit (WorldPalette.kit()), que lee color, superficie y oclusión de los
## vértices.
static func kit(parent: Node3D, node_name: String, mesh: Mesh, material: Material = null, position: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return _add(parent, node_name, mesh, position, material if material != null else WorldPalette.kit())


static func box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _add(parent, node_name, mesh, position, material)


static func cylinder(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, material: Material, rotation_degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	var instance: MeshInstance3D = _add(parent, node_name, mesh, position, material)
	instance.rotation_degrees = rotation_degrees
	return instance


static func sphere(parent: Node3D, node_name: String, radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _add(parent, node_name, mesh, position, material)


## Plano que mira hacia +Z; sirve para pantallas y ventanas con textura.
static func quad(parent: Node3D, node_name: String, size: Vector2, position: Vector3, material: Material, rotation_degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = _add(parent, node_name, mesh, position, material)
	instance.rotation_degrees = rotation_degrees
	return instance


static func group(parent: Node3D, node_name: String, position: Vector3 = Vector3.ZERO) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	node.position = position
	parent.add_child(node)
	return node


static func _add(parent: Node3D, node_name: String, mesh: Mesh, position: Vector3, material: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance
