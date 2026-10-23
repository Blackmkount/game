class_name PackageModel
extends RefCounted
## Cajas del rincón de despacho (biblia de arte §10), exageradas para que se
## vean (más de 3 cm, ver docs/ESTILO.md). Cada una es una malla del kit
## ("Box"), compartida por todas:
## - package: un paquete cerrado de cartón corrugado con cinta y una etiqueta
##   blanca con un ícono azul oscuro (sin texto), centrado en su origen (se
##   apilan sobre el guacal de salida).
## - open_box: una caja abierta con las solapas abiertas, relleno de papel y
##   la pieza adentro ("Piece", la tiñe DispatchView con el color del pedido),
##   con la base en su origen (se apoya en la mesa de embalar).

## Medidas del paquete cerrado (DispatchCornerModel.PACKAGE_HEIGHT de alto).
const PACKAGE_SIZE: Vector3 = Vector3(0.18, DispatchCornerModel.PACKAGE_HEIGHT, 0.16)
## Caja abierta: medidas, grosor del cartón y largo de las solapas.
const OPEN_BOX_SIZE: Vector3 = Vector3(0.15, 0.08, 0.14)
const CARDBOARD_THICKNESS: float = 0.006
const FLAP_LENGTH: float = 0.065
## Las solapas largas (de adelante y de atrás) caen hacia afuera este tanto
## (grados); las cortas cuelgan contra los costados.
const FLAP_DROP: float = 30.0
## La pieza de adentro: medidas y altura de su centro (asoma por arriba).
const PIECE_SIZE: Vector3 = Vector3(0.08, 0.06, 0.08)
const PIECE_CENTER_Y: float = 0.09


static func package(parent: Node3D, node_name: String) -> Node3D:
	var root: Node3D = PropBuilder.group(parent, node_name)
	PropBuilder.kit(root, "Box", KitMesh.cached("package:closed", _package_mesh))
	return root


static func open_box(parent: Node3D, node_name: String) -> Node3D:
	var root: Node3D = PropBuilder.group(parent, node_name)
	PropBuilder.kit(root, "Box", KitMesh.cached("package:open", _open_box_mesh))
	var piece_mesh: ArrayMesh = KitMesh.cached("package:piece", func() -> ArrayMesh:
		var kit: KitMesh = KitMesh.new()
		kit.ao_enabled = false
		kit.box(PIECE_SIZE, Vector3.ZERO, 0.006)
		return kit.commit())
	PropBuilder.kit(root, "Piece", piece_mesh, WorldPalette.solid(WorldPalette.PLASTIC_BEIGE), Vector3(0.0, PIECE_CENTER_Y, 0.0))
	return root


## Cartón con la cinta del cierre (arriba y bajando por los dos costados) y la
## etiqueta al frente: un ícono y dos rayas que no se leen.
static func _package_mesh() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	var h: Vector3 = PACKAGE_SIZE / 2.0
	kit.ao_enabled = false
	kit.paint(LookPalette.CARDBOARD, WorldPalette.Surface.CARDBOARD, 0.05)
	kit.box(PACKAGE_SIZE, Vector3.ZERO, 0.008)
	kit.paint(LookPalette.TAPE, WorldPalette.Surface.SMOOTH, 0.55)
	kit.box(Vector3(PACKAGE_SIZE.x + 0.002, 0.003, 0.045), Vector3(0.0, h.y + 0.0005, 0.0), 0.0)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.003, 0.05, 0.045), Vector3((h.x + 0.0005) * x, h.y - 0.025, 0.0), 0.0)
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.2)
	kit.box(Vector3(0.08, 0.055, 0.002), Vector3(-0.03, -0.012, h.z + 0.0005), 0.0)
	kit.paint(LookPalette.RUG_PATTERN[2])
	kit.box(Vector3(0.018, 0.018, 0.002), Vector3(-0.055, -0.008, h.z + 0.0015), 0.0)
	kit.paint(LookPalette.METAL_MID)
	kit.box(Vector3(0.035, 0.005, 0.002), Vector3(-0.018, -0.002, h.z + 0.0015), 0.0)
	kit.box(Vector3(0.025, 0.005, 0.002), Vector3(-0.023, -0.016, h.z + 0.0015), 0.0)
	return kit.commit()


## Caja de cartón abierta: fondo, cuatro paredes, el relleno de papel, las
## solapas largas abiertas hacia afuera y las cortas colgando a los lados.
static func _open_box_mesh() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	var s: Vector3 = OPEN_BOX_SIZE
	var t: float = CARDBOARD_THICKNESS
	kit.ao_enabled = false
	kit.paint(LookPalette.CARDBOARD, WorldPalette.Surface.CARDBOARD, 0.05)
	kit.box(Vector3(s.x, t, s.z), Vector3(0.0, t / 2.0, 0.0), 0.0)
	for z: float in KitMesh.SIGNS:
		kit.box(Vector3(s.x, s.y, t), Vector3(0.0, s.y / 2.0, (s.z - t) / 2.0 * z), 0.002)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(t, s.y, s.z - t * 2.0), Vector3((s.x - t) / 2.0 * x, s.y / 2.0, 0.0), 0.0)
	kit.paint(LookPalette.RUG_BASE, WorldPalette.Surface.FABRIC, 0.05)
	kit.blob(Vector3(s.x / 2.0 - t, 0.012, s.z / 2.0 - t), Vector3(0.0, s.y - 0.022, 0.0), Vector3.ZERO, 0.4, 0.7, Vector2.ONE, Vector2i(10, 4))
	kit.paint(LookPalette.CARDBOARD_DARK, WorldPalette.Surface.CARDBOARD, 0.05)
	var drop: float = deg_to_rad(FLAP_DROP)
	var reach: Vector2 = Vector2(cos(drop), -sin(drop)) * FLAP_LENGTH / 2.0
	for z: float in KitMesh.SIGNS:
		kit.box(Vector3(s.x, 0.004, FLAP_LENGTH), Vector3(0.0, s.y + reach.y, (s.z / 2.0 + reach.x) * z), 0.0, Vector3(FLAP_DROP * z, 0.0, 0.0))
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.004, FLAP_LENGTH * 0.8, s.z - 0.01), Vector3((s.x / 2.0 + 0.002) * x, s.y - FLAP_LENGTH * 0.4, 0.0), 0.0)
	return kit.commit()
