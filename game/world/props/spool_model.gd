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


static func build(parent: Node3D, node_name: String, position: Vector3, color_hex: String, radius: float = 0.1, flanges: bool = true) -> Node3D:
	var spool: Node3D = PropBuilder.group(parent, node_name, position)
	var filament: MeshInstance3D = PropBuilder.kit(spool, "Filament", winding_mesh(radius), WorldPalette.solid(color_hex))
	# La malla va a lo largo de Y: acostada, el eje queda en X.
	filament.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	if flanges:
		var mesh: ArrayMesh = KitMesh.cached("spool_flanges:%.3f" % radius, func() -> ArrayMesh:
			var kit: KitMesh = KitMesh.new()
			kit.ao_enabled = false
			add_flanges(kit, Vector3.ZERO, radius)
			return kit.commit())
		PropBuilder.kit(spool, "Flanges", mesh)
	return spool


## El bobinado: un anillo grueso del núcleo al borde, con los cantos
## redondeados. A lo largo de Y y centrado en el origen.
static func winding_mesh(radius: float) -> ArrayMesh:
	return KitMesh.cached("spool_winding:%.3f" % radius, func() -> ArrayMesh:
		var outer: float = radius * WINDING
		var core: float = radius * CORE
		var half: float = radius * (WIDTH / 2.0 - FLANGE_THICKNESS)
		var round: float = radius * 0.05
		var kit: KitMesh = KitMesh.new()
		kit.ao_enabled = false
		kit.lathe(PackedVector2Array([
			Vector2(core, -half), Vector2(outer - round, -half), Vector2(outer, -half + round),
			Vector2(outer, half - round), Vector2(outer - round, half), Vector2(core, half),
		]), Vector3.ZERO, Vector3.ZERO, SIDES)
		return kit.commit())


## Las dos tapas abiertas y su centro, en `kit`, para un carrete acostado (eje
## en X) con el centro en `center`.
static func add_flanges(kit: KitMesh, center: Vector3, radius: float) -> void:
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
		for i: int in 4:
			var angle: float = 45.0 + 90.0 * i
			var out: Vector3 = Vector3(0.0, cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * spoke_middle
			kit.box(Vector3(thickness, spoke_length, radius * SPOKE_WIDTH), face + out, 0.0, Vector3(angle, 0.0, 0.0))
		kit.paint(LookPalette.SPOOL_HUB, WorldPalette.Surface.SMOOTH, 0.3)
		kit.lathe(hub, face, sideways, HUB_SIDES)


## Perfil (radio, alto) de un anillo plano de grosor 2·`t`: tapa de abajo,
## pared de afuera, tapa de arriba y pared de adentro, con cantos vivos.
static func _ring_profile(inner: float, outer: float, t: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(inner, -t), Vector2(outer, -t), Vector2(outer, -t), Vector2(outer, t),
		Vector2(outer, t), Vector2(inner, t), Vector2(inner, t), Vector2(inner, -t),
	])
