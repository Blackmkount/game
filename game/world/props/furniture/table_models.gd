class_name TableModels
extends RefCounted
## Las dos mesas para impresoras (biblia de arte §10), cada una UNA malla del
## kit con el frente hacia +Z y la base en y = 0:
## - mesa_auxiliar: mesita blanca de melamina con el canto de madera a la
##   vista, patas cuadradas y una repisa abajo (un tarro impreso y un
##   atomizador de alcohol).
## - mesa_trabajo: banco de madera clara con una cajonera metálica colgada
##   del tablero y una repisa baja con cajas organizadoras.

## Mesita: ancho, alto (donde se apoya la impresora) y fondo.
const SIDE_TABLE_SIZE: Vector3 = Vector3(0.6, 0.5, 0.55)
const SIDE_TABLE_TOP: float = 0.028
const SIDE_TABLE_LEG: float = 0.045
const SIDE_TABLE_SHELF_Y: float = 0.13
## Banco: ancho, alto y fondo; grosor del tablero, patas y la repisa baja.
const WORK_TABLE_SIZE: Vector3 = Vector3(1.3, 0.8, 0.6)
const WORK_TABLE_TOP: float = 0.045
const WORK_TABLE_LEG: float = 0.06
const WORK_TABLE_SHELF_Y: float = 0.15
## Faldones bajo el tablero: alto.
const APRON_HEIGHT: float = 0.06
## Cajonera metálica bajo el tablero: centro en x, ancho, alto y fondo, y
## sus tres cajones.
const DRAWERS_X: float = 0.36
const DRAWERS_SIZE: Vector3 = Vector3(0.4, 0.42, 0.5)
const DRAWER_COUNT: int = 3
## Grosor de las paredes de las cajas organizadoras.
const BIN_WALL: float = 0.008
## Dónde van las impresoras (biblia §10: arriba del tablero).
const SIDE_TABLE_SPOTS: Array[Vector3] = [Vector3(0.0, 0.5, 0.0)]
const WORK_TABLE_SPOTS: Array[Vector3] = [Vector3(-0.3, 0.8, 0.0), Vector3(0.3, 0.8, 0.0)]


static func side_table() -> ArrayMesh:
	var kit: KitMesh = FurnitureParts.kit()
	var size: Vector3 = SIDE_TABLE_SIZE
	# Tablero: el canto de madera y encima la lámina blanca (un poco más
	# chica: el canto se ve como un filo alrededor).
	kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(size.x, SIDE_TABLE_TOP - 0.003, size.z), Vector3(0.0, size.y - SIDE_TABLE_TOP / 2.0 - 0.0015, 0.0), 0.006)
	kit.paint(LookPalette.MELAMINE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(size.x - 0.008, 0.004, size.z - 0.008), Vector3(0.0, size.y - 0.002, 0.0), 0.0)
	var under: float = size.y - SIDE_TABLE_TOP
	var inset: Vector2 = Vector2(size.x, size.z) / 2.0 - Vector2.ONE * (SIDE_TABLE_LEG / 2.0 + 0.012)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			kit.box(Vector3(SIDE_TABLE_LEG, under, SIDE_TABLE_LEG), Vector3(x * inset.x, under / 2.0, z * inset.y), 0.006)
	# Repisa de abajo, entre las patas, con su canto.
	kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(inset.x * 2.0, 0.018, inset.y * 2.0), Vector3(0.0, SIDE_TABLE_SHELF_Y, 0.0), 0.003)
	kit.paint(LookPalette.MELAMINE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(inset.x * 2.0 - 0.008, 0.004, inset.y * 2.0 - 0.008), Vector3(0.0, SIDE_TABLE_SHELF_Y + 0.009, 0.0), 0.0)
	# Sobre la repisa: un tarro impreso y el atomizador de alcohol.
	var shelf: float = SIDE_TABLE_SHELF_Y + 0.011
	kit.ao_base = shelf
	kit.printed(LookPalette.RUG_PATTERN[0], 0.004)
	kit.box(Vector3(0.16, 0.09, 0.12), Vector3(-0.09, shelf + 0.045, -0.04), 0.008, Vector3(0.0, 8.0, 0.0))
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.5)
	kit.cylinder(0.028, 0.15, Vector3(0.13, shelf + 0.075, 0.05), Vector3.ZERO, 12, 0.006)
	kit.paint(LookPalette.FILAMENT_BLUE, WorldPalette.Surface.SMOOTH, 0.4)
	kit.cylinder(0.016, 0.035, Vector3(0.13, shelf + 0.167, 0.05), Vector3.ZERO, 8, 0.003)
	kit.box(Vector3(0.012, 0.012, 0.03), Vector3(0.13, shelf + 0.175, 0.07), 0.0)
	return kit.commit()


static func work_table() -> ArrayMesh:
	var kit: KitMesh = FurnitureParts.kit()
	var size: Vector3 = WORK_TABLE_SIZE
	var under: float = size.y - WORK_TABLE_TOP
	kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.28)
	kit.box(Vector3(size.x, WORK_TABLE_TOP, size.z), Vector3(0.0, size.y - WORK_TABLE_TOP / 2.0, 0.0), 0.012)
	# Patas y faldones (lisos: la veta de las tablas no va en lo vertical).
	var leg: Vector2 = Vector2(size.x / 2.0 - 0.05, size.z / 2.0 - 0.05)
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.SMOOTH, 0.25)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			kit.box(Vector3(WORK_TABLE_LEG, under, WORK_TABLE_LEG), Vector3(x * leg.x, under / 2.0, z * leg.y), 0.008)
	for z: float in KitMesh.SIGNS:
		kit.box(Vector3(leg.x * 2.0 - WORK_TABLE_LEG, APRON_HEIGHT, 0.02), Vector3(0.0, under - APRON_HEIGHT / 2.0, z * leg.y), 0.004)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.02, APRON_HEIGHT, leg.y * 2.0 - WORK_TABLE_LEG), Vector3(x * leg.x, under - APRON_HEIGHT / 2.0, 0.0), 0.004)
	# Repisa baja de tablas.
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.22)
	kit.box(Vector3(leg.x * 2.0 + WORK_TABLE_LEG, 0.024, leg.y * 2.0 - WORK_TABLE_LEG + 0.01), Vector3(0.0, WORK_TABLE_SHELF_Y, 0.0), 0.005)
	_drawers(kit, under - APRON_HEIGHT)
	_bins(kit)
	return kit.commit()


## Cajonera metálica colgada bajo los faldones (a la derecha): cuerpo oscuro,
## tres cajones con tirador de aluminio y una etiqueta blanca cada uno. Su
## techo queda en `top`.
static func _drawers(kit: KitMesh, top: float) -> void:
	var size: Vector3 = DRAWERS_SIZE
	var bottom: float = top - size.y
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(size, Vector3(DRAWERS_X, bottom + size.y / 2.0, -0.02), 0.008)
	var front: float = size.z / 2.0 - 0.02
	var gap: float = 0.014
	var height: float = (size.y - gap * (DRAWER_COUNT + 1)) / DRAWER_COUNT
	for i: int in DRAWER_COUNT:
		var y: float = bottom + gap + height / 2.0 + i * (height + gap)
		kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
		kit.box(Vector3(size.x - 0.03, height, 0.014), Vector3(DRAWERS_X, y, front + 0.007), 0.004)
		kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.8)
		kit.box(Vector3(0.12, 0.016, 0.018), Vector3(DRAWERS_X, y + height * 0.18, front + 0.022), 0.004)
		kit.paint(LookPalette.SHEET)
		kit.quad(Vector2(0.07, 0.03), Vector3(DRAWERS_X, y - height * 0.2, front + 0.0145))


## Cajas organizadoras sobre la repisa baja (a la izquierda), de los colores
## del tapete: abiertas arriba, con su asa calada al frente.
static func _bins(kit: KitMesh) -> void:
	var shelf: float = WORK_TABLE_SHELF_Y + 0.012
	kit.ao_base = shelf
	var colors: Array[String] = [LookPalette.RUG_PATTERN[0], LookPalette.RUG_PATTERN[3], LookPalette.RUG_PATTERN[2]]
	var size: Vector3 = Vector3(0.2, 0.13, 0.32)
	for i: int in colors.size():
		var x: float = -0.5 + i * 0.22
		kit.paint(colors[i], WorldPalette.Surface.SMOOTH, 0.35)
		FurnitureParts.open_bin(kit, Vector3(x, shelf, 0.0), size, BIN_WALL)
		kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.1)
		kit.quad(Vector2(0.07, 0.02), Vector3(x, shelf + size.y - 0.03, size.z / 2.0 + 0.001))
	kit.ao_base = 0.0
