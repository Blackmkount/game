class_name FurnitureParts
extends RefCounted
## Lo que comparten los muebles (biblia de arte §10 y §5.1–5.2): el detalle,
## los lugares de las impresoras, el pie propio de lo que se cuelga cuando no
## hay pared, las escuadras impresas y las cajas de filamento.
##
## Cada mueble es UNA malla del kit ("Body", con el material del kit: color,
## superficie y capas en los vértices): 2 llamadas de dibujo con su sombra.
## Los carretes que guarda van dentro de esa malla (SpoolModel.add_on_shelf y
## add_stack): no cambian de color y así no suman llamadas.

## Detalle de lo redondo (biblia §5.1; como el escritorio).
const DETAIL: float = 0.8
## Los biseles más chicos que esto (m) no se hacen (KitMesh.bevel_cutoff):
## en piezas chicas no se ven y cuestan 32 triángulos cada caja. Los de los
## tableros y las patas (biblia §5.1: 10–20 mm en muebles) quedan.
const BEVEL_CUTOFF: float = 0.005
## Lo que se cuelga o se arrima queda a esto de la pared (m): pegado, sin
## tocarla. Con menos, el borde de su sombra cae justo sobre la pared, al
## lado de su canto de arriba, y se ven los dientes del mapa de sombras; así
## queda detrás del mueble.
const WALL_CLEARANCE: float = 0.015
## Lo que va en el piso junto a la pared se separa esto (m): no choca con el
## zócalo (sobresale 1,8 cm).
const FLOOR_WALL_GAP: float = 0.03
## Pie propio (lo que se cuelga, en un lugar sin pared): parantes cuadrados
## de metal y pies en T con tapones de goma.
const STAND_POST: float = 0.03
const STAND_FOOT_DEPTH: float = 0.42
const STAND_FOOT_HEIGHT: float = 0.025
const STAND_LOW_BAR: float = 0.3
## Escuadras impresas (naranja, biblia §10): ancho, grosor y alto de capa.
const BRACKET_WIDTH: float = 0.026
const BRACKET_THICKNESS: float = 0.012
const BRACKET_LAYER: float = 0.004
## Caja de filamento (cartón con cinta y etiqueta): medidas.
const FILAMENT_BOX_SIZE: Vector3 = Vector3(0.22, 0.09, 0.22)


## Un KitMesh con el detalle de los muebles.
static func kit() -> KitMesh:
	var mesh: KitMesh = KitMesh.new()
	mesh.detail = DETAIL
	mesh.bevel_cutoff = BEVEL_CUTOFF
	return mesh


## El lugar de una impresora ("PrinterSpot<index>", Marker3D): lo lee
## RoomView para poner cada impresora del mueble.
static func spot(furniture: Node3D, index: int, position: Vector3) -> Marker3D:
	var point: Marker3D = Marker3D.new()
	point.name = "PrinterSpot%d" % index
	point.position = position
	furniture.add_child(point)
	return point


## Pie propio: dos parantes de metal en x = ±`half_width`, con su cara de
## adelante en z = `front` y de `height` de alto, pies en T a lo largo de Z
## (centrados en `front` − STAND_POST/2) con tapones, y dos travesaños
## (arriba y abajo).
static func stand(mesh: KitMesh, half_width: float, front: float, height: float) -> void:
	var z: float = front - STAND_POST / 2.0
	mesh.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.45)
	for side: float in KitMesh.SIGNS:
		var x: float = side * half_width
		mesh.box(Vector3(STAND_POST, height - STAND_FOOT_HEIGHT, STAND_POST), Vector3(x, STAND_FOOT_HEIGHT + (height - STAND_FOOT_HEIGHT) / 2.0, z), 0.004)
		mesh.box(Vector3(STAND_POST, STAND_FOOT_HEIGHT, STAND_FOOT_DEPTH), Vector3(x, STAND_FOOT_HEIGHT / 2.0, z), 0.004)
	for y: float in [STAND_LOW_BAR, height - STAND_POST / 2.0]:
		mesh.box(Vector3(half_width * 2.0, STAND_POST * 0.8, STAND_POST * 0.8), Vector3(0.0, y, z), 0.0)
	mesh.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.2)
	for side: float in KitMesh.SIGNS:
		for end: float in KitMesh.SIGNS:
			mesh.box(Vector3(STAND_POST + 0.006, 0.012, 0.03), Vector3(side * half_width, 0.006, z + end * (STAND_FOOT_DEPTH / 2.0 - 0.015)), 0.0)


## Escuadra impresa en L con su refuerzo en diagonal, en x = `x`, bajo una
## tabla cuya cara de abajo está en y = `under` y que va desde z = `back`
## (la pared o el parante) `depth` hacia +Z.
static func bracket(mesh: KitMesh, x: float, under: float, back: float, depth: float) -> void:
	var t: float = BRACKET_THICKNESS
	var w: float = BRACKET_WIDTH
	var drop: float = depth * 0.7
	mesh.printed(LookPalette.FILAMENT_ORANGE, BRACKET_LAYER)
	mesh.box(Vector3(w, drop, t), Vector3(x, under - drop / 2.0, back + t / 2.0), 0.0)
	mesh.box(Vector3(w, t, depth * 0.85), Vector3(x, under - t / 2.0, back + depth * 0.425), 0.0)
	var arm: Vector2 = Vector2(depth * 0.6, drop * 0.75)
	# Del pie de la placa (abajo, contra la pared) a la punta del brazo: el
	# giro en X lleva el largo de la caja (Z) hacia arriba y afuera.
	mesh.box(Vector3(w * 0.8, t, arm.length()), Vector3(x, under - t - arm.y / 2.0, back + t + arm.x / 2.0), 0.0, Vector3(-rad_to_deg(atan2(arm.y, arm.x)), 0.0, 0.0))


## Caja de filamento de cartón con la base en `base`, girada `yaw` grados:
## cinta del cierre y la etiqueta con un ícono (sin texto) al frente.
static func filament_box(mesh: KitMesh, base: Vector3, yaw: float) -> void:
	var size: Vector3 = FILAMENT_BOX_SIZE
	var saved: Transform3D = mesh.origin
	mesh.origin = saved * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), base)
	mesh.paint(LookPalette.CARDBOARD, WorldPalette.Surface.CARDBOARD, 0.1)
	mesh.box(size, Vector3(0.0, size.y / 2.0, 0.0), 0.006)
	mesh.paint(LookPalette.TAPE, WorldPalette.Surface.SMOOTH, 0.5)
	mesh.box(Vector3(0.05, 0.003, size.z + 0.004), Vector3(0.0, size.y + 0.0005, 0.0), 0.0)
	mesh.paint(LookPalette.SHEET)
	mesh.quad(Vector2(0.09, 0.05), Vector3(0.03, size.y / 2.0, size.z / 2.0 + 0.001))
	mesh.paint(LookPalette.RUG_PATTERN[2])
	mesh.quad(Vector2(0.025, 0.025), Vector3(0.0, size.y / 2.0, size.z / 2.0 + 0.002))
	mesh.origin = saved
