class_name FurnitureModel
extends RefCounted
## Modelo 3D de cada mueble (biblia de arte §10). El frente mira hacia +Z y
## la base queda en y = 0. Todo lo fijo es UNA malla del kit ("Body", en
## caché por tipo y variante): 2 llamadas de dibujo con su sombra. Los
## lugares donde va una impresora quedan marcados con "PrinterSpot0",
## "PrinterSpot1"... (Marker3D), tantos como `printer_slots` en
## data/furniture.json.
##
## `wall_gap` es la distancia del centro del lugar a la pared de atrás
## (RoomLayout; NO_WALL si no hay pared donde colgar nada). Lo que se cuelga
## (la repisa de filamento y el tablero de herramientas) queda pegado a esa
## pared; sin pared lleva su pie propio. El mueble de cubos se arrima a la
## pared si la hay (contra el zócalo). Lo demás va centrado en su lugar.

## Sin pared donde colgar (el lugar del medio del cuarto, bajo la ventana, o
## las vistas de la tienda).
const NO_WALL: float = -1.0
## Lo que se cuelga de la pared (o va sobre su pie propio).
const HANGING: Array[String] = ["repisa_filamento", "panel_herramientas"]
## Lo que se arrima a la pared si la hay (su espalda en z = 0 de la malla).
const AGAINST_WALL: Array[String] = ["estanteria_cubos"]


static func build(parent: Node3D, node_name: String, furniture_id: String, wall_gap: float = NO_WALL) -> Node3D:
	if furniture_id == "mesa_computador":
		return ComputerDeskModel.build(parent, node_name)
	var root: Node3D = PropBuilder.group(parent, node_name)
	var on_wall: bool = wall_gap >= 0.0
	var body: MeshInstance3D = PropBuilder.kit(root, "Body", body_mesh(furniture_id, on_wall))
	var bounds: AABB = body.mesh.get_aabb()
	if on_wall and furniture_id in HANGING:
		# Su espalda contra la pared de atrás.
		body.position.z = -wall_gap + FurnitureParts.WALL_CLEARANCE - bounds.position.z
	elif on_wall and furniture_id in AGAINST_WALL:
		# En el piso: su espalda contra el zócalo.
		body.position.z = -wall_gap + FurnitureParts.FLOOR_WALL_GAP - bounds.position.z
	elif furniture_id in AGAINST_WALL:
		body.position.z = -bounds.get_center().z
	var spots: Array[Vector3] = printer_spots(furniture_id)
	for i: int in spots.size():
		FurnitureParts.spot(root, i, spots[i])
	return root


## Lo que se toca de un mueble armado con build() (`root`), en su espacio,
## si no es su caja entera: las partes de la estantería metálica, que es
## abierta (MetalRackModel.touch_parts). Vacío para los demás.
static func touch_parts(root: Node3D, furniture_id: String) -> Array[AABB]:
	var parts: Array[AABB] = []
	if furniture_id != MetalRackModel.FURNITURE_ID:
		return parts
	var body: Node3D = root.get_node("Body")
	for part: AABB in MetalRackModel.touch_parts():
		parts.append(body.transform * part)
	return parts


## Dónde va cada impresora del mueble (en su espacio), en orden.
static func printer_spots(furniture_id: String) -> Array[Vector3]:
	match furniture_id:
		"mesa_auxiliar":
			return TableModels.SIDE_TABLE_SPOTS
		"mesa_trabajo":
			return TableModels.WORK_TABLE_SPOTS
		MetalRackModel.FURNITURE_ID:
			var spots: Array[Vector3] = []
			for height: float in MetalRackModel.spot_heights():
				spots.append(Vector3(0.0, height, 0.0))
			return spots
	return []


## La malla de un mueble (en caché). `on_wall` solo cambia lo que se cuelga:
## pegado a la pared o sobre su pie.
static func body_mesh(furniture_id: String, on_wall: bool) -> ArrayMesh:
	var hangs: bool = furniture_id in HANGING
	var variant: String = ("wall" if on_wall else "stand") if hangs else "fixed"
	return KitMesh.cached("furniture:%s:%s:%.2f" % [furniture_id, variant, FurnitureParts.DETAIL], func() -> ArrayMesh:
		return _mesh(furniture_id, hangs and on_wall))


static func _mesh(furniture_id: String, on_wall: bool) -> ArrayMesh:
	match furniture_id:
		"mesa_auxiliar":
			return TableModels.side_table()
		"mesa_trabajo":
			return TableModels.work_table()
		MetalRackModel.FURNITURE_ID:
			return MetalRackModel.mesh()
		"repisa_filamento":
			return FilamentStorageModels.filament_shelf(on_wall)
		"estanteria_cubos":
			return FilamentStorageModels.cube_shelf()
		"panel_herramientas":
			return PegboardModel.mesh(on_wall)
	# Un mueble nuevo sin modelo todavía: la mesita.
	return TableModels.side_table()
