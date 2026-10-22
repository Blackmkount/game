class_name FilamentStorageModels
extends RefCounted
## Los muebles que guardan filamento (biblia de arte §10), cada uno UNA malla
## del kit con el frente hacia +Z y la base en y = 0. Los carretes van dentro
## de la malla (no cambian de color), con el eje paralelo a la pared: siempre
## se ve la banda de color (§9.4).
## - repisa_filamento: dos tablas con 6 carretes (6 kg), escuadras impresas
##   naranjas y dos cajas de filamento en el piso. Colgada (`on_wall`): su
##   espalda en z = 0 (la pared) y todo hacia +Z. Sin pared: centrada, sobre
##   su pie propio.
## - estanteria_cubos: mueble blanco de dos columnas de cubos (0,80 × 1,50 ×
##   0,40 m) con 4 pilas de 3 carretes (12 kg), una caja de filamento, dos
##   tarros impresos y un florero impreso. Su espalda en z = 0.

## Repisa: ancho, grosor y fondo de cada tabla, y la altura de su cara de
## arriba.
const SHELF_BOARD: Vector3 = Vector3(1.1, 0.03, 0.24)
const SHELF_TOPS: Array[float] = [1.13, 1.53]
## Escuadras (y parantes del pie) en x = ±esto; alto del pie (más que los
## carretes de arriba).
const SHELF_BRACKET_X: float = 0.45
const SHELF_STAND_HEIGHT: float = 1.78
## Carretes de la repisa: radio, dónde va cada uno en x y sus colores (los
## de abajo primero).
const SHELF_SPOOL_RADIUS: float = 0.1
const SHELF_SPOOL_X: Array[float] = [-0.34, -0.02, 0.3]
const SHELF_SPOOL_COLORS: Array[String] = [
	LookPalette.FILAMENT_RED, LookPalette.FILAMENT_YELLOW, LookPalette.FILAMENT_BLUE,
	LookPalette.FILAMENT_GREEN, LookPalette.FILAMENT_PURPLE, LookPalette.FILAMENT_ORANGE,
]
## Mueble de cubos: medidas, grosor de los tableros y columnas × filas.
const CUBES_SIZE: Vector3 = Vector3(0.8, 1.5, 0.4)
const CUBES_PANEL: float = 0.025
const CUBES_DIVIDER: float = 0.02
const CUBES_GRID: Vector2i = Vector2i(2, 4)
## Lo que va en cada hueco queda corrido esto (m) desde su centro: hacia
## adelante y un poco a la izquierda, para que el costado del mueble no lo
## tape con la cámara del juego (que mira desde adelante a la derecha).
const CUBES_CONTENT_SHIFT: Vector2 = Vector2(-0.03, 0.04)
## Pilas de carretes del mueble de cubos: radio, en qué hueco (columna,
## fila desde abajo) y sus colores de abajo hacia arriba.
const CUBES_SPOOL_RADIUS: float = 0.1
const CUBES_STACKS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 3)]
const CUBES_STACK_COLORS: Array[Array] = [
	[LookPalette.FILAMENT_BLACK, LookPalette.FILAMENT_GREY, LookPalette.FILAMENT_WHITE],
	[LookPalette.FILAMENT_RED, LookPalette.FILAMENT_ORANGE, LookPalette.FILAMENT_YELLOW],
	[LookPalette.FILAMENT_GREEN, LookPalette.FILAMENT_BLUE, LookPalette.FILAMENT_PURPLE],
	[LookPalette.FILAMENT_WHITE, LookPalette.FILAMENT_BLUE, LookPalette.FILAMENT_RED],
]


static func filament_shelf(on_wall: bool) -> ArrayMesh:
	var kit: KitMesh = FurnitureParts.kit()
	var depth: float = SHELF_BOARD.z
	# La espalda de las tablas: la pared, o delante de los parantes del pie.
	var back: float = 0.0 if on_wall else -depth / 2.0
	if not on_wall:
		FurnitureParts.stand(kit, SHELF_BRACKET_X, back, SHELF_STAND_HEIGHT)
	# Dos cajas de filamento en el piso, una sobre otra.
	var boxes_z: float = (FurnitureParts.FLOOR_WALL_GAP if on_wall else back + 0.01) + FurnitureParts.FILAMENT_BOX_SIZE.z / 2.0
	FurnitureParts.filament_box(kit, Vector3(0.18, 0.0, boxes_z), -4.0)
	kit.ao_base = FurnitureParts.FILAMENT_BOX_SIZE.y
	FurnitureParts.filament_box(kit, Vector3(0.2, FurnitureParts.FILAMENT_BOX_SIZE.y, boxes_z), 5.0)
	kit.ao_base = 0.0
	for level: int in SHELF_TOPS.size():
		var top: float = SHELF_TOPS[level]
		kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.25)
		kit.box(SHELF_BOARD, Vector3(0.0, top - SHELF_BOARD.y / 2.0, back + depth / 2.0), 0.008)
		for side: float in KitMesh.SIGNS:
			FurnitureParts.bracket(kit, side * SHELF_BRACKET_X, top - SHELF_BOARD.y, back, depth)
		kit.ao_base = top
		for i: int in SHELF_SPOOL_X.size():
			var center: Vector3 = Vector3(SHELF_SPOOL_X[i], top + SHELF_SPOOL_RADIUS, back + depth / 2.0)
			SpoolModel.add_on_shelf(kit, center, SHELF_SPOOL_RADIUS, SHELF_SPOOL_COLORS[level * SHELF_SPOOL_X.size() + i])
		kit.ao_base = 0.0
	return kit.commit()


static func cube_shelf() -> ArrayMesh:
	var kit: KitMesh = FurnitureParts.kit()
	var size: Vector3 = CUBES_SIZE
	var p: float = CUBES_PANEL
	var z: float = size.z / 2.0
	kit.paint(LookPalette.MELAMINE, WorldPalette.Surface.SMOOTH, 0.3)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(p, size.y, size.z), Vector3(side * (size.x - p) / 2.0, size.y / 2.0, z), 0.006)
	for y: float in [p / 2.0, size.y - p / 2.0]:
		kit.box(Vector3(size.x - p * 2.0, p, size.z), Vector3(0.0, y, z), 0.004)
	var cell: Vector2 = cell_size()
	kit.box(Vector3(CUBES_DIVIDER, size.y - p * 2.0, size.z - 0.01), Vector3(0.0, size.y / 2.0, z + 0.005), 0.0)
	for row: int in range(1, CUBES_GRID.y):
		kit.box(Vector3(size.x - p * 2.0, CUBES_DIVIDER, size.z - 0.01), Vector3(0.0, p + row * (cell.y + CUBES_DIVIDER) - CUBES_DIVIDER / 2.0, z + 0.005), 0.0)
	# El fondo de los huecos, más oscuro (hace de sombra adentro).
	kit.paint(LookPalette.MELAMINE_SHADE, WorldPalette.Surface.SMOOTH, 0.1)
	kit.box(Vector3(size.x - p * 2.0, size.y - p * 2.0, 0.006), Vector3(0.0, size.y / 2.0, 0.003), 0.0)
	for i: int in CUBES_STACKS.size():
		var colors: Array[String] = []
		colors.assign(CUBES_STACK_COLORS[i])
		var base: Vector3 = cell_floor(CUBES_STACKS[i])
		kit.ao_base = base.y
		SpoolModel.add_stack(kit, base, CUBES_SPOOL_RADIUS, colors)
	_cube_extras(kit)
	kit.ao_base = 0.0
	return kit.commit()


## Ancho y alto por dentro de cada hueco del mueble de cubos.
static func cell_size() -> Vector2:
	var inner: Vector2 = Vector2(CUBES_SIZE.x, CUBES_SIZE.y) - Vector2.ONE * CUBES_PANEL * 2.0
	return Vector2((inner.x - CUBES_DIVIDER * (CUBES_GRID.x - 1)) / CUBES_GRID.x, (inner.y - CUBES_DIVIDER * (CUBES_GRID.y - 1)) / CUBES_GRID.y)


## Dónde se apoya lo que va en un hueco (columna, fila desde abajo) del
## mueble de cubos: su piso, corrido CUBES_CONTENT_SHIFT del centro.
static func cell_floor(cell_index: Vector2i) -> Vector3:
	var cell: Vector2 = cell_size()
	var x: float = -CUBES_SIZE.x / 2.0 + CUBES_PANEL + cell.x / 2.0 + cell_index.x * (cell.x + CUBES_DIVIDER)
	var y: float = CUBES_PANEL + cell_index.y * (cell.y + CUBES_DIVIDER)
	return Vector3(x + CUBES_CONTENT_SHIFT.x, y, CUBES_SIZE.z / 2.0 + CUBES_CONTENT_SHIFT.y)


## Lo demás de los huecos libres: la caja de filamento, dos tarros impresos
## (abiertos: se ve el fondo oscuro) y un florero impreso en espiral.
static func _cube_extras(kit: KitMesh) -> void:
	var box_floor: Vector3 = cell_floor(Vector2i(1, 0))
	kit.ao_base = box_floor.y
	FurnitureParts.filament_box(kit, box_floor, 3.0)
	var bins: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 3)]
	var bin_colors: Array[String] = [LookPalette.RUG_PATTERN[0], LookPalette.RUG_PATTERN[3]]
	var bin_size: Vector3 = Vector3(0.24, 0.16, 0.3)
	for i: int in bins.size():
		var at: Vector3 = cell_floor(bins[i])
		kit.ao_base = at.y
		kit.printed(bin_colors[i], 0.004)
		kit.box(bin_size, at + Vector3(0.0, bin_size.y / 2.0, 0.0), 0.01)
		kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.1)
		kit.quad(Vector2(bin_size.x - 0.03, bin_size.z - 0.03), at + Vector3(0.0, bin_size.y + 0.001, 0.0), Vector3(-90.0, 0.0, 0.0))
	var vase: Vector3 = cell_floor(Vector2i(1, 2))
	kit.ao_base = vase.y
	kit.printed(LookPalette.FILAMENT_PURPLE, 0.003)
	kit.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.07, 0.07), Vector2(0.045, 0.17), Vector2(0.055, 0.22), Vector2(0.0, 0.22)]), vase + Vector3(-0.04, 0.0, 0.0), Vector3.ZERO, 12)
