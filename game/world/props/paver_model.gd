class_name PaverModel
extends RefCounted
## Baldosa de concreto bajo la impresora del piso, con su cable hasta el
## enchufe de la pared del fondo (biblia de arte §9.3; idea del prototipo
## "Diorama"). Es decoración (va en Room/Decor): no se toca, no es obstáculo
## (queda bajo la impresora, que sí lo es) y no da sombra. La impresora se
## apoya encima: RoomLayout sube su lugar RoomLayout.FLOOR_PRINTER_RAISE.
##
## Una malla del kit en coordenadas del cuarto (el cable llega a la pared),
## guardada en caché por el lugar de la impresora.

## Ancho (x), alto y fondo (z) de la baldosa, y su bisel.
const SIZE: Vector3 = Vector3(0.54, RoomLayout.FLOOR_PRINTER_RAISE, 0.5)
const BEVEL: float = 0.006
## Granitos del concreto (discos chatos encima): cuántos, su radio y la
## huella de la impresora, que los taparía (solo van en el borde que se ve).
const GRAINS: int = 16
const GRAIN_RADIUS: Vector2 = Vector2(0.005, 0.01)
const GRAIN_SEED: int = 11
const PRINTER_FOOTPRINT: Vector2 = Vector2(0.45, 0.42)
## Radio del cable: en el piso mide 4 mm de alto (biblia §5.4).
const CABLE_RADIUS: float = 0.002
## Por dónde sale el cable de la impresora (su fuente de poder, atrás a la
## derecha; espacio de la impresora) y cuánto se aparta de la pared al bajar.
const CABLE_EXIT: Vector3 = Vector3(0.13, 0.03, -0.11)
const WALL_GAP: float = 0.026
## Enchufe (la caja del enchufe la arma RoomShell): medidas de la clavija.
const PLUG_SIZE: Vector3 = Vector3(0.034, 0.04, 0.024)


## La baldosa y el cable de la impresora del piso puesta en `spot` (el lugar
## de la impresora, ya subido): un hijo "Paver" de `decor`.
static func build(decor: Node3D, spot: Transform3D) -> MeshInstance3D:
	var on_floor: Transform3D = Transform3D(spot.basis, Vector3(spot.origin.x, 0.0, spot.origin.z))
	var key: String = "paver:%.3f:%.3f:%.4f" % [on_floor.origin.x, on_floor.origin.z, on_floor.basis.get_euler().y]
	var mesh: ArrayMesh = KitMesh.cached(key, func() -> ArrayMesh: return _mesh(on_floor))
	var paver: MeshInstance3D = PropBuilder.kit(decor, "Paver", mesh)
	paver.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return paver


static func _mesh(on_floor: Transform3D) -> ArrayMesh:
	var kit: KitMesh = KitMesh.new()
	# La baldosa es baja: con la oclusión de contacto toda su cara de arriba
	# quedaría sucia. El piso la asienta con su mancha (FloorAO).
	kit.ao_enabled = false
	kit.origin = on_floor
	kit.paint(LookPalette.CONCRETE_TILE, WorldPalette.Surface.SMOOTH, 0.12)
	kit.box(SIZE, Vector3(0.0, SIZE.y / 2.0, 0.0), BEVEL)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = GRAIN_SEED
	kit.paint(LookPalette.CONCRETE_GRAIN, WorldPalette.Surface.SMOOTH, 0.05)
	var inside: Vector2 = Vector2(SIZE.x, SIZE.z) / 2.0 - Vector2.ONE * (BEVEL + GRAIN_RADIUS.y)
	var hidden: Rect2 = Rect2(-PRINTER_FOOTPRINT / 2.0, PRINTER_FOOTPRINT)
	var placed: int = 0
	while placed < GRAINS:
		var at: Vector2 = Vector2(rng.randf_range(-inside.x, inside.x), rng.randf_range(-inside.y, inside.y))
		if hidden.has_point(at):
			continue
		kit.disc(rng.randf_range(GRAIN_RADIUS.x, GRAIN_RADIUS.y), Vector3(at.x, SIZE.y + 0.0005, at.y), Vector3(-90.0, rng.randf_range(0.0, 360.0), 0.0), 6)
		placed += 1
	_cable(kit, on_floor)
	return kit.commit()


## Del fondo de la impresora baja por la baldosa al piso, cruza el piso hasta
## la pared (entre los lugares 2 y 3, sin pisar ninguno) y sube a la clavija.
static func _cable(kit: KitMesh, on_floor: Transform3D) -> void:
	var lift: Vector3 = Vector3(0.0, SIZE.y, 0.0)
	var r: float = CABLE_RADIUS
	var wall: float = -RoomShell.SIZE / 2.0
	var plug: Vector3 = Vector3(RoomShell.OUTLET_X, RoomShell.OUTLET_Y, wall + 0.012 + PLUG_SIZE.z / 2.0)
	var points: PackedVector3Array = PackedVector3Array([
		on_floor * (CABLE_EXIT + lift),
		on_floor * (Vector3(0.15, r, -0.17) + lift),
		on_floor * (Vector3(0.16, r, -SIZE.z / 2.0 + 0.012) + lift),
		on_floor * Vector3(0.163, SIZE.y * 0.5, -SIZE.z / 2.0 - 0.006),
		on_floor * Vector3(0.166, r, -SIZE.z / 2.0 - 0.03),
		Vector3(RoomShell.OUTLET_X + 0.07, r, (on_floor.origin.z + wall) / 2.0 - 0.15),
		Vector3(RoomShell.OUTLET_X + 0.03, r, wall + 0.12),
		Vector3(RoomShell.OUTLET_X + 0.005, r, wall + WALL_GAP + 0.012),
		Vector3(RoomShell.OUTLET_X, 0.014, wall + WALL_GAP + 0.002),
		Vector3(RoomShell.OUTLET_X, 0.08, wall + WALL_GAP),
		Vector3(RoomShell.OUTLET_X, plug.y - PLUG_SIZE.y / 2.0, plug.z),
	])
	kit.origin = Transform3D.IDENTITY
	kit.paint(LookPalette.METAL_DARK, WorldPalette.Surface.SMOOTH, 0.3)
	kit.tube(points, r, 6, 4)
	kit.box(PLUG_SIZE, plug, 0.004)
