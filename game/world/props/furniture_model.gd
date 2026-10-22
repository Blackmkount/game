class_name FurnitureModel
extends RefCounted
## Modelo 3D de cada mueble. El frente mira hacia +Z. Los lugares donde va
## una impresora quedan marcados con nodos "PrinterSpot0", "PrinterSpot1"...


static func build(parent: Node3D, node_name: String, furniture_id: String) -> Node3D:
	var root: Node3D
	match furniture_id:
		"mesa_computador":
			root = ComputerDeskModel.build(parent, node_name)
		"mesa_auxiliar":
			root = PropBuilder.group(parent, node_name)
			_table(root, Vector3(0.6, 0.5, 0.55), WorldPalette.paint("e6e2d8", WorldPalette.Surface.SMOOTH, 0.2))
			_spot(root, 0, Vector3(0.0, 0.5, 0.0))
		"mesa_trabajo":
			root = PropBuilder.group(parent, node_name)
			_table(root, Vector3(1.3, 0.8, 0.6), WorldPalette.paint(WorldPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.15))
			PropBuilder.box(root, "Drawers", Vector3(0.4, 0.5, 0.5), Vector3(0.38, 0.4, 0.0), WorldPalette.paint(WorldPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4))
			_spot(root, 0, Vector3(-0.3, 0.8, 0.0))
			_spot(root, 1, Vector3(0.3, 0.8, 0.0))
		"estanteria_metalica":
			root = PropBuilder.group(parent, node_name)
			_rack(root)
		"repisa_filamento":
			root = PropBuilder.group(parent, node_name)
			_filament_shelf(root)
		"estanteria_cubos":
			root = PropBuilder.group(parent, node_name)
			_cube_shelf(root)
		"panel_herramientas":
			root = PropBuilder.group(parent, node_name)
			_pegboard(root)
		_:
			root = PropBuilder.group(parent, node_name)
			_table(root, Vector3(0.8, 0.7, 0.5), WorldPalette.paint(WorldPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.15))
	return root


static func _spot(parent: Node3D, index: int, position: Vector3) -> void:
	var spot: Marker3D = Marker3D.new()
	spot.name = "PrinterSpot%d" % index
	spot.position = position
	parent.add_child(spot)


static func _table(parent: Node3D, size: Vector3, material: Material) -> void:
	PropBuilder.box(parent, "Top", Vector3(size.x, 0.05, size.z), Vector3(0.0, size.y - 0.025, 0.0), material)
	for i: int in 4:
		var x: float = (size.x / 2.0 - 0.04) * (1.0 if i % 2 == 0 else -1.0)
		var z: float = (size.z / 2.0 - 0.04) * (1.0 if i < 2 else -1.0)
		PropBuilder.box(parent, "Leg%d" % (i + 1), Vector3(0.05, size.y - 0.05, 0.05), Vector3(x, (size.y - 0.05) / 2.0, z), material)


static func _rack(parent: Node3D) -> void:
	var metal: Material = WorldPalette.paint(WorldPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	for i: int in 4:
		var x: float = 0.6 * (1.0 if i % 2 == 0 else -1.0)
		var z: float = 0.24 * (1.0 if i < 2 else -1.0)
		PropBuilder.box(parent, "Post%d" % i, Vector3(0.04, 1.9, 0.04), Vector3(x, 0.95, z), metal)
	for level: int in 3:
		var y: float = 0.08 + level * 0.62
		PropBuilder.box(parent, "Shelf%d" % level, Vector3(1.24, 0.03, 0.52), Vector3(0.0, y, 0.0), WorldPalette.paint(WorldPalette.METAL_MID, WorldPalette.Surface.METAL, 0.4))
		_spot(parent, level, Vector3(0.0, y + 0.015, 0.0))


static func _filament_shelf(parent: Node3D) -> void:
	var wood: Material = WorldPalette.paint(WorldPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.15)
	var colors: Array[String] = ["e0453a", "f5cf3c", "3b7fe0", "4cbf5a", "9b5de5", "f28c28"]
	for level: int in 2:
		var y: float = 1.1 + level * 0.4
		PropBuilder.box(parent, "Board%d" % level, Vector3(1.1, 0.04, 0.26), Vector3(0.0, y, -0.15), wood)
		for i: int in 3:
			SpoolModel.build(parent, "Spool%d_%d" % [level, i], Vector3(-0.34 + i * 0.34, y + 0.12, -0.15), colors[level * 3 + i], 0.1)


static func _cube_shelf(parent: Node3D) -> void:
	var wood: Material = WorldPalette.paint("e6e2d8", WorldPalette.Surface.SMOOTH, 0.2)
	PropBuilder.box(parent, "Body", Vector3(0.8, 1.5, 0.4), Vector3(0.0, 0.75, -0.05), wood)
	var colors: Array[String] = ["f2efe6", "2b2b33", "8a8f9c", "e0453a"]
	for i: int in 4:
		var x: float = -0.19 if i % 2 == 0 else 0.19
		var y: float = 0.4 if i < 2 else 1.1
		PropBuilder.box(parent, "Hole%d" % i, Vector3(0.32, 0.6, 0.02), Vector3(x, y, 0.15), WorldPalette.paint("2c2532"))
		SpoolModel.build(parent, "Spool%d" % i, Vector3(x, y - 0.18, 0.2), colors[i], 0.1)


static func _pegboard(parent: Node3D) -> void:
	PropBuilder.box(parent, "Board", Vector3(1.0, 0.7, 0.03), Vector3(0.0, 1.5, -0.25), WorldPalette.paint("d9c6a0"))
	var tools: Array[String] = ["e0453a", "3b7fe0", "2b2f3a", "f5cf3c", "4cbf5a"]
	for i: int in tools.size():
		PropBuilder.box(parent, "Tool%d" % i, Vector3(0.05, 0.2 + (i % 2) * 0.08, 0.03), Vector3(-0.36 + i * 0.18, 1.5, -0.22), WorldPalette.paint(tools[i], WorldPalette.Surface.SMOOTH, 0.3))
