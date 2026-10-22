class_name SpoolModel
extends RefCounted
## Carrete de filamento (biblia de arte §9.4): dos tapas abiertas gris claro
## (un aro y cuatro rayos, un 10 % más grandes que el bobinado), el centro
## gris y el bobinado del color del filamento. Queda acostado, con el eje a lo
## largo de X: siempre se ve la banda de color, nunca un "disco negro".
##
## "Filament" (el bobinado) va aparte: su material lo cambia la vista con
## WorldPalette.solid(color). Su malla se arma a lo largo de Y y el nodo se
## acuesta, así las capas del plástico impreso (que siguen el eje del objeto,
## ver kit_body.gdshaderinc) dibujan los surcos del enrollado alrededor del eje.
## En las impresoras las tapas van dentro de la malla de la impresora
## (`flanges = false` y add_flanges()).

## Medidas respecto del radio de las tapas: ancho de todo el carrete, grosor
## de cada tapa, el bobinado (las tapas son un 10 % más grandes), el núcleo,
## el aro de las tapas, el centro y sus rayos.
const WIDTH: float = 0.68
const FLANGE_THICKNESS: float = 0.06
const WINDING: float = 1.0 / 1.1
const CORE: float = 0.42
const RING_INNER: float = 0.84
const HUB: float = 0.3
const AXLE_HOLE: float = 0.09
const SPOKE_WIDTH: float = 0.14
## Lados de lo redondo (con detail 1).
const SIDES: int = 20
const HUB_SIDES: int = 10
## Lados de los carretes guardados en los muebles (con detail 1; con el de
## los muebles, FurnitureParts.DETAIL, quedan en 10): se ven chicos y van
## muchos en una malla.
const SHELF_SIDES: int = 12


## `detail` multiplica los lados del bobinado y de las tapas (biblia §5.1).
static func build(parent: Node3D, node_name: String, position: Vector3, color_hex: String, radius: float = 0.1, flanges: bool = true, detail: float = 1.0) -> Node3D:
	var spool: Node3D = PropBuilder.group(parent, node_name, position)
	var filament: MeshInstance3D = PropBuilder.kit(spool, "Filament", winding_mesh(radius, detail), WorldPalette.solid(color_hex))
	# La malla va a lo largo de Y: acostada, el eje queda en X.
	filament.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	if flanges:
		var mesh: ArrayMesh = KitMesh.cached("spool_flanges:%.3f:%.2f" % [radius, detail], func() -> ArrayMesh:
			var kit: KitMesh = KitMesh.new()
			kit.ao_enabled = false
			kit.detail = detail
			add_flanges(kit, Vector3.ZERO, radius)
			return kit.commit())
		PropBuilder.kit(spool, "Flanges", mesh)
	return spool


## El bobinado: un anillo grueso del núcleo al borde, con los cantos
## redondeados. A lo largo de Y y centrado en el origen.
static func winding_mesh(radius: float, detail: float = 1.0) -> ArrayMesh:
	return KitMesh.cached("spool_winding:%.3f:%.2f" % [radius, detail], func() -> ArrayMesh:
		var kit: KitMesh = KitMesh.new()
		kit.ao_enabled = false
		kit.detail = detail
		kit.lathe(_winding_profile(radius), Vector3.ZERO, Vector3.ZERO, SIDES)
		return kit.commit())


## Un bobinado fijo del color `hex`, acostado (eje en X) con el centro en
## `center`, dentro de `kit`: el carrete de las impresoras cerradas, que no
## cambia de color (no está a la vista del todo).
static func add_winding(kit: KitMesh, center: Vector3, radius: float, hex: String) -> void:
	kit.paint(hex, WorldPalette.Surface.SMOOTH, WorldPalette.PRINTED_GLOSS)
	kit.lathe(_winding_profile(radius), center, Vector3(0.0, 0.0, 90.0), SIDES)


## Las dos tapas abiertas y su centro, en `kit`, para un carrete acostado (eje
## en X) con el centro en `center`. `lean` (las copias que se ven chicas): el
## centro sin agujero y dos rayos cruzados en vez de cuatro.
static func add_flanges(kit: KitMesh, center: Vector3, radius: float, lean: bool = false) -> void:
	var thickness: float = radius * FLANGE_THICKNESS
	var t: float = thickness / 2.0
	var ring: PackedVector2Array = _ring_profile(radius * RING_INNER, radius, t)
	var hub: PackedVector2Array = _ring_profile(radius * AXLE_HOLE, radius * HUB, t * 1.6)
	var spoke_length: float = radius * (RING_INNER - HUB) + thickness
	var spoke_middle: float = radius * (RING_INNER + HUB) / 2.0
	var sideways: Vector3 = Vector3(0.0, 0.0, 90.0)
	for side: float in KitMesh.SIGNS:
		var face: Vector3 = center + Vector3(side * radius * (WIDTH / 2.0 - FLANGE_THICKNESS / 2.0), 0.0, 0.0)
		kit.paint(LookPalette.SPOOL_FLANGE, WorldPalette.Surface.SMOOTH, 0.35)
		kit.lathe(ring, face, sideways, SIDES)
		if lean:
			for angle: float in [45.0, 135.0]:
				kit.box(Vector3(thickness, radius * RING_INNER * 2.0 + thickness, radius * SPOKE_WIDTH), face, 0.0, Vector3(angle, 0.0, 0.0))
		else:
			for i: int in 4:
				var angle: float = 45.0 + 90.0 * i
				var out: Vector3 = Vector3(0.0, cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * spoke_middle
				kit.box(Vector3(thickness, spoke_length, radius * SPOKE_WIDTH), face + out, 0.0, Vector3(angle, 0.0, 0.0))
		kit.paint(LookPalette.SPOOL_HUB, WorldPalette.Surface.SMOOTH, 0.3)
		if lean:
			kit.cylinder(radius * HUB, thickness * 1.6, face, sideways, HUB_SIDES)
		else:
			kit.lathe(hub, face, sideways, HUB_SIDES)


## Un carrete chico y simple (los de las cajas de color, o uno que se ve
## chico): dos tapas llenas (sin ellas si no `flanges`) y el bobinado del
## color `hex` (sin él si `hex` está vacío: el bobinado va aparte,
## "Spool/Filament"), acostado (eje en X) con el centro en `center`. Pocos
## triángulos.
static func add_small(kit: KitMesh, center: Vector3, radius: float, hex: String = "", flanges: bool = true) -> void:
	var sideways: Vector3 = Vector3(0.0, 0.0, 90.0)
	var half: float = radius * (WIDTH / 2.0 - FLANGE_THICKNESS)
	if not hex.is_empty():
		kit.paint(hex, WorldPalette.Surface.SMOOTH, WorldPalette.PRINTED_GLOSS)
		kit.cylinder(radius * WINDING, half * 2.0, center, sideways, SIDES / 2)
	if not flanges:
		return
	for side: float in KitMesh.SIGNS:
		var face: Vector3 = center + Vector3(side * radius * (WIDTH / 2.0 - FLANGE_THICKNESS / 2.0), 0.0, 0.0)
		kit.paint(LookPalette.SPOOL_FLANGE, WorldPalette.Surface.SMOOTH, 0.35)
		kit.cylinder(radius, radius * FLANGE_THICKNESS, face, sideways, SIDES / 2)


## Un carrete guardado de canto en una repisa (biblia §9.4: el eje paralelo a
## la pared, en X), con el centro en `center`: el bobinado del color `hex` y
## las dos tapas abiertas (el aro con su canto y dos rayos cruzados); por el
## aro se ve el color. Sin las caras que tapa el bobinado: ~170 triángulos,
## para que quepan varios en la malla de un mueble.
static func add_on_shelf(kit: KitMesh, center: Vector3, radius: float, hex: String) -> void:
	var sideways: Vector3 = Vector3(0.0, 0.0, 90.0)
	var thickness: float = radius * FLANGE_THICKNESS
	kit.paint(hex, WorldPalette.Surface.SMOOTH, WorldPalette.PRINTED_GLOSS)
	kit.cylinder(radius * WINDING, radius * (WIDTH - FLANGE_THICKNESS * 2.0), center, sideways, SHELF_SIDES)
	for side: float in KitMesh.SIGNS:
		var face: Vector3 = center + Vector3(side * radius * (WIDTH / 2.0 - FLANGE_THICKNESS / 2.0), 0.0, 0.0)
		kit.paint(LookPalette.SPOOL_FLANGE, WorldPalette.Surface.SMOOTH, 0.35)
		# Acostado (giro de 90° en Z), el alto del torno va hacia −X: la tapa de
		# +X tiene su cara de afuera abajo en el torno.
		kit.lathe(_open_flange_profile(radius * RING_INNER, radius, thickness / 2.0, side < 0.0), face, sideways, SHELF_SIDES)
		for angle: float in [45.0, 135.0]:
			kit.box(Vector3(thickness, radius * RING_INNER * 2.0 + thickness, radius * SPOKE_WIDTH), face, 0.0, Vector3(angle, 0.0, 0.0))


## Una pila de carretes acostados (eje vertical, paralelo a la pared) con la
## base en `base`, de abajo hacia arriba con los colores `hexes`: se ven las
## bandas de color entre los cantos grises de las tapas (las de dos carretes
## que se tocan, en un solo canto) y arriba la tapa abierta. Sin las caras que
## tapa la pila.
static func add_stack(kit: KitMesh, base: Vector3, radius: float, hexes: Array[String]) -> void:
	var flange: float = radius * FLANGE_THICKNESS
	var band: float = radius * (WIDTH - FLANGE_THICKNESS * 2.0)
	var y: float = base.y
	for i: int in hexes.size():
		var rim: float = flange if i == 0 else flange * 2.0
		kit.paint(LookPalette.SPOOL_FLANGE, WorldPalette.Surface.SMOOTH, 0.35)
		kit.cylinder(radius, rim, Vector3(base.x, y + rim / 2.0, base.z), Vector3.ZERO, SHELF_SIDES, 0.0, -1.0, false)
		y += rim
		kit.paint(hexes[i], WorldPalette.Surface.SMOOTH, WorldPalette.PRINTED_GLOSS)
		kit.cylinder(radius * WINDING, band, Vector3(base.x, y + band / 2.0, base.z), Vector3.ZERO, SHELF_SIDES, 0.0, -1.0, false)
		y += band
	# Arriba: la tapa del bobinado (se ve por el aro), el aro con su canto y
	# los dos rayos.
	kit.disc(radius * WINDING, Vector3(base.x, y, base.z), Vector3(-90.0, 0.0, 0.0), SHELF_SIDES)
	kit.paint(LookPalette.SPOOL_FLANGE, WorldPalette.Surface.SMOOTH, 0.35)
	var top: Vector3 = Vector3(base.x, y + flange / 2.0, base.z)
	kit.lathe(_open_flange_profile(radius * RING_INNER, radius, flange / 2.0, true), top, Vector3.ZERO, SHELF_SIDES)
	for angle: float in [45.0, 135.0]:
		kit.box(Vector3(radius * RING_INNER * 2.0 + flange, flange, radius * SPOKE_WIDTH), top, 0.0, Vector3(0.0, angle, 0.0))


## Alto de una pila de `count` carretes de radio `radius` (add_stack).
static func stack_height(radius: float, count: int) -> float:
	return radius * WIDTH * count


## Perfil (radio, alto) de una tapa abierta vista de afuera: el canto y la
## cara de afuera del aro, arriba (`outer_up`) o abajo del torno. La cara de
## adentro no va (la tapa el bobinado).
static func _open_flange_profile(inner: float, outer: float, t: float, outer_up: bool) -> PackedVector2Array:
	if outer_up:
		return PackedVector2Array([Vector2(outer, -t), Vector2(outer, t), Vector2(outer, t), Vector2(inner, t)])
	return PackedVector2Array([Vector2(inner, -t), Vector2(outer, -t), Vector2(outer, -t), Vector2(outer, t)])


## Perfil (radio, alto) del bobinado: del núcleo al borde, con los cantos
## redondeados; centrado en el alto 0.
static func _winding_profile(radius: float) -> PackedVector2Array:
	var outer: float = radius * WINDING
	var core: float = radius * CORE
	var half: float = radius * (WIDTH / 2.0 - FLANGE_THICKNESS)
	var round: float = radius * 0.05
	return PackedVector2Array([
		Vector2(core, -half), Vector2(outer - round, -half), Vector2(outer, -half + round),
		Vector2(outer, half - round), Vector2(outer - round, half), Vector2(core, half),
	])


## Perfil (radio, alto) de un anillo plano de grosor 2·`t`: tapa de abajo,
## pared de afuera, tapa de arriba y pared de adentro, con cantos vivos.
static func _ring_profile(inner: float, outer: float, t: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(inner, -t), Vector2(outer, -t), Vector2(outer, -t), Vector2(outer, t),
		Vector2(outer, t), Vector2(inner, t), Vector2(inner, t), Vector2(inner, -t),
	])
