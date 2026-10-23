class_name PrinterParts
extends RefCounted
## Lo que comparten los modelos de las impresoras (biblia de arte §9 y
## §5.1–5.2): el detalle según dónde están, los marcadores que lee
## PrinterView, la pantallita, el carrete, las patas y la boquilla.
##
## Cada familia es UNA malla fija ("Body", con el material del kit) más las
## partes que se mueven o cambian de material, que van aparte porque son
## contratos con PrinterView. En los muebles (detalle < FLOOR_DETAIL) solo
## "Body" da sombra: así una impresora de mueble cuesta 6 llamadas.
##
## Con el zoom lejos (PrinterView.set_far) "Body" cambia a su malla lejana
## (PrinterModel.far_body, detalle FAR_DETAIL): lo fijo con menos detalle y,
## dentro, lo que en la versión normal va aparte y no se mueve (el bobinado
## del carrete, en su color de siempre); lo que se mueve se esconde.

## Detalle de la impresora del piso y de las de los muebles (biblia §5.1).
const FLOOR_DETAIL: float = 1.0
const FURNITURE_DETAIL: float = 0.6
## Detalle de la versión lejana (biblia §5.1 y §5.2: ≤ 450 triángulos).
const FAR_DETAIL: float = 0.35
## Con menos detalle que el del piso, los biseles más chicos que esto (m) no
## se hacen (KitMesh.bevel_cutoff): de lejos no se ven y cuestan triángulos.
## En la versión lejana, tampoco los de hasta FAR_BEVEL_CUTOFF, ni lo más
## fino que FAR_MIN_FEATURE (ranuras, tornillos, franjas: KitMesh.min_feature).
const LOW_DETAIL_BEVEL_CUTOFF: float = 0.009
const FAR_BEVEL_CUTOFF: float = 0.025
const FAR_MIN_FEATURE: float = 0.016
## La punta de la boquilla queda esto bajo el origen del cabezal (escala 1):
## con PrinterView.HEAD_CLEARANCE, a 2 mm de la capa de arriba.
const NOZZLE_TIP: float = -0.043
## Alto de las patas de goma.
const FEET_HEIGHT: float = 0.012


## Un KitMesh con el detalle de la copia.
static func kit(detail: float) -> KitMesh:
	var mesh: KitMesh = KitMesh.new()
	mesh.detail = detail
	if detail >= FLOOR_DETAIL:
		mesh.bevel_cutoff = 0.0
	elif detail > FAR_DETAIL:
		mesh.bevel_cutoff = LOW_DETAIL_BEVEL_CUTOFF
	else:
		mesh.bevel_cutoff = FAR_BEVEL_CUTOFF
		mesh.min_feature = FAR_MIN_FEATURE
	return mesh


## Las copias que se ven chicas (detalle de mueble o menos): carretes con
## tapas simples, sin patas y curvas con menos tramos.
static func lean(detail: float) -> bool:
	return detail < FLOOR_DETAIL


## La versión lejana (detalle FAR_DETAIL o menos): además, sin patas y con
## las tapas del carrete llenas.
static func far(detail: float) -> bool:
	return detail <= FAR_DETAIL


## Las tapas del carrete de las abiertas (dentro de "Body"; el bobinado es
## "Spool/Filament"): abiertas, más simples en las copias chicas y, en la
## versión lejana, llenas y con el bobinado del color `far_spool` (ahí
## "Spool" va escondido).
static func spool_flanges(kit: KitMesh, center: Vector3, radius: float, far_spool: String = "") -> void:
	if far(kit.detail):
		SpoolModel.add_small(kit, center, radius, far_spool)
	else:
		SpoolModel.add_flanges(kit, center, radius, lean(kit.detail))


## Tramos entre cada par de puntos de un tubo (KitMesh.tube) según el detalle.
static func curve_steps(detail: float) -> int:
	return 3 if detail >= FLOOR_DETAIL else 1


## Clave de la caché de una malla de impresora: familia, parte, detalle y lo
## que la cambie además (un color).
static func key(family: String, part: String, detail: float, extra: String = "") -> String:
	return "printer:%s:%s:%.2f:%s" % [family, part, detail, extra]


## Un punto con nombre en el modelo, que la vista lee (Marker3D).
static func marker(printer: Node3D, marker_name: String, position: Vector3) -> Marker3D:
	var point: Marker3D = Marker3D.new()
	point.name = marker_name
	point.position = position
	printer.add_child(point)
	return point


## La malla fija de la impresora ("Body"), con el material del kit.
static func body(printer: Node3D, mesh: ArrayMesh) -> MeshInstance3D:
	return PropBuilder.kit(printer, "Body", mesh)


## Una parte que se mueve o cambia de material. En los muebles no da sombra
## (solo "Body", biblia §5.2); `shadow` = false la apaga también en el piso
## (lo que queda dentro de una impresora cerrada).
static func moving(parent: Node3D, part_name: String, mesh: ArrayMesh, detail: float, position: Vector3 = Vector3.ZERO, shadow: bool = true) -> MeshInstance3D:
	var part: MeshInstance3D = PropBuilder.kit(parent, part_name, mesh, null, position)
	if detail < FLOOR_DETAIL or not shadow:
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part


## La pantallita ("Display"): un cuadro que mira hacia +Z (girado con
## `rot_deg`); su material lo cambia PrinterView según el estado. Sin sombra.
static func display(printer: Node3D, size: Vector2, position: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var screen: MeshInstance3D = PropBuilder.quad(printer, "Display", size, position, WorldPalette.glow("ffffff", "printer_display"), rot_deg)
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return screen


## El carrete de las impresoras abiertas ("Spool/Filament", toma el color del
## filamento). Sus tapas van dentro de "Body" (SpoolModel.add_flanges).
static func spool(printer: Node3D, position: Vector3, color_hex: String, radius: float, detail: float) -> Node3D:
	var reel: Node3D = SpoolModel.build(printer, "Spool", position, color_hex, radius, detail)
	if detail < FLOOR_DETAIL:
		(reel.get_node("Filament") as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return reel


## Patas de goma en las cuatro esquinas de un rectángulo de medias medidas
## `half` (x, z) alrededor de `center` (en el piso), de FEET_HEIGHT de alto.
## Las copias chicas llevan cubitos (no se ven y cuestan menos); la lejana,
## nada.
static func feet(mesh: KitMesh, half: Vector2, center: Vector3 = Vector3.ZERO, radius: float = 0.016) -> void:
	if far(mesh.detail):
		return
	mesh.paint(LookPalette.OUTLINE, WorldPalette.Surface.SMOOTH, 0.2)
	for x: float in KitMesh.SIGNS:
		for z: float in KitMesh.SIGNS:
			var at: Vector3 = center + Vector3(half.x * x, FEET_HEIGHT / 2.0, half.y * z)
			if lean(mesh.detail):
				mesh.box(Vector3(radius * 2.0, FEET_HEIGHT, radius * 2.0), at, 0.0)
			else:
				mesh.cylinder(radius, FEET_HEIGHT, at, Vector3.ZERO, 6)


## Bloque calefactor de aluminio y boquilla de latón con la punta en
## NOZZLE_TIP × `size`, en (0, z) del cabezal.
static func nozzle(mesh: KitMesh, z: float, size: float = 1.0) -> void:
	mesh.paint(LookPalette.ALUMINIUM, WorldPalette.Surface.METAL, 0.6)
	mesh.box(Vector3(0.022, 0.012, 0.02) * size, Vector3(0.0, -0.03 * size, z), 0.002)
	mesh.paint(LookPalette.NOZZLE, WorldPalette.Surface.METAL, 0.85)
	mesh.cylinder(0.0025 * size, 0.008 * size, Vector3(0.0, (NOZZLE_TIP + 0.004) * size, z), Vector3.ZERO, 8, 0.0, 0.0065 * size)
