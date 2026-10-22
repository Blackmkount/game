class_name PegboardModel
extends RefCounted
## El tablero de herramientas (biblia de arte §10): un tablero perforado con
## marco de madera, ganchos impresos naranja y las herramientas del maker
## (alicate, cortafríos, espátula, calibrador, llaves Allen y un rollo de
## cinta), una repisita impresa con el pegamento y el atomizador, y una caja
## de herramientas en el piso. UNA malla del kit, frente hacia +Z.
##
## Colgado (`on_wall`): su espalda en z = 0 (la pared) y todo hacia +Z. Sin
## pared: centrado, sobre su pie propio.

## Tablero: ancho y alto (con el marco), alto de su borde de abajo, ancho del
## marco y fondo (del marco y de la cara del tablero).
const BOARD_SIZE: Vector2 = Vector2(1.0, 0.7)
const BOARD_BOTTOM: float = 1.15
const FRAME: float = 0.03
const FRAME_DEPTH: float = 0.025
const PANEL_FRONT: float = 0.021
## Agujeros: columnas × filas y separación (m).
const HOLES: Vector2i = Vector2i(11, 7)
const HOLE_SPACING: float = 0.08
const HOLE_SIZE: float = 0.009
## Parantes del pie (sin pared) en x = ±esto.
const STAND_X: float = 0.45
## Caja de herramientas del piso: medidas.
const TOOLBOX_SIZE: Vector3 = Vector3(0.42, 0.17, 0.2)


static func mesh(on_wall: bool) -> ArrayMesh:
	var kit: KitMesh = FurnitureParts.kit()
	var back: float = 0.0 if on_wall else -FRAME_DEPTH / 2.0
	if not on_wall:
		FurnitureParts.stand(kit, STAND_X, back, BOARD_BOTTOM + BOARD_SIZE.y + 0.02)
	var toolbox: Vector3 = Vector3(-0.12, 0.0, FurnitureParts.FLOOR_WALL_GAP + TOOLBOX_SIZE.z / 2.0) if on_wall else Vector3.ZERO
	_toolbox(kit, toolbox)
	kit.origin = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, back))
	_board(kit)
	var front: float = PANEL_FRONT
	_pliers(kit, Vector3(-0.36, 1.74, front), LookPalette.FILAMENT_RED, 1.0)
	_pliers(kit, Vector3(-0.21, 1.74, front), LookPalette.FILAMENT_YELLOW, 0.75)
	_spatula(kit, Vector3(-0.06, 1.74, front))
	_caliper(kit, Vector3(0.11, 1.74, front))
	_hex_keys(kit, Vector3(0.3, 1.74, front))
	_tape(kit, Vector3(-0.3, 1.34, front))
	_little_shelf(kit, Vector3(0.18, 1.24, front))
	kit.origin = Transform3D.IDENTITY
	return kit.commit()


## Marco de madera y tablero perforado, con los agujeros oscuros.
static func _board(kit: KitMesh) -> void:
	var center_y: float = BOARD_BOTTOM + BOARD_SIZE.y / 2.0
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.SMOOTH, 0.25)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(FRAME, BOARD_SIZE.y, FRAME_DEPTH), Vector3(side * (BOARD_SIZE.x - FRAME) / 2.0, center_y, FRAME_DEPTH / 2.0), 0.004)
		kit.box(Vector3(BOARD_SIZE.x - FRAME * 2.0, FRAME, FRAME_DEPTH), Vector3(0.0, center_y + side * (BOARD_SIZE.y - FRAME) / 2.0, FRAME_DEPTH / 2.0), 0.004)
	kit.paint(LookPalette.PEGBOARD, WorldPalette.Surface.SMOOTH, 0.15)
	kit.box(Vector3(BOARD_SIZE.x - FRAME * 2.0, BOARD_SIZE.y - FRAME * 2.0, 0.006), Vector3(0.0, center_y, PANEL_FRONT - 0.003), 0.0)
	kit.paint(LookPalette.WOOD_DARK)
	for column: int in HOLES.x:
		for row: int in HOLES.y:
			var x: float = (column - (HOLES.x - 1) / 2.0) * HOLE_SPACING
			var y: float = center_y + (row - (HOLES.y - 1) / 2.0) * HOLE_SPACING
			kit.quad(Vector2.ONE * HOLE_SIZE, Vector3(x, y, PANEL_FRONT + 0.0005))


## Gancho impreso naranja que sale del tablero en `at` (en su cara).
static func _hook(kit: KitMesh, at: Vector3) -> void:
	kit.printed(LookPalette.FILAMENT_ORANGE, FurnitureParts.BRACKET_LAYER)
	kit.box(Vector3(0.012, 0.012, 0.04), at + Vector3(0.0, 0.0, 0.02), 0.0)
	kit.box(Vector3(0.012, 0.022, 0.01), at + Vector3(0.0, 0.008, 0.035), 0.0)


## Alicate (o cortafríos, más chico con `size`) colgado de su gancho: cabeza
## de metal y dos mangos de color abiertos en V.
static func _pliers(kit: KitMesh, hook: Vector3, handles: String, size: float) -> void:
	_hook(kit, hook)
	var z: float = hook.z + 0.012
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.6)
	kit.box(Vector3(0.036, 0.07, 0.012) * size, Vector3(hook.x, hook.y - 0.045 * size, z), 0.003)
	kit.paint(handles, WorldPalette.Surface.SMOOTH, 0.4)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.02, 0.15, 0.014) * size, Vector3(hook.x + side * 0.017 * size, hook.y - 0.15 * size, z), 0.005, Vector3(0.0, 0.0, side * 7.0))


## Espátula de despegar piezas: mango azul y hoja de aluminio.
static func _spatula(kit: KitMesh, hook: Vector3) -> void:
	_hook(kit, hook)
	var z: float = hook.z + 0.014
	kit.paint(LookPalette.FILAMENT_BLUE, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.03, 0.11, 0.02), Vector3(hook.x, hook.y - 0.07, z), 0.008)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.8)
	kit.box(Vector3(0.06, 0.08, 0.003), Vector3(hook.x, hook.y - 0.165, z), 0.0)


## Calibrador: regla de aluminio, las dos mandíbulas y la pantallita.
static func _caliper(kit: KitMesh, hook: Vector3) -> void:
	_hook(kit, hook)
	var z: float = hook.z + 0.008
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.8)
	kit.box(Vector3(0.022, 0.25, 0.005), Vector3(hook.x, hook.y - 0.14, z), 0.0)
	kit.box(Vector3(0.07, 0.018, 0.005), Vector3(hook.x - 0.024, hook.y - 0.03, z), 0.0)
	kit.box(Vector3(0.06, 0.016, 0.006), Vector3(hook.x - 0.02, hook.y - 0.09, z + 0.004), 0.0)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(0.036, 0.03, 0.008), Vector3(hook.x + 0.006, hook.y - 0.115, z + 0.006), 0.002)


## Llaves Allen colgadas de un soporte impreso, de la más corta a la más
## larga.
static func _hex_keys(kit: KitMesh, at: Vector3) -> void:
	kit.printed(LookPalette.FILAMENT_ORANGE, FurnitureParts.BRACKET_LAYER)
	kit.box(Vector3(0.13, 0.03, 0.035), at + Vector3(0.0, 0.0, 0.0175), 0.004)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.6)
	for i: int in 5:
		var length: float = 0.06 + i * 0.02
		kit.box(Vector3(0.007, length, 0.007), at + Vector3(-0.05 + i * 0.025, -0.015 - length / 2.0, 0.02), 0.0)


## Rollo de cinta de enmascarar en su gancho (el eje hacia afuera).
static func _tape(kit: KitMesh, hook: Vector3) -> void:
	_hook(kit, hook)
	kit.paint(LookPalette.TAPE, WorldPalette.Surface.CARDBOARD, 0.3)
	var ring: PackedVector2Array = PackedVector2Array([
		Vector2(0.026, -0.0125), Vector2(0.045, -0.0125), Vector2(0.045, -0.0125), Vector2(0.045, 0.0125),
		Vector2(0.045, 0.0125), Vector2(0.026, 0.0125), Vector2(0.026, 0.0125), Vector2(0.026, -0.0125),
	])
	kit.lathe(ring, Vector3(hook.x, hook.y - 0.045, hook.z + 0.03), Vector3(90.0, 0.0, 0.0), 12)


## Repisita impresa (con sus dos escuadras) y encima el pegamento en barra y
## el atomizador de alcohol.
static func _little_shelf(kit: KitMesh, at: Vector3) -> void:
	kit.printed(LookPalette.FILAMENT_ORANGE, FurnitureParts.BRACKET_LAYER)
	kit.box(Vector3(0.36, 0.012, 0.09), at + Vector3(0.0, 0.0, 0.045), 0.003)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.012, 0.05, 0.012), at + Vector3(side * 0.14, -0.03, 0.006), 0.0)
	var top: float = at.y + 0.006
	kit.ao_base = top
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.5)
	kit.cylinder(0.014, 0.09, Vector3(at.x - 0.1, top + 0.045, at.z + 0.045), Vector3.ZERO, 10, 0.003)
	kit.paint(LookPalette.FILAMENT_PURPLE, WorldPalette.Surface.SMOOTH, 0.5)
	kit.cylinder(0.015, 0.03, Vector3(at.x - 0.1, top + 0.1, at.z + 0.045), Vector3.ZERO, 10, 0.003)
	kit.paint(LookPalette.PAINT_BUCKET, WorldPalette.Surface.SMOOTH, 0.5)
	kit.cylinder(0.026, 0.15, Vector3(at.x + 0.06, top + 0.075, at.z + 0.045), Vector3.ZERO, 12, 0.006)
	kit.paint(LookPalette.PAINT_BUCKET_STRIPE, WorldPalette.Surface.SMOOTH, 0.5)
	kit.cylinder(0.0265, 0.03, Vector3(at.x + 0.06, top + 0.09, at.z + 0.045), Vector3.ZERO, 12)
	kit.cylinder(0.012, 0.03, Vector3(at.x + 0.06, top + 0.165, at.z + 0.045), Vector3.ZERO, 8)
	kit.ao_base = 0.0


## Caja de herramientas metálica en el piso, con la base en `base`: tapa con
## su borde oscuro, manija de aluminio y dos cierres de latón.
static func _toolbox(kit: KitMesh, base: Vector3) -> void:
	var size: Vector3 = TOOLBOX_SIZE
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	kit.box(size, base + Vector3(0.0, size.y / 2.0, 0.0), 0.01)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(size.x + 0.004, 0.018, size.z + 0.004), base + Vector3(0.0, size.y - 0.04, 0.0), 0.0)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.8)
	kit.box(Vector3(0.16, 0.018, 0.022), base + Vector3(0.0, size.y + 0.03, 0.0), 0.006)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.016, 0.03, 0.016), base + Vector3(side * 0.07, size.y + 0.012, 0.0), 0.0)
	kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.85)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.03, 0.04, 0.01), base + Vector3(side * 0.12, size.y - 0.04, size.z / 2.0 + 0.004), 0.003)
