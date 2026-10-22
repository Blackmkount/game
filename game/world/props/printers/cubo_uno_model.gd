class_name CuboUnoModel
extends RefCounted
## La Cubo Uno (biblia de arte §9.3, "la clásica", tipo Ender): cama móvil
## con dos postes Z de perfil con ranura, cama PEI dorada con perillas
## amarillas, cabezal con el ventilador azul y la boquilla de latón, tubo PTFE
## en arco, caja de control con la pantallita abajo a la derecha y el carrete
## de tapas abiertas arriba.
##
## Todo lo que no se mueve es UNA malla ("Body", con las tapas del carrete);
## aparte: "Gantry" (la barra X, sube con la pieza), "PrintHead" con
## "Carriage" (el cabezal, va y viene), "Display" y "Spool/Filament".
## Marcadores (ver PrinterParts y PrinterView): "Bed" (marca que es
## abierta), "PieceAnchor", "HeadRest", "HeadPark", "TrayAnchor" y
## "BedLight". Sus lugares son las medidas de PrinterView (BED_TOP, PIECE_Z,
## HEAD_REST_Y, HEAD_PARK_X, TRAY_*): la Cubo Uno es la impresora de
## referencia (lo prueba tests/unit/test_printer_model.gd).

## La cama (lámina PEI) y la pieza, en metros.
const BED_TOP: float = PrinterView.BED_TOP
const BED_Z: float = PrinterView.PIECE_Z
const BED_SIZE: float = 0.235
## Postes Z (perfil de aluminio negro) y la barra de arriba.
const POST_X: float = 0.19
const POST_Z: float = -0.09
const FRAME_BOTTOM: float = 0.062
const FRAME_TOP: float = 0.49
const PROFILE: float = 0.04
## Barra X (Gantry): su profundidad; sube con el cabezal.
const GANTRY_Z: float = -0.04
## El cabezal quieto (sobre la cama), estacionado a un lado y la punta de la
## boquilla bajo su origen.
const HEAD_REST: Vector3 = Vector3(0.0, PrinterView.HEAD_REST_Y, 0.0)
const HEAD_PARK_X: float = PrinterView.HEAD_PARK_X
const NOZZLE_TIP: float = PrinterParts.NOZZLE_TIP
## Bandeja de piezas terminadas: sobre la caja de control, al frente.
const TRAY_ANCHOR: Vector3 = Vector3(PrinterView.TRAY_START_X, PrinterView.TRAY_BASE_Y, PrinterView.TRAY_Z)
## Barra LED bajo la barra de arriba (alumbra la cama: cc_pl3).
const BED_LIGHT: Vector3 = Vector3(0.0, 0.46, -0.07)
## Carrete arriba: centro y radio de las tapas (todo queda bajo
## PrinterModel.MAX_HEIGHT).
const SPOOL: Vector3 = Vector3(0.0, 0.618, POST_Z)
const SPOOL_RADIUS: float = 0.088
## Pantallita, abajo a la derecha de la caja de control.
const DISPLAY: Vector3 = Vector3(0.14, 0.046, 0.2175)
const DISPLAY_SIZE: Vector2 = Vector2(0.075, 0.042)


static func build(printer: Node3D, spool_color: String, detail: float) -> void:
	PrinterParts.body(printer, KitMesh.cached(PrinterParts.key("cubo_uno", "body", detail), _body.bind(detail)))
	PrinterParts.marker(printer, "Bed", Vector3(0.0, BED_TOP, BED_Z))
	PrinterParts.marker(printer, "PieceAnchor", Vector3(0.0, BED_TOP, BED_Z))
	PrinterParts.marker(printer, "HeadRest", HEAD_REST)
	PrinterParts.marker(printer, "HeadPark", Vector3(HEAD_PARK_X, HEAD_REST.y, HEAD_REST.z))
	PrinterParts.marker(printer, "TrayAnchor", TRAY_ANCHOR)
	PrinterParts.marker(printer, "BedLight", BED_LIGHT)
	PrinterParts.moving(printer, "Gantry", KitMesh.cached(PrinterParts.key("cubo_uno", "gantry", detail), _gantry.bind(detail)), detail, Vector3(0.0, HEAD_REST.y, GANTRY_Z))
	var head: Node3D = PropBuilder.group(printer, "PrintHead", HEAD_REST)
	PrinterParts.moving(head, "Carriage", KitMesh.cached(PrinterParts.key("cubo_uno", "head", detail), _head.bind(detail)), detail)
	PrinterParts.display(printer, DISPLAY_SIZE, DISPLAY)
	PrinterParts.spool(printer, SPOOL, spool_color, SPOOL_RADIUS, detail)


## Lo fijo de la Cubo Uno: base, cama, postes, barra LED, portacarrete y las
## tapas del carrete.
static func _body(detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	var frame: String = LookPalette.CUBE_FRAME
	var ink: String = LookPalette.OUTLINE
	PrinterParts.feet(kit, Vector2(0.2, 0.18), Vector3.ZERO, 0.017)
	# Base: dos largueros, el travesaño de atrás y la caja de control al frente.
	kit.paint(frame, WorldPalette.Surface.METAL, 0.45)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(PROFILE, 0.05, 0.4), Vector3(0.2 * x, 0.037, -0.005), 0.006)
	kit.box(Vector3(0.36, 0.04, PROFILE), Vector3(0.0, 0.032, -0.185), 0.0)
	kit.box(Vector3(0.44, 0.068, 0.05), Vector3(0.0, 0.046, 0.19), 0.008)
	# Marco de la pantallita y perilla del menú.
	kit.paint(ink, WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(DISPLAY_SIZE.x + 0.01, DISPLAY_SIZE.y + 0.008, 0.002), DISPLAY - Vector3(0.0, 0.0, 0.0015), 0.0)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.011, 0.012, Vector3(0.075, 0.046, 0.219), Vector3(90.0, 0.0, 0.0), 10)
	# Fuente de poder bajo la cama, atrás a la derecha (de ahí sale el cable).
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.35)
	kit.box(Vector3(0.09, 0.045, 0.14), Vector3(0.115, 0.0345, -0.095), 0.0)
	# Riel de la cama, carro, perillas para nivelar, placa y lámina PEI dorada.
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.5)
	kit.box(Vector3(PROFILE, 0.018, 0.355), Vector3(0.0, 0.071, -0.015), 0.0)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(0.22, 0.008, 0.22), Vector3(0.0, 0.084, BED_Z), 0.003)
	kit.paint(LookPalette.KNOBS, WorldPalette.Surface.SMOOTH, 0.5)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			kit.cylinder(0.017, 0.01, Vector3(0.105 * x, 0.093, BED_Z + 0.105 * z), Vector3.ZERO, 10)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.55)
	kit.box(Vector3(BED_SIZE, 0.008, BED_SIZE), Vector3(0.0, BED_TOP - 0.008, BED_Z), 0.002)
	kit.paint(LookPalette.PEI_BED, WorldPalette.Surface.PEI, 0.35)
	kit.box(Vector3(BED_SIZE - 0.006, 0.004, BED_SIZE - 0.006), Vector3(0.0, BED_TOP - 0.002, BED_Z), 0.0)
	# Postes Z y la barra de arriba, con su ranura.
	var post_height: float = FRAME_TOP - FRAME_BOTTOM
	var post_y: float = (FRAME_TOP + FRAME_BOTTOM) / 2.0
	var bar_y: float = FRAME_TOP + 0.017
	kit.paint(frame, WorldPalette.Surface.METAL, 0.45)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.034, post_height, PROFILE), Vector3(POST_X * x, post_y, POST_Z), 0.005)
	kit.box(Vector3(0.414, 0.034, PROFILE), Vector3(0.0, bar_y, POST_Z), 0.006)
	kit.paint(ink)
	var front: float = POST_Z + PROFILE / 2.0 + 0.0005
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.008, post_height - 0.03, 0.002), Vector3(POST_X * x, post_y, front), 0.0)
	kit.box(Vector3(0.002, post_height - 0.03, 0.008), Vector3(POST_X + 0.0175, post_y, POST_Z), 0.0)
	kit.box(Vector3(0.37, 0.008, 0.002), Vector3(0.0, bar_y, front), 0.0)
	# Motor Z abajo a la izquierda y su tornillo de bronce.
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.042, 0.042, 0.042), Vector3(-0.15, FRAME_BOTTOM + 0.021, POST_Z), 0.005)
	kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.7)
	kit.cylinder(0.004, 0.37, Vector3(-0.15, FRAME_BOTTOM + 0.042 + 0.185, POST_Z), Vector3.ZERO, 6)
	# Barra LED bajo la barra de arriba (siempre encendida): la luz se ve en
	# su canto de adelante, de abajo (la cámara mira desde arriba).
	var led_front: float = BED_LIGHT.z + 0.004
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.4)
	kit.box(Vector3(0.3, 0.012, 0.024), Vector3(0.0, FRAME_TOP - 0.006, led_front - 0.012), 0.003)
	kit.glowing(LookPalette.BED_LED, 1.2)
	kit.box(Vector3(0.27, 0.005, 0.003), Vector3(0.0, FRAME_TOP - 0.0085, led_front + 0.001), 0.0)
	# Portacarrete impreso (con sus capas), el eje y las tapas abiertas.
	var arm_bottom: float = FRAME_TOP + 0.034
	kit.printed(LookPalette.CUBE_ACCENT, 0.004)
	kit.box(Vector3(0.02, SPOOL.y + 0.012 - arm_bottom, 0.03), Vector3(-0.05, (SPOOL.y + 0.012 + arm_bottom) / 2.0, POST_Z), 0.004)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.006, 0.095, Vector3(-0.0075, SPOOL.y, POST_Z), Vector3(0.0, 0.0, 90.0), 8)
	SpoolModel.add_flanges(kit, SPOOL, SPOOL_RADIUS, PrinterParts.lean(detail))
	return kit.commit()


## La barra X (sube con la pieza): perfil con su correa, las placas que
## abrazan los postes, el motor X a la izquierda y la polea a la derecha.
static func _gantry(detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	var inner: float = POST_X - 0.017
	kit.paint(LookPalette.CUBE_FRAME, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(inner * 2.0, 0.028, 0.026), Vector3.ZERO, 0.004)
	kit.paint(LookPalette.METAL_MID, WorldPalette.Surface.METAL, 0.45)
	for x: float in KitMesh.SIGNS:
		kit.box(Vector3(0.058, 0.056, 0.016), Vector3(POST_X * x, 0.0, -0.021), 0.004)
	kit.paint(LookPalette.OUTLINE)
	kit.box(Vector3(inner * 2.0 - 0.04, 0.006, 0.002), Vector3(0.0, 0.0, 0.0135), 0.0)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.4)
	kit.box(Vector3(0.042, 0.042, 0.036), Vector3(-0.205, 0.0, 0.006), 0.005)
	kit.box(Vector3(0.024, 0.03, 0.03), Vector3(POST_X + 0.012, 0.0, 0.006), 0.0)
	return kit.commit()


## El cabezal (extrusor directo): placa, extrusor arriba, cubierta con el
## ventilador azul, bloque calefactor, la boquilla de latón (la punta en
## NOZZLE_TIP, sobre el centro de la cama) y el tubo PTFE que sube en
## arco hacia el carrete.
static func _head(detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	var nozzle_z: float = BED_Z - HEAD_REST.z
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
	kit.cylinder(0.0025, 0.008, Vector3(0.0, NOZZLE_TIP + 0.004, nozzle_z), Vector3.ZERO, 8, 0.0, 0.0065)
	kit.paint(LookPalette.DRAWSTRINGS, WorldPalette.Surface.SMOOTH, 0.5)
	kit.tube(PackedVector3Array([Vector3(0.0, 0.06, 0.004), Vector3(0.0, 0.115, -0.006), Vector3(0.025, 0.162, -0.024), Vector3(0.068, 0.178, -0.045), Vector3(0.1, 0.16, -0.062)]), 0.0045, 6, PrinterParts.curve_steps(detail))
	return kit.commit()
