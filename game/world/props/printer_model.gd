class_name PrinterModel
extends RefCounted
## Modelo 3D de cada impresora (GDD §8, biblia de arte §9). Cada familia se ve
## distinta. El frente mira hacia +Z y la base queda en y = 0.
##
## La Cubo Uno (§9.3, "la clásica") es del kit: todo lo que no se mueve es UNA
## malla ("Body", con las tapas del carrete); lo que se mueve o cambia va
## aparte: "Gantry" (la barra X, sube con la pieza), "PrintHead" con
## "Carriage" (el cabezal, va y viene), "Display" (la pantallita) y
## "Spool/Filament" (el bobinado, toma el color del filamento). Marcadores
## (Marker3D) que lee PrinterView en vez de números fijos: "Bed" (marca que es
## abierta), "PieceAnchor" (la base de la pieza sobre la cama), "HeadRest" y
## "HeadPark" (el cabezal quieto y estacionado a un lado), "TrayAnchor" (el
## primer bloquecito de la bandeja) y "BedLight" (la barra LED que alumbra la
## cama). Valen lo mismo que las constantes de PrinterView (lo prueba
## tests/unit/test_printer_model.gd).
##
## Las otras seis familias todavía son de cajas (llegan en el paso 8 de Arte
## 2.0): sin marcadores, PrinterView usa sus constantes.

## Cubo Uno, en metros (escala 1). La cama (lámina PEI) y la pieza.
const CUBO_BED_TOP: float = 0.11
const CUBO_BED_Z: float = 0.03
const CUBO_BED_SIZE: float = 0.235
## Postes Z (perfil de aluminio negro) y la barra de arriba.
const CUBO_POST_X: float = 0.19
const CUBO_POST_Z: float = -0.09
const CUBO_FRAME_BOTTOM: float = 0.062
const CUBO_FRAME_TOP: float = 0.49
const CUBO_PROFILE: float = 0.04
## Barra X (Gantry): su profundidad; sube con el cabezal.
const CUBO_GANTRY_Z: float = -0.04
## El cabezal quieto (sobre la cama), estacionado a un lado y la punta de la
## boquilla bajo su origen (PrinterView deja HEAD_CLEARANCE entre el origen
## del cabezal y la pieza: la boquilla queda a 2 mm de la capa de arriba).
const CUBO_HEAD_REST: Vector3 = Vector3(0.0, 0.25, 0.0)
const CUBO_HEAD_PARK_X: float = -0.15
const CUBO_NOZZLE_TIP: float = -0.043
## Bandeja de piezas terminadas: sobre la caja de control, al frente.
const CUBO_TRAY_ANCHOR: Vector3 = Vector3(-0.15, 0.08, 0.18)
## Barra LED bajo la barra de arriba (alumbra la cama: cc_pl3).
const CUBO_BED_LIGHT: Vector3 = Vector3(0.0, 0.46, -0.07)
## Carrete arriba: centro y radio de las tapas (todo queda bajo MAX_HEIGHT).
const CUBO_SPOOL: Vector3 = Vector3(0.0, 0.618, CUBO_POST_Z)
const CUBO_SPOOL_RADIUS: float = 0.088
## Pantallita, abajo a la derecha de la caja de control.
const CUBO_DISPLAY: Vector3 = Vector3(0.14, 0.046, 0.2175)
const CUBO_DISPLAY_SIZE: Vector2 = Vector2(0.075, 0.042)
## Alto máximo de toda impresora, con su carrete (biblia §9.1: cabe en la
## estantería).
const MAX_HEIGHT: float = 0.72


static func build(parent: Node3D, node_name: String, printer_id: String, spool_color: String = "f2efe6") -> Node3D:
	var printer: Node3D = PropBuilder.group(parent, node_name)
	match printer_id:
		"cubo_uno":
			_cubo_uno(printer, spool_color)
		"rayo_mini", "rayo_x1":
			_open_frame(printer, LookPalette.PRINTER_WHITE, LookPalette.PRINTER_GREEN, spool_color, frame_scale(printer_id))
		"prisma_mc":
			_open_frame(printer, LookPalette.PRINTER_WHITE, LookPalette.PRINTER_PURPLE, spool_color, frame_scale(printer_id))
			_color_box(printer, Vector3(0.0, 0.62, -0.05))
		"boveda_p1", "titan_pro":
			_enclosed(printer, printer_id == "titan_pro", spool_color)
		"gota_r1":
			_resin(printer)
		_:
			_open_frame(printer, WorldPalette.METAL_MID, WorldPalette.ACCENT_BLUE, spool_color, frame_scale(printer_id))
	return printer


## Escala del modelo de las impresoras abiertas: la Rayo Mini es más chica.
## PrinterView la usa para ubicar la pieza, el cabezal y la bandeja.
static func frame_scale(printer_id: String) -> float:
	return 0.82 if printer_id == "rayo_mini" else 1.0


## Cubo Uno (biblia §9.3): cama móvil con dos postes Z de perfil con ranura,
## cama PEI dorada con perillas amarillas, cabezal con el ventilador azul y la
## boquilla de latón, tubo PTFE en arco, caja de control con la pantallita
## abajo a la derecha y el carrete de tapas abiertas arriba.
static func _cubo_uno(printer: Node3D, spool_color: String) -> void:
	PropBuilder.kit(printer, "Body", KitMesh.cached("printer:cubo_uno:body", _cubo_body))
	_marker(printer, "Bed", Vector3(0.0, CUBO_BED_TOP, CUBO_BED_Z))
	_marker(printer, "PieceAnchor", Vector3(0.0, CUBO_BED_TOP, CUBO_BED_Z))
	_marker(printer, "HeadRest", CUBO_HEAD_REST)
	_marker(printer, "HeadPark", Vector3(CUBO_HEAD_PARK_X, CUBO_HEAD_REST.y, CUBO_HEAD_REST.z))
	_marker(printer, "TrayAnchor", CUBO_TRAY_ANCHOR)
	_marker(printer, "BedLight", CUBO_BED_LIGHT)
	PropBuilder.kit(printer, "Gantry", KitMesh.cached("printer:cubo_uno:gantry", _cubo_gantry), null, Vector3(0.0, CUBO_HEAD_REST.y, CUBO_GANTRY_Z))
	var head: Node3D = PropBuilder.group(printer, "PrintHead", CUBO_HEAD_REST)
	PropBuilder.kit(head, "Carriage", KitMesh.cached("printer:cubo_uno:head", _cubo_head))
	var display: MeshInstance3D = PropBuilder.quad(printer, "Display", CUBO_DISPLAY_SIZE, CUBO_DISPLAY, WorldPalette.glow("ffffff", "printer_display"))
	display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	SpoolModel.build(printer, "Spool", CUBO_SPOOL, spool_color, CUBO_SPOOL_RADIUS, false)


## Lo fijo de la Cubo Uno: base, cama, postes, barra LED, portacarrete y las
## tapas del carrete.
static func _cubo_body() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	var frame: String = LookPalette.CUBE_FRAME
	var ink: String = LookPalette.OUTLINE
	# Patas de goma.
	kit.paint(ink, WorldPalette.Surface.SMOOTH, 0.2)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			kit.cylinder(0.017, 0.012, Vector3(0.2 * x, 0.006, 0.18 * z), Vector3.ZERO, 6)
	# Base: dos largueros, el travesaño de atrás y la caja de control al frente.
	kit.paint(frame, WorldPalette.Surface.METAL, 0.45)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(CUBO_PROFILE, 0.05, 0.4), Vector3(0.2 * x, 0.037, -0.005), 0.006)
	kit.box(Vector3(0.36, 0.04, CUBO_PROFILE), Vector3(0.0, 0.032, -0.185), 0.0)
	kit.box(Vector3(0.44, 0.068, 0.05), Vector3(0.0, 0.046, 0.19), 0.008)
	# Marco de la pantallita y perilla del menú.
	kit.paint(ink, WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(CUBO_DISPLAY_SIZE.x + 0.01, CUBO_DISPLAY_SIZE.y + 0.008, 0.002), CUBO_DISPLAY - Vector3(0.0, 0.0, 0.0015), 0.0)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.011, 0.012, Vector3(0.075, 0.046, 0.219), Vector3(90.0, 0.0, 0.0), 10)
	# Fuente de poder bajo la cama, atrás a la derecha (de ahí sale el cable).
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.35)
	kit.box(Vector3(0.09, 0.045, 0.14), Vector3(0.115, 0.0345, -0.095), 0.0)
	# Riel de la cama, carro, perillas para nivelar, placa y lámina PEI dorada.
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.5)
	kit.box(Vector3(CUBO_PROFILE, 0.018, 0.355), Vector3(0.0, 0.071, -0.015), 0.0)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(0.22, 0.008, 0.22), Vector3(0.0, 0.084, CUBO_BED_Z), 0.003)
	kit.paint(LookPalette.KNOBS, WorldPalette.Surface.SMOOTH, 0.5)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			kit.cylinder(0.017, 0.01, Vector3(0.105 * x, 0.093, CUBO_BED_Z + 0.105 * z), Vector3.ZERO, 10)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.55)
	kit.box(Vector3(CUBO_BED_SIZE, 0.008, CUBO_BED_SIZE), Vector3(0.0, CUBO_BED_TOP - 0.008, CUBO_BED_Z), 0.002)
	kit.paint(LookPalette.PEI_BED, WorldPalette.Surface.PEI, 0.35)
	kit.box(Vector3(CUBO_BED_SIZE - 0.006, 0.004, CUBO_BED_SIZE - 0.006), Vector3(0.0, CUBO_BED_TOP - 0.002, CUBO_BED_Z), 0.0)
	# Postes Z y la barra de arriba, con su ranura.
	var post_height: float = CUBO_FRAME_TOP - CUBO_FRAME_BOTTOM
	var post_y: float = (CUBO_FRAME_TOP + CUBO_FRAME_BOTTOM) / 2.0
	var bar_y: float = CUBO_FRAME_TOP + 0.017
	kit.paint(frame, WorldPalette.Surface.METAL, 0.45)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.034, post_height, CUBO_PROFILE), Vector3(CUBO_POST_X * x, post_y, CUBO_POST_Z), 0.005)
	kit.box(Vector3(0.414, 0.034, CUBO_PROFILE), Vector3(0.0, bar_y, CUBO_POST_Z), 0.006)
	kit.paint(ink)
	var front: float = CUBO_POST_Z + CUBO_PROFILE / 2.0 + 0.0005
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.008, post_height - 0.03, 0.002), Vector3(CUBO_POST_X * x, post_y, front), 0.0)
	kit.box(Vector3(0.002, post_height - 0.03, 0.008), Vector3(CUBO_POST_X + 0.0175, post_y, CUBO_POST_Z), 0.0)
	kit.box(Vector3(0.37, 0.008, 0.002), Vector3(0.0, bar_y, front), 0.0)
	# Motor Z abajo a la izquierda y su tornillo de bronce.
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.042, 0.042, 0.042), Vector3(-0.15, CUBO_FRAME_BOTTOM + 0.021, CUBO_POST_Z), 0.005)
	kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.7)
	kit.cylinder(0.004, 0.37, Vector3(-0.15, CUBO_FRAME_BOTTOM + 0.042 + 0.185, CUBO_POST_Z), Vector3.ZERO, 6)
	# Barra LED bajo la barra de arriba (siempre encendida): la luz se ve en
	# su canto de adelante, de abajo (la cámara mira desde arriba).
	var led_front: float = CUBO_BED_LIGHT.z + 0.004
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.3, 0.012, 0.024), Vector3(0.0, CUBO_FRAME_TOP - 0.006, led_front - 0.012), 0.003)
	kit.glowing(LookPalette.BED_LED, 1.2)
	kit.box(Vector3(0.27, 0.005, 0.003), Vector3(0.0, CUBO_FRAME_TOP - 0.0085, led_front + 0.001), 0.0)
	# Portacarrete impreso (con sus capas), el eje y las tapas abiertas.
	var arm_bottom: float = CUBO_FRAME_TOP + 0.034
	kit.printed(LookPalette.CUBE_ACCENT, 0.004)
	kit.box(Vector3(0.02, CUBO_SPOOL.y + 0.012 - arm_bottom, 0.03), Vector3(-0.05, (CUBO_SPOOL.y + 0.012 + arm_bottom) / 2.0, CUBO_POST_Z), 0.004)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.006, 0.095, Vector3(-0.0075, CUBO_SPOOL.y, CUBO_POST_Z), Vector3(0.0, 0.0, 90.0), 8)
	SpoolModel.add_flanges(kit, CUBO_SPOOL, CUBO_SPOOL_RADIUS)
	return kit.commit()


## La barra X (sube con la pieza): perfil con su correa, las placas que
## abrazan los postes, el motor X a la izquierda y la polea a la derecha.
static func _cubo_gantry() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	var inner: float = CUBO_POST_X - 0.017
	kit.paint(LookPalette.CUBE_FRAME, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(inner * 2.0, 0.028, 0.026), Vector3.ZERO, 0.004)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.058, 0.056, 0.016), Vector3(CUBO_POST_X * x, 0.0, -0.021), 0.004)
	kit.paint(LookPalette.OUTLINE)
	kit.box(Vector3(inner * 2.0 - 0.04, 0.006, 0.002), Vector3(0.0, 0.0, 0.0135), 0.0)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.042, 0.042, 0.036), Vector3(-0.205, 0.0, 0.006), 0.005)
	kit.box(Vector3(0.024, 0.03, 0.03), Vector3(CUBO_POST_X + 0.012, 0.0, 0.006), 0.0)
	return kit.commit()


## El cabezal (extrusor directo): placa, extrusor arriba, cubierta con el
## ventilador azul, bloque calefactor, la boquilla de latón (la punta en
## CUBO_NOZZLE_TIP, sobre el centro de la cama) y el tubo PTFE que sube en
## arco hacia el carrete.
static func _cubo_head() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	var nozzle_z: float = CUBO_BED_Z - CUBO_HEAD_REST.z
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.062, 0.068, 0.008), Vector3(0.0, 0.006, -0.023), 0.003)
	kit.box(Vector3(0.042, 0.03, 0.04), Vector3(0.0, 0.049, 0.004), 0.005)
	kit.paint(LookPalette.CUBE_FRAME, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.056, 0.058, 0.066), Vector3(0.0, 0.005, 0.014), 0.008)
	kit.paint(LookPalette.CUBE_ACCENT, WorldPalette.Surface.SMOOTH, 0.45)
	kit.cylinder(0.021, 0.004, Vector3(0.0, 0.006, 0.049), Vector3(90.0, 0.0, 0.0), 14)
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.3)
	kit.cylinder(0.008, 0.003, Vector3(0.0, 0.006, 0.0515), Vector3(90.0, 0.0, 0.0), 8)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.box(Vector3(0.022, 0.012, 0.02), Vector3(0.0, -0.03, nozzle_z), 0.002)
	kit.paint(LookPalette.NOZZLE, WorldPalette.Surface.METAL, 0.85)
	kit.cylinder(0.0025, 0.008, Vector3(0.0, CUBO_NOZZLE_TIP + 0.004, nozzle_z), Vector3.ZERO, 8, 0.0, 0.0065)
	kit.paint(LookPalette.DRAWSTRINGS, WorldPalette.Surface.SMOOTH, 0.5)
	kit.tube(PackedVector3Array([Vector3(0.0, 0.06, 0.004), Vector3(0.0, 0.115, -0.006), Vector3(0.025, 0.162, -0.024), Vector3(0.068, 0.178, -0.045), Vector3(0.1, 0.16, -0.062)]), 0.0045, 6, 3)
	return kit.commit()


## Un punto con nombre en el modelo, que la vista lee (Marker3D).
static func _marker(printer: Node3D, marker_name: String, position: Vector3) -> Marker3D:
	var marker: Marker3D = Marker3D.new()
	marker.name = marker_name
	marker.position = position
	printer.add_child(marker)
	return marker


## Impresora abierta de cama móvil de cajas (Rayo Mini, Rayo X1, Prisma MC),
## hasta que pase al kit (paso 8 de Arte 2.0).
static func _open_frame(printer: Node3D, frame_hex: String, accent_hex: String, spool_color: String, size: float) -> void:
	var frame: Material = WorldPalette.paint(frame_hex, WorldPalette.Surface.SMOOTH, 0.3)
	var dark: Material = WorldPalette.paint(WorldPalette.PLASTIC_BLACK, WorldPalette.Surface.SMOOTH, 0.3)
	var metal: Material = WorldPalette.paint(WorldPalette.METAL_MID, WorldPalette.Surface.METAL, 0.4)
	var s: float = size
	PropBuilder.box(printer, "Base", Vector3(0.44, 0.08, 0.42) * s, Vector3(0.0, 0.04, 0.0) * s, frame)
	PropBuilder.box(printer, "Bed", Vector3(0.28, 0.02, 0.28) * s, Vector3(0.0, 0.1, 0.03) * s, WorldPalette.paint(WorldPalette.PRINT_BED, WorldPalette.Surface.PEI, 0.35))
	PropBuilder.box(printer, "LeftPost", Vector3(0.035, 0.44, 0.04) * s, Vector3(-0.19, 0.3, -0.09) * s, frame)
	PropBuilder.box(printer, "RightPost", Vector3(0.035, 0.44, 0.04) * s, Vector3(0.19, 0.3, -0.09) * s, frame)
	PropBuilder.box(printer, "TopBar", Vector3(0.415, 0.035, 0.04) * s, Vector3(0.0, 0.535, -0.09) * s, frame)
	PropBuilder.box(printer, "Gantry", Vector3(0.38, 0.03, 0.03) * s, Vector3(0.0, 0.25, -0.06) * s, metal)
	var head: Node3D = PropBuilder.group(printer, "PrintHead", Vector3(-0.05, 0.25, -0.02) * s)
	PropBuilder.box(head, "Carriage", Vector3(0.07, 0.08, 0.05) * s, Vector3.ZERO, dark)
	PropBuilder.box(head, "Fan", Vector3(0.05, 0.05, 0.01) * s, Vector3(0.0, 0.0, 0.03) * s, WorldPalette.paint(accent_hex, WorldPalette.Surface.SMOOTH, 0.3))
	PropBuilder.quad(printer, "Display", Vector2(0.1, 0.05) * s, Vector3(0.14, 0.05, 0.215) * s, WorldPalette.glow("ffffff", "printer_display"))
	PropBuilder.box(printer, "SpoolArm", Vector3(0.03, 0.08, 0.03) * s, Vector3(0.0, 0.59, -0.09) * s, frame)
	SpoolModel.build(printer, "Spool", Vector3(0.0, 0.64, -0.09) * s, spool_color, 0.09 * s)


## Impresora cerrada tipo caja (Bóveda P1, Titán Pro).
static func _enclosed(printer: Node3D, large: bool, spool_color: String) -> void:
	var s: float = 1.3 if large else 1.0
	var body: Material = WorldPalette.paint(WorldPalette.PLASTIC_BLACK, WorldPalette.Surface.SMOOTH, 0.3)
	PropBuilder.box(printer, "Body", Vector3(0.4, 0.46, 0.4) * s, Vector3(0.0, 0.23, 0.0) * s, body)
	PropBuilder.quad(printer, "Window", Vector2(0.3, 0.3) * s, Vector3(0.0, 0.25, 0.201) * s, WorldPalette.glow("ffcf7a"))
	PropBuilder.box(printer, "Part", Vector3(0.08, 0.1, 0.08) * s, Vector3(0.0, 0.16, 0.12) * s, WorldPalette.solid(spool_color))
	PropBuilder.quad(printer, "Display", Vector2(0.08, 0.05) * s, Vector3(-0.12, 0.06, 0.201) * s, WorldPalette.glow("ffffff", "printer_display"))
	if large:
		_color_box(printer, Vector3(0.0, 0.62, -0.02))


## Caja de colores para impresoras multicolor.
static func _color_box(printer: Node3D, position: Vector3) -> void:
	var box: Node3D = PropBuilder.group(printer, "ColorBox", position)
	PropBuilder.box(box, "Case", Vector3(0.38, 0.1, 0.16), Vector3.ZERO, WorldPalette.paint(LookPalette.PRINTER_WHITE, WorldPalette.Surface.SMOOTH, 0.3))
	var colors: Array[String] = ["e0453a", "f5cf3c", "3b7fe0", "4cbf5a"]
	for i: int in colors.size():
		PropBuilder.box(box, "Color%d" % i, Vector3(0.06, 0.04, 0.01), Vector3(-0.13 + i * 0.087, 0.0, 0.08), WorldPalette.paint(colors[i], WorldPalette.Surface.SMOOTH, 0.3))


## Impresora de resina: base y tapa ámbar.
static func _resin(printer: Node3D) -> void:
	PropBuilder.box(printer, "Base", Vector3(0.3, 0.14, 0.3), Vector3(0.0, 0.07, 0.0), WorldPalette.paint(WorldPalette.PLASTIC_BLACK, WorldPalette.Surface.SMOOTH, 0.3))
	PropBuilder.box(printer, "Lid", Vector3(0.26, 0.3, 0.26), Vector3(0.0, 0.29, 0.0), WorldPalette.paint(LookPalette.RESIN_LID, WorldPalette.Surface.SMOOTH, 0.6))
	PropBuilder.quad(printer, "Display", Vector2(0.1, 0.05), Vector3(0.0, 0.07, 0.151), WorldPalette.glow("ffffff", "printer_display"))
