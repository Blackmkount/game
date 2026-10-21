class_name SlotMarker
extends RefCounted
## Marca brillante en el piso de un lugar libre para un mueble, con un "+".


static func build(parent: Node3D, node_name: String, material: StandardMaterial3D) -> Node3D:
	var marker: Node3D = PropBuilder.group(parent, node_name)
	var width: float = 1.2
	var depth: float = 0.56
	var line: float = 0.04
	var y: float = 0.006
	PropBuilder.box(marker, "Front", Vector3(width, 0.01, line), Vector3(0.0, y, depth / 2.0), material)
	PropBuilder.box(marker, "Back", Vector3(width, 0.01, line), Vector3(0.0, y, -depth / 2.0), material)
	PropBuilder.box(marker, "Left", Vector3(line, 0.01, depth), Vector3(-width / 2.0, y, 0.0), material)
	PropBuilder.box(marker, "Right", Vector3(line, 0.01, depth), Vector3(width / 2.0, y, 0.0), material)
	PropBuilder.box(marker, "PlusH", Vector3(0.2, 0.01, line), Vector3(0.0, y, 0.0), material)
	PropBuilder.box(marker, "PlusV", Vector3(line, 0.01, 0.2), Vector3(0.0, y, 0.0), material)
	return marker
