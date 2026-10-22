class_name DispatchCornerModel
extends RefCounted
## Rincón de despacho junto a la puerta (biblia de arte §10): una mesita para
## embalar (dispensador de cinta, cúter, etiquetas y un marcador encima;
## cartones planos y un rollo de plástico de burbujas en la repisa de abajo) y
## un guacal de madera (cajón de listones) con relleno de papel triturado,
## donde esperan los paquetes listos. El frente mira hacia +Z y la base queda
## en y = 0. Todo lo fijo es UNA malla del kit ("Body").
##
## El guacal queda detrás de la mesa para la cámara, así que es casi tan alto
## como ella: los paquetes se apilan por encima de la tabla y se ven enteros.
##
## Las marcas "PackSpot0..2" (sobre la mesa) y "OutSpot0..2" (apiladas sobre el
## guacal, un poco giradas, como apiladas a mano) dicen dónde van las cajas
## abiertas y los paquetes (DispatchView). La caja que se toca no cambia: x
## −0,435…0,45, z −0,2…0,2, contando los paquetes escondidos (la prueba lo
## fija).

const PACK_SPOTS: int = 3
const OUT_SPOTS: int = 3
## Alto del guacal de salida (la mesa mide TABLE_TOP).
const CRATE_HEIGHT: float = 0.42
## Alto de un paquete (PackageModel.package): uno encima del otro.
const PACKAGE_HEIGHT: float = 0.14
## Giro de cada paquete apilado (grados).
const OUT_SPOT_YAW: Array[float] = [0.0, 6.0, -5.0]
## La mesa de embalar: centro en x, ancho (x) y fondo (z), y el alto de su
## tabla.
const TABLE_X: float = 0.2
const TABLE_SIZE: Vector2 = Vector2(0.5, 0.4)
const TABLE_TOP: float = 0.5
const TABLE_THICKNESS: float = 0.035
## El guacal: centro en x, ancho (x) y fondo (z); sus listones (alto,
## separación y grosor) y los esquineros.
const CRATE_X: float = -0.25
const CRATE_SIZE: Vector2 = Vector2(0.37, 0.34)
const SLAT_HEIGHT: float = 0.06
const SLAT_STEP: float = 0.1
const SLAT_THICKNESS: float = 0.012
const CRATE_POST: float = 0.03
## Tiras de papel triturado que asoman del relleno.
const PAPER_STRIPS: int = 10
const PAPER_SEED: int = 5


static func build(parent: Node3D, node_name: String) -> Node3D:
	var corner: Node3D = PropBuilder.group(parent, node_name)
	PropBuilder.kit(corner, "Body", KitMesh.cached("dispatch_corner", _body))
	# Las cajas abiertas se apoyan en la mesa; los paquetes se apilan con su
	# centro en cada marca.
	for i: int in PACK_SPOTS:
		_marker(corner, "PackSpot%d" % i, Vector3(0.03 + i * 0.17, TABLE_TOP, 0.02))
	for i: int in OUT_SPOTS:
		var spot: Marker3D = _marker(corner, "OutSpot%d" % i, Vector3(CRATE_X, CRATE_HEIGHT + PACKAGE_HEIGHT * (i + 0.5), 0.0))
		spot.rotation_degrees = Vector3(0.0, OUT_SPOT_YAW[i], 0.0)
	return corner


static func _body() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	_table(kit)
	_crate(kit)
	return kit.commit()


## La mesita: tabla, patas, repisa con cartones planos y el rollo de plástico
## de burbujas; encima, el dispensador de cinta, las etiquetas, un marcador y
## el cúter (fuera de los lugares de las cajas abiertas).
static func _table(kit: KitMesh) -> void:
	var half: Vector2 = TABLE_SIZE / 2.0
	var legs: float = TABLE_TOP - TABLE_THICKNESS
	kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.3)
	kit.box(Vector3(TABLE_SIZE.x, TABLE_THICKNESS, TABLE_SIZE.y), Vector3(TABLE_X, TABLE_TOP - TABLE_THICKNESS / 2.0, 0.0), 0.01)
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.25)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			kit.box(Vector3(0.035, legs, 0.035), Vector3(TABLE_X + (half.x - 0.03) * x, legs / 2.0, (half.y - 0.03) * z), 0.006)
	kit.box(Vector3(TABLE_SIZE.x - 0.04, 0.02, TABLE_SIZE.y - 0.04), Vector3(TABLE_X, 0.12, 0.0), 0.004)
	# Cartones planos (tres, algo corridos) y el rollo de burbujas encima.
	for k: int in 3:
		kit.paint(LookPalette.CARDBOARD if k % 2 == 0 else LookPalette.CARDBOARD_DARK, WorldPalette.Surface.CARDBOARD, 0.05)
		kit.box(Vector3(0.4, 0.012, 0.3), Vector3(TABLE_X + (k - 1) * 0.008, 0.136 + k * 0.013, (k - 1) * 0.01), 0.0, Vector3(0.0, (k - 1) * 3.0, 0.0))
	var roll: Vector3 = Vector3(TABLE_X, 0.235, -0.06)
	kit.paint(LookPalette.PILLOW, WorldPalette.Surface.SMOOTH, 0.85)
	kit.cylinder(0.06, 0.28, roll, Vector3(0.0, 0.0, 90.0), 14, 0.008)
	kit.paint(LookPalette.CARDBOARD_DARK, WorldPalette.Surface.CARDBOARD, 0.05)
	kit.cylinder(0.022, 0.29, roll, Vector3(0.0, 0.0, 90.0), 8)
	# Encima de la tabla: contacto oscuro a su altura.
	kit.ao_base = TABLE_TOP
	var dispenser: Vector3 = Vector3(0.37, TABLE_TOP, -0.14)
	kit.paint(LookPalette.RUG_PATTERN[0], WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(0.12, 0.03, 0.06), dispenser + Vector3(0.0, 0.015, 0.0), 0.008)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.6)
	kit.box(Vector3(0.012, 0.018, 0.05), dispenser + Vector3(0.055, 0.036, 0.0), 0.002)
	kit.paint(LookPalette.TAPE, WorldPalette.Surface.SMOOTH, 0.6)
	kit.cylinder(0.034, 0.045, dispenser + Vector3(-0.01, 0.062, 0.0), Vector3(90.0, 0.0, 0.0), 14, 0.004)
	kit.paint(LookPalette.CARDBOARD_DARK, WorldPalette.Surface.CARDBOARD, 0.05)
	kit.cylinder(0.02, 0.047, dispenser + Vector3(-0.01, 0.062, 0.0), Vector3(90.0, 0.0, 0.0), 10)
	var labels: Vector3 = Vector3(0.06, TABLE_TOP, -0.15)
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.2)
	kit.box(Vector3(0.09, 0.012, 0.06), labels + Vector3(0.0, 0.006, 0.0), 0.002, Vector3(0.0, -8.0, 0.0))
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(-8.0)), labels + Vector3(0.0, 0.0125, 0.0))
	kit.paint(LookPalette.RUG_PATTERN[2])
	kit.box(Vector3(0.022, 0.001, 0.022), Vector3(-0.025, 0.0, 0.0), 0.0)
	kit.paint(LookPalette.METAL_MID)
	kit.box(Vector3(0.035, 0.001, 0.004), Vector3(0.016, 0.0, -0.007), 0.0)
	kit.box(Vector3(0.025, 0.001, 0.004), Vector3(0.011, 0.0, 0.006), 0.0)
	kit.origin = Transform3D.IDENTITY
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.5)
	kit.cylinder(0.008, 0.12, Vector3(0.17, TABLE_TOP + 0.008, -0.15), Vector3(0.0, 10.0, 90.0), 8)
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(25.0)), Vector3(0.33, TABLE_TOP, 0.155))
	kit.paint(LookPalette.KNOBS, WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(0.11, 0.016, 0.026), Vector3(0.0, 0.008, 0.0), 0.005)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.8)
	kit.box(Vector3(0.03, 0.005, 0.012), Vector3(0.068, 0.006, 0.0), 0.0)
	kit.origin = Transform3D.IDENTITY
	kit.ao_base = 0.0


## El guacal: esquineros, cuatro filas de listones con espacios, el fondo y
## el relleno de papel triturado con algunas tiras que asoman.
static func _crate(kit: KitMesh) -> void:
	var half: Vector2 = CRATE_SIZE / 2.0
	var inset: float = SLAT_THICKNESS + CRATE_POST / 2.0
	kit.paint(LookPalette.CRATE_DARK, WorldPalette.Surface.WOOD, 0.2)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			kit.box(Vector3(CRATE_POST, CRATE_HEIGHT, CRATE_POST), Vector3(CRATE_X + (half.x - inset) * x, CRATE_HEIGHT / 2.0, (half.y - inset) * z), 0.0)
	kit.box(Vector3(CRATE_SIZE.x - 0.02, 0.012, CRATE_SIZE.y - 0.02), Vector3(CRATE_X, 0.03, 0.0), 0.0)
	for row: int in 4:
		var y: float = 0.035 + SLAT_HEIGHT / 2.0 + row * SLAT_STEP
		# El de adelante se ve: con bisel (atrapa la luz). Los demás, simples.
		kit.paint(LookPalette.CRATE, WorldPalette.Surface.WOOD, 0.22)
		kit.box(Vector3(CRATE_SIZE.x, SLAT_HEIGHT, SLAT_THICKNESS), Vector3(CRATE_X, y, half.y - SLAT_THICKNESS / 2.0), 0.003)
		kit.box(Vector3(CRATE_SIZE.x, SLAT_HEIGHT, SLAT_THICKNESS), Vector3(CRATE_X, y, -half.y + SLAT_THICKNESS / 2.0), 0.0)
		for x: float in KitMesh.SIGNS:
			kit.box(Vector3(SLAT_THICKNESS, SLAT_HEIGHT, CRATE_SIZE.y - SLAT_THICKNESS * 2.0), Vector3(CRATE_X + (half.x - SLAT_THICKNESS / 2.0) * x, y, 0.0), 0.0)
	kit.ao_base = CRATE_HEIGHT - 0.06
	kit.paint(LookPalette.RUG_BASE, WorldPalette.Surface.FABRIC, 0.05)
	kit.blob(Vector3(half.x - 0.025, 0.035, half.y - 0.025), Vector3(CRATE_X, CRATE_HEIGHT - 0.035, 0.0), Vector3.ZERO, 0.5, 0.7, Vector2.ONE, Vector2i(10, 5))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = PAPER_SEED
	var colors: Array[String] = [LookPalette.SHEET, LookPalette.TAPE, LookPalette.RUG_BASE]
	for i: int in PAPER_STRIPS:
		kit.paint(colors[i % colors.size()], WorldPalette.Surface.SMOOTH, 0.1)
		var at: Vector3 = Vector3(CRATE_X + rng.randf_range(-0.13, 0.13), CRATE_HEIGHT - 0.004, rng.randf_range(-0.12, 0.12))
		kit.box(Vector3(0.05, 0.003, 0.009), at, 0.0, Vector3(rng.randf_range(-35.0, 35.0), rng.randf_range(0.0, 180.0), rng.randf_range(-25.0, 25.0)))
	kit.ao_base = 0.0


static func _marker(parent: Node3D, node_name: String, position: Vector3) -> Marker3D:
	var marker: Marker3D = Marker3D.new()
	marker.name = node_name
	marker.position = position
	parent.add_child(marker)
	return marker
