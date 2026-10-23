class_name DecorItems
extends RefCounted
## Lo que adorna el piso del cuarto (biblia de arte §8.8): la cama con la
## cobija de tigre, el puf con el control y las zapatillas, el librero del
## rincón, la costilla de Adán, el basurero de impresiones fallidas y las
## cajas de filamento; y lo plano (el tapete andino, el felpudo, el cable del
## escritorio y un barquito fallido). Cada cosa se agrega a un KitMesh en
## coordenadas del cuarto; RoomDecor las une en pocas mallas.
##
## Medidas en metros. La pared de la ventana es x = −3 (mira a +X) y la del
## fondo z = −3 (mira a +Z); los lados +X y +Z están abiertos, del lado de la
## cámara. Lo que la cámara no ve (el lado −X de la cama, los fondos) no se
## arma.

## Cama de una plaza contra el borde +X, con la cabecera hacia el fondo:
## rincón (x, z) y medidas (ancho en x, largo en z). La cabecera queda a
## 0,76 m del frente del lugar 4: así no tapa (desde la cámara) la impresora
## de abajo de una estantería en ese lugar y entre las dos pasa el personaje
## (≥ 0,5 m, ver test_room_decor).
const BED_CORNER: Vector2 = Vector2(1.95, -1.5)
const BED_SIZE: Vector2 = Vector2(0.95, 2.0)
## Alto de las patas, de la cama (arriba del marco), del colchón y de la
## cabecera (biblia: 0,45 y 0,75), y la repisa de arriba de la cabecera.
const BED_LEGS: float = 0.1
const BED_FRAME_TOP: float = 0.28
const BED_MATTRESS_TOP: float = 0.44
const BED_HEADBOARD: float = 0.75
const BED_LEDGE: Vector2 = Vector2(0.03, 0.16)
## La cobija tapa el 60 % de la cama, desde los pies.
const BLANKET_COVER: float = 0.6
## Foco de la lámpara de la cama (biblia §6.2, cc_pl2): sobre la repisa de
## la cabecera. Al lado, el celular (su base).
const BED_LAMP_BULB: Vector3 = Vector3(2.45, 0.85, -1.45)
const PHONE_AT: Vector3 = Vector3(2.155, 0.78, -1.44)
## Puf con un control de videojuegos encima, y las zapatillas sueltas al lado.
const POUF_CENTER: Vector2 = Vector2(2.5, 1.0)
const POUF_HALF: Vector3 = Vector3(0.31, 0.215, 0.31)
## Librero alto del rincón del fondo (zona F1): centro de la base, ancho (x),
## alto y fondo (z).
const BOOKCASE_BASE: Vector3 = Vector3(-2.7, 0.0, -2.8125)
const BOOKCASE_SIZE: Vector3 = Vector3(0.5, 1.8, 0.325)
## Caras de arriba de las tablas del librero (la primera es el zócalo).
const BOOKCASE_SHELVES: Array[float] = [0.08, 0.46, 0.84, 1.22, 1.6]
## Costilla de Adán en maceta de barro (F1): centro de la maceta y su alto.
const MONSTERA_BASE: Vector3 = Vector3(-2.7, 0.0, -2.4)
const MONSTERA_POT: Vector3 = Vector3(0.13, 0.27, 0.165)
## Hojas: [punta del tallo, hacia dónde apunta (grados alrededor de Y desde
## +Z), inclinación hacia arriba (grados), largo, ancho]. En el espacio de la
## maceta.
const MONSTERA_LEAVES: Array[Array] = [
	[Vector3(-0.04, 1.22, -0.06), -120.0, 25.0, 0.26, 0.22],
	[Vector3(0.05, 1.1, 0.02), 70.0, -10.0, 0.24, 0.2],
	[Vector3(-0.06, 1.0, 0.05), -60.0, 5.0, 0.22, 0.2],
	[Vector3(0.02, 0.86, -0.05), 150.0, 10.0, 0.2, 0.18],
	[Vector3(0.03, 0.78, 0.04), 40.0, -5.0, 0.2, 0.18],
	[Vector3(-0.02, 0.66, 0.0), -100.0, 0.0, 0.22, 0.18],
	[Vector3(0.04, 0.55, -0.02), 110.0, -15.0, 0.2, 0.17],
]
## Lóbulos de cada lado de una hoja (con un corte entre cada uno).
const LEAF_LOBES: int = 4
## Basurero de impresiones fallidas (F5): centro, radio de abajo y de arriba,
## alto. Lo que tiene adentro sube con el nivel (`tier`).
const BIN_CENTER: Vector2 = Vector2(-2.8, -0.25)
const BIN_RADIUS: Vector2 = Vector2(0.115, 0.135)
const BIN_HEIGHT: float = 0.38
const BIN_FILL: Array[float] = [0.27, 0.31, 0.35]
const BIN_PIECES: Array[int] = [3, 4, 6]
const BIN_SPAGHETTI: Array[int] = [2, 3, 4]
const BIN_SEED: int = 23
## Cajas de filamento apiladas en la punta derecha del fondo (F4): una al
## empezar, dos al vender y cuatro en el taller.
const BOXES_BASE: Vector3 = Vector3(2.875, 0.0, -2.84)
const BOXES_COUNT: Array[int] = [1, 2, 4]
const BOXES_YAW: Array[float] = [3.0, -4.0, 2.0, -3.0]
## Tapete andino tejido con flecos (centro y medidas) y felpudo de la puerta.
const RUG_CENTER: Vector3 = Vector3(-0.1, 0.0, -0.05)
const RUG_SIZE: Vector2 = Vector2(2.4, 1.2)
const DOORMAT_CENTER: Vector3 = Vector3(-2.55, 0.0, 2.1)
const DOORMAT_SIZE: Vector2 = Vector2(0.4, 0.6)
## Cable del escritorio: sale de la regleta bajo la mesa (lugar 0), va por
## el piso pegado a la pared de la ventana y sube al enchufe de F5.
const CABLE_RADIUS: float = 0.002
const CABLE_WALL_X: float = -2.978
const OUTLET: Vector3 = Vector3(-2.994, 0.3, 0.0)
## Barquito que falló a las dos capas, en el piso junto al basurero.
const FAILED_BOAT: Vector3 = Vector3(-2.56, 0.0, -0.2)


## Agrega lo del piso `id` (una llave de RoomDecor.FLOOR) como se ve en el
## nivel de decoración `tier` (0, 1 o 2).
static func add_floor(kit: KitMesh, id: String, tier: int) -> void:
	match id:
		"bed":
			_bed(kit)
		"pouf":
			_pouf(kit)
		"bookcase":
			_bookcase(kit)
		"monstera":
			_monstera(kit)
		"fail_bin":
			_fail_bin(kit, tier)
		"filament_boxes":
			_filament_boxes(kit, tier)
	kit.origin = Transform3D.IDENTITY


## Lo plano del piso (biblia §8.8 y §5.4): no es obstáculo y mide 4 mm o
## menos.
static func add_flat(kit: KitMesh) -> void:
	kit.ao_enabled = false
	_rug(kit)
	_doormat(kit)
	_failed_boat(kit)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	kit.tube(desk_cable_floor(), CABLE_RADIUS, 6, 3)
	kit.ao_enabled = true


## El tramo del cable del escritorio que va por el piso.
static func desk_cable_floor() -> PackedVector3Array:
	var r: float = CABLE_RADIUS
	var strip: Vector3 = desk_cable_start()
	return PackedVector3Array([
		Vector3(strip.x, r, strip.z + 0.04),
		Vector3(strip.x - 0.07, r, strip.z + 0.12),
		Vector3(strip.x - 0.16, r, strip.z + 0.2),
		Vector3(CABLE_WALL_X, r, strip.z + 0.32),
		Vector3(CABLE_WALL_X, r, OUTLET.z - 0.12),
		Vector3(CABLE_WALL_X, r, OUTLET.z - 0.03),
	])


## Donde el cable sale de la regleta del escritorio (en el lugar 0, el del
## escritorio, que no se vende ni se mueve).
static func desk_cable_start() -> Vector3:
	var desk: Transform3D = RoomLayout.for_space(RoomDecor.SPACE_ID).slots[0]
	var strip: Vector3 = ComputerDeskModel.POWER_STRIP_POS
	var size: Vector3 = ComputerDeskModel.POWER_STRIP_SIZE
	return desk * Vector3(strip.x - size.x / 2.0, size.y * 0.35, strip.z)


# --- La cama ---------------------------------------------------------------------

static func _bed(kit: KitMesh) -> void:
	var x0: float = BED_CORNER.x
	var z0: float = BED_CORNER.y
	var w: float = BED_SIZE.x
	var l: float = BED_SIZE.y
	var x1: float = x0 + w
	var z1: float = z0 + l
	var cx: float = x0 + w / 2.0
	var cz: float = z0 + l / 2.0
	var head: float = 0.06
	# Patas, marco, cabecera con dos tableros y la repisa de arriba.
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.WOOD, 0.2)
	for x: float in [x0 + 0.05, x1 - 0.05]:
		for z: float in [z0 + head + 0.05, z1 - 0.05]:
			kit.box(Vector3(0.06, BED_LEGS, 0.06), Vector3(x, BED_LEGS / 2.0, z), 0.008)
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.25)
	kit.box(Vector3(w, BED_FRAME_TOP - BED_LEGS, l - head), Vector3(cx, (BED_FRAME_TOP + BED_LEGS) / 2.0, cz + head / 2.0), 0.015)
	kit.box(Vector3(w, BED_HEADBOARD, head), Vector3(cx, BED_HEADBOARD / 2.0, z0 + head / 2.0), 0.015)
	kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.25)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.4, 0.24, 0.008), Vector3(cx + side * 0.22, 0.53, z0 + head + 0.003), 0.0)
	var ledge_top: float = BED_HEADBOARD + BED_LEDGE.x
	kit.box(Vector3(w + 0.02, BED_LEDGE.x, BED_LEDGE.y), Vector3(cx, BED_HEADBOARD + BED_LEDGE.x / 2.0, z0 - 0.01 + BED_LEDGE.y / 2.0), 0.008)
	# Colchón con la sábana y la almohada.
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.FABRIC, 0.05)
	kit.box(Vector3(w - 0.06, BED_MATTRESS_TOP - BED_FRAME_TOP, l - head - 0.06), Vector3(cx, (BED_MATTRESS_TOP + BED_FRAME_TOP) / 2.0, cz + head / 2.0), 0.04)
	kit.paint(LookPalette.PILLOW, WorldPalette.Surface.FABRIC, 0.05)
	kit.blob(Vector3(0.3, 0.06, 0.15), Vector3(cx, BED_MATTRESS_TOP + 0.05, z0 + head + 0.24), Vector3(8.0, 0.0, 0.0), 0.35, 0.6, Vector2.ONE, Vector2i(14, 8))
	_tiger_blanket(kit, x0, x1, z0 + head + (l - head) * (1.0 - BLANKET_COVER), z1)
	dragon(kit, Vector3(cx - 0.18, BED_MATTRESS_TOP + 0.03, cz + 0.35), 25.0, LookPalette.FILAMENT_PURPLE, 0.034)
	_bed_lamp(kit, ledge_top)
	# El celular sobre la repisa: la pantalla brilla de noche.
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(12.0)), PHONE_AT)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(0.14, 0.009, 0.07), Vector3(0.0, 0.0045, 0.0), 0.0)
	kit.night_glow(LookPalette.PHONE_SCREEN, 0.9)
	kit.quad(Vector2(0.12, 0.055), Vector3(0.0, 0.0095, 0.0), Vector3(-90.0, 0.0, 0.0))
	kit.origin = Transform3D.IDENTITY


## Cobija de tigre desaturada (biblia §4.4): encima del colchón desde `from`
## hasta los pies, cae por el lado +X y por los pies (los que ve la cámara),
## con el doblez claro en la punta de arriba y rayas oscuras.
static func _tiger_blanket(kit: KitMesh, x0: float, x1: float, from: float, to: float) -> void:
	var top: float = BED_MATTRESS_TOP + 0.03
	var drop: float = 0.21
	var cx: float = (x0 + x1) / 2.0
	kit.paint(LookPalette.TIGER_BLANKET, WorldPalette.Surface.FABRIC, 0.08)
	kit.box(Vector3(x1 - x0 - 0.01, 0.03, to - from), Vector3(cx + 0.005, top - 0.015, (from + to) / 2.0), 0.012)
	kit.box(Vector3(0.022, drop, to - from), Vector3(x1 + 0.002, top - drop / 2.0, (from + to) / 2.0), 0.0)
	kit.box(Vector3(x1 - x0 + 0.012, drop, 0.022), Vector3(cx + 0.006, top - drop / 2.0, to + 0.002), 0.0)
	kit.paint(LookPalette.TIGER_BELLY, WorldPalette.Surface.FABRIC, 0.08)
	kit.cylinder(0.026, x1 - x0 - 0.02, Vector3(cx, top + 0.008, from + 0.02), Vector3(0.0, 0.0, 90.0), 10)
	kit.box(Vector3(x1 - x0 - 0.02, 0.006, 0.09), Vector3(cx, top + 0.002, from + 0.08), 0.0)
	# Rayas: cuñas que entran desde los bordes, en el techo y en las caídas.
	kit.paint(LookPalette.TIGER_STRIPES, WorldPalette.Surface.FABRIC, 0.05)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 41
	var lift: float = top + 0.0008
	var z: float = from + 0.17
	var index: int = 0
	while z < to - 0.05:
		var length: float = rng.randf_range(0.2, 0.36)
		var width: float = rng.randf_range(0.03, 0.05)
		var bend: float = rng.randf_range(-0.04, 0.04)
		if index % 2 == 0:
			_stripe(kit, Vector3(x1 - 0.014, lift, z), Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), length, width, bend)
			_stripe(kit, Vector3(x1 + 0.0135, top - drop + 0.01, z + 0.02), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, 1.0), rng.randf_range(0.11, 0.17), width, bend * 0.5)
		else:
			_stripe(kit, Vector3(x0 + 0.02, lift, z), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), length * 0.8, width, bend)
		z += rng.randf_range(0.07, 0.1)
		index += 1
	var x: float = x0 + 0.08
	while x < x1 - 0.04:
		_stripe(kit, Vector3(x, top - drop + 0.01, to + 0.0135), Vector3(0.0, 1.0, 0.0), Vector3(1.0, 0.0, 0.0), rng.randf_range(0.1, 0.16), rng.randf_range(0.03, 0.045), rng.randf_range(-0.03, 0.03))
		x += rng.randf_range(0.11, 0.15)


## Una raya de tigre: una cuña que nace en `base` (de `width` de ancho a lo
## largo de `across`) y entra `length` metros hacia `along`, torcida `bend`
## a la mitad. Una cara, hacia afuera de la tela (along × across).
static func _stripe(kit: KitMesh, base: Vector3, along: Vector3, across: Vector3, length: float, width: float, bend: float) -> void:
	var half: Vector3 = across * width / 2.0
	var mid: Vector3 = base + along * length * 0.55 + across * bend
	var tip: Vector3 = base + along * length + across * bend * 0.4
	var out: Vector3 = along.cross(across)
	if out.dot(Vector3(1.0, 1.0, 1.0)) < 0.0:
		out = -out
	facing(kit, base - half, base + half, mid + half * 0.45, out)
	facing(kit, base - half, mid + half * 0.45, mid - half * 0.45, out)
	facing(kit, mid - half * 0.45, mid + half * 0.45, tip, out)


## Un triángulo de una sola cara que mira hacia `out`.
static func facing(kit: KitMesh, a: Vector3, b: Vector3, c: Vector3, out: Vector3) -> void:
	if (b - a).cross(c - a).dot(out) < 0.0:
		kit.triangle(a, c, b, Vector3.ZERO, Vector3.ZERO, false)
	else:
		kit.triangle(a, b, c, Vector3.ZERO, Vector3.ZERO, false)


## Dragón articulado impreso (segmentos en curva, cabeza con cuernitos y la
## cola), apoyado en `base`, girado `yaw` grados.
static func dragon(kit: KitMesh, base: Vector3, yaw: float, hex: String, segment: float) -> void:
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), base)
	kit.printed(hex, 0.003)
	for i: int in 7:
		var t: float = float(i) / 6.0
		var at: Vector3 = Vector3(0.0, segment * 0.3, -t * segment * 6.0)
		at.x = sin(t * 3.2) * segment * 1.6
		var size: float = segment * (1.0 - t * 0.45)
		kit.box(Vector3(size, size * 0.6, size * 0.85), at, 0.0, Vector3(0.0, rad_to_deg(cos(t * 3.2) * 0.7), 0.0))
	kit.box(Vector3(segment * 1.3, segment * 0.8, segment * 1.2), Vector3(0.0, segment * 0.42, segment * 0.95), 0.0)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(segment * 0.2, segment * 0.5, segment * 0.2), Vector3(side * segment * 0.35, segment * 0.9, segment * 0.8), 0.0, Vector3(-25.0, 0.0, side * 15.0))
	kit.origin = Transform3D.IDENTITY


## Lámpara de hongo impresa sobre la repisa de la cabecera: la pantalla es
## de PLA claro y brilla de noche (la luz cc_pl2 sale de su foco).
static func _bed_lamp(kit: KitMesh, ledge_top: float) -> void:
	var b: Vector3 = Vector3(BED_LAMP_BULB.x, ledge_top, BED_LAMP_BULB.z)
	kit.printed(LookPalette.FILAMENT_WHITE, 0.003)
	kit.cylinder(0.045, 0.015, b + Vector3(0.0, 0.0075, 0.0), Vector3.ZERO, 16, 0.004)
	kit.cylinder(0.008, 0.05, b + Vector3(0.0, 0.04, 0.0), Vector3.ZERO, 8)
	kit.night_glow(LookPalette.BED_LAMP, 0.8)
	kit.layer = 0.003
	var shade: PackedVector2Array = PackedVector2Array([Vector2(0.078, 0.05), Vector2(0.072, 0.075), Vector2(0.052, 0.105), Vector2(0.0, 0.118)])
	kit.lathe(shade, b, Vector3.ZERO, 18)


# --- El puf ----------------------------------------------------------------------

static func _pouf(kit: KitMesh) -> void:
	var c: Vector3 = Vector3(POUF_CENTER.x, 0.0, POUF_CENTER.y)
	# Un puf de tela con forma de pera, liso: lo grande y redondo lleva más
	# lados que el resto de la decoración.
	var saved: float = kit.detail
	kit.detail = 1.0
	kit.paint(LookPalette.POUF, WorldPalette.Surface.FABRIC, 0.1)
	var h: Vector3 = POUF_HALF
	var profile: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(h.x * 0.86, 0.0), Vector2(h.x * 0.98, h.y * 0.18), Vector2(h.x, h.y * 0.5),
		Vector2(h.x * 0.96, h.y * 1.0), Vector2(h.x * 0.84, h.y * 1.5), Vector2(h.x * 0.62, h.y * 1.85),
		Vector2(h.x * 0.32, h.y * 2.02), Vector2(0.0, h.y * 2.06),
	])
	kit.lathe(profile, c, Vector3.ZERO, 24)
	kit.detail = saved
	# El control de videojuegos (sin marca) en el hoyo de arriba.
	kit.origin = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-8.0), deg_to_rad(25.0), 0.0)), c + Vector3(-0.04, POUF_HALF.y * 1.95, -0.05))
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.35)
	kit.blob(Vector3(0.07, 0.016, 0.04), Vector3(0.0, 0.016, 0.0), Vector3.ZERO, 0.6, 0.8, Vector2.ONE, Vector2i(10, 4))
	for side: float in KitMesh.SIGNS:
		kit.blob(Vector3(0.026, 0.017, 0.04), Vector3(side * 0.056, 0.014, 0.028), Vector3(0.0, side * -15.0, 0.0), 0.8, 0.8, Vector2.ONE, Vector2i(8, 4))
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.SMOOTH, 0.3)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.016, 0.01, 0.016), Vector3(side * 0.022, 0.034, 0.012), 0.0)
	var buttons: Array[String] = [LookPalette.RUG_PATTERN[1], LookPalette.RUG_PATTERN[3], LookPalette.RUG_PATTERN[0], LookPalette.FILAMENT_GREEN]
	for i: int in buttons.size():
		kit.paint(buttons[i], WorldPalette.Surface.SMOOTH, 0.5)
		var a: float = i * TAU / 4.0
		kit.box(Vector3(0.01, 0.006, 0.01), Vector3(0.05 + cos(a) * 0.011, 0.033, -0.008 + sin(a) * 0.011), 0.0)
	kit.origin = Transform3D.IDENTITY
	_sneaker(kit, Transform3D(Basis(Vector3.UP, deg_to_rad(35.0)), Vector3(2.3, 0.0, 1.12)))
	# La otra quedó de lado.
	_sneaker(kit, Transform3D(Basis.from_euler(Vector3(0.0, deg_to_rad(-20.0), deg_to_rad(78.0))), Vector3(2.53, 0.048, 1.14)))


## Zapatilla blanca con una franja terracota (nada de cian cerca del piso:
## biblia §4.8). `at`: la base del centro de la suela, la punta hacia +Z.
static func _sneaker(kit: KitMesh, at: Transform3D) -> void:
	kit.origin = at
	kit.paint(LookPalette.SHOE_SOLE, WorldPalette.Surface.SMOOTH, 0.2)
	kit.box(Vector3(0.095, 0.025, 0.25), Vector3(0.0, 0.0125, 0.0), 0.01)
	kit.paint(LookPalette.SHOES, WorldPalette.Surface.FABRIC, 0.15)
	kit.blob(Vector3(0.044, 0.048, 0.11), Vector3(0.0, 0.06, -0.01), Vector3.ZERO, 0.7, 0.7, Vector2(1.0, 0.8), Vector2i(12, 6))
	kit.paint(LookPalette.RUG_PATTERN[1], WorldPalette.Surface.FABRIC, 0.2)
	kit.box(Vector3(0.004, 0.018, 0.1), Vector3(0.044, 0.06, -0.02), 0.0)
	kit.paint(LookPalette.DRAWSTRINGS)
	for i: int in 3:
		kit.box(Vector3(0.05, 0.006, 0.008), Vector3(0.0, 0.103 - i * 0.004, 0.035 - i * 0.025), 0.0)
	kit.origin = Transform3D.IDENTITY


# --- El librero del rincón -------------------------------------------------------

static func _bookcase(kit: KitMesh) -> void:
	var s: Vector3 = BOOKCASE_SIZE
	var half: Vector3 = s / 2.0
	var wood: float = 0.02
	kit.origin = Transform3D(Basis.IDENTITY, BOOKCASE_BASE)
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.2)
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(wood, s.y, s.z), Vector3(side * (half.x - wood / 2.0), half.y, 0.0), 0.006)
	kit.box(Vector3(s.x, 0.025, s.z), Vector3(0.0, s.y - 0.0125, 0.0), 0.008)
	var inner: float = s.x - wood * 2.0
	for top: float in BOOKCASE_SHELVES:
		kit.box(Vector3(inner, wood, s.z - 0.02), Vector3(0.0, top - wood / 2.0, 0.01), 0.0)
	kit.box(Vector3(inner, BOOKCASE_SHELVES[0] - wood, s.z - 0.04), Vector3(0.0, (BOOKCASE_SHELVES[0] - wood) / 2.0, 0.0), 0.0)
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.WOOD, 0.1)
	kit.box(Vector3(inner, s.y - 0.04, 0.012), Vector3(0.0, s.y / 2.0, -half.z + 0.006), 0.0)
	var front: float = half.z - 0.02
	var shelves: Array[float] = BOOKCASE_SHELVES
	# Abajo: una caja de cartón con etiqueta y una caja impresa con cosas.
	kit.ao_base = shelves[0]
	FurnitureParts.filament_box(kit, Vector3(-0.1, shelves[0], 0.0), 90.0)
	FurnitureParts.filament_box(kit, Vector3(-0.1, shelves[0] + FurnitureParts.FILAMENT_BOX_SIZE.y, 0.01), 86.0)
	kit.printed(LookPalette.RUG_PATTERN[0], 0.004)
	FurnitureParts.open_bin(kit, Vector3(0.12, shelves[0], 0.0), Vector3(0.18, 0.16, 0.24), 0.006)
	kit.printed(LookPalette.FILAMENT_YELLOW, 0.003)
	kit.box(Vector3(0.05, 0.05, 0.05), Vector3(0.09, shelves[0] + 0.15, 0.03), 0.0, Vector3(0.0, 20.0, 0.0))
	# Libros parados, el último apoyado.
	kit.ao_base = shelves[1]
	_books(kit, Vector3(-0.22, shelves[1], 0.0), [0.035, 0.045, 0.03, 0.05, 0.04, 0.035, 0.045], [0.26, 0.3, 0.24, 0.28, 0.25, 0.27, 0.22], 0.2, 0)
	# Jarrón en espiral (modo jarrón: puras capas) y libros acostados.
	kit.ao_base = shelves[2]
	kit.printed(LookPalette.FILAMENT_RED, 0.003, 0.45)
	var vase: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.032, 0.0), Vector2(0.046, 0.06), Vector2(0.034, 0.14), Vector2(0.043, 0.19), Vector2(0.037, 0.19), Vector2(0.028, 0.14), Vector2(0.026, 0.03), Vector2(0.0, 0.03)])
	kit.lathe(vase, Vector3(0.13, shelves[2], 0.0), Vector3.ZERO, 14)
	var stack: Array[String] = [LookPalette.RUG_PATTERN[2], LookPalette.SHEET, LookPalette.RUG_PATTERN[1]]
	for i: int in stack.size():
		kit.paint(stack[i], WorldPalette.Surface.SMOOTH, 0.15)
		kit.box(Vector3(0.22, 0.035, 0.17), Vector3(-0.08, shelves[2] + 0.0175 + i * 0.035, 0.0), 0.0, Vector3(0.0, i * 6.0 - 4.0, 0.0))
	# El dragón articulado y una caja con etiqueta.
	kit.ao_base = shelves[3]
	dragon(kit, BOOKCASE_BASE + Vector3(0.06, shelves[3], 0.06), -70.0, LookPalette.FILAMENT_GREEN, 0.026)
	kit.origin = Transform3D(Basis.IDENTITY, BOOKCASE_BASE)
	kit.paint(LookPalette.CARDBOARD, WorldPalette.Surface.CARDBOARD, 0.1)
	kit.box(Vector3(0.12, 0.1, 0.2), Vector3(-0.14, shelves[3] + 0.05, -0.01), 0.004)
	kit.paint(LookPalette.SHEET)
	kit.quad(Vector2(0.07, 0.04), Vector3(-0.14, shelves[3] + 0.05, 0.091))
	# Arriba: cuadernos bajos.
	kit.ao_base = shelves[4]
	_books(kit, Vector3(-0.2, shelves[4], 0.0), [0.03, 0.035, 0.025, 0.04, 0.03], [0.15, 0.14, 0.15, 0.13, 0.15], 0.16, 3)
	kit.ao_base = 0.0
	_potus(kit, s.y, front)
	kit.origin = Transform3D.IDENTITY


## Libros parados en fila desde `start` (x a la izquierda, la base en la
## tabla), de los anchos y altos dados y `depth` de fondo; el último se
## apoya en el de al lado. `offset` corre el primer color de la lista.
static func _books(kit: KitMesh, start: Vector3, widths: Array, heights: Array, depth: float, offset: int) -> void:
	var colors: Array[String] = [LookPalette.RUG_PATTERN[1], LookPalette.RUG_PATTERN[2], LookPalette.RUG_PATTERN[3], LookPalette.RUG_PATTERN[0], LookPalette.SHEET, LookPalette.WOOD_DARK, LookPalette.PLANTS[0]]
	var x: float = start.x
	for i: int in widths.size():
		var w: float = widths[i]
		var h: float = heights[i]
		kit.paint(colors[(i + offset) % colors.size()], WorldPalette.Surface.SMOOTH, 0.15)
		if i == widths.size() - 1:
			kit.box(Vector3(w, h, depth), Vector3(x + h * 0.13 + w / 2.0, start.y + h / 2.0 - 0.01, start.z), 0.0, Vector3(0.0, 0.0, -15.0))
		else:
			kit.box(Vector3(w, h, depth), Vector3(x + w / 2.0, start.y + h / 2.0, start.z), 0.0)
		x += w + 0.003


## Potus en una maceta impresa arriba del librero, con guías que cuelgan por
## delante y por el costado que ve la cámara (se balancean más abajo).
static func _potus(kit: KitMesh, top: float, front: float) -> void:
	var pot: Vector3 = Vector3(0.1, top, 0.02)
	kit.printed(LookPalette.FILAMENT_WHITE, 0.004)
	kit.cylinder(0.055, 0.1, pot + Vector3(0.0, 0.05, 0.0), Vector3.ZERO, 16, 0.0, 0.068)
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.FABRIC)
	kit.disc(0.062, pot + Vector3(0.0, 0.095, 0.0), Vector3(-90.0, 0.0, 0.0), 12)
	var vines: Array[PackedVector3Array] = [
		PackedVector3Array([pot + Vector3(0.04, 0.09, 0.04), Vector3(0.17, top + 0.04, front + 0.01), Vector3(0.18, top - 0.25, front + 0.025), Vector3(0.17, top - 0.55, front + 0.03), Vector3(0.15, top - 0.78, front + 0.03)]),
		PackedVector3Array([pot + Vector3(0.05, 0.09, -0.02), Vector3(0.24, top + 0.03, 0.05), Vector3(0.256, top - 0.2, 0.06), Vector3(0.256, top - 0.48, 0.03)]),
		PackedVector3Array([pot + Vector3(-0.04, 0.09, 0.03), Vector3(-0.05, top + 0.02, front + 0.01), Vector3(-0.1, top - 0.14, front + 0.025)]),
	]
	# Hacia dónde mira la cara por la que cuelga cada guía: las hojas se
	# abren a los lados, casi pegadas al mueble.
	var faces: Array[Vector3] = [Vector3.BACK, Vector3.RIGHT, Vector3.BACK]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 17
	for v: int in vines.size():
		var vine: PackedVector3Array = vines[v]
		var out: Vector3 = faces[v]
		var across: Vector3 = out.cross(Vector3.UP)
		kit.paint(LookPalette.PLANTS[2], WorldPalette.Surface.SMOOTH, 0.2)
		kit.hanging(0.7, top + 0.1, 0.9)
		kit.tube(vine, 0.004, 4, 2, false)
		var path: PackedVector3Array = KitMesh.smooth_path(vine, 2)
		for k: int in range(1, path.size()):
			kit.paint(LookPalette.PLANTS[k % 2], WorldPalette.Surface.SMOOTH, 0.45)
			kit.hanging(0.7, top + 0.1, 0.9)
			var side: float = 1.0 if k % 2 == 0 else -1.0
			_leaf_diamond(kit, path[k], (across * side * 0.85 + Vector3.DOWN * 0.35 + out * 0.2).normalized(), rng.randf_range(0.045, 0.06))
	for i: int in 5:
		var a: float = i * TAU / 5.0 + 0.4
		kit.paint(LookPalette.PLANTS[i % 3], WorldPalette.Surface.SMOOTH, 0.45)
		_leaf_diamond(kit, pot + Vector3(cos(a) * 0.03, 0.1, sin(a) * 0.03), Vector3(cos(a), 0.7, sin(a)).normalized(), 0.065)


## Hoja chica en rombo (dos triángulos que se ven de los dos lados) desde
## `base` hacia `direction`, de `size` de largo.
static func _leaf_diamond(kit: KitMesh, base: Vector3, direction: Vector3, size: float) -> void:
	var side: Vector3 = direction.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized() * size * 0.38
	var mid: Vector3 = base + direction * size * 0.45
	var tip: Vector3 = base + direction * size
	kit.triangle(base, mid + side, tip)
	kit.triangle(base, tip, mid - side)


# --- La costilla de Adán ---------------------------------------------------------

static func _monstera(kit: KitMesh) -> void:
	var p: Vector3 = MONSTERA_POT
	kit.origin = Transform3D(Basis.IDENTITY, MONSTERA_BASE)
	kit.paint(LookPalette.CLAY_POT, WorldPalette.Surface.SMOOTH, 0.15)
	kit.cylinder(p.x, p.y, Vector3(0.0, p.y / 2.0, 0.0), Vector3.ZERO, 18, 0.0, p.z)
	kit.cylinder(p.z + 0.012, 0.035, Vector3(0.0, p.y + 0.0125, 0.0), Vector3.ZERO, 18)
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.FABRIC)
	var soil: float = p.y + 0.029
	kit.disc(p.z - 0.005, Vector3(0.0, soil + 0.001, 0.0), Vector3(-90.0, 0.0, 0.0), 14)
	for i: int in MONSTERA_LEAVES.size():
		var leaf: Array = MONSTERA_LEAVES[i]
		var tip: Vector3 = leaf[0]
		var base: Vector3 = Vector3(tip.x * 0.4, soil, tip.z * 0.4)
		var bend: Vector3 = base.lerp(tip, 0.55) + Vector3(tip.x, 0.0, tip.z).normalized() * 0.03
		kit.paint(LookPalette.PLANTS[1], WorldPalette.Surface.SMOOTH, 0.25)
		kit.rooted(0.8, soil, 1.0)
		kit.tube(PackedVector3Array([base, bend, tip]), 0.007, 4, 2, false)
		kit.paint(LookPalette.PLANTS[i % 3], WorldPalette.Surface.SMOOTH, 0.45)
		kit.rooted(0.8, soil, 1.0)
		var frame: Transform3D = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-float(leaf[2])), deg_to_rad(float(leaf[1])), 0.0)), tip)
		_monstera_leaf(kit, frame, leaf[3], leaf[4])
	kit.origin = Transform3D.IDENTITY


## Hoja de costilla de Adán en `frame` (espacio de la maceta): nace en el
## origen y va hacia +Z, con LEAF_LOBES lóbulos por lado separados por cortes
## que llegan a la vena; los bordes y la punta caen un poco. Una cara (la de
## arriba).
static func _monstera_leaf(kit: KitMesh, frame: Transform3D, length: float, width: float) -> void:
	var saved: Transform3D = kit.origin
	kit.origin = saved * frame
	var gap: float = 0.32 / LEAF_LOBES
	for side: float in KitMesh.SIGNS:
		for k: int in LEAF_LOBES:
			var a: float = float(k) / LEAF_LOBES
			var b: float = float(k + 1) / LEAF_LOBES
			var mid_a: Vector3 = _leaf_point(a, 0.0, length, width)
			var mid_b: Vector3 = _leaf_point(b, 0.0, length, width)
			var edge_a: Vector3 = _leaf_point(minf(a + gap, b), side, length, width)
			var edge_b: Vector3 = _leaf_point(b, side, length, width)
			facing(kit, mid_a, mid_b, edge_a, Vector3.UP)
			facing(kit, edge_a, mid_b, edge_b, Vector3.UP)
	kit.origin = saved


## Punto de la hoja a la fracción `t` del largo: en la vena (`side` 0) o en
## el borde de ese lado (±1). Ancho de corazón, más ancho cerca de la base.
static func _leaf_point(t: float, side: float, length: float, width: float) -> Vector3:
	var half: float = width / 2.0 * pow(sin(PI * clampf(pow(t, 0.8), 0.0, 1.0)), 0.7) * absf(side)
	var droop: float = -0.05 * t * t * length - 0.25 * half * half / maxf(width, 0.01)
	return Vector3(side * half, droop, t * length)


# --- Basurero y cajas ------------------------------------------------------------

## Basurero de impresiones fallidas, abierto, con espaguetis y piezas
## malogradas adentro (más lleno según el nivel).
static func _fail_bin(kit: KitMesh, tier: int) -> void:
	var c: Vector3 = Vector3(BIN_CENTER.x, 0.0, BIN_CENTER.y)
	var r0: float = BIN_RADIUS.x
	var r1: float = BIN_RADIUS.y
	var h: float = BIN_HEIGHT
	var wall: float = 0.01
	kit.paint(LookPalette.RUG_PATTERN[1], WorldPalette.Surface.SMOOTH, 0.35)
	var shell: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(r0, 0.0), Vector2(r0, 0.0), Vector2(r1, h), Vector2(r1, h),
		Vector2(r1 - wall, h), Vector2(r1 - wall, h), Vector2(r0 - wall, 0.02), Vector2(r0 - wall, 0.02), Vector2(0.0, 0.02),
	])
	kit.lathe(shell, c, Vector3.ZERO, 20)
	var fill: float = BIN_FILL[tier]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = BIN_SEED
	var inside: float = lerpf(r0, r1, fill / h) - wall
	kit.paint(LookPalette.FAILED_PIECE, WorldPalette.Surface.SMOOTH, 0.2)
	kit.cylinder(inside, 0.02, c + Vector3(0.0, fill - 0.01, 0.0), Vector3.ZERO, 14)
	var colors: Array[String] = [LookPalette.FILAMENT_RED, LookPalette.FILAMENT_YELLOW, LookPalette.FILAMENT_WHITE, LookPalette.FILAMENT_BLUE, LookPalette.FILAMENT_PURPLE, LookPalette.FILAMENT_GREEN]
	for i: int in BIN_PIECES[tier]:
		var a: float = rng.randf() * TAU
		var d: float = rng.randf_range(0.0, inside - 0.04)
		kit.printed(colors[i % colors.size()], 0.004)
		kit.box(Vector3(0.05, 0.035, 0.045), c + Vector3(cos(a) * d, fill + 0.012, sin(a) * d), 0.0, Vector3(rng.randf_range(-25.0, 25.0), rng.randf_range(0.0, 90.0), rng.randf_range(-25.0, 25.0)))
	for i: int in BIN_SPAGHETTI[tier]:
		var a: float = rng.randf() * TAU
		var q: Vector3 = Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(0.0, 0.05) + Vector3(0.0, fill, 0.0)
		var points: PackedVector3Array = PackedVector3Array()
		for k: int in 6:
			points.append(c + q)
			q += Vector3(rng.randf_range(-0.045, 0.045), rng.randf_range(0.02, 0.045), rng.randf_range(-0.045, 0.045))
			var flat: Vector2 = Vector2(q.x, q.z).limit_length(r1 - wall - 0.012)
			q = Vector3(flat.x, minf(q.y, h + 0.09), flat.y)
		kit.paint(colors[(i + 2) % colors.size()], WorldPalette.Surface.SMOOTH, 0.5)
		kit.tube(points, 0.0045, 4, 2)


static func _filament_boxes(kit: KitMesh, tier: int) -> void:
	for i: int in BOXES_COUNT[tier]:
		FurnitureParts.filament_box(kit, BOXES_BASE + Vector3(0.0, FurnitureParts.FILAMENT_BOX_SIZE.y * i, 0.0), BOXES_YAW[i])


# --- Lo plano --------------------------------------------------------------------

## Tapete andino tejido (biblia §4.4): fondo crudo, franjas en los bordes,
## dientes, una fila de rombos y flecos en las puntas. Todo mira hacia
## arriba (solo se ve de arriba).
static func _rug(kit: KitMesh) -> void:
	var c: Vector3 = RUG_CENTER
	var half: Vector2 = RUG_SIZE / 2.0
	var base_top: float = 0.003
	var up: Vector3 = Vector3(-90.0, 0.0, 0.0)
	var pattern: Array[String] = LookPalette.RUG_PATTERN
	kit.paint(LookPalette.RUG_BASE, WorldPalette.Surface.FABRIC, 0.04)
	kit.box(Vector3(RUG_SIZE.x, base_top, RUG_SIZE.y), c + Vector3(0.0, base_top / 2.0, 0.0), 0.0)
	var y: float = base_top + 0.0003
	# Franjas a lo largo (cerca de los dos bordes largos) y en las puntas.
	for side: float in KitMesh.SIGNS:
		kit.paint(pattern[2], WorldPalette.Surface.FABRIC, 0.04)
		kit.quad(Vector2(RUG_SIZE.x - 0.12, 0.06), c + Vector3(0.0, y, side * (half.y - 0.08)), up)
		kit.paint(pattern[1], WorldPalette.Surface.FABRIC, 0.04)
		kit.quad(Vector2(RUG_SIZE.x - 0.12, 0.025), c + Vector3(0.0, y, side * (half.y - 0.15)), up)
		kit.paint(pattern[0], WorldPalette.Surface.FABRIC, 0.04)
		kit.quad(Vector2(0.05, RUG_SIZE.y - 0.12), c + Vector3(side * (half.x - 0.1), y, 0.0), up)
	# Dientes hacia adentro, junto a las franjas.
	kit.paint(pattern[0], WorldPalette.Surface.FABRIC, 0.04)
	for side: float in KitMesh.SIGNS:
		var z: float = c.z + side * (half.y - 0.1625)
		var x: float = c.x - half.x + 0.2
		while x < c.x + half.x - 0.19:
			facing(kit, Vector3(x - 0.05, y, z), Vector3(x + 0.05, y, z), Vector3(x, y, z - side * 0.07), Vector3.UP)
			x += 0.16
	# Rombos anidados en el centro, más largos a lo largo del tapete.
	for i: int in 5:
		var at: Vector3 = c + Vector3(-0.8 + i * 0.4, 0.0, 0.0)
		var rings: Array[String] = [pattern[1] if i % 2 == 0 else pattern[0], pattern[3], pattern[2]]
		var sizes: Array[Vector2] = [Vector2(0.17, 0.12), Vector2(0.11, 0.075), Vector2(0.045, 0.03)]
		for k: int in rings.size():
			kit.paint(rings[k], WorldPalette.Surface.FABRIC, 0.04)
			var d: Vector2 = sizes[k]
			var lift: Vector3 = at + Vector3(0.0, y + 0.0002 * (k + 1), 0.0)
			facing(kit, lift + Vector3(-d.x, 0.0, 0.0), lift + Vector3(0.0, 0.0, -d.y), lift + Vector3(d.x, 0.0, 0.0), Vector3.UP)
			facing(kit, lift + Vector3(-d.x, 0.0, 0.0), lift + Vector3(d.x, 0.0, 0.0), lift + Vector3(0.0, 0.0, d.y), Vector3.UP)
	# Flecos en las dos puntas.
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.FABRIC, 0.04)
	for side: float in KitMesh.SIGNS:
		for i: int in 18:
			var z: float = c.z - half.y + 0.04 + (RUG_SIZE.y - 0.08) * i / 17.0
			kit.quad(Vector2(0.06, 0.012), Vector3(c.x + side * (half.x + 0.028), 0.001, z), up)


## Felpudo dentro del paso de la puerta, con su borde más claro.
static func _doormat(kit: KitMesh) -> void:
	var c: Vector3 = DOORMAT_CENTER
	var s: Vector2 = DOORMAT_SIZE
	kit.paint(LookPalette.DOORMAT, WorldPalette.Surface.FABRIC, 0.02)
	kit.box(Vector3(s.x, 0.003, s.y), c + Vector3(0.0, 0.0015, 0.0), 0.0)
	kit.paint(LookPalette.CARDBOARD_DARK, WorldPalette.Surface.FABRIC, 0.02)
	var up: Vector3 = Vector3(-90.0, 0.0, 0.0)
	var y: float = 0.0034
	for side: float in KitMesh.SIGNS:
		kit.quad(Vector2(s.x - 0.04, 0.025), c + Vector3(0.0, y, side * (s.y / 2.0 - 0.035)), up)
		kit.quad(Vector2(0.025, s.y - 0.1), c + Vector3(side * (s.x / 2.0 - 0.035), y, 0.0), up)


## El barquito que se despegó a las dos capas: solo el contorno del casco y
## el relleno, en el piso junto al basurero.
static func _failed_boat(kit: KitMesh) -> void:
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(-30.0)), FAILED_BOAT)
	kit.printed(LookPalette.FILAMENT_ORANGE, 0.002)
	kit.box(Vector3(0.05, 0.004, 0.07), Vector3(0.0, 0.002, -0.005), 0.0)
	kit.box(Vector3(0.034, 0.004, 0.034), Vector3(0.0, 0.002, 0.04), 0.0, Vector3(0.0, 45.0, 0.0))
	kit.origin = Transform3D.IDENTITY
