class_name RayoModel
extends RefCounted
## Las impresoras de voladizo, blancas (biblia de arte §9.3): una sola
## columna Z a la izquierda, de la que sale el brazo X con el cabezal sobre
## una cama que se mueve hacia adelante y atrás.
##
## - Rayo Mini, "la compacta" (×MINI_SCALE): achatada, cama cuadrada chica,
##   cabezal redondo con un aro verde que brilla y el carrete en un soporte
##   aparte a la derecha.
## - Rayo X1, "la rápida": columna más alta con una barra de luz LED, cama
##   grande, el carrete arriba de la columna y la pantalla táctil en un brazo
##   al frente a la derecha.
## - Prisma MC, "la multicolor": el cuerpo de la Rayo X1 con acento morado y,
##   en vez del carrete, una caja de color con 4 carretes a la vista bajo su
##   tapa, sobre un soporte a la izquierda; 4 tubos que se juntan y la rampa
##   de purga con un montoncito de purga de 4 colores.
##
## Mismo contrato que la Cubo Uno (ver PrinterParts): "Body", "Gantry",
## "PrintHead/Carriage", "Display", "Spool/Filament" y los marcadores "Bed",
## "PieceAnchor", "HeadRest", "HeadPark", "TrayAnchor" y "BedLight".

enum Kind { MINI, X1, PRISMA }

## La Rayo Mini es la misma idea, más chica (PrinterModel.frame_scale).
const MINI_SCALE: float = 0.82

# --- Rayo X1 y Prisma MC (escala 1) ------------------------------------------
## Base blanca (con la torre de la columna a la izquierda) y la cama.
const BASE_SIZE: Vector3 = Vector3(0.36, 0.06, 0.42)
const BASE_CENTER: Vector3 = Vector3(0.04, 0.04, 0.0)
const BED_TOP: float = 0.11
const BED_CENTER: Vector2 = Vector2(0.05, 0.03)
const BED_SIZE: float = 0.25
## Columna Z: lugar (x, z), medidas y alto de arriba (sin la tapa).
const COLUMN: Vector2 = Vector2(-0.175, -0.1)
const COLUMN_SIZE: Vector2 = Vector2(0.065, 0.075)
const COLUMN_BOTTOM: float = 0.12
const COLUMN_TOP: float = 0.51
const CAP_HEIGHT: float = 0.025
## El brazo X (Gantry) va delante de la columna.
const ARM_Z: float = -0.045
## Cabezal quieto, estacionado junto a la columna, y la boquilla (z del
## cabezal) sobre el centro de la cama.
const HEAD_REST: Vector3 = Vector3(0.05, 0.25, 0.0)
const HEAD_PARK_X: float = -0.09
## Bandeja al frente de la base, barra LED en la columna (cc_pl3).
const TRAY_ANCHOR: Vector3 = Vector3(-0.11, 0.07, 0.185)
const BED_LIGHT: Vector3 = Vector3(-0.138, 0.33, -0.1)
## El carrete de la Rayo X1, arriba de la columna.
const SPOOL: Vector3 = Vector3(-0.165, 0.63, -0.1)
const SPOOL_RADIUS: float = 0.088
## Pantalla táctil en su brazo, al frente a la derecha: centro, medidas y giro
## (mira hacia adelante y un poco hacia arriba y la derecha).
const SCREEN: Vector3 = Vector3(0.25, 0.125, 0.2)
const SCREEN_SIZE: Vector2 = Vector2(0.085, 0.055)
const SCREEN_ROT: Vector3 = Vector3(-30.0, 20.0, 0.0)
## Caja de color de la Prisma MC: medio ancho, centro y alto de su piso;
## los 4 carretes (el de más a la derecha es "Spool", el del trabajo).
const AMS_CENTER: Vector3 = Vector3(-0.16, 0.535, -0.1)
const AMS_SIZE: Vector3 = Vector3(0.26, 0.13, 0.14)
const AMS_SPOOL_RADIUS: float = 0.048
const AMS_SPOOL_Y: float = 0.6
const AMS_PITCH: float = 0.058
## Los otros tres carretes de la caja (filamentos de config.filament_colors).
const AMS_COLORS: Array[String] = ["e0453a", "f5cf3c", "3b7fe0"]
## Montoncito de purga al pie de la rampa (4 colores).
const PURGE_COLORS: Array[String] = ["e0453a", "f5cf3c", "3b7fe0", "4cbf5a"]

# --- Rayo Mini (antes de MINI_SCALE) -------------------------------------------
const MINI_BASE_SIZE: Vector3 = Vector3(0.29, 0.055, 0.33)
const MINI_BASE_CENTER: Vector3 = Vector3(0.025, 0.0375, 0.0)
const MINI_BED_TOP: float = 0.1
const MINI_BED_CENTER: Vector2 = Vector2(0.04, 0.02)
const MINI_BED_SIZE: float = 0.2
const MINI_COLUMN: Vector2 = Vector2(-0.155, -0.085)
const MINI_COLUMN_SIZE: Vector2 = Vector2(0.055, 0.065)
const MINI_COLUMN_BOTTOM: float = 0.11
const MINI_COLUMN_TOP: float = 0.44
const MINI_ARM_Z: float = -0.04
const MINI_HEAD_REST: Vector3 = Vector3(0.04, 0.23, 0.0)
const MINI_HEAD_PARK_X: float = -0.075
const MINI_TRAY_ANCHOR: Vector3 = Vector3(-0.1, 0.065, 0.14)
const MINI_BED_LIGHT: Vector3 = Vector3(-0.155, 0.33, -0.05)
## El carrete en su soporte aparte, a la derecha de la base.
const MINI_SPOOL: Vector3 = Vector3(0.255, 0.2, -0.03)
const MINI_SPOOL_RADIUS: float = 0.085
const MINI_DISPLAY: Vector3 = Vector3(0.1, 0.0375, 0.1655)
const MINI_DISPLAY_SIZE: Vector2 = Vector2(0.065, 0.034)


static func build(printer: Node3D, kind: Kind, spool_color: String, detail: float) -> void:
	var family: String = _family(kind)
	PrinterParts.body(printer, KitMesh.cached(PrinterParts.key(family, "body", detail), _body.bind(kind, detail)))
	if kind == Kind.MINI:
		_markers(printer, MINI_BED_TOP, MINI_BED_CENTER, MINI_HEAD_REST, MINI_HEAD_PARK_X, MINI_TRAY_ANCHOR, MINI_BED_LIGHT, MINI_SCALE)
		PrinterParts.display(printer, MINI_DISPLAY_SIZE * MINI_SCALE, MINI_DISPLAY * MINI_SCALE)
	else:
		_markers(printer, BED_TOP, BED_CENTER, HEAD_REST, HEAD_PARK_X, TRAY_ANCHOR, BED_LIGHT, 1.0)
		PrinterParts.display(printer, SCREEN_SIZE, SCREEN, SCREEN_ROT)
	var rest: Vector3 = (printer.get_node("HeadRest") as Node3D).position
	var arm_z: float = MINI_ARM_Z * MINI_SCALE if kind == Kind.MINI else ARM_Z
	PrinterParts.moving(printer, "Gantry", KitMesh.cached(PrinterParts.key(family, "gantry", detail), _arm.bind(kind, detail)), detail, Vector3(0.0, rest.y, arm_z))
	var head: Node3D = PropBuilder.group(printer, "PrintHead", rest)
	PrinterParts.moving(head, "Carriage", KitMesh.cached(PrinterParts.key(family, "head", detail), _head.bind(kind, detail)), detail)
	match kind:
		Kind.MINI:
			PrinterParts.spool(printer, MINI_SPOOL * MINI_SCALE, spool_color, MINI_SPOOL_RADIUS * MINI_SCALE, detail)
		Kind.X1:
			PrinterParts.spool(printer, SPOOL, spool_color, SPOOL_RADIUS, detail)
		Kind.PRISMA:
			PrinterParts.spool(printer, _ams_spool(0), spool_color, AMS_SPOOL_RADIUS, detail)


static func _family(kind: Kind) -> String:
	match kind:
		Kind.MINI:
			return "rayo_mini"
		Kind.PRISMA:
			return "prisma_mc"
	return "rayo_x1"


static func _accent(kind: Kind) -> String:
	return LookPalette.PRINTER_PURPLE if kind == Kind.PRISMA else LookPalette.PRINTER_GREEN


static func _markers(printer: Node3D, bed_top: float, bed: Vector2, rest: Vector3, park_x: float, tray: Vector3, light: Vector3, s: float) -> void:
	PrinterParts.marker(printer, "Bed", Vector3(bed.x, bed_top, bed.y) * s)
	PrinterParts.marker(printer, "PieceAnchor", Vector3(bed.x, bed_top, bed.y) * s)
	PrinterParts.marker(printer, "HeadRest", rest * s)
	PrinterParts.marker(printer, "HeadPark", Vector3(park_x, rest.y, rest.z) * s)
	PrinterParts.marker(printer, "TrayAnchor", tray * s)
	PrinterParts.marker(printer, "BedLight", light * s)


## Centro del carrete `slot` de la caja de color (0 = el de más a la derecha).
static func _ams_spool(slot: int) -> Vector3:
	var right: float = AMS_CENTER.x + 1.5 * AMS_PITCH
	return Vector3(right - slot * AMS_PITCH, AMS_SPOOL_Y, AMS_CENTER.z)


static func _body(kind: Kind, detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	if kind == Kind.MINI:
		kit.origin = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * MINI_SCALE), Vector3.ZERO)
		_mini_body(kit)
	else:
		_x1_body(kit, kind)
	return kit.commit()


## Base, cama, columna con su barra LED y la pantalla (Rayo X1 y Prisma MC),
## y arriba el carrete (X1) o la caja de color (Prisma).
static func _x1_body(kit: KitMesh, kind: Kind) -> void:
	var white: String = LookPalette.PRINTER_WHITE
	var accent: String = _accent(kind)
	PrinterParts.feet(kit, Vector2(0.16, 0.18), Vector3(BASE_CENTER.x - 0.02, 0.0, 0.0))
	# Base y la torre de la columna (motores), blancas y redondeadas.
	kit.paint(white, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(BASE_SIZE, BASE_CENTER, 0.014)
	kit.box(Vector3(0.09, 0.11, BASE_SIZE.z), Vector3(COLUMN.x, 0.065, 0.0), 0.02)
	# Franja del color de acento al frente de la base.
	kit.paint(accent, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(BASE_SIZE.x - 0.06, 0.008, 0.003), Vector3(BASE_CENTER.x, 0.045, BASE_SIZE.z / 2.0 + 0.001), 0.0)
	_bed(kit, BED_TOP, BED_CENTER, BED_SIZE, BASE_CENTER.y + BASE_SIZE.y / 2.0)
	_column(kit, COLUMN, COLUMN_SIZE, COLUMN_BOTTOM, COLUMN_TOP, accent)
	# Barra de luz LED en la cara de la columna que da a la cama (siempre
	# encendida: alumbra la cama).
	var side: float = COLUMN.x + COLUMN_SIZE.x / 2.0
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.006, 0.3, 0.02), Vector3(side + 0.003, BED_LIGHT.y, COLUMN.y), 0.0)
	kit.glowing(LookPalette.BED_LED, 1.2)
	kit.box(Vector3(0.003, 0.28, 0.008), Vector3(side + 0.0065, BED_LIGHT.y, COLUMN.y), 0.0)
	# Brazo de la pantalla táctil (la pantalla va aparte: "Display").
	var screen_basis: Basis = Basis.from_euler(SCREEN_ROT * (PI / 180.0))
	var arm_from: Vector3 = Vector3(0.21, BASE_CENTER.y + BASE_SIZE.y / 2.0, 0.16)
	var arm_to: Vector3 = SCREEN - screen_basis.z * 0.02
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(0.012, arm_from.distance_to(arm_to), 0.012), (arm_from + arm_to) / 2.0, 0.0, _tilt_toward(arm_to - arm_from))
	kit.paint(white, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(Vector3(SCREEN_SIZE.x + 0.014, SCREEN_SIZE.y + 0.014, 0.012), SCREEN - screen_basis.z * 0.0065, 0.004, SCREEN_ROT)
	if kind == Kind.PRISMA:
		_ams(kit)
		_purge(kit)
	else:
		# Soporte del carrete arriba de la columna, su eje y las tapas.
		var cap_top: float = COLUMN_TOP + CAP_HEIGHT
		kit.paint(white, WorldPalette.Surface.SMOOTH, 0.35)
		for x: float in [SPOOL.x - 0.042, SPOOL.x + 0.042]:
			kit.box(Vector3(0.012, SPOOL.y - cap_top + 0.012, 0.03), Vector3(x, (SPOOL.y + 0.012 + cap_top) / 2.0, SPOOL.z), 0.004)
		kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
		kit.cylinder(0.006, 0.1, SPOOL, Vector3(0.0, 0.0, 90.0), 8)
		SpoolModel.add_flanges(kit, SPOOL, SPOOL_RADIUS, PrinterParts.lean(kit.detail))


## La Rayo Mini (sus medidas antes de MINI_SCALE, que pone `kit.origin`):
## base, cama chica, columna corta con una ventanita LED y el soporte del
## carrete aparte, a la derecha.
static func _mini_body(kit: KitMesh) -> void:
	var white: String = LookPalette.PRINTER_WHITE
	var accent: String = LookPalette.PRINTER_GREEN
	PrinterParts.feet(kit, Vector2(0.13, 0.14), Vector3(0.0, 0.0, 0.0))
	kit.paint(white, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(MINI_BASE_SIZE, MINI_BASE_CENTER, 0.014)
	kit.box(Vector3(0.08, 0.1, MINI_BASE_SIZE.z), Vector3(MINI_COLUMN.x, 0.06, 0.0), 0.02)
	# Marco de la pantallita (va aparte: "Display") y la franja verde.
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(MINI_DISPLAY_SIZE.x + 0.01, MINI_DISPLAY_SIZE.y + 0.008, 0.002), MINI_DISPLAY - Vector3(0.0, 0.0, 0.0018), 0.0)
	kit.paint(accent, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.1, 0.006, 0.003), Vector3(-0.03, 0.0375, MINI_BASE_SIZE.z / 2.0 + 0.001), 0.0)
	_bed(kit, MINI_BED_TOP, MINI_BED_CENTER, MINI_BED_SIZE, MINI_BASE_CENTER.y + MINI_BASE_SIZE.y / 2.0)
	_column(kit, MINI_COLUMN, MINI_COLUMN_SIZE, MINI_COLUMN_BOTTOM, MINI_COLUMN_TOP, accent)
	# Ventanita LED al frente de la columna.
	kit.glowing(LookPalette.BED_LED, 1.2)
	kit.box(Vector3(0.03, 0.012, 0.003), Vector3(MINI_COLUMN.x, MINI_BED_LIGHT.y, MINI_COLUMN.y + MINI_COLUMN_SIZE.y / 2.0 + 0.001), 0.0)
	# Soporte del carrete: un pie, dos postes, el eje y las tapas.
	var spool: Vector3 = MINI_SPOOL
	var half_gap: float = MINI_SPOOL_RADIUS * SpoolModel.WIDTH / 2.0 + 0.012
	kit.paint(white, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(Vector3(half_gap * 2.0 + 0.04, 0.012, 0.15), Vector3(spool.x, 0.006, spool.z), 0.004)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.012, spool.y, 0.028), Vector3(spool.x + side * half_gap, spool.y / 2.0 + 0.006, spool.z), 0.004)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.006, half_gap * 2.0 + 0.012, spool, Vector3(0.0, 0.0, 90.0), 8)
	SpoolModel.add_flanges(kit, spool, MINI_SPOOL_RADIUS, PrinterParts.lean(kit.detail))


## Riel, carro y cama con la lámina PEI dorada (sin perillas: se nivela sola),
## con su cara de arriba en `top` y el centro en `center` (x, z), sobre la
## base de arriba en `base_top`.
static func _bed(kit: KitMesh, top: float, center: Vector2, size: float, base_top: float) -> void:
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.5)
	kit.box(Vector3(0.035, top - 0.02 - base_top, size * 1.35), Vector3(center.x, (top - 0.02 + base_top) / 2.0, 0.0), 0.0)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(size * 0.9, 0.008, size * 0.9), Vector3(center.x, top - 0.016, center.y), 0.003)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.55)
	kit.box(Vector3(size, 0.008, size), Vector3(center.x, top - 0.008, center.y), 0.002)
	kit.paint(LookPalette.PEI_BED, WorldPalette.Surface.PEI, 0.35)
	kit.box(Vector3(size - 0.006, 0.004, size - 0.006), Vector3(center.x, top - 0.002, center.y), 0.0)


## La columna Z blanca con su ranura y la tapa de arriba, con una franja del
## acento.
static func _column(kit: KitMesh, at: Vector2, size: Vector2, bottom: float, top: float, accent: String) -> void:
	kit.paint(LookPalette.PRINTER_WHITE, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(Vector3(size.x, top - bottom, size.y), Vector3(at.x, (top + bottom) / 2.0, at.y), 0.01)
	kit.box(Vector3(size.x + 0.02, CAP_HEIGHT, size.y + 0.02), Vector3(at.x, top + CAP_HEIGHT / 2.0, at.y), 0.01)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.012, top - bottom - 0.04, 0.003), Vector3(at.x, (top + bottom) / 2.0, at.y + size.y / 2.0 + 0.001), 0.0)
	kit.paint(accent, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(size.x + 0.021, 0.006, size.y + 0.021), Vector3(at.x, top + 0.004, at.y), 0.0)


## Giro (grados) que lleva el eje Y hacia `direction` (para una barra).
static func _tilt_toward(direction: Vector3) -> Vector3:
	var turn: Quaternion = Quaternion(Vector3.UP, direction.normalized())
	return Basis(turn).get_euler() * (180.0 / PI)


## Caja de color de la Prisma MC (4 carretes a la vista bajo el marco de su
## tapa) sobre la columna, con su soporte a la izquierda y los 4 tubos que se
## juntan en un repartidor.
static func _ams(kit: KitMesh) -> void:
	var c: Vector3 = AMS_CENTER
	var half: Vector3 = AMS_SIZE / 2.0
	var white: String = LookPalette.PRINTER_WHITE
	# Soporte: un puntal desde la columna hasta el ala izquierda de la caja.
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	kit.tube(PackedVector3Array([Vector3(COLUMN.x - 0.03, COLUMN_TOP - 0.08, COLUMN.y), Vector3(c.x - half.x + 0.03, c.y - 0.004, c.z)]), 0.007, 6, 1)
	# Piso, fondo, costados y un labio bajo al frente.
	kit.paint(white, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(Vector3(AMS_SIZE.x, 0.016, AMS_SIZE.z), Vector3(c.x, c.y + 0.008, c.z), 0.0)
	kit.box(Vector3(AMS_SIZE.x, AMS_SIZE.y, 0.012), Vector3(c.x, c.y + half.y, c.z - half.z + 0.006), 0.0)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.012, AMS_SIZE.y, AMS_SIZE.z), Vector3(c.x + side * (half.x - 0.006), c.y + half.y, c.z), 0.0)
	kit.box(Vector3(AMS_SIZE.x, 0.034, 0.012), Vector3(c.x, c.y + 0.017, c.z + half.z - 0.006), 0.0)
	# Marco de la tapa (con su franja morada).
	kit.paint(LookPalette.PRINTER_PURPLE, WorldPalette.Surface.SMOOTH, 0.45)
	kit.box(Vector3(AMS_SIZE.x + 0.006, 0.012, 0.016), Vector3(c.x, c.y + AMS_SIZE.y, c.z + half.z - 0.008), 0.0)
	kit.paint(white, WorldPalette.Surface.SMOOTH, 0.35)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.016, 0.012, AMS_SIZE.z), Vector3(c.x + side * (half.x - 0.005), c.y + AMS_SIZE.y, c.z), 0.0)
	kit.box(Vector3(AMS_SIZE.x, 0.012, 0.016), Vector3(c.x, c.y + AMS_SIZE.y, c.z - half.z + 0.008), 0.0)
	# Los carretes chicos: tapas de todos (en las copias chicas, sin tapas) y
	# el bobinado fijo de los otros tres (el del trabajo es "Spool/Filament").
	for slot: int in 4:
		SpoolModel.add_small(kit, _ams_spool(slot), AMS_SPOOL_RADIUS, AMS_COLORS[slot - 1] if slot > 0 else "", not PrinterParts.lean(kit.detail))
	# Los 4 tubos que salen del frente de la caja y se juntan (en las copias
	# chicas no se verían: solo el repartidor).
	var hub: Vector3 = Vector3(c.x + half.x - 0.035, c.y - 0.012, c.z + half.z - 0.012)
	kit.paint(LookPalette.DRAWSTRINGS, WorldPalette.Surface.SMOOTH, 0.5)
	for slot: int in 0 if PrinterParts.lean(kit.detail) else 4:
		var start: Vector3 = _ams_spool(slot) + Vector3(0.0, -0.03, half.z - 0.004)
		kit.tube(PackedVector3Array([start, start + Vector3(0.0, -0.004, 0.02), hub + Vector3(-0.012, 0.004, 0.0)]), 0.0035, 6, mini(PrinterParts.curve_steps(kit.detail), 2))
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.03, 0.022, 0.022), hub, 0.004)


## Rampa de purga atrás a la derecha y el montoncito de purga de colores.
static func _purge(kit: KitMesh) -> void:
	var base_top: float = BASE_CENTER.y + BASE_SIZE.y / 2.0
	kit.printed(LookPalette.PRINTER_PURPLE, 0.004)
	kit.box(Vector3(0.05, 0.006, 0.07), Vector3(0.19, base_top + 0.04, -0.155), 0.002, Vector3(-40.0, 0.0, 0.0))
	var bits: Array[Vector3] = [Vector3(0.18, 0.0, -0.195), Vector3(0.197, 0.004, -0.19), Vector3(0.188, 0.012, -0.198), Vector3(0.205, 0.0, -0.2)]
	for i: int in bits.size():
		if PrinterParts.lean(kit.detail) and i % 2 == 1:
			continue
		var at: Vector3 = bits[i] + Vector3(0.0, base_top + 0.007, 0.0)
		kit.paint(PURGE_COLORS[i], WorldPalette.Surface.SMOOTH, 0.5)
		if PrinterParts.lean(kit.detail):
			kit.box(Vector3(0.02, 0.014, 0.018), at, 0.0, Vector3(0.0, 30.0 * i, 0.0))
		else:
			kit.blob(Vector3(0.011, 0.008, 0.01), at, Vector3(0.0, 30.0 * i, 0.0), 0.8, 0.8, Vector2.ONE, Vector2i(6, 4))


## El brazo X (sube con el cabezal): la viga, la camisa que abraza la columna
## (con la franja del acento) y la tapa del otro extremo.
static func _arm(kind: Kind, detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	var column: Vector2 = COLUMN
	var column_size: Vector2 = COLUMN_SIZE
	var arm_z: float = ARM_Z
	var right: float = 0.215
	if kind == Kind.MINI:
		kit.origin = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * MINI_SCALE), Vector3.ZERO)
		column = MINI_COLUMN
		column_size = MINI_COLUMN_SIZE
		arm_z = MINI_ARM_Z
		right = 0.17
	var left: float = column.x + column_size.x / 2.0 + 0.012
	var sleeve_z: float = column.y - arm_z
	kit.paint(LookPalette.PRINTER_WHITE, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(Vector3(right - left, 0.03, 0.03), Vector3((right + left) / 2.0, 0.0, 0.0), 0.006)
	kit.box(Vector3(column_size.x + 0.024, 0.07, column_size.y + 0.024), Vector3(column.x, 0.0, sleeve_z), 0.012)
	kit.paint(_accent(kind), WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(column_size.x + 0.025, 0.008, column_size.y + 0.025), Vector3(column.x, -0.02, sleeve_z), 0.0)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(right - left - 0.03, 0.006, 0.003), Vector3((right + left) / 2.0, 0.0, 0.0155), 0.0)
	kit.box(Vector3(0.02, 0.034, 0.034), Vector3(right, 0.0, 0.0), 0.005)
	return kit.commit()


## El cabezal, con la boquilla sobre el centro de la cama. La Rayo Mini: un
## cilindro con un aro verde que brilla; la X1 y la Prisma: una caja blanca
## redondeada con el ventilador y una franja del acento. El tubo PTFE sube
## hacia el carrete.
static func _head(kind: Kind, detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	var nozzle_z: float = BED_CENTER.y - HEAD_REST.z
	var tube_end: Vector3 = Vector3(-0.12, 0.17, -0.06)
	if kind == Kind.MINI:
		kit.origin = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * MINI_SCALE), Vector3.ZERO)
		nozzle_z = MINI_BED_CENTER.y - MINI_HEAD_REST.z
		tube_end = Vector3(0.13, 0.13, -0.03)
	elif kind == Kind.PRISMA:
		tube_end = Vector3(-0.07, 0.13, -0.04)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.06, 0.06, 0.008), Vector3(0.0, 0.006, -0.011), 0.003)
	if kind == Kind.MINI:
		kit.paint(LookPalette.PRINTER_WHITE, WorldPalette.Surface.SMOOTH, 0.4)
		kit.cylinder(0.034, 0.05, Vector3(0.0, 0.004, 0.018), Vector3(90.0, 0.0, 0.0), 16, 0.008)
		kit.glowing(LookPalette.PRINTER_GREEN, 0.8)
		kit.torus(Vector2(0.026, 0.026), 0.004, Vector3(0.0, 0.004, 0.043), Vector3(90.0, 0.0, 0.0), TAU, Vector2i(18, 6))
		kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.3)
		kit.disc(0.016, Vector3(0.0, 0.004, 0.0435), Vector3.ZERO, 12)
	else:
		kit.paint(LookPalette.PRINTER_WHITE, WorldPalette.Surface.SMOOTH, 0.4)
		kit.box(Vector3(0.06, 0.072, 0.056), Vector3(0.0, 0.006, 0.017), 0.014)
		kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.3)
		kit.cylinder(0.017, 0.003, Vector3(-0.004, 0.01, 0.0455), Vector3(90.0, 0.0, 0.0), 14)
		kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.SMOOTH, 0.4)
		kit.cylinder(0.006, 0.003, Vector3(-0.004, 0.01, 0.047), Vector3(90.0, 0.0, 0.0), 8)
		kit.paint(_accent(kind), WorldPalette.Surface.SMOOTH, 0.45)
		kit.box(Vector3(0.008, 0.05, 0.003), Vector3(0.022, 0.006, 0.0455), 0.0)
	PrinterParts.nozzle(kit, nozzle_z)
	kit.paint(LookPalette.DRAWSTRINGS, WorldPalette.Surface.SMOOTH, 0.5)
	kit.tube(PackedVector3Array([Vector3(0.0, 0.04, 0.0), Vector3(0.0, 0.08, -0.008), tube_end * Vector3(0.45, 0.85, 0.6), tube_end]), 0.0045, 6, PrinterParts.curve_steps(detail))
	return kit.commit()
