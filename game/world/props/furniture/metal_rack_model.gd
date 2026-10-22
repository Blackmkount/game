class_name MetalRackModel
extends RefCounted
## La estantería metálica (biblia de arte §10): 2,40 m de alto, cuatro
## postes negros de ángulo, cuatro tablas de madera sobre su marco de ángulo,
## cruces atrás y a los lados, tapones de goma, una regleta en el poste de
## atrás a la derecha y el atado de cables con amarras blancas. UNA malla del
## kit, frente hacia +Z, base en y = 0.
##
## Entre tabla y tabla quedan 0,74 m libres en los tres pisos: cabe cualquier
## impresora (ninguna pasa de 0,72 m con su carrete). Antes las tablas iban
## cada 0,62 m y las impresoras las atravesaban. (La biblia da las tablas en
## 0,08 / 0,85 / 1,62 / 2,37, que dejan 0,72 m en el piso de arriba: las tres
## de abajo bajan 2 cm para que los tres pisos tengan 0,74 m.)

const HEIGHT: float = 2.4
## Centro (y) de cada tabla, de abajo hacia arriba, y su grosor. Las tres de
## abajo llevan una impresora cada una (PrinterSpot0..2 sobre su cara de
## arriba); la de arriba es el techo.
const BOARDS: Array[float] = [0.06, 0.83, 1.6, 2.37]
const BOARD_THICKNESS: float = 0.03
## Medio ancho y medio fondo por fuera de los postes.
const HALF_SIZE: Vector2 = Vector2(0.62, 0.295)
## Ángulo de los postes y del marco de cada tabla: ancho del ala y grosor.
const ANGLE: float = 0.035
const ANGLE_THICKNESS: float = 0.004
## Tapones de goma bajo los postes: alto.
const FOOT: float = 0.012
## Barras de las cruces: ancho.
const BRACE_WIDTH: float = 0.022
## Regleta en el poste de atrás a la derecha: centro y medidas.
const POWER_STRIP_Y: float = 0.5
const POWER_STRIP_SIZE: Vector3 = Vector3(0.03, 0.3, 0.05)
## Carretes guardados arriba: radio.
const TOP_SPOOL_RADIUS: float = 0.1
## Amarras del atado de cables: altos.
const TIES: Array[float] = [0.95, 1.25, 1.55]


## Alto de la cara de arriba de cada tabla con impresora (donde van los
## PrinterSpot).
static func spot_heights() -> Array[float]:
	var heights: Array[float] = []
	for i: int in BOARDS.size() - 1:
		heights.append(BOARDS[i] + BOARD_THICKNESS / 2.0)
	return heights


static func mesh() -> ArrayMesh:
	var kit: KitMesh = FurnitureParts.kit()
	_posts(kit)
	_boards(kit)
	_braces(kit)
	_cables(kit)
	_stored_on_top(kit)
	return kit.commit()


## Cuatro postes de ángulo (el ala de adelante o atrás y la del costado, con
## el hueco hacia adentro) sobre tapones de goma.
static func _posts(kit: KitMesh) -> void:
	var t: float = ANGLE_THICKNESS
	var h: float = HEIGHT - FOOT
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.5)
	for sx: float in KitMesh.SIGNS:
		for sz: float in KitMesh.SIGNS:
			kit.box(Vector3(ANGLE, h, t), Vector3(sx * (HALF_SIZE.x - ANGLE / 2.0), FOOT + h / 2.0, sz * (HALF_SIZE.y - t / 2.0)), 0.0)
			kit.box(Vector3(t, h, ANGLE), Vector3(sx * (HALF_SIZE.x - t / 2.0), FOOT + h / 2.0, sz * (HALF_SIZE.y - ANGLE / 2.0)), 0.0)
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.2)
	for sx: float in KitMesh.SIGNS:
		for sz: float in KitMesh.SIGNS:
			kit.box(Vector3(ANGLE + 0.008, FOOT, ANGLE + 0.008), Vector3(sx * (HALF_SIZE.x - ANGLE / 2.0 + 0.002), FOOT / 2.0, sz * (HALF_SIZE.y - ANGLE / 2.0 + 0.002)), 0.0)


## Cada tabla de madera dentro de su marco de ángulo (cuatro alas, al ras de
## la cara de arriba de la tabla).
static func _boards(kit: KitMesh) -> void:
	var t: float = ANGLE_THICKNESS
	var inner: Vector2 = HALF_SIZE - Vector2.ONE * t * 2.0
	for y: float in BOARDS:
		var top: float = y + BOARD_THICKNESS / 2.0
		kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.25)
		kit.box(Vector3(inner.x * 2.0, BOARD_THICKNESS, inner.y * 2.0), Vector3(0.0, y, 0.0), 0.004)
		kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.5)
		for s: float in KitMesh.SIGNS:
			kit.box(Vector3((HALF_SIZE.x - t) * 2.0, ANGLE, t), Vector3(0.0, top - ANGLE / 2.0, s * (HALF_SIZE.y - t * 1.5)), 0.0)
			kit.box(Vector3(t, ANGLE, (HALF_SIZE.y - t) * 2.0), Vector3(s * (HALF_SIZE.x - t * 1.5), top - ANGLE / 2.0, 0.0), 0.0)


## Cruces de barra plana: atrás en el piso de abajo y en el de arriba, y una
## diagonal a cada lado en el del medio.
static func _braces(kit: KitMesh) -> void:
	var t: float = ANGLE_THICKNESS
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.5)
	for bay: int in [0, 2]:
		var low: float = BOARDS[bay] + BOARD_THICKNESS / 2.0 + 0.02
		var high: float = BOARDS[bay + 1] - BOARD_THICKNESS / 2.0 - 0.02
		var span: Vector2 = Vector2((HALF_SIZE.x - ANGLE) * 2.0, high - low)
		var angle: float = rad_to_deg(atan2(span.y, span.x))
		for s: float in KitMesh.SIGNS:
			kit.box(Vector3(span.length(), BRACE_WIDTH, t), Vector3(0.0, (low + high) / 2.0, -HALF_SIZE.y - t / 2.0), 0.0, Vector3(0.0, 0.0, s * angle))
	var low_side: float = BOARDS[1] + BOARD_THICKNESS / 2.0 + 0.02
	var high_side: float = BOARDS[2] - BOARD_THICKNESS / 2.0 - 0.02
	var side_span: Vector2 = Vector2((HALF_SIZE.y - ANGLE) * 2.0, high_side - low_side)
	for s: float in KitMesh.SIGNS:
		# El largo de la caja (Z) sube hacia adelante: giro negativo en X.
		kit.box(Vector3(t, BRACE_WIDTH, side_span.length()), Vector3(s * (HALF_SIZE.x + t / 2.0), (low_side + high_side) / 2.0, 0.0), 0.0, Vector3(-rad_to_deg(atan2(side_span.y, side_span.x)), 0.0, 0.0))


## Regleta blanca atornillada al costado del poste de atrás a la derecha (con
## su interruptor encendido), el atado de cables que sube por el poste con
## amarras blancas y un cable que entra a cada piso.
static func _cables(kit: KitMesh) -> void:
	var x: float = HALF_SIZE.x + POWER_STRIP_SIZE.x / 2.0
	var z: float = -HALF_SIZE.y + POWER_STRIP_SIZE.z / 2.0 + 0.004
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(POWER_STRIP_SIZE, Vector3(x, POWER_STRIP_Y, z), 0.006)
	kit.glowing(LookPalette.FILAMENT_RED, 1.2)
	kit.box(Vector3(0.006, 0.02, 0.014), Vector3(x + POWER_STRIP_SIZE.x / 2.0, POWER_STRIP_Y + POWER_STRIP_SIZE.y / 2.0 - 0.03, z), 0.0)
	kit.paint(LookPalette.METAL_DARK)
	for i: int in 3:
		kit.quad(Vector2(0.024, 0.03), Vector3(x + POWER_STRIP_SIZE.x / 2.0 + 0.001, POWER_STRIP_Y + 0.06 - i * 0.07, z), Vector3(0.0, 90.0, 0.0))
	# El atado: de la regleta hasta arriba, por fuera del poste.
	var bundle_x: float = HALF_SIZE.x + 0.012
	var bundle_z: float = -HALF_SIZE.y + 0.012
	var from: float = POWER_STRIP_Y + POWER_STRIP_SIZE.y / 2.0
	var to: float = BOARDS[BOARDS.size() - 2] + 0.12
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.cylinder(0.009, to - from, Vector3(bundle_x, (from + to) / 2.0, bundle_z), Vector3.ZERO, 8, 0.0, -1.0, false)
	for height: float in spot_heights():
		var y: float = height + 0.1
		if y < from:
			continue
		kit.tube(PackedVector3Array([Vector3(bundle_x, y, bundle_z), Vector3(bundle_x - 0.01, y - 0.03, bundle_z + 0.05), Vector3(HALF_SIZE.x - 0.07, height + 0.03, -HALF_SIZE.y + 0.1)]), 0.004, 6, 2)
	kit.paint(LookPalette.DRAWSTRINGS, WorldPalette.Surface.SMOOTH, 0.4)
	for y: float in TIES:
		kit.box(Vector3(0.03, 0.008, 0.03), Vector3(bundle_x - 0.004, y, bundle_z + 0.004), 0.0)


## Lo que se guarda arriba (se ve desde la cámara): dos cajas de filamento
## apiladas y dos carretes acostados.
static func _stored_on_top(kit: KitMesh) -> void:
	var top: float = BOARDS[BOARDS.size() - 1] + BOARD_THICKNESS / 2.0
	kit.ao_base = top
	FurnitureParts.filament_box(kit, Vector3(-0.3, top, 0.02), 6.0)
	kit.ao_base = top + FurnitureParts.FILAMENT_BOX_SIZE.y
	FurnitureParts.filament_box(kit, Vector3(-0.28, top + FurnitureParts.FILAMENT_BOX_SIZE.y, 0.0), -3.0)
	kit.ao_base = top
	var spools: Array[String] = [LookPalette.FILAMENT_GREY, LookPalette.FILAMENT_WHITE]
	SpoolModel.add_stack(kit, Vector3(0.3, top, 0.05), TOP_SPOOL_RADIUS, spools)
	kit.ao_base = 0.0
