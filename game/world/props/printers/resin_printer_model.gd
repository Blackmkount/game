class_name ResinPrinterModel
extends RefCounted
## La Gota R1, "la de resina" (biblia de arte §9.3): base negra con la
## pantallita, una tina de aluminio con la resina, un riel Z atrás y la placa
## que sube; todo bajo una tapa ámbar transparente.
##
## La pieza cuelga bajo la placa y crece hacia abajo mientras la placa sube
## (PrinterView); si falla, cae a la tina.
##
## Partes aparte (contrato con PrinterView): "Plate" (la placa con su brazo:
## su origen es la cara de abajo de la placa), "Resin" (la resina de la tina:
## toma el color del trabajo, como el filamento), "Lid" (la tapa
## transparente, sin sombra: una llamada más) y "Display". Marcadores:
## "PieceAnchor" (la cara de abajo de la placa al empezar: sobre la resina),
## "PlateTop" (la placa arriba, sin trabajo o con la pieza lista),
## "VatFloor" (el fondo de la tina, donde cae la pieza que falla),
## "TrayAnchor" y "BedLight".

## Base (sin las patas), la tina y la resina, el riel y la placa (m).
const FEET_HEIGHT: float = 0.012
const BASE_SIZE: Vector3 = Vector3(0.28, 0.15, 0.32)
const VAT_Z: float = -0.01
const VAT_SIZE: Vector3 = Vector3(0.2, 0.025, 0.16)
const VAT_WALL: float = 0.006
const RESIN_TOP: float = 0.185
const RAIL_Z: float = -0.115
const RAIL_TOP: float = 0.44
const PLATE_SIZE: Vector3 = Vector3(0.15, 0.012, 0.13)
## Cuánto sube la placa sobre la pieza más alta (S) cuando está arriba.
const PLATE_TOP_GAP: float = 0.02
## La tapa ámbar: medio ancho, fondo (z) y alto de arriba.
const LID_HALF_X: float = 0.12
const LID_Z: Vector2 = Vector2(-0.14, 0.105)
const LID_TOP: float = 0.47
## Pantallita al frente de la base y la bandeja en el borde de adelante.
const DISPLAY: Vector3 = Vector3(0.0, 0.085, 0.1625)
const DISPLAY_SIZE: Vector2 = Vector2(0.09, 0.045)
const TRAY_ANCHOR: Vector3 = Vector3(-0.11, 0.162, 0.135)
## La tapa opaca de la malla lejana: cuánto de su color ámbar se ve sobre lo
## oscuro de adentro (más que su transparencia: la de cerca suma además el
## brillo del vidrio y lo claro de la tina).
const FAR_LID_TINT: float = 0.85


static func build(printer: Node3D, spool_color: String, detail: float) -> void:
	PrinterParts.body(printer, KitMesh.cached(PrinterParts.key("gota_r1", "body", detail), _body.bind(detail)))
	var anchor: Vector3 = Vector3(0.0, RESIN_TOP, VAT_Z)
	var top: float = RESIN_TOP + PieceModel.SIZES["S"].y + PLATE_TOP_GAP
	PrinterParts.marker(printer, "PieceAnchor", anchor)
	PrinterParts.marker(printer, "PlateTop", Vector3(anchor.x, top, anchor.z))
	PrinterParts.marker(printer, "VatFloor", Vector3(anchor.x, _base_top() + 0.004, anchor.z))
	PrinterParts.marker(printer, "TrayAnchor", TRAY_ANCHOR)
	PrinterParts.marker(printer, "BedLight", Vector3(0.0, 0.3, VAT_Z))
	PrinterParts.moving(printer, "Plate", KitMesh.cached(PrinterParts.key("gota_r1", "plate", detail), _plate.bind(detail)), detail, Vector3(0.0, top, 0.0))
	var resin: MeshInstance3D = PropBuilder.kit(printer, "Resin", KitMesh.cached("printer:gota_r1:resin", _resin), WorldPalette.solid(spool_color))
	resin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lid: MeshInstance3D = PropBuilder.kit(printer, "Lid", KitMesh.cached("printer:gota_r1:lid", _lid), WorldPalette.glass(LookPalette.RESIN_LID, LookPalette.RESIN_LID_ALPHA))
	lid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	PrinterParts.display(printer, DISPLAY_SIZE, DISPLAY)


static func _base_top() -> float:
	return FEET_HEIGHT + BASE_SIZE.y


## La malla lejana (PrinterParts.FAR_DETAIL): la base con menos detalle y
## la tapa ámbar opaca, del color que se ve a través de ella (con el zoom
## lejos la tapa transparente, la placa y la resina van escondidas).
static func far_body() -> ArrayMesh:
	return KitMesh.cached(PrinterParts.key("gota_r1", "far", PrinterParts.FAR_DETAIL), _body.bind(PrinterParts.FAR_DETAIL, true))


## Lo que se ve de la tapa ámbar con lo de adentro detrás (FAR_LID_TINT).
static func far_lid_hex() -> String:
	return Color(LookPalette.RESIN_BASE).lerp(Color(LookPalette.RESIN_LID), FAR_LID_TINT).to_html(false)


## La base con su zócalo de goma para la tapa, la pantalla LCD bajo la tina,
## la tina con sus trabas, el riel Z con su tornillo y el motor (en la malla
## lejana, `far_lid`, con la tapa opaca encima).
static func _body(detail: float, far_lid: bool = false) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	var top: float = _base_top()
	var half: Vector3 = BASE_SIZE / 2.0
	PrinterParts.feet(kit, Vector2(half.x - 0.035, half.z - 0.035))
	kit.ao_base = FEET_HEIGHT
	kit.paint(LookPalette.RESIN_BASE, WorldPalette.Surface.SMOOTH, 0.35)
	kit.box(BASE_SIZE, Vector3(0.0, FEET_HEIGHT + half.y, 0.0), 0.02)
	# Franja ámbar al frente y el botón de encendido.
	kit.paint(LookPalette.RESIN_LID, WorldPalette.Surface.SMOOTH, 0.45)
	kit.box(Vector3(BASE_SIZE.x - 0.05, 0.006, 0.003), Vector3(0.0, top - 0.03, half.z + 0.0015), 0.0)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.008, 0.006, Vector3(0.1, DISPLAY.y, half.z + 0.002), Vector3(90.0, 0.0, 0.0), 10)
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.5)
	kit.box(Vector3(DISPLAY_SIZE.x + 0.01, DISPLAY_SIZE.y + 0.008, 0.002), Vector3(DISPLAY.x, DISPLAY.y, half.z + 0.0005), 0.0)
	# Zócalo de goma donde apoya la tapa.
	kit.ao_base = top
	kit.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.2)
	var lid_mid_z: float = (LID_Z.x + LID_Z.y) / 2.0
	var lid_depth: float = LID_Z.y - LID_Z.x
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(0.008, 0.006, lid_depth + 0.008), Vector3(side * LID_HALF_X, top + 0.003, lid_mid_z), 0.0)
		kit.box(Vector3(LID_HALF_X * 2.0, 0.006, 0.008), Vector3(0.0, top + 0.003, lid_mid_z + side * lid_depth / 2.0), 0.0)
	# Pantalla LCD (vidrio oscuro con un brillo UV apenas) bajo la tina.
	kit.glowing("2f3a57", 0.15)
	kit.box(Vector3(VAT_SIZE.x + 0.02, 0.003, VAT_SIZE.z + 0.02), Vector3(0.0, top + 0.0015, VAT_Z), 0.0)
	# La tina: fondo y cuatro paredes de aluminio, y sus dos trabas.
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	var vat_half: Vector3 = VAT_SIZE / 2.0
	var vat_y: float = top + 0.003 + vat_half.y
	for side: float in KitMesh.SIGNS:
		kit.box(Vector3(VAT_WALL, VAT_SIZE.y, VAT_SIZE.z), Vector3(side * (vat_half.x - VAT_WALL / 2.0), vat_y, VAT_Z), 0.002)
		kit.box(Vector3(VAT_SIZE.x, VAT_SIZE.y, VAT_WALL), Vector3(0.0, vat_y, VAT_Z + side * (vat_half.z - VAT_WALL / 2.0)), 0.002)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.45)
	for side: float in KitMesh.SIGNS:
		kit.cylinder(0.01, 0.012, Vector3(side * (vat_half.x + 0.007), top + 0.012, VAT_Z), Vector3(0.0, 0.0, 90.0), 10)
	# Riel Z (perfil de aluminio con ranura), su tornillo y el motor abajo.
	var rail_height: float = RAIL_TOP - top
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.5)
	kit.box(Vector3(0.034, rail_height, 0.03), Vector3(0.0, top + rail_height / 2.0, RAIL_Z), 0.004)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	kit.box(Vector3(0.008, rail_height - 0.02, 0.002), Vector3(0.0, top + rail_height / 2.0, RAIL_Z + 0.0155), 0.0)
	kit.box(Vector3(0.045, 0.04, 0.04), Vector3(0.0, top + 0.02, RAIL_Z - 0.003), 0.005)
	kit.paint(LookPalette.METAL_BRASS, WorldPalette.Surface.METAL, 0.7)
	kit.cylinder(0.004, rail_height - 0.05, Vector3(0.025, top + rail_height / 2.0 + 0.02, RAIL_Z), Vector3.ZERO, 6)
	if far_lid:
		var bottom: float = top + 0.006
		kit.paint(far_lid_hex(), WorldPalette.Surface.SMOOTH, 0.7)
		kit.box(Vector3(LID_HALF_X * 2.0, LID_TOP - bottom, LID_Z.y - LID_Z.x), Vector3(0.0, (LID_TOP + bottom) / 2.0, (LID_Z.x + LID_Z.y) / 2.0), 0.0)
	return kit.commit()


## La placa (su cara de abajo en el origen), el soporte con la perilla, el
## brazo y el carro del riel.
static func _plate(detail: float) -> ArrayMesh:
	var kit: KitMesh = PrinterParts.kit(detail)
	kit.ao_enabled = false
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.65)
	kit.box(PLATE_SIZE, Vector3(0.0, PLATE_SIZE.y / 2.0, VAT_Z), 0.003)
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(0.05, 0.02, 0.05), Vector3(0.0, PLATE_SIZE.y + 0.01, VAT_Z), 0.004)
	kit.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	kit.cylinder(0.012, 0.014, Vector3(0.0, PLATE_SIZE.y + 0.027, VAT_Z), Vector3.ZERO, 12, 0.003)
	var rail_front: float = RAIL_Z + 0.015
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.METAL, 0.45)
	kit.box(Vector3(0.036, 0.016, VAT_Z - rail_front), Vector3(0.0, PLATE_SIZE.y + 0.012, (VAT_Z + rail_front) / 2.0), 0.003)
	kit.box(Vector3(0.06, 0.06, 0.024), Vector3(0.0, PLATE_SIZE.y + 0.02, rail_front + 0.012), 0.005)
	return kit.commit()


## La resina en la tina (su cara de arriba en RESIN_TOP).
static func _resin() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	var inner: Vector3 = VAT_SIZE - Vector3(VAT_WALL * 2.0, 0.0, VAT_WALL * 2.0)
	var bottom: float = _base_top() + 0.004
	kit.box(Vector3(inner.x, RESIN_TOP - bottom, inner.z), Vector3(0.0, (RESIN_TOP + bottom) / 2.0, VAT_Z), 0.0)
	return kit.commit()


## La tapa ámbar: cinco caras (sin fondo), un poco redondeadas arriba. Su
## material es transparente y se ve de los dos lados (WorldPalette.glass).
static func _lid() -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	kit.ao_enabled = false
	var bottom: float = _base_top() + 0.006
	var height: float = LID_TOP - bottom
	var mid_z: float = (LID_Z.x + LID_Z.y) / 2.0
	var depth: float = LID_Z.y - LID_Z.x
	var middle: float = bottom + height / 2.0
	kit.quad(Vector2(LID_HALF_X * 2.0, height), Vector3(0.0, middle, LID_Z.y))
	kit.quad(Vector2(LID_HALF_X * 2.0, height), Vector3(0.0, middle, LID_Z.x), Vector3(0.0, 180.0, 0.0))
	for side: float in KitMesh.SIGNS:
		kit.quad(Vector2(depth, height), Vector3(side * LID_HALF_X, middle, mid_z), Vector3(0.0, side * 90.0, 0.0))
	kit.quad(Vector2(LID_HALF_X * 2.0, depth), Vector3(0.0, LID_TOP, mid_z), Vector3(-90.0, 0.0, 0.0))
	return kit.commit()
