class_name EnclosedPrinterModel
extends RefCounted
## Las impresoras cerradas (biblia de arte §9.3), de cama que baja: el cabezal
## va arriba, adentro, y la cama baja de a una capa mientras la pieza crece.
## La pieza se ve por la puerta (solo su marco y un reflejo en diagonal: sin
## vidrio transparente) contra el interior iluminado.
##
## - Bóveda P1, "la cerrada": cubo grafito de esquinas redondeadas, interior
##   cálido, acento verde y el carrete atrás, asomando por encima.
## - Titán Pro, "la grande": gabinete grafito más grande con naranja, dos
##   boquillas, la caja de colores con 4 carretes integrada arriba y una
##   pantalla ancha.
##
## Partes aparte (contrato con PrinterView): "PrintHead/Carriage" (va y viene
## arriba, nunca sube), "Platform" (la cama: baja con la pieza; su cara de
## arriba en su origen), "Interior" (el fondo y la luz de adentro: su material
## lo cambia la vista según el estado) y "Display". Marcadores:
## "PieceAnchor" (la cama arriba del todo, al empezar una pieza: la boquilla a
## HEAD_CLEARANCE), "PlatformLow" (la cama abajo, sin trabajo), "HeadRest",
## "HeadPark", "TrayAnchor" (sobre el techo) y "BedLight".
##
## Lo de adentro no da sombra (la caja no deja pasar el sol) y el carrete es
## parte de "Body" (fijo, del color del primer carrete de la partida): así
## cuesta 6 llamadas también en el piso.

enum Kind { VAULT, TITAN }

## Medidas por tipo (índice = Kind): caja de afuera (sin las patas), grosor
## de las paredes, del techo y alto del zócalo (el piso de adentro). Las
## paredes son gruesas para que sus esquinas redondeadas (ROUND) se vean.
const OUTER: Array[Vector3] = [Vector3(0.4, 0.508, 0.4), Vector3(0.54, 0.588, 0.5)]
const WALL: Array[float] = [0.04, 0.045]
const ROOF: Array[float] = [0.045, 0.05]
const PLINTH_TOP: Array[float] = [0.08, 0.1]
const FEET_HEIGHT: float = 0.012
const ROUND: float = 0.02
## Cabezal quieto (arriba, adentro) y estacionado; la cama y su lugar más
## bajo; la lámina PEI.
const HEAD_REST: Array[Vector3] = [Vector3(0.0, 0.435, 0.0), Vector3(0.0, 0.5, 0.0)]
const HEAD_PARK_X: Array[float] = [-0.11, -0.15]
const BED_Z: float = 0.03
const BED_SIZE: Array[float] = [0.27, 0.34]
const PLATFORM_LOW_ABOVE_FLOOR: float = 0.02
## Pantallita (ancha en la Titán) en el zócalo, a la izquierda.
const DISPLAY: Array[Vector3] = [Vector3(-0.11, 0.046, 0.2025), Vector3(-0.08, 0.056, 0.2525)]
const DISPLAY_SIZE: Array[Vector2] = [Vector2(0.08, 0.036), Vector2(0.17, 0.05)]
## Bandeja sobre el marco del techo, al frente.
const TRAY_ANCHOR: Array[Vector3] = [Vector3(-0.15, 0.52, 0.17), Vector3(-0.17, 0.6, 0.22)]
## Color de la carcasa, del acento y de la luz de adentro (§4.5).
const SHELL: Array[String] = [LookPalette.VAULT_GRAPHITE, LookPalette.TITAN_GRAPHITE]
const ACCENT: Array[String] = [LookPalette.PRINTER_GREEN, LookPalette.TITAN_ORANGE]
const INSIDE: Array[String] = [LookPalette.VAULT_INSIDE, LookPalette.TITAN_INSIDE]
## Techo de vidrio (solo su marco): de dónde a dónde (z) va el vidrio. En la
## Titán, detrás va la caja de colores.
const TOP_GLASS_Z: Array[Vector2] = [Vector2(-0.15, 0.14), Vector2(-0.02, 0.19)]
## El carrete de la Bóveda, atrás (de frente a la cámara: eje en Z).
const VAULT_SPOOL: Vector3 = Vector3(0.06, 0.5, -0.235)
const VAULT_SPOOL_RADIUS: float = 0.088
## Caja de colores de la Titán, sobre el techo: alto, fondo y sus carretes.
const TITAN_BOX_HEIGHT: float = 0.1
const TITAN_BOX_Z: Vector2 = Vector2(-0.24, -0.02)
const TITAN_SPOOL_RADIUS: float = 0.042
const TITAN_SPOOL_X: Array[float] = [-0.18, -0.06, 0.06, 0.18]
const TITAN_COLORS: Array[String] = ["e0453a", "f5cf3c", "3b7fe0"]
## Las dos boquillas de la Titán (x en el cabezal).
const TITAN_NOZZLES: Array[float] = [-0.02, 0.02]


static func build(printer: Node3D, kind: Kind, spool_color: String, detail: float) -> void:
	var family: String = _family(kind)
	PrinterParts.body(printer, KitMesh.cached(PrinterParts.key(family, "body", detail, spool_color), _body.bind(kind, spool_color, detail)))
	var rest: Vector3 = HEAD_REST[kind]
	var anchor: Vector3 = Vector3(0.0, rest.y - PrinterView.HEAD_CLEARANCE, BED_Z)
	PrinterParts.marker(printer, "PieceAnchor", anchor)
	PrinterParts.marker(printer, "PlatformLow", Vector3(anchor.x, _floor(kind) + PLATFORM_LOW_ABOVE_FLOOR, anchor.z))
	PrinterParts.marker(printer, "HeadRest", rest)
	PrinterParts.marker(printer, "HeadPark", Vector3(HEAD_PARK_X[kind], rest.y, rest.z))
	PrinterParts.marker(printer, "TrayAnchor", TRAY_ANCHOR[kind])
	PrinterParts.marker(printer, "BedLight", Vector3(0.0, _ceiling(kind) - 0.01, OUTER[kind].z / 2.0 - 0.06))
	var head: Node3D = PropBuilder.group(printer, "PrintHead", rest)
	PrinterParts.moving(head, "Carriage", KitMesh.cached(PrinterParts.key(family, "head", detail), _head.bind(kind, detail)), detail, Vector3.ZERO, false)
	PrinterParts.moving(printer, "Platform", KitMesh.cached(PrinterParts.key(family, "platform", detail), _platform.bind(kind, detail)), detail, Vector3(0.0, anchor.y, 0.0), false)
	PrinterParts.moving(printer, "Interior", KitMesh.cached(PrinterParts.key(family, "interior", detail), _interior.bind(kind, detail)), detail, Vector3.ZERO, false)
	PrinterParts.display(printer, DISPLAY_SIZE[kind], DISPLAY[kind])


## La malla lejana (PrinterParts.FAR_DETAIL): la misma caja con menos
## detalle (su carrete ya va adentro, del color `spool_color`).
static func far_body(kind: Kind, spool_color: String) -> ArrayMesh:
	return KitMesh.cached(PrinterParts.key(_family(kind), "body", PrinterParts.FAR_DETAIL, spool_color), _body.bind(kind, spool_color, PrinterParts.FAR_DETAIL))


static func _family(kind: Kind) -> String:
	return "titan_pro" if kind == Kind.TITAN else "boveda_p1"


## El piso de adentro (arriba del zócalo) y el techo de adentro.
static func _floor(kind: Kind) -> float:
	return PLINTH_TOP[kind]


static func _ceiling(kind: Kind) -> float:
	return FEET_HEIGHT + OUTER[kind].y - ROOF[kind]


## La carcasa (zócalo, paredes, techo con sus esquinas redondeadas), el
## marco de la puerta con su manija y su reflejo, los rieles y tornillos de
## adentro y, afuera, el carrete (Bóveda) o la caja de colores (Titán).
static func _body(kind: Kind, spool_color: String, detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	var size: Vector3 = OUTER[kind]
	var half: Vector3 = size / 2.0
	var wall: float = WALL[kind]
	var bottom: float = FEET_HEIGHT
	var top: float = FEET_HEIGHT + size.y
	var floor_y: float = _floor(kind)
	var ceiling: float = _ceiling(kind)
	var shell: String = SHELL[kind]
	var accent: String = ACCENT[kind]
	PrinterParts.feet(kit, Vector2(half.x - 0.04, half.z - 0.04))
	kit.ao_base = bottom
	# Zócalo, paredes de los lados y de atrás, techo.
	kit.paint(shell, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(size.x, floor_y - bottom, size.z), Vector3(0.0, (floor_y + bottom) / 2.0, 0.0), ROUND)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(wall, size.y, size.z), Vector3(side * (half.x - wall / 2.0), bottom + half.y, 0.0), ROUND)
	kit.box(Vector3(size.x, size.y, wall), Vector3(0.0, bottom + half.y, -half.z + wall / 2.0), ROUND)
	# Techo de vidrio: solo el marco (adelante, atrás y los lados); desde
	# arriba se ven el cabezal, la pieza y la luz de adentro.
	var glass: Vector2 = TOP_GLASS_Z[kind]
	var roof_y: float = (top + ceiling) / 2.0
	var side_bar: float = wall + 0.01
	kit.box(Vector3(size.x, top - ceiling, half.z - glass.y), Vector3(0.0, roof_y, (half.z + glass.y) / 2.0), ROUND)
	kit.box(Vector3(size.x, top - ceiling, glass.x + half.z), Vector3(0.0, roof_y, (glass.x - half.z) / 2.0), ROUND)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(side_bar, top - ceiling, glass.y - glass.x + 0.04), Vector3(side * (half.x - side_bar / 2.0), roof_y, (glass.x + glass.y) / 2.0), ROUND)
	# Por dentro un poco más claro (si no, de lejos es un hueco negro).
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.SMOOTH, 0.2)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.004, ceiling - floor_y, size.z - wall - 0.01), Vector3(side * (half.x - wall - 0.002), (ceiling + floor_y) / 2.0, wall / 2.0 - 0.005), 0.0)
	kit.box(Vector3(size.x - 2.0 * wall, 0.004, size.z - wall - 0.01), Vector3(0.0, floor_y + 0.002, wall / 2.0 - 0.005), 0.0)
	# Marco de la puerta (vidrio sin dibujar), su reflejo y la manija.
	var front: float = half.z + 0.003
	var opening: Vector2 = Vector2(size.x - 2.0 * wall, ceiling - floor_y)
	var middle: float = (ceiling + floor_y) / 2.0
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.5)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.012, opening.y + 0.012, 0.006), Vector3(side * (opening.x / 2.0 - 0.003), middle, front), 0.002)
		kit.box(Vector3(opening.x, 0.012, 0.006), Vector3(0.0, middle + side * (opening.y / 2.0 - 0.003), front), 0.002)
	kit.glowing(LookPalette.WINDOW_ALUMINIUM, 0.25)
	var corner: Vector2 = Vector2(-opening.x / 2.0 + 0.05, ceiling - 0.05)
	kit.box(Vector3(0.11, 0.007, 0.002), Vector3(corner.x, corner.y, front + 0.002), 0.0, Vector3(0.0, 0.0, -40.0))
	if not PrinterParts.lean(detail):
		kit.box(Vector3(0.07, 0.004, 0.002), Vector3(corner.x + 0.016, corner.y - 0.022, front + 0.002), 0.0, Vector3(0.0, 0.0, -40.0))
	# Y en el vidrio del techo, en la esquina de adelante a la izquierda.
	kit.box(Vector3(0.1, 0.002, 0.007), Vector3(-half.x + side_bar + 0.05, top - 0.003, glass.y - 0.045), 0.0, Vector3(0.0, 40.0, 0.0))
	var handle_x: float = half.x - wall / 2.0
	kit.paint(accent if kind == Kind.TITAN else LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.box(Vector3(0.012, opening.y * 0.38, 0.012), Vector3(handle_x, middle, front + 0.01), 0.004)
	# Acento: luz de estado al frente del zócalo (Bóveda) o franjas naranjas
	# en el zócalo y en el borde del techo (Titán).
	if kind == Kind.VAULT:
		kit.glowing(accent, 0.6)
		kit.box(Vector3(0.05, 0.006, 0.003), Vector3(0.12, DISPLAY[kind].y, half.z + 0.0015), 0.0)
	else:
		kit.paint(accent, WorldPalette.Surface.SMOOTH, 0.45)
		kit.box(Vector3(size.x - 0.05, 0.008, 0.003), Vector3(0.0, floor_y - 0.012, half.z + 0.0015), 0.0)
		kit.box(Vector3(size.x - 0.05, 0.01, 0.003), Vector3(0.0, top - 0.025, half.z + 0.0015), 0.0)
	# Marco de la pantallita (va aparte: "Display").
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.5)
	var screen: Vector3 = DISPLAY[kind]
	var screen_size: Vector2 = DISPLAY_SIZE[kind]
	kit.box(Vector3(screen_size.x + 0.01, screen_size.y + 0.008, 0.002), Vector3(screen.x, screen.y, half.z + 0.0005), 0.0)
	# Adentro y oscuro: con el zoom lejos no se ve.
	if not PrinterParts.far(detail):
		_inside_mechanics(kit, kind, floor_y, ceiling)
	if kind == Kind.VAULT:
		_vault_spool(kit, spool_color, half.z)
	else:
		_titan_color_box(kit, spool_color, top)
	return kit.commit()


## Rieles de arriba (el cabezal corre en X sobre una barra) y los tornillos
## por los que baja la cama, atrás.
static func _inside_mechanics(kit: KitMesh, kind: Kind, floor_y: float, ceiling: float) -> void:
	var half: Vector3 = OUTER[kind] / 2.0
	var inner: float = half.x - WALL[kind]
	var rail_y: float = HEAD_REST[kind].y + 0.012
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(inner * 2.0, 0.018, 0.018), Vector3(0.0, rail_y, -0.035), 0.003)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	for side: float in KitMesh.SIGNS:
		kit.cylinder(0.005, half.z * 2.0 - WALL[kind], Vector3(side * (inner - 0.012), rail_y, WALL[kind] / 2.0), Vector3(90.0, 0.0, 0.0), 6)
	var screw_z: float = -half.z + WALL[kind] + 0.03
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.35)
	for side: float in KitMesh.SIGNS:
		kit.cylinder(0.004, ceiling - floor_y, Vector3(side * (BED_SIZE[kind] / 2.0 + 0.02), (ceiling + floor_y) / 2.0, screw_z), Vector3.ZERO, 6)


## El carrete de la Bóveda, atrás y de frente (eje en Z), con su eje
## saliendo de la pared: asoma por encima del techo.
static func _vault_spool(kit: KitMesh, spool_color: String, back: float) -> void:
	var center: Vector3 = VAULT_SPOOL
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	var axle_end: float = center.z - 0.04
	kit.cylinder(0.008, -back - axle_end, Vector3(center.x, center.y, (axle_end - back) / 2.0), Vector3(90.0, 0.0, 0.0), 8)
	var turn: Basis = Basis(Vector3.UP, PI / 2.0)
	kit.origin = Transform3D(turn, Vector3.ZERO)
	var local: Vector3 = turn.inverse() * center
	if PrinterParts.lean(kit.detail):
		SpoolModel.add_small(kit, local, VAULT_SPOOL_RADIUS, spool_color)
	else:
		SpoolModel.add_flanges(kit, local, VAULT_SPOOL_RADIUS)
		SpoolModel.add_winding(kit, local, VAULT_SPOOL_RADIUS, spool_color)
	kit.origin = Transform3D.IDENTITY


## La caja de colores de la Titán, integrada sobre el techo: 4 carretes a la
## vista bajo el marco de su tapa (el primero, del color del primer carrete de
## la partida).
static func _titan_color_box(kit: KitMesh, spool_color: String, roof: float) -> void:
	var half_x: float = OUTER[Kind.TITAN].x / 2.0 - 0.02
	var z: Vector2 = TITAN_BOX_Z
	var depth: float = z.y - z.x
	var mid_z: float = (z.x + z.y) / 2.0
	var height: float = TITAN_BOX_HEIGHT
	kit.ao_base = roof
	kit.paint(LookPalette.TITAN_GRAPHITE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(half_x * 2.0, 0.014, depth), Vector3(0.0, roof + 0.007, mid_z), 0.006)
	kit.box(Vector3(half_x * 2.0, height, 0.012), Vector3(0.0, roof + height / 2.0, z.x + 0.006), 0.005)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.012, height, depth), Vector3(side * (half_x - 0.006), roof + height / 2.0, mid_z), 0.005)
	kit.box(Vector3(half_x * 2.0, 0.03, 0.012), Vector3(0.0, roof + 0.015, z.y - 0.006), 0.005)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.016, 0.012, depth), Vector3(side * (half_x - 0.006), roof + height, mid_z), 0.004)
	kit.box(Vector3(half_x * 2.0, 0.012, 0.016), Vector3(0.0, roof + height, z.x + 0.008), 0.004)
	kit.paint(LookPalette.TITAN_ORANGE, WorldPalette.Surface.SMOOTH, 0.45)
	kit.box(Vector3(half_x * 2.0 + 0.004, 0.012, 0.016), Vector3(0.0, roof + height, z.y - 0.008), 0.004)
	var spool_y: float = roof + 0.014 + TITAN_SPOOL_RADIUS + 0.002
	for i: int in TITAN_SPOOL_X.size():
		var at: Vector3 = Vector3(TITAN_SPOOL_X[i], spool_y, mid_z)
		SpoolModel.add_small(kit, at, TITAN_SPOOL_RADIUS, spool_color if i == 0 else TITAN_COLORS[i - 1], not PrinterParts.lean(kit.detail))


## El cabezal: caja grafito con el acento y el ventilador; una boquilla (la
## Bóveda) o dos (la Titán), con la punta en PrinterParts.NOZZLE_TIP.
static func _head(kind: Kind, detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	var wide: float = 0.1 if kind == Kind.TITAN else 0.07
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(wide + 0.01, 0.05, 0.01), Vector3(0.0, 0.006, -0.023), 0.003)
	kit.paint(SHELL[kind], WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(wide, 0.055, 0.06), Vector3(0.0, 0.003, 0.012), 0.01)
	kit.paint(ACCENT[kind], WorldPalette.Surface.SMOOTH, 0.45)
	kit.box(Vector3(wide - 0.012, 0.008, 0.003), Vector3(0.0, 0.022, 0.0425), 0.0)
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.cylinder(0.015, 0.003, Vector3(0.0, -0.004, 0.0425), Vector3(90.0, 0.0, 0.0), 12)
	if kind == Kind.TITAN:
		for x: float in TITAN_NOZZLES:
			kit.origin = Transform3D(Basis.IDENTITY, Vector3(x, 0.0, 0.0))
			PrinterParts.nozzle(kit, BED_Z)
		kit.origin = Transform3D.IDENTITY
	else:
		PrinterParts.nozzle(kit, BED_Z)
	return kit.commit()


## La cama que baja: lámina PEI dorada (su cara de arriba en el origen), la
## placa y el carro con los brazos que la llevan por los tornillos de atrás.
static func _platform(kind: Kind, detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	var size: float = BED_SIZE[kind]
	var screw_z: float = -OUTER[kind].z / 2.0 + WALL[kind] + 0.03
	kit.paint(LookPalette.PEI_BED, WorldPalette.Surface.PEI, 0.35)
	kit.box(Vector3(size - 0.006, 0.004, size - 0.006), Vector3(0.0, -0.002, BED_Z), 0.0)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.55)
	kit.box(Vector3(size, 0.008, size), Vector3(0.0, -0.008, BED_Z), 0.002)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.45)
	var arm_length: float = BED_Z - size / 2.0 - screw_z + 0.02
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.03, 0.014, arm_length), Vector3(side * (size / 2.0 + 0.02), -0.019, screw_z + arm_length / 2.0 - 0.01), 0.003)
	kit.box(Vector3(size + 0.07, 0.014, 0.03), Vector3(0.0, -0.019, screw_z), 0.003)
	return kit.commit()


## La luz de adentro: el fondo y la tira LED del techo. Sin trabajo está
## apagada (gris); PrinterView le pone un material por estado (cálido al
## imprimir, verde al terminar, rojo al fallar).
static func _interior(kind: Kind, detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	var half: Vector3 = OUTER[kind] / 2.0
	var inner: float = half.x - WALL[kind]
	var floor_y: float = _floor(kind)
	var ceiling: float = _ceiling(kind)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.SMOOTH, 0.2)
	kit.box(Vector3(inner * 2.0 - 0.01, ceiling - floor_y - 0.01, 0.004), Vector3(0.0, (ceiling + floor_y) / 2.0, -half.z + WALL[kind] + 0.003), 0.0)
	kit.box(Vector3(inner * 2.0 - 0.04, 0.006, 0.016), Vector3(0.0, ceiling - 0.004, half.z - 0.05), 0.0)
	return kit.commit()
