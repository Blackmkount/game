class_name ComputerDeskModel
extends RefCounted
## El escritorio del comienzo (biblia de arte §10): mesa vieja de madera con
## cajonera de 3 cajones; monitor de tubo beige con un papelito amarillo y su
## LED verde; torre con bahías; teclado con teclas; ratón con alfombrilla;
## lámpara articulada amarilla; taza roja; portalápices impreso; bocetos,
## cuaderno y calibrador; cables a una regleta en el piso, y una caja de
## cartón con un cojín como silla (el comienzo humilde). El frente mira hacia
## +Z.
##
## Todo lo fijo es UNA malla del kit ("Body"); aparte va solo la pantalla, que
## cambia ("Monitor/Screen", la cambia DeskView). Marcadores (Marker3D) que
## lee RoomView para las luces del sombreador (§6.2): "LampBulb" (la ampolleta
## de la lámpara, cc_pl0) y "ScreenGlow" (el brillo delante de la pantalla,
## cc_pl1). De noche, además, dos halos (night_lights(), biblia §4.7): la
## mancha cálida de la lámpara sobre la mesa y el resplandor del monitor.
##
## La caja que se toca no cambia: x ±0,65, z −0,41…0,81 y 1,15 de alto (la
## prueba lo fija).

## El tablero: ancho, alto de arriba y fondo. Con él RoomView arma la caja que
## tapa el parche de sol de la ventana (el escritorio está bajo la ventana).
const TABLE_SIZE: Vector3 = Vector3(1.3, 0.75, 0.62)
const TABLE_THICKNESS: float = 0.05
## Detalle de lo redondo (biblia §5.1: escritorio 0,8).
const DETAIL: float = 0.8
## Cajonera (hacia la puerta, a la izquierda en la pantalla): centro en x,
## ancho y fondo; el zócalo y los tres cajones (el del medio, entreabierto).
const PEDESTAL_X: float = -0.43
const PEDESTAL_SIZE: Vector2 = Vector2(0.4, 0.56)
const PLINTH: float = 0.03
const DRAWER_HEIGHT: float = 0.2
const DRAWER_GAP: float = 0.02
const DRAWER_AJAR: float = 0.03
## Patas del otro lado (x) y su profundidad (±z).
const LEG_X: float = 0.6
const LEG_Z: float = 0.27
## Monitor de tubo: dónde se apoya (el nodo "Monitor"), la pantalla (en el
## espacio del monitor) y el brillo que alumbra delante de ella.
const MONITOR_POS: Vector3 = Vector3(-0.15, 0.75, -0.08)
const SCREEN_POS: Vector3 = Vector3(0.0, 0.225, 0.1675)
const SCREEN_SIZE: Vector2 = Vector2(0.33, 0.25)
const SCREEN_GLOW_AHEAD: float = 0.12
## Torre (sobre la mesa, al lado de la ventana): su base.
const TOWER_POS: Vector3 = Vector3(0.42, 0.75, -0.1)
const TOWER_SIZE: Vector3 = Vector3(0.18, 0.4, 0.4)
## Teclado: centro sobre la mesa y su giro (grados).
const KEYBOARD_POS: Vector3 = Vector3(-0.12, 0.75, 0.19)
const KEYBOARD_YAW: float = 3.0
## Lámpara articulada: base, codo, cabeza (donde se une la pantalla) y la
## ampolleta, que asoma por la boca de la pantalla cónica: la pantalla mira
## al frente de la mesa (donde se sienta) y un poco hacia la cámara, para que
## de noche se vea la ampolleta encendida. La pantalla mide
## LAMP_SHADE_LENGTH desde la cabeza hasta la boca.
const LAMP_BASE: Vector3 = Vector3(-0.55, 0.75, -0.2)
const LAMP_ELBOW: Vector3 = Vector3(-0.57, 1.06, -0.24)
const LAMP_HEAD: Vector3 = Vector3(-0.53, 1.1, 0.02)
const LAMP_BULB: Vector3 = Vector3(-0.519, 1.032, 0.106)
const LAMP_SHADE_LENGTH: float = 0.11
## El croquis azul de una pieza en el papel de arriba: cada línea es (x, z,
## largo, giro en grados).
const SKETCH: Array[Vector4] = [
	Vector4(0.0, -0.03, 0.07, 0.0), Vector4(0.0, 0.03, 0.07, 0.0),
	Vector4(-0.035, 0.0, 0.06, 90.0), Vector4(0.035, 0.0, 0.06, 90.0),
	Vector4(0.0, 0.0, 0.05, 45.0),
]
## La caja de cartón que hace de silla: base y medidas.
const SEAT_POS: Vector3 = Vector3(0.05, 0.0, 0.6)
const SEAT_SIZE: Vector3 = Vector3(0.42, 0.4, 0.42)
## Regleta en el piso, bajo la mesa (ahí llegan los cables).
const POWER_STRIP_POS: Vector3 = Vector3(0.06, 0.0, -0.24)
const POWER_STRIP_SIZE: Vector3 = Vector3(0.28, 0.035, 0.06)
## Radio de los cables.
const CABLE_RADIUS: float = 0.004
## Halos de noche (HaloField): la mancha de la lámpara sobre la mesa (dónde
## cae respecto de la ampolleta y su tamaño) y el resplandor alrededor de la
## pantalla (cuánto más grande que ella y a qué distancia delante), con la
## fuerza de cada uno.
const LAMP_POOL_OFFSET: Vector2 = Vector2(0.06, 0.02)
const LAMP_POOL_SIZE: Vector2 = Vector2(0.7, 0.55)
const LAMP_POOL_STRENGTH: float = 0.33
const SCREEN_HALO_SCALE: float = 1.9
const SCREEN_HALO_AHEAD: float = 0.012
const SCREEN_HALO_STRENGTH: float = 0.22


## Las luces de noche del escritorio (los halos de HaloField, en el espacio
## del mueble): dónde (un plano: su +Y mira afuera), de qué tamaño y color.
static func night_lights() -> Array[Dictionary]:
	var bulb: Vector3 = LAMP_BULB
	var pool: Vector3 = Vector3(bulb.x + LAMP_POOL_OFFSET.x, TABLE_SIZE.y + HaloField.LIFT, bulb.z + LAMP_POOL_OFFSET.y)
	var screen: Vector3 = MONITOR_POS + SCREEN_POS + Vector3(0.0, 0.0, SCREEN_HALO_AHEAD)
	return [
		{"at": Transform3D(Basis.IDENTITY, pool), "size": LAMP_POOL_SIZE, "color": Color(LookPalette.LAMP_HALO) * LAMP_POOL_STRENGTH},
		{"at": Transform3D(Basis(Vector3.RIGHT, PI / 2.0), screen), "size": SCREEN_SIZE * SCREEN_HALO_SCALE, "color": Color(LookPalette.MONITOR_HALO) * SCREEN_HALO_STRENGTH},
	]


## La caja del tablero (con lo que hay debajo), en el espacio del mueble.
static func table_box() -> AABB:
	return AABB(Vector3(-TABLE_SIZE.x / 2.0, 0.0, -TABLE_SIZE.z / 2.0), TABLE_SIZE)


static func build(parent: Node3D, node_name: String) -> Node3D:
	var desk: Node3D = PropBuilder.group(parent, node_name)
	PropBuilder.kit(desk, "Body", KitMesh.cached("desk:computer:%.2f" % DETAIL, _body))
	var monitor: Node3D = PropBuilder.group(desk, "Monitor", MONITOR_POS)
	var screen: MeshInstance3D = PropBuilder.quad(monitor, "Screen", SCREEN_SIZE, SCREEN_POS, WorldPalette.glow("ffffff", "crt_screen"))
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker(desk, "LampBulb", LAMP_BULB)
	_marker(desk, "ScreenGlow", MONITOR_POS + SCREEN_POS + Vector3(0.0, 0.0, SCREEN_GLOW_AHEAD))
	return desk


static func _body() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.detail = DETAIL
	_frame(kit)
	_seat(kit)
	_power_strip(kit)
	# Lo que está sobre la mesa: el contacto oscuro a la altura del tablero.
	kit.ao_base = TABLE_SIZE.y
	_monitor(kit)
	_tower(kit)
	_keyboard_and_mouse(kit)
	_lamp(kit)
	_clutter(kit)
	return kit.commit()


## El mueble: tablero, cajonera con sus tres cajones y tiradores de bronce,
## dos patas con su travesaño y los faldones bajo el tablero.
static func _frame(kit: KitMesh) -> void:
	var under: float = TABLE_SIZE.y - TABLE_THICKNESS
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.28)
	kit.box(Vector3(TABLE_SIZE.x, TABLE_THICKNESS, TABLE_SIZE.z), Vector3(0.0, TABLE_SIZE.y - TABLE_THICKNESS / 2.0, 0.0), 0.014)
	# Cajonera sobre su zócalo.
	var depth: float = PEDESTAL_SIZE.y
	var front: float = depth / 2.0 - 0.01
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.WOOD, 0.22)
	kit.box(Vector3(PEDESTAL_SIZE.x, under - PLINTH, depth), Vector3(PEDESTAL_X, PLINTH + (under - PLINTH) / 2.0, -0.01), 0.012)
	kit.box(Vector3(PEDESTAL_SIZE.x - 0.04, PLINTH, depth - 0.06), Vector3(PEDESTAL_X, PLINTH / 2.0, -0.02), 0.0)
	for i: int in 3:
		var y: float = PLINTH + DRAWER_GAP + DRAWER_HEIGHT / 2.0 + i * (DRAWER_HEIGHT + DRAWER_GAP)
		var out: float = DRAWER_AJAR if i == 1 else 0.0
		if out > 0.0:
			kit.paint(LookPalette.WOOD_LIGHT, WorldPalette.Surface.WOOD, 0.2)
			kit.box(Vector3(PEDESTAL_SIZE.x - 0.07, DRAWER_HEIGHT - 0.04, out + 0.01), Vector3(PEDESTAL_X, y + 0.01, front + out / 2.0), 0.0)
		kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.3)
		kit.box(Vector3(PEDESTAL_SIZE.x - 0.04, DRAWER_HEIGHT, 0.02), Vector3(PEDESTAL_X, y, front + 0.01 + out), 0.006)
		kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.8)
		kit.box(Vector3(0.1, 0.016, 0.016), Vector3(PEDESTAL_X, y + 0.045, front + 0.028 + out), 0.004)
	# Patas, travesaño y faldones.
	kit.paint(LookPalette.WOOD_DARK, WorldPalette.Surface.WOOD, 0.22)
	for z: float in KitMesh.SIGNS:
		kit.box(Vector3(0.05, under, 0.05), Vector3(LEG_X, under / 2.0, LEG_Z * z), 0.008)
	kit.box(Vector3(0.03, 0.03, LEG_Z * 2.0 - 0.05), Vector3(LEG_X, 0.12, 0.0), 0.0)
	var apron_from: float = PEDESTAL_X + PEDESTAL_SIZE.x / 2.0
	var apron_to: float = LEG_X - 0.025
	kit.paint(LookPalette.WOOD_MID, WorldPalette.Surface.WOOD, 0.22)
	for z: float in KitMesh.SIGNS:
		kit.box(Vector3(apron_to - apron_from, 0.07, 0.02), Vector3((apron_from + apron_to) / 2.0, under - 0.035, LEG_Z * z), 0.006)
	kit.box(Vector3(0.02, 0.07, LEG_Z * 2.0 - 0.05), Vector3(LEG_X, under - 0.035, 0.0), 0.006)


## Monitor de tubo beige: pie giratorio, el cuerpo que se angosta hacia atrás
## con su cola, el marco con el vidrio oscuro (la pantalla es
## "Monitor/Screen"), el papelito amarillo, el botón y el LED verde.
static func _monitor(kit: KitMesh) -> void:
	var m: Vector3 = MONITOR_POS
	kit.paint(LookPalette.COMPUTER_BEIGE_WORN, WorldPalette.Surface.SMOOTH, 0.25)
	kit.cylinder(0.1, 0.02, m + Vector3(0.0, 0.01, 0.0), Vector3.ZERO, 18, 0.006)
	kit.box(Vector3(0.09, 0.04, 0.09), m + Vector3(0.0, 0.04, 0.0), 0.01)
	kit.blob(Vector3(0.195, 0.115, 0.155), m + Vector3(0.0, 0.215, -0.07), Vector3(-90.0, 0.0, 0.0), 0.35, 0.5, Vector2(1.0, 0.72), Vector2i(16, 8))
	kit.box(Vector3(0.24, 0.2, 0.15), m + Vector3(0.0, 0.2, -0.255), 0.035)
	kit.paint(LookPalette.COMPUTER_BEIGE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.44, 0.36, 0.09), m + Vector3(0.0, 0.22, 0.115), 0.025)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.6)
	kit.box(Vector3(SCREEN_SIZE.x + 0.03, SCREEN_SIZE.y + 0.025, 0.01), m + Vector3(SCREEN_POS.x, SCREEN_POS.y, 0.161), 0.003)
	kit.paint(LookPalette.KNOBS, WorldPalette.Surface.SMOOTH, 0.1)
	kit.box(Vector3(0.05, 0.05, 0.003), m + Vector3(0.185, 0.372, 0.1615), 0.0, Vector3(0.0, 0.0, 8.0))
	kit.paint(LookPalette.COMPUTER_BEIGE_WORN, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(Vector3(0.03, 0.016, 0.008), m + Vector3(0.12, 0.07, 0.162), 0.003)
	kit.glowing(LookPalette.PRINTER_GREEN, 1.6)
	kit.box(Vector3(0.012, 0.012, 0.004), m + Vector3(0.165, 0.07, 0.161), 0.0)


## Torre beige con dos bahías, la disquetera, el botón, el LED y la rejilla.
static func _tower(kit: KitMesh) -> void:
	var t: Vector3 = TOWER_POS
	var front: float = t.z + TOWER_SIZE.z / 2.0
	kit.paint(LookPalette.COMPUTER_BEIGE_WORN, WorldPalette.Surface.SMOOTH, 0.25)
	kit.box(TOWER_SIZE, t + Vector3(0.0, TOWER_SIZE.y / 2.0, 0.0), 0.012)
	kit.paint(LookPalette.COMPUTER_BEIGE, WorldPalette.Surface.SMOOTH, 0.3)
	for i: int in 2:
		kit.box(Vector3(0.14, 0.04, 0.008), Vector3(t.x, t.y + 0.345 - i * 0.05, front + 0.0025), 0.003)
	kit.box(Vector3(0.14, 0.03, 0.006), Vector3(t.x, t.y + 0.255, front + 0.002), 0.002)
	kit.cylinder(0.014, 0.008, Vector3(t.x, t.y + 0.12, front + 0.003), Vector3(90.0, 0.0, 0.0), 12)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.09, 0.006, 0.004), Vector3(t.x, t.y + 0.255, front + 0.005), 0.0)
	for i: int in 3:
		kit.box(Vector3(0.1, 0.004, 0.003), Vector3(t.x, t.y + 0.04 + i * 0.015, front + 0.001), 0.0)
	kit.glowing(LookPalette.PRINTER_GREEN, 1.6)
	kit.box(Vector3(0.012, 0.012, 0.004), Vector3(t.x + 0.045, t.y + 0.12, front + 0.001), 0.0)


## Teclado con sus teclas (tres filas y la de la barra espaciadora) y el
## ratón sobre su alfombrilla, con el cable que se va detrás del monitor.
static func _keyboard_and_mouse(kit: KitMesh) -> void:
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(KEYBOARD_YAW)), KEYBOARD_POS)
	kit.paint(LookPalette.COMPUTER_BEIGE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.42, 0.024, 0.15), Vector3(0.0, 0.012, 0.0), 0.007)
	kit.paint(LookPalette.COMPUTER_BEIGE_WORN, WorldPalette.Surface.SMOOTH, 0.15)
	kit.box(Vector3(0.39, 0.004, 0.118), Vector3(0.0, 0.025, 0.006), 0.0)
	kit.paint(LookPalette.COMPUTER_BEIGE, WorldPalette.Surface.SMOOTH, 0.35)
	var key: Vector3 = Vector3(0.022, 0.008, 0.022)
	var pitch: float = 0.0285
	for row: int in 3:
		var z: float = -0.036 + row * pitch
		for column: int in 13:
			kit.box(key, Vector3(-0.171 + column * pitch, 0.031, z), 0.0)
	var space_z: float = -0.036 + 3 * pitch
	for column: int in 3:
		kit.box(key, Vector3(-0.171 + column * pitch, 0.031, space_z), 0.0)
		kit.box(key, Vector3(0.171 - column * pitch, 0.031, space_z), 0.0)
	kit.box(Vector3(0.16, key.y, key.z), Vector3(0.0, 0.031, space_z), 0.0)
	kit.origin = Transform3D.IDENTITY
	kit.paint(LookPalette.RUG_PATTERN[2], WorldPalette.Surface.FABRIC, 0.05)
	kit.box(Vector3(0.18, 0.004, 0.16), Vector3(0.21, TABLE_SIZE.y + 0.002, 0.2), 0.0)
	kit.paint(LookPalette.COMPUTER_BEIGE, WorldPalette.Surface.SMOOTH, 0.45)
	kit.blob(Vector3(0.027, 0.017, 0.043), Vector3(0.21, TABLE_SIZE.y + 0.019, 0.21), Vector3(0.0, -8.0, 0.0), 0.8, 0.8, Vector2.ONE, Vector2i(10, 6))
	kit.paint(LookPalette.COMPUTER_BEIGE_WORN, WorldPalette.Surface.SMOOTH, 0.3)
	var top: float = TABLE_SIZE.y + 0.006
	kit.tube(PackedVector3Array([Vector3(0.205, top + 0.006, 0.168), Vector3(0.19, top, 0.1), Vector3(0.12, top, 0.03), Vector3(0.03, top, -0.04)]), 0.0035, 6, 3)


## Lámpara articulada amarilla: base, dos brazos con sus uniones y la
## pantalla cónica que mira al teclado, con la ampolleta en la boca (de
## noche brilla; su luz es cc_pl0).
static func _lamp(kit: KitMesh) -> void:
	kit.paint(LookPalette.RUG_PATTERN[3], WorldPalette.Surface.SMOOTH, 0.55)
	kit.cylinder(0.07, 0.022, LAMP_BASE + Vector3(0.0, 0.011, 0.0), Vector3.ZERO, 18, 0.007)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.6)
	kit.tube(PackedVector3Array([LAMP_BASE + Vector3(0.0, 0.02, 0.0), LAMP_ELBOW]), 0.008, 6, 1)
	kit.tube(PackedVector3Array([LAMP_ELBOW, LAMP_HEAD]), 0.007, 6, 1)
	kit.blob(Vector3.ONE * 0.016, LAMP_ELBOW, Vector3.ZERO, 1.0, 1.0, Vector2.ONE, Vector2i(8, 6))
	kit.blob(Vector3.ONE * 0.014, LAMP_HEAD, Vector3.ZERO, 1.0, 1.0, Vector2.ONE, Vector2i(8, 6))
	# La pantalla: un cono con la punta en la cabeza y la boca hacia la
	# ampolleta.
	var aim: Vector3 = (LAMP_BULB - LAMP_HEAD).normalized()
	kit.origin = Transform3D(Basis(Quaternion(Vector3.UP, -aim)), LAMP_HEAD + aim * (LAMP_SHADE_LENGTH / 2.0 + 0.005))
	kit.paint(LookPalette.RUG_PATTERN[3], WorldPalette.Surface.SMOOTH, 0.55)
	kit.cylinder(0.068, LAMP_SHADE_LENGTH - 0.01, Vector3.ZERO, Vector3.ZERO, 18, 0.006, 0.026)
	kit.origin = Transform3D.IDENTITY
	kit.night_glow(LookPalette.SHEET, 1.6)
	kit.blob(Vector3.ONE * 0.03, LAMP_BULB, Vector3.ZERO, 1.0, 1.0, Vector2.ONE, Vector2i(10, 6))


## Taza roja con café, portalápices impreso con lápices, papeles con
## bocetos, el cuaderno y el calibrador.
static func _clutter(kit: KitMesh) -> void:
	var top: float = TABLE_SIZE.y
	# Taza.
	var mug: Vector3 = Vector3(0.42, top, 0.2)
	kit.paint("e0453a", WorldPalette.Surface.SMOOTH, 0.55)
	kit.cylinder(0.038, 0.09, mug + Vector3(0.0, 0.045, 0.0), Vector3.ZERO, 14, 0.006)
	kit.torus(Vector2(0.022, 0.024), 0.007, mug + Vector3(0.045, 0.05, 0.0), Vector3(90.0, 0.0, 0.0), TAU, Vector2i(10, 6))
	kit.paint(LookPalette.TIGER_STRIPES, WorldPalette.Surface.SMOOTH, 0.7)
	kit.disc(0.032, mug + Vector3(0.0, 0.082, 0.0), Vector3(-90.0, 0.0, 0.0), 14)
	# Portalápices impreso (con sus capas) y tres lápices.
	var holder: Vector3 = Vector3(0.2, top, -0.06)
	kit.printed("9b5de5", 0.0045)
	kit.cylinder(0.036, 0.1, holder + Vector3(0.0, 0.05, 0.0), Vector3.ZERO, 6, 0.004)
	kit.paint("f5cf3c", WorldPalette.Surface.SMOOTH, 0.3)
	kit.cylinder(0.006, 0.17, holder + Vector3(-0.008, 0.11, -0.005), Vector3(8.0, 0.0, -7.0), 6)
	kit.paint("e0453a", WorldPalette.Surface.SMOOTH, 0.3)
	kit.cylinder(0.006, 0.16, holder + Vector3(0.01, 0.108, 0.006), Vector3(-6.0, 0.0, 10.0), 6)
	kit.paint("3b7fe0", WorldPalette.Surface.SMOOTH, 0.3)
	kit.cylinder(0.005, 0.15, holder + Vector3(-0.01, 0.1, 0.012), Vector3(-10.0, 0.0, -9.0), 6)
	# Papeles con bocetos (en azul, el croquis de una pieza), el cuaderno
	# cerrado encima y el calibrador.
	var papers: Vector3 = Vector3(-0.47, top, 0.16)
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.1)
	kit.box(Vector3(0.18, 0.002, 0.24), papers + Vector3(0.0, 0.001, 0.0), 0.0, Vector3(0.0, 12.0, 0.0))
	kit.paint(LookPalette.WINDOW_SILL, WorldPalette.Surface.SMOOTH, 0.1)
	kit.box(Vector3(0.18, 0.002, 0.24), papers + Vector3(0.02, 0.003, 0.01), 0.0, Vector3(0.0, -6.0, 0.0))
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(-6.0)), papers + Vector3(0.05, 0.0045, 0.06))
	kit.paint("3b7fe0")
	for line: Vector4 in SKETCH:
		kit.box(Vector3(line.z, 0.001, 0.003), Vector3(line.x, 0.0, line.y), 0.0, Vector3(0.0, line.w, 0.0))
	kit.origin = Transform3D.IDENTITY
	kit.paint(LookPalette.RUG_PATTERN[2], WorldPalette.Surface.FABRIC, 0.1)
	kit.box(Vector3(0.14, 0.012, 0.19), papers + Vector3(-0.03, 0.01, -0.04), 0.004, Vector3(0.0, 10.0, 0.0))
	kit.origin = Transform3D(Basis(Vector3.UP, deg_to_rad(28.0)), papers + Vector3(0.03, 0.0065, 0.1))
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.7)
	kit.box(Vector3(0.15, 0.005, 0.016), Vector3.ZERO, 0.0)
	kit.box(Vector3(0.01, 0.005, 0.04), Vector3(-0.07, 0.0, 0.026), 0.0)
	kit.box(Vector3(0.03, 0.008, 0.026), Vector3(-0.03, 0.002, 0.003), 0.002)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.6)
	kit.box(Vector3(0.02, 0.002, 0.012), Vector3(-0.03, 0.006, 0.003), 0.0)
	kit.origin = Transform3D.IDENTITY


## La silla: una caja de cartón cerrada con cinta, con su etiqueta y un cojín
## encima.
static func _seat(kit: KitMesh) -> void:
	var s: Vector3 = SEAT_POS
	var h: Vector3 = SEAT_SIZE / 2.0
	kit.paint(LookPalette.CARDBOARD, WorldPalette.Surface.CARDBOARD, 0.05)
	kit.box(SEAT_SIZE, s + Vector3(0.0, h.y, 0.0), 0.006)
	kit.paint(LookPalette.TAPE, WorldPalette.Surface.SMOOTH, 0.45)
	kit.box(Vector3(0.07, 0.003, SEAT_SIZE.z + 0.002), s + Vector3(0.0, SEAT_SIZE.y + 0.0015, 0.0), 0.0)
	kit.box(Vector3(0.07, 0.1, 0.003), s + Vector3(0.0, SEAT_SIZE.y - 0.05, h.z - 0.0005), 0.0)
	kit.paint(LookPalette.SHEET, WorldPalette.Surface.SMOOTH, 0.15)
	kit.box(Vector3(0.003, 0.1, 0.14), s + Vector3(-h.x - 0.001, 0.22, 0.02), 0.0)
	kit.paint(LookPalette.RUG_PATTERN[2])
	kit.box(Vector3(0.002, 0.03, 0.03), s + Vector3(-h.x - 0.003, 0.235, -0.025), 0.0)
	kit.box(Vector3(0.002, 0.006, 0.06), s + Vector3(-h.x - 0.003, 0.2, 0.035), 0.0)
	kit.paint(LookPalette.RUG_PATTERN[0], WorldPalette.Surface.FABRIC, 0.05)
	kit.blob(Vector3(0.17, 0.045, 0.17), s + Vector3(0.01, SEAT_SIZE.y + 0.04, 0.0), Vector3(0.0, 8.0, 0.0), 0.35, 0.6, Vector2.ONE, Vector2i(14, 8))


## Regleta en el piso bajo la mesa y los cables del monitor, la torre y la
## lámpara, que bajan por detrás del tablero.
static func _power_strip(kit: KitMesh) -> void:
	var p: Vector3 = POWER_STRIP_POS
	var size: Vector3 = POWER_STRIP_SIZE
	kit.paint(LookPalette.TRIM, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(size, p + Vector3(0.0, size.y / 2.0, 0.0), 0.008)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	for i: int in 3:
		kit.box(Vector3(0.03, 0.002, 0.03), p + Vector3(-0.06 + i * 0.05, size.y + 0.001, 0.0), 0.0)
	kit.glowing("e0453a", 1.4)
	kit.box(Vector3(0.016, 0.006, 0.022), p + Vector3(0.11, size.y + 0.002, 0.0), 0.0)
	var r: float = CABLE_RADIUS
	# En el piso, un poco más arriba que el radio: la curva no se hunde.
	var low: float = r * 1.2
	var back: float = -TABLE_SIZE.z / 2.0 - 0.06
	var m: Vector3 = MONITOR_POS
	var cables: Array[PackedVector3Array] = [
		PackedVector3Array([m + Vector3(0.0, 0.12, -0.32), Vector3(m.x + 0.02, TABLE_SIZE.y + 0.01, back - 0.02), Vector3(m.x + 0.05, 0.45, back), Vector3(m.x + 0.1, 0.06, back + 0.03), Vector3(p.x - 0.12, low, p.z - 0.07), Vector3(p.x - 0.06, size.y * 0.6, p.z - 0.02)]),
		PackedVector3Array([TOWER_POS + Vector3(0.0, 0.12, -TOWER_SIZE.z / 2.0), Vector3(TOWER_POS.x - 0.02, TABLE_SIZE.y + 0.01, back - 0.02), Vector3(0.36, 0.4, back), Vector3(0.24, 0.06, back + 0.03), Vector3(p.x + 0.07, low, p.z - 0.06), Vector3(p.x + 0.04, size.y * 0.6, p.z - 0.02)]),
		PackedVector3Array([LAMP_BASE + Vector3(0.0, 0.008, -0.06), Vector3(LAMP_BASE.x - 0.02, TABLE_SIZE.y + 0.005, back - 0.02), Vector3(-0.48, 0.4, back), Vector3(-0.3, 0.05, back + 0.03), Vector3(p.x - 0.16, low, p.z - 0.04), Vector3(p.x - 0.11, size.y * 0.6, p.z)]),
	]
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	for cable: PackedVector3Array in cables:
		kit.tube(cable, r, 6, 3)


static func _marker(parent: Node3D, marker_name: String, position: Vector3) -> Marker3D:
	var marker: Marker3D = Marker3D.new()
	marker.name = marker_name
	marker.position = position
	parent.add_child(marker)
	return marker
